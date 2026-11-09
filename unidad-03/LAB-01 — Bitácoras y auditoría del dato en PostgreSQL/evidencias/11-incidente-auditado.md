# Evidencia 11 — Función y disparador de auditoría

## 1. Preguntas

**Pregunta 1. ¿Por qué se ejecuta `REVOKE ALL ON FUNCTION ... FROM PUBLIC` si el disparador seguirá funcionando para `app_ventas`?**

Por defecto, PostgreSQL otorga el privilegio `EXECUTE` sobre las funciones nuevas al pseudo-rol `PUBLIC`, es decir, a cualquier rol. Si no se revoca, cualquier usuario podría invocar directamente `auditoria.registrar_cambio_cliente()`. Como la función es `SECURITY DEFINER`, esa llamada correría con los privilegios de su dueño, que puede escribir en el esquema de auditoría.

El `REVOKE` no afecta al disparador. Un disparador no necesita que el usuario que modifica `clientes` tenga `EXECUTE` sobre la función: el privilegio se verifica al crear el disparador, y cuando se dispara, la función corre con los permisos de su dueño. Por eso `app_ventas` puede seguir haciendo `INSERT`, `UPDATE` y `DELETE` sobre `clientes` y la auditoría se registra igual, pero nadie puede ejecutar la función a mano. Esto sigue el principio de mínimo privilegio.

**Pregunta 2. ¿Qué pasaría si la función no fuera `SECURITY DEFINER`? (Hipótesis antes de la Actividad 12)**

**Hipótesis:** la función se ejecutaría con los privilegios del usuario que modifica la tabla (`app_ventas`). Ese rol no tiene permiso para escribir en `auditoria.cambios_clientes` (ni probablemente `USAGE` sobre el esquema `auditoria`), así que el `INSERT` dentro de la función fallaría con un error de `permiso denegado`.

Como el disparador es `AFTER ... FOR EACH ROW` y se ejecuta dentro de la misma transacción, ese error cancelaría toda la operación. Es decir, `app_ventas` no podría insertar, actualizar ni borrar clientes. La alternativa sería darle permisos de escritura sobre la tabla de auditoría, lo cual sería peor: podría alterar o borrar su propio rastro. `SECURITY DEFINER` permite que la auditoría se escriba sin darle ese acceso al usuario de la aplicación. Esta hipótesis se comprobará en la Actividad 12.

**Pregunta 3. Consulta `dba.bitacora`. ¿Quedó registrada la creación del esquema, la tabla, la función y el disparador? ¿Por qué?**

Se consulta con:

```sql
SELECT linea FROM dba.bitacora
WHERE linea LIKE '%CREATE SCHEMA%' OR linea LIKE '%CREATE TABLE%'
   OR linea LIKE '%CREATE FUNCTION%' OR linea LIKE '%CREATE OR REPLACE FUNCTION%'
   OR linea LIKE '%CREATE TRIGGER%'
ORDER BY num;
```

Sí quedaron registradas, siempre que `log_statement` esté en `ddl`, `mod` o `all`. `CREATE SCHEMA`, `CREATE TABLE`, `CREATE FUNCTION`, `CREATE TRIGGER` (y también el `REVOKE`) son sentencias DDL, y con esa configuración el servidor escribe en la bitácora el texto de cada una, junto con el usuario, la base de datos y la hora. Si `log_statement` estuviera en `none`, no aparecerían, porque no se registraría ninguna sentencia. Estas sentencias no dependen del disparador: la bitácora las registra a nivel de servidor, de forma independiente a la tabla de auditoría.

Esto muestra que hay dos niveles de auditoría complementarios: la bitácora del servidor registra los cambios de estructura (DDL), mientras que el disparador registra los cambios de datos en `clientes` (DML).

## 2. Conclusión

La función `auditoria.registrar_cambio_cliente()` y el disparador `trg_auditoria_clientes` permiten registrar automáticamente cada `INSERT`, `UPDATE` y `DELETE` sobre `clientes`, guardando los valores anteriores y posteriores en formato `jsonb`. La verificación en `pg_trigger` confirmó que el disparador quedó habilitado (`tgenabled = O`).

`SECURITY DEFINER` hace posible que la aplicación genere auditoría sin tener acceso a la tabla de auditoría, y `SET search_path = pg_catalog, public` evita que la función sea engañada por objetos falsos en otros esquemas. El `REVOKE ... FROM PUBLIC` cierra la posibilidad de que otros roles ejecuten la función directamente. Finalmente, la bitácora conservó la evidencia de la creación de los objetos, de modo que tanto los cambios de estructura como los de datos quedan rastreados.



# Evidencia 12 — El incidente auditado

## 1. Cambio del RFC desde la aplicación

La aplicación, conectándose como `app_ventas` con el nombre de aplicación `app-ventas-web`, cambió el RFC de María García (cliente con `id = 3`):

```powershell
psql "postgresql://app_ventas:<contraseña>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912ZZZ' WHERE id = 3"
```

**Resultado:**

```
UPDATE 1
```

Después, con el mismo usuario, intentó revisar la auditoría:

```powershell
psql "postgresql://app_ventas:<contraseña>@127.0.0.1/comercial" -c "SELECT * FROM auditoria.cambios_clientes"
```

**Resultado:**

```
ERROR:  permiso denegado al esquema auditoria
LÍNEA 1: SELECT * FROM auditoria.cambios_clientes
                       ^
```

**Interpretación:**

El `UPDATE` se ejecutó correctamente (1 fila modificada), pero la aplicación no puede leer la tabla de auditoría: no tiene permisos sobre el esquema `auditoria`. La auditoría se escribió igualmente porque el disparador llama a una función `SECURITY DEFINER`, que corre con los privilegios de su dueño y no con los de `app_ventas`.

