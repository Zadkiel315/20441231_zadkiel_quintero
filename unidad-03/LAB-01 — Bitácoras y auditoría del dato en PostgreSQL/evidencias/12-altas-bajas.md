# Evidencia 12 — Altas y bajas

## 1. Alta y baja de un cliente como administrador

En la sesión de administrador (`postgres`) se insertó un cliente y después se eliminó:

```sql
INSERT INTO clientes (nombre, correo, rfc, edad, ciudad, codigo_postal)
VALUES ('Pedro Ruiz', 'pedro.ruiz@example.test', 'RUPE950101AAA', 30, 'Guasave', '81000');

DELETE FROM clientes WHERE nombre = 'Pedro Ruiz';
```

**Resultado:**

```
INSERT 0 1
DELETE 1
```

**Interpretación:**

Las dos operaciones afectaron una fila cada una. Al terminar, `Pedro Ruiz` ya no existe en la tabla `clientes`, pero el disparador `trg_auditoria_clientes` se ejecutó en ambas operaciones.

## 2. Eventos registrados en la auditoría

Se consultó la tabla de auditoría mostrando el RFC antes y después de cada evento:

```sql
SELECT id_evento, usuario_sesion, aplicacion, ip_cliente, operacion, id_cliente,
       valores_antes ->> 'rfc' AS rfc_antes, valores_despues ->> 'rfc' AS rfc_despues
FROM auditoria.cambios_clientes ORDER BY id_evento;
```

**Resultado:** 3 filas.

| id_evento | usuario_sesion | aplicacion | ip_cliente | operacion | id_cliente | rfc_antes | rfc_despues |
|---|---|---|---|---|---|---|---|
| 1 | app_ventas | app-ventas-web | 127.0.0.1 | UPDATE | 3 | GAMA780912XYZ | GAMA780912ZZZ |
| 2 | postgres | psql | ::1 | INSERT | 6 | | RUPE950101AAA |
| 3 | postgres | psql | ::1 | DELETE | 6 | RUPE950101AAA | |

**Interpretación:**

El evento 1 es el cambio de RFC de la actividad anterior. Los eventos 2 y 3 corresponden al alta y a la baja de `Pedro Ruiz` (`id_cliente = 6`). Cada operación deja una huella distinta: el `INSERT` solo tiene valores posteriores (`rfc_antes` vacío), el `DELETE` solo tiene valores anteriores (`rfc_despues` vacío) y el `UPDATE` tiene ambos. Los eventos 2 y 3 quedaron a nombre de `postgres` desde la aplicación `psql`, porque se hicieron desde la sesión del administrador.

## 3. Preguntas

**Pregunta 1. El cliente `Pedro Ruiz` ya no existe en `clientes`. ¿Dónde queda evidencia de que existió y de sus datos?**

En la tabla `auditoria.cambios_clientes`. El evento 2 (`INSERT`) guarda en `valores_despues` el registro completo tal como se creó, y el evento 3 (`DELETE`) guarda en `valores_antes` el registro completo tal como estaba al momento de borrarlo, en formato `jsonb`. Es decir, el disparador conserva todos los campos (nombre, correo, RFC, edad, ciudad y código postal), no solo el RFC que se mostró en la consulta. Se pueden ver con:

```sql
SELECT valores_antes FROM auditoria.cambios_clientes WHERE id_evento = 3;
```

Además, si `log_statement` está en `mod` o `all`, la bitácora del servidor (`dba.bitacora`) también conserva el texto de las sentencias `INSERT` y `DELETE`, con el usuario y la hora.

**Pregunta 2. ¿Por qué `ip_cliente` está vacía en los eventos 2 y 3?**

En la guía se esperaba vacía porque `ip_cliente` queda en `NULL` cuando el cliente se conecta por un socket local de Unix, sin pasar por la red (lo habitual en un servidor Linux).

En este laboratorio no ocurrió así: el resultado muestra `::1` en los eventos 2 y 3. En Windows, `psql` se conecta por TCP a `localhost` y no por un socket de Unix, por lo que el servidor registra la dirección de bucle local IPv6 (`::1`). Es el mismo comportamiento observado en la Evidencia 09 con `pg_stat_activity`. En cambio, el evento 1 muestra `127.0.0.1` porque la aplicación se conectó explícitamente a esa dirección IPv4.

**Pregunta 3. La política de retención de la Unidad II pedía eliminar datos cuando ya no fueran necesarios. ¿Qué conflicto aparece? ¿Quién debe resolverlo?**

El conflicto es que borrar a `Pedro Ruiz` de `clientes` no borra sus datos personales: siguen completos en `auditoria.cambios_clientes` (nombre, correo, RFC, etc.) y en la bitácora, sin fecha de caducidad. La política de retención pide eliminar los datos cuando ya no se necesitan, pero la auditoría necesita conservar el historial para poder reconstruir lo ocurrido. Ambas necesidades chocan: si se elimina el rastro, se pierde la capacidad de investigar; si se conserva sin límite, se retienen datos personales más tiempo del necesario.

No lo debe resolver el administrador de base de datos por sí solo. Es una decisión de gobierno de datos que corresponde al responsable de los datos junto con las áreas legal y de cumplimiento (y la dirección), que deben definir cuánto tiempo se conserva la auditoría, quién puede consultarla y qué se hace al vencer el plazo (por ejemplo, borrarla o anonimizarla). El administrador implementa esa decisión técnicamente, por ejemplo con una purga programada de la tabla de auditoría y restricciones de acceso.

## 4. Conclusión

El disparador de auditoría registró tanto el alta como la baja del cliente `Pedro Ruiz`, conservando el registro completo en `valores_despues` (alta) y en `valores_antes` (baja). Así, aunque el cliente ya no exista en `clientes`, queda evidencia de que existió, quién lo creó y quién lo eliminó, y cuándo.

La actividad también mostró que la dirección `ip_cliente` depende de cómo se conecta el cliente (`::1` en Windows por TCP local, `NULL` en Linux por socket de Unix) y que la auditoría genera una tensión con la política de retención: los datos eliminados de `clientes` siguen existiendo en la auditoría. Resolverlo requiere definir una política de conservación de la auditoría, decisión que corresponde al responsable de los datos y al área legal, y que el administrador debe implementar.