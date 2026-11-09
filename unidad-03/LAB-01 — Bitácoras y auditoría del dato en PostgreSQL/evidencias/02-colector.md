# Evidencia 02 — Colector de bitácoras y lectura de la bitácora desde SQL

## 1. Activación del colector

Se activó el colector de bitácoras y se consultó `pg_settings` para verificar si el cambio quedaba pendiente de reinicio.

```sql
ALTER SYSTEM SET logging_collector = on;
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';
```

| Parámetro | Valor | pending_restart |
|---|---|---|
| logging_collector | on | f |

**Interpretación:**

El parámetro `pending_restart` quedó en `f` porque el colector ya estaba activado desde la configuración inicial (evidencia 01). Por esa razón no fue necesario reiniciar el servicio.

## 2. Comprobación del resultado

```sql
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
SELECT pg_current_logfile();
```

| Parámetro | Valor | Origen |
|---|---|---|
| logging_collector | on | configuration file |

| Archivo de bitácora vigente |
|---|
| `log/postgresql-2026-10-27_000000.log` |

La ruta es relativa al directorio de datos (`C:/Program Files/PostgreSQL/18/data`), por lo que el archivo completo es `C:/Program Files/PostgreSQL/18/data/log/postgresql-2026-10-27_000000.log`.

## 3. Lectura de la bitácora desde el motor

La bitácora de este servidor está escrita con la página de códigos de Windows (Windows-1252), mientras que la base de datos usa UTF8. Por ello el archivo se lee como bytes con `pg_read_binary_file` y se convierte con `convert_from`, y después se divide en una fila por línea:

```sql
SELECT linea
FROM regexp_split_to_table(
       convert_from(pg_read_binary_file(pg_current_logfile()), 'LATIN1'),
       E'\n') AS linea;
```

| Parte de la consulta | Qué hace |
|---|---|
| `pg_current_logfile()` | Obtiene la ruta del archivo vigente |
| `pg_read_binary_file(...)` | Lee el archivo como bytes |
| `convert_from(..., 'LATIN1')` | Convierte los bytes a texto |
| `regexp_split_to_table(..., E'\n')` | Divide el texto en una fila por línea |

La consulta devolvió 53 filas con los eventos de conexión, autenticación, checkpoints y sentencias con error.

## 4. Creación de la vista `dba.bitacora`

Se creó un esquema de uso exclusivo del administrador y una vista para no repetir la consulta anterior:

```sql
CREATE SCHEMA dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;

CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(
       convert_from(pg_read_binary_file(pg_current_logfile()), 'LATIN1'),
       E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';
```

`WITH ORDINALITY` agrega el número de línea (`num`), útil para ordenar y para citar una línea en el informe. El `REVOKE` impide que roles sin permiso accedan al esquema.

## 5. Consultas sobre la vista

### 5.1 Últimas 10 líneas

```sql
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;
```

Devolvió las 10 últimas líneas del archivo (de la línea 71 a la 62), incluidos los eventos de checkpoint más recientes.

### 5.2 Líneas que contienen un texto, sin distinguir mayúsculas

```sql
SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';
```

Devolvió 1 fila, que corresponde a la propia consulta registrada en la bitácora. No aparece ningún `UPDATE` real, porque `log_statement` sigue en `none`.

### 5.3 Líneas que cumplen una expresión regular

```sql
SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';
```

Devolvió 9 filas. Entre ellas está el evento `FATAL` de las 17:07:01, un intento de autenticación fallido para el usuario `postgres` que coincidió con la regla de la línea 117 de `pg_hba.conf`, junto con varias líneas `ERROR` de la sesión de trabajo.

## 6. Preguntas

**Pregunta 1. ¿Por qué `logging_collector` requiere reinicio y `log_statement` solo recarga?**

`logging_collector` tiene contexto `postmaster`: el colector es un proceso auxiliar que se inicia junto con el servidor y recibe, mediante una tubería, la salida de error de todos los procesos hijos. Esa redirección se establece al arrancar y los procesos ya creados no pueden cambiarla, por lo que activarlo o desactivarlo exige reiniciar el servidor.

`log_statement` es un parámetro que cada sesión consulta mientras trabaja: decide si escribe o no una sentencia en el momento en que la procesa. Basta con que los procesos relean la configuración (recarga con `pg_reload_conf()`), sin reiniciar el servicio. Se puede comprobar con:

```sql
SELECT name, context FROM pg_settings WHERE name IN ('logging_collector', 'log_statement');
```

**Pregunta 2. ¿Qué ventaja tiene que la bitácora se lea con SQL y no con una herramienta del sistema operativo o del contenedor? ¿Qué riesgo introduce?**

*Ventajas:*

- No se necesita acceso al sistema operativo ni al contenedor; basta una sesión de administrador.
- Se puede filtrar con `WHERE`, `ILIKE` y expresiones regulares, y ordenar y limitar resultados con el mismo lenguaje que ya se usa.
- La numeración de líneas permite citarlas en el informe.
- El archivo pertenece al usuario del servicio y tiene permisos restringidos; la vista evita ese problema porque el servidor lee su propio archivo.

*Riesgos:*

- La bitácora puede contener datos sensibles: sentencias SQL, nombres de usuario, direcciones IP y valores de datos dentro de los mensajes de error.
- `pg_read_file` y `pg_read_binary_file` son funciones privilegiadas. Como la vista se ejecuta con los privilegios de su propietario, cualquier rol con `SELECT` sobre ella podría leer el archivo aunque no tenga permiso para usar esas funciones.
- Leer la bitácora también deja rastro en ella: las consultas sobre la vista aparecen registradas (se observó en la consulta 5.2).
- Solo se lee el archivo vigente y la codificación del archivo puede mezclar formatos, por lo que algunos caracteres especiales pueden verse mal.

**Pregunta 3. ¿Quién debería poder consultar `dba.bitacora`?**

Solo el rol administrador (`postgres`) o un rol de auditoría creado expresamente para ello, con permisos otorgados de forma explícita (`USAGE` sobre el esquema `dba` y `SELECT` sobre la vista). No deben tener acceso los roles de aplicación ni de soporte, como `app_ventas` y `soporte_ana`.

El esquema `dba` ya tiene `REVOKE ALL ... FROM PUBLIC`, por lo que los roles sin permiso no pueden acceder a la vista. Como medida adicional, la vista puede crearse con `WITH (security_invoker = on)`, de modo que se ejecute con los privilegios de quien la consulta y no con los del propietario.

## 7. Conclusión

La actividad permitió comprobar que el servidor tiene el colector de bitácoras activado y que escribe sus eventos en archivos dentro del directorio `log/`, con la ruta del archivo vigente disponible mediante `pg_current_logfile()`.

También se logró leer esa bitácora desde SQL mediante la vista `dba.bitacora`, que permite ordenar, filtrar y buscar eventos con consultas comunes. Las consultas de verificación confirmaron que la bitácora registra conexiones, autenticaciones, un intento de acceso fallido y errores, pero no las sentencias `UPDATE`, porque `log_statement` sigue en `none`.

Finalmente, se identificó que la vista expone información sensible del servidor, por lo que su acceso debe limitarse al administrador o a un rol de auditoría.