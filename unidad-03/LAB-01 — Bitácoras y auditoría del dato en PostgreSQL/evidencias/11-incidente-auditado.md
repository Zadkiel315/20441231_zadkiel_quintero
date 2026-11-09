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