## 2. Evento registrado en la auditoría

En la sesión de administrador se activó la presentación vertical (`\x`) y se consultó la tabla de auditoría:

```sql
\x
SELECT id_evento, momento, usuario_sesion, usuario_efectivo, aplicacion, ip_cliente, operacion, id_cliente
FROM auditoria.cambios_clientes ORDER BY id_evento;
\x
```

**Resultado:** 1 fila.

| Campo | Valor |
|---|---|
| id_evento | 1 |
| momento | 2026-11-08 21:38:57.39961-06 |
| usuario_sesion | app_ventas |
| usuario_efectivo | postgres |
| aplicacion | app-ventas-web |
| ip_cliente | 127.0.0.1 |
| operacion | UPDATE |
| id_cliente | 3 |

**Interpretación:**

El disparador registró quién, cuándo, desde dónde y qué operación se hizo. `usuario_sesion` conserva al usuario real (`app_ventas`), mientras que `usuario_efectivo` es `postgres` porque dentro de una función `SECURITY DEFINER`, `current_user` es el propietario de la función. Si la auditoría solo usara `current_user`, todos los cambios parecerían hechos por `postgres`; por eso se guarda también el usuario de la sesión.

## 3. Qué campo cambió

Para saber exactamente qué se modificó, se compararon `valores_antes` y `valores_despues` campo por campo:

```sql
SELECT a.id_evento, a.momento, a.usuario_sesion, a.ip_cliente,
       d.key                     AS campo,
       a.valores_antes ->> d.key AS antes,
       d.value #>> '{}'          AS despues
FROM auditoria.cambios_clientes a
CROSS JOIN LATERAL jsonb_each(a.valores_despues) d
WHERE a.operacion = 'UPDATE'
  AND a.valores_antes -> d.key IS DISTINCT FROM d.value
ORDER BY a.id_evento;
```

**Resultado:** 1 fila.

| id_evento | momento | usuario_sesion | ip_cliente | campo | antes | despues |
|---|---|---|---|---|---|---|
| 1 | 2026-11-08 21:38:57.39961-06 | app_ventas | 127.0.0.1 | rfc | GAMA780912XYZ | GAMA780912ZZZ |

**Interpretación:**

El único campo que cambió fue `rfc`: pasó de `GAMA780912XYZ` a `GAMA780912ZZZ`. La consulta funciona así:

| Parte | Qué hace |
|---|---|
| `jsonb_each(a.valores_despues)` | Convierte el documento en filas clave/valor, una por campo |
| `CROSS JOIN LATERAL` | Aplica esa función a cada fila de auditoría |
| `->>` / `#>> '{}'` | Extraen el valor como texto |
| `IS DISTINCT FROM` | Compara tratando correctamente los nulos |

## 4. Preguntas

**Pregunta 1. Compara tu hipótesis de la Actividad 11 con este resultado.**

La hipótesis fue que, sin `SECURITY DEFINER`, la función correría con los privilegios de `app_ventas`, que no puede escribir en el esquema de auditoría, y por lo tanto el `INSERT` fallaría y cancelaría toda la operación.

El resultado respalda esa hipótesis de forma indirecta. Con `SECURITY DEFINER`, el `UPDATE` funcionó y la auditoría se escribió (`usuario_efectivo = postgres` confirma que la función corrió con los privilegios de su dueño). Además, el error `permiso denegado al esquema auditoria` al hacer el `SELECT` demuestra que `app_ventas` efectivamente no tiene acceso a ese esquema; sin `SECURITY DEFINER`, el `INSERT` del disparador habría chocado con la misma restricción. La prueba directa (quitar `SECURITY DEFINER` y repetir el `UPDATE`) no se hizo en esta actividad.

**Pregunta 2. Escribe la sentencia `UPDATE` que restauraría el valor anterior.**

```sql
UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3;
```

Esta sentencia también activaría el disparador y quedaría registrada como un nuevo evento de auditoría, de modo que el historial completo se conserva: el cambio original y su reversión.

**Pregunta 3. ¿Qué columna conserva más valor para una investigación: `aplicacion` o `ip_cliente`? ¿Cuál puede falsificar el cliente con más facilidad?**

`ip_cliente` conserva más valor. Es la dirección desde la que el servidor recibió la conexión, y la obtiene el propio servidor, no el cliente. Permite ubicar el origen del cambio (aunque detrás de un proxy o NAT mostraría la dirección del intermediario).

`aplicacion` es la que el cliente puede falsificar con más facilidad, porque `application_name` lo declara el propio cliente en la cadena de conexión: en este laboratorio bastó con escribir `?application_name=app-ventas-web`, y la segunda conexión, sin ese parámetro, también funcionó. Sirve para distinguir aplicaciones legítimas, pero no es evidencia fuerte de identidad.

## 5. Conclusión

El incidente mostró el ciclo completo de una auditoría con disparador: la aplicación modificó el RFC de un cliente, la función `SECURITY DEFINER` registró el cambio sin que `app_ventas` tuviera acceso a la tabla de auditoría, y el administrador pudo reconstruir lo ocurrido: quién lo hizo (`usuario_sesion`), con qué privilegios corrió el registro (`usuario_efectivo`), desde dónde (`ip_cliente`), con qué aplicación declarada y cuándo.

La comparación de `valores_antes` y `valores_despues` con `jsonb_each` permitió identificar el campo exacto que cambió (`rfc`, de `GAMA780912XYZ` a `GAMA780912ZZZ`) y deducir la sentencia de restauración. También quedó claro que no todos los datos de auditoría valen lo mismo: los que determina el servidor (como `ip_cliente`) son más confiables que los que declara el cliente (como `application_name`).