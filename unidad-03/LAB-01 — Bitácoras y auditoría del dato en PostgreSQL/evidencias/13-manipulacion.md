# Evidencia 13 — Intento de manipular la auditoría

## 1. Intento desde la cuenta de la aplicación

Desde la cuenta `app_ventas` se intentó borrar la tabla de auditoría y desactivar el disparador:

```powershell
psql "postgresql://app_ventas:<contraseña>@127.0.0.1/comercial?application_name=app-ventas-web" -c "DELETE FROM auditoria.cambios_clientes" -c "ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes"
```

**Resultado:**

```
ERROR:  permiso denegado al esquema auditoria
LÍNEA 1: DELETE FROM auditoria.cambios_clientes
                     ^
ERROR:  debe ser dueño de la tabla clientes
```

**Interpretación:**

Los dos intentos fallaron. `app_ventas` no tiene permisos sobre el esquema `auditoria`, por lo que no puede borrar ni leer la tabla de auditoría, y tampoco es dueño de `clientes`, por lo que no puede desactivar el disparador. Los controles de privilegios protegen la auditoría frente a la cuenta de la aplicación.

## 2. Manipulación desde la cuenta de administrador

Desde la sesión de administrador se desactivó el disparador, se modificó un dato y se volvió a activar:

```sql
ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;
UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3;
ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;
SELECT count(*) FROM auditoria.cambios_clientes;
```

**Resultado:**

```
ALTER TABLE
UPDATE 1
ALTER TABLE
```

| count |
|---|
| 3 |

**Interpretación:**

El administrador, al ser propietario de `clientes`, sí pudo desactivar el disparador. El `UPDATE` se ejecutó (1 fila), pero la tabla de auditoría sigue con 3 eventos: el cambio del RFC a `GAMA780912GHI` **no quedó registrado** en ella. Es decir, un cambio de datos pasó sin auditoría.

## 3. Revisión de la bitácora del servidor

Se buscó en la bitácora el rastro de esas sentencias:

```sql
SELECT linea FROM dba.bitacora
WHERE linea ~ 'statement: (ALTER TABLE clientes (DIS|EN)ABLE|UPDATE clientes SET rfc = .GAMA780912GHI)'
ORDER BY num;
```

**Resultado:** 0 filas.

**Interpretación:**

La consulta no devolvió filas porque el patrón buscaba el texto `statement:` (mensajes en inglés), mientras que el servidor de este laboratorio emite sus mensajes en español, por lo que en la bitácora la etiqueta es `sentencia:`. La búsqueda se repitió con el patrón en español:

```sql
SELECT linea FROM dba.bitacora
WHERE linea ~ 'sentencia: (ALTER TABLE clientes (DIS|EN)ABLE|UPDATE clientes SET rfc = .GAMA780912GHI)'
ORDER BY num;
```

**Resultado:** 4 filas.

| Hora | PID | Usuario | Aplicación | Cliente | Sentencia |
|---|---|---|---|---|---|
| 21:54:04.145 | 7220 | app_ventas | app-ventas-web | 127.0.0.1 | `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes` |
| 21:54:23.187 | 17360 | postgres | psql | ::1 | `ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes;` |
| 21:54:23.203 | 17360 | postgres | psql | ::1 | `UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3;` |
| 21:54:23.223 | 17360 | postgres | psql | ::1 | `ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes;` |

**Interpretación:**

La bitácora conservó el rastro completo, aunque la tabla de auditoría no lo tenga. La primera línea es el intento de `app_ventas` (PID 7220): la sentencia se registra antes de ejecutarse, aunque después falle por falta de privilegios. Las otras tres, de `postgres` (PID 17360, la misma sesión de administrador), muestran cómo se desactivó el disparador, se modificó el RFC y se volvió a activar, en una ventana de menos de 100 milisegundos. Que el `UPDATE` aparezca indica además que `log_statement` registra sentencias que modifican datos (`mod` o `all`).

La actividad deja este contraste entre las dos fuentes de evidencia:

| Fuente | Qué guarda | Quién puede debilitarla |
|---|---|---|
| Tabla de auditoría | Detalle del dato (antes y después) | La puede desactivar el propietario de la tabla |
| Bitácora del servidor | Que el mecanismo se desactivó | La puede alterar quien controle el servidor |

## 4. Preguntas

**Pregunta 1. ¿Qué evidencia permite detectar que hubo un cambio sin auditar?**

Hay varias señales que, combinadas, delatan el cambio:

- **La bitácora del servidor:** registra las sentencias `ALTER TABLE clientes DISABLE TRIGGER`, el `UPDATE` y `ENABLE TRIGGER` ejecutados por `postgres`, con su hora y su PID, aun cuando la tabla de auditoría no tenga nada.
- **El conteo de la tabla de auditoría:** sigue en 3 después de un `UPDATE` que sí se ejecutó (`UPDATE 1`).
- **El desajuste entre `clientes` y la auditoría:** el RFC actual del cliente 3 es `GAMA780912GHI`, pero el último valor registrado en `valores_despues` para ese cliente es `GAMA780912ZZZ`. Un dato actual que no coincide con el último evento auditado indica un cambio sin registrar.

Detectarlo exige comparar las dos fuentes: ninguna por sí sola lo muestra de forma completa.

**Pregunta 2. ¿Qué control administrativo (no técnico) reduciría este riesgo?**

La revisión periódica e independiente de la bitácora, junto con un procedimiento formal de gestión de cambios: que cualquier intervención del administrador sobre estructuras de auditoría (como desactivar un disparador) requiera una solicitud autorizada y quede documentada, y que un responsable ajeno al equipo de base de datos revise la bitácora y concilie esos cambios contra las autorizaciones. Complementan este control enviar las bitácoras a un sistema externo administrado por otra área y exigir cuentas nombradas (no compartidas) para los administradores.

**Pregunta 3. Relaciona esta actividad con el principio de separación de funciones de la Unidad II.**

La separación de funciones establece que una sola persona no debe controlar todas las etapas de un proceso sensible, para que nadie pueda cometer y ocultar una irregularidad. Aquí el administrador de la base de datos podía operar los datos, desactivar el disparador y, con control del servidor, alterar la bitácora: concentraba tanto la operación como la custodia de la evidencia, y nada dentro de PostgreSQL lo detiene.

La cuenta de la aplicación sí estaba bien limitada: no podía tocar la auditoría ni el disparador. El riesgo restante está en quien tiene control total. Por eso se separa a quien opera la base (el administrador) de quien custodia la evidencia (un área de auditoría o seguridad que recibe las bitácoras en un sistema que el administrador no controla).

## 5. Conclusión

La actividad mostró dos niveles de protección. Frente a la cuenta de la aplicación, los privilegios funcionaron: `app_ventas` no pudo borrar la auditoría ni desactivar el disparador. Frente al administrador, no: al ser propietario de `clientes`, desactivó el disparador, cambió el RFC del cliente 3 a `GAMA780912GHI` y lo reactivó, y la tabla de auditoría quedó en 3 eventos, sin rastro de ese cambio.

La detección depende de contrastar fuentes: la bitácora del servidor registra que el mecanismo se desactivó y la tabla de auditoría ya no coincide con el estado real de `clientes`. Pero ningún mecanismo dentro del propio servidor protege contra un administrador con control total. Por eso se requieren controles administrativos y organizacionales: separación de funciones, revisión independiente y envío de las bitácoras a un sistema externo custodiado por otra área.