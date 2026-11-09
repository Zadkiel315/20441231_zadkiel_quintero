# Evidencia 04 — Configuración de la bitácora

## 1. Configuración aplicada

Desde la sesión de administrador se ajustaron los parámetros de registro con `ALTER SYSTEM` y se recargó la configuración:

```sql
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();
```

| Parámetro | Valor | Qué hace |
|---|---|---|
| log_connections | on | Registra cada conexión al servidor |
| log_disconnections | on | Registra cada desconexión y la duración de la sesión |
| log_line_prefix | `%m [%p] user=%u db=%d app=%a client=%h ` | Cada línea incluye hora con milisegundos, PID, usuario, base de datos, aplicación y cliente |
| log_statement | ddl | Registra las sentencias de definición (CREATE, ALTER, DROP) |

`pg_reload_conf()` devolvió `t`: la señal de recarga fue enviada. La recarga es asíncrona, por lo que no garantiza que los valores ya estén aplicados al regresar.

## 2. Verificación del origen de los valores

```sql
SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');
```

| Parámetro | Valor | Origen | Archivo |
|---|---|---|---|
| log_connections | on | configuration file | `C:/Program Files/PostgreSQL/18/data/postgresql.auto.conf` |
| log_line_prefix | `%m [%p] user=%u db=%d app=%a client=%h ` | configuration file | `C:/Program Files/PostgreSQL/18/data/postgresql.auto.conf` |
| log_statement | ddl | configuration file | `C:/Program Files/PostgreSQL/18/data/postgresql.auto.conf` |

**Interpretación:**

Los tres valores quedaron aplicados y provienen de `postgresql.auto.conf`, el archivo que administra el servidor con `ALTER SYSTEM`. Con esto se confirma que el cambio se hizo por el mecanismo previsto y no editando archivos a mano.

## 3. Revisión de las últimas líneas de la bitácora

```sql
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 6;
```

La consulta devolvió 4 filas:

| num | Hora | Prefijo | Evento |
|---|---|---|---|
| 4 | 18:49:16.533 | `[524] user=postgres db=comercial app=psql client=::1` | Desconexión de la sesión anterior (duración 0:06:41) |
| 3 | 18:49:16.517 | `[17360] user=postgres db=comercial app=[desconocido] client=::1` | Conexión autorizada: usuario `postgres`, base `comercial`, aplicación `psql` |
| 2 | 18:49:16.517 | `[17360] user=postgres db=comercial app=[desconocido] client=::1` | Conexión autenticada con `scram-sha-256` (regla `pg_hba.conf` línea 117) |
| 1 | 18:49:16.492 | `[17360] user=[desconocido] db=[desconocido] app=[desconocido] client=::1` | Conexión recibida desde `::1` |

**Interpretación:**

El nuevo `log_line_prefix` ya está en uso: cada línea muestra ahora el usuario, la base de datos, la aplicación y el cliente, información que antes no aparecía (el prefijo anterior solo tenía la hora).

En la línea 1, el usuario y la base figuran como `[desconocido]` porque la conexión se acababa de recibir y todavía no estaba autenticada. En las líneas 2 y 3 el usuario ya aparece, y la aplicación todavía figura como `[desconocido]` hasta que la sesión la informa.

**Límite de la vista:**

Después de recargar la configuración, el colector comenzó un archivo nuevo (`log/postgresql-2026-11-06_000000.log`) y la vista `dba.bitacora` solo lee el archivo vigente. Por eso el resultado solo contiene las líneas posteriores al cambio. Los eventos anteriores (por ejemplo, la sesión de `app_ventas` de la actividad 3) están en el archivo anterior (`log/postgresql-2026-10-27_000000.log`), que se puede listar con `pg_ls_logdir()`.

## 4. Análisis

1. **Las sentencias `ALTER SYSTEM` no aparecen.** Cuando se ejecutaron, `log_statement` todavía valía `none`, por lo que no se registraron.
2. **No se observaron las líneas de aviso de cambio de parámetros** (`parameter ... changed to ...`) en la bitácora consultada. La recarga coincidió con el cambio de archivo y esos avisos no aparecieron ni en el archivo anterior ni en el vigente.
3. **La sesión del administrador sí quedó registrada** (líneas 1 a 4). Consultar la bitácora también deja rastro en ella.

## 5. Preguntas

**Pregunta 1. ¿Por qué el proceso que registra el cambio es el principal y no tu sesión?**

Porque `pg_reload_conf()` solo envía una señal de recarga al proceso principal del servidor (el *postmaster*) y regresa. Quien relee los archivos de configuración, aplica los nuevos valores y avisa de los parámetros que cambiaron es ese proceso, una sola vez, y no cada sesión. La sesión del administrador únicamente solicitó la recarga. Por eso esos avisos no llevan usuario ni base de datos en el prefijo: no pertenecen a una sesión de cliente.

**Pregunta 2. ¿Qué pasaría si alguien ejecutara `ALTER SYSTEM SET log_statement = 'none'`? ¿Quedaría rastro?**

Sí, debería quedar rastro, aunque limitado. Con `log_statement = 'ddl'` activo, la sentencia `ALTER SYSTEM` se registra, y con el nuevo prefijo la línea indicaría qué usuario, desde qué cliente y con qué aplicación la ejecutó. Después de la recarga, el servidor también avisaría de que el parámetro cambió a `none`. Esto no se probó en el laboratorio para no desactivar el registro.

El rastro tiene un límite: a partir de ese momento las sentencias dejarían de registrarse, por lo que cualquier cambio posterior quedaría sin evidencia hasta que alguien lo detecte y lo revierta. Por eso conviene proteger la bitácora, conservar sus archivos y revisarlos periódicamente.

**Pregunta 3. ¿Por qué no se recomienda editar `postgresql.auto.conf` a mano?**

Porque es un archivo administrado por el servidor. Un error de sintaxis o un valor inválido puede hacer fallar la recarga o incluso impedir que el servidor arranque, y al editarlo a mano no se validan los valores. Además, el archivo se reescribe con el siguiente `ALTER SYSTEM`, por lo que una edición manual puede perderse.

Por último, editarlo a mano se salta el registro de la sentencia: no queda en la bitácora quién hizo el cambio ni cuándo, lo que debilita la auditoría. Con `ALTER SYSTEM` el cambio pasa por el servidor, que lo valida y lo puede registrar.

## 6. Conclusión

Se configuraron el registro de conexiones y desconexiones, un prefijo de línea con usuario, base de datos, aplicación y cliente, y el registro de sentencias de definición (`log_statement = 'ddl'`). La consulta a `pg_settings` confirmó que los valores provienen de `postgresql.auto.conf`.

La bitácora ya identifica quién se conecta y desde dónde, algo que antes no era posible con el prefijo `%t`. Sin embargo, `log_statement = 'ddl'` no registra sentencias `UPDATE`, por lo que un incidente como el de la actividad 3 todavía no dejaría evidencia de la sentencia ejecutada.

También se observó que la vista `dba.bitacora` solo lee el archivo vigente y que, tras la recarga, el colector comenzó un archivo nuevo, por lo que los eventos anteriores quedan en archivos previos.