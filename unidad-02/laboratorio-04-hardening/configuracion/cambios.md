# Registro de cambios de seguridad

## Cambio 1. Restringir las interfaces de escucha

| Campo | Descripción |
|---|---|
| Archivo modificado | `C:\Program Files\PostgreSQL\18\data\postgresql.conf` |
| Parámetro | `listen_addresses` |
| Valor anterior | `*` |
| Valor nuevo | `localhost` |
| Motivo | Restringir las conexiones a las interfaces locales, ya que PostgreSQL se utiliza desde este equipo mediante pgAdmin. |
| Respaldo | Se guardaron copias de `postgresql.conf` y `pg_hba.conf` en `Documents\Respaldo-PostgreSQL-LAB04`. |
| Aplicación | Se reinició el servicio de PostgreSQL 18. |
| Verificación | Se ejecutó `Get-NetTCPConnection -State Listen -LocalPort 5432` en PowerShell. |
| Resultado obtenido | Las direcciones en escucha fueron `127.0.0.1` y `::1`, ambas en el puerto `5432`. |
| Estado | Cambio aplicado y verificado correctamente. |

## Cambio 2. Activar el registro de conexiones y desconexiones

| Campo | Descripción |
|---|---|
| Archivo modificado | `C:\Program Files\PostgreSQL\18\data\postgresql.conf` |
| Parámetros | `log_connections` y `log_disconnections` |
| Valores anteriores | `log_connections`: predeterminado (efectivamente `off`); `log_disconnections`: `off` |
| Valores nuevos | Ambos parámetros configurados en `on` |
| Motivo | Mejorar la auditoría de las sesiones mediante el registro de conexiones y desconexiones. |
| Aplicación | Se guardaron los parámetros y se reinició el servicio de PostgreSQL 18. |
| Verificación | Se ejecutaron `SHOW log_connections;` y `SHOW log_disconnections;` en pgAdmin. |
| Resultado obtenido | Ambos parámetros devolvieron `on`. |
| Estado | Cambio aplicado y verificado correctamente. |

### Evidencia adicional del Cambio 2

| Comprobación | Resultado |
|---|---|
| Registro de conexiones | Se observaron mensajes de conexión recibida, autenticación y autorización. |
| Dirección del cliente | `::1` (interfaz local IPv6). |
| Método de autenticación | `scram-sha-256`. |
| Bases de datos observadas | `postgres` y `db_20441231_zadkiel_quintero`. |
| Resultado | Se confirmó que PostgreSQL está generando mensajes de registro relacionados con las conexiones. |

## Cambio 3. Configurar tiempos de espera

| Campo | Descripción |
|---|---|
| Archivo modificado | `C:\Program Files\PostgreSQL\18\data\postgresql.conf` |
| Parámetros modificados | `statement_timeout` e `idle_in_transaction_session_timeout` |
| Valores anteriores | Ambos parámetros tenían el valor `0`. |
| Valores nuevos | `statement_timeout = 60s`; `idle_in_transaction_session_timeout = 5min`. |
| Motivo | Limitar la duración de consultas y evitar que las sesiones mantengan transacciones abiertas mientras permanecen inactivas. |
| Aplicación | Se guardaron los cambios y se recargó la configuración mediante `pg_reload_conf()`. |
| Verificación | Se ejecutaron `SHOW statement_timeout;` y `SHOW idle_in_transaction_session_timeout;`. |
| Resultado | Ambos parámetros devolvieron los valores configurados. |
| Estado | Cambio aplicado y verificado correctamente. |

## Cambio 4. Habilitar el inicio de sesión del rol `analista`

| Campo | Descripción |
|---|---|
| Objeto modificado | Rol `analista` en PostgreSQL. |
| Atributo anterior | `LOGIN` deshabilitado (`rolcanlogin = false`). |
| Atributo nuevo | `LOGIN` habilitado (`rolcanlogin = true`). |
| Comando ejecutado | `ALTER ROLE analista LOGIN;` |
| Motivo | Permitir que el rol `analista` se utilice para tareas cotidianas, separadas de las actividades administrativas realizadas con `postgres`. |
| Verificación de atributos | Se consultó `pg_roles` para comprobar los atributos del rol. |
| Resultado obtenido | `rolsuper = false`, `rolcreaterole = false`, `rolcreatedb = false` y `rolcanlogin = true`. |
| Permisos revisados | Se confirmó acceso de lectura (`SELECT`) sobre `public.clientes` y `public.v_analitica_clientes`. |
| Prueba de lectura | Se ejecutó una consulta sobre `public.v_analitica_clientes` utilizando la conexión de `analista`, obteniendo resultados. |
| Prueba de privilegios | `INSERT = false`, `UPDATE = false`, `DELETE = false` y `SELECT = true` sobre `public.clientes`. |
| Estado | Inicio de sesión habilitado y atributos verificados. La conexión y la consulta de lectura funcionaron; se comprobaron los permisos efectivos de lectura y modificación indicados. |

**Consideración de seguridad:** el rol `analista` no tiene privilegios de superusuario ni permisos para crear roles o bases de datos. La contraseña no debe incluirse en este archivo ni en otros archivos del repositorio.

## Cambio 5. Activar el registro de consultas lentas

| Campo | Descripción |
|---|---|
| Archivo modificado | `C:\Program Files\PostgreSQL\18\data\postgresql.conf` |
| Parámetro | `log_min_duration_statement` |
| Valor anterior | `-1` (registro de duración de consultas desactivado). |
| Valor nuevo | `1000ms` (1 segundo). |
| Motivo | Facilitar la identificación de consultas que tardan demasiado en ejecutarse y apoyar la supervisión del rendimiento de PostgreSQL. |
| Configuración aplicada | Se agregó `log_min_duration_statement = '1000ms'` al archivo de configuración. |
| Aplicación | Se recargó la configuración mediante `pg_reload_conf()`. |
| Verificación | Se consultó `SHOW log_min_duration_statement;`, que devolvió `1s`. |
| Prueba realizada | Se ejecutó `SELECT pg_sleep(1.2);` para generar una consulta con una duración superior al umbral configurado. |
| Resultado obtenido | Se confirmó la presencia de una entrada correspondiente a la consulta lenta en el registro de PostgreSQL. |
| Estado | Cambio aplicado y verificado correctamente. |

**Consideración de seguridad:** los registros pueden contener sentencias SQL y otra información potencialmente sensible. Deben protegerse los archivos de registro y limitarse su acceso a usuarios autorizados.

## Cambio 6. Restringir el permiso general de conexión a la base de datos

**Archivo o componente afectado:** Privilegios de la base de datos `db_20441231_zadkiel_quintero`.

**Objetivo:** Reducir el acceso general a la base de datos mediante la revocación del permiso `CONNECT` para el rol especial `PUBLIC`, manteniendo el acceso explícito de los roles necesarios.

### Configuración anterior

El rol `PUBLIC` tenía permiso para conectarse a la base de datos. Los roles `postgres` y `analista` podían iniciar sesión.

### Cambio aplicado

Se ejecutaron las siguientes instrucciones SQL:

```sql
REVOKE CONNECT ON DATABASE db_20441231_zadkiel_quintero FROM PUBLIC;

GRANT CONNECT ON DATABASE db_20441231_zadkiel_quintero TO postgres;
GRANT CONNECT ON DATABASE db_20441231_zadkiel_quintero TO analista;
```

### Verificación

Se consultaron los privilegios efectivos y se obtuvo el siguiente resultado:

| Rol | Puede conectarse |
|---|---|
| `postgres` | `true` |
| `analista` | `true` |
| `PUBLIC` | `false` |

Posteriormente, desde la conexión independiente de `analista`, se verificó la identidad y la base de datos mediante:

```sql
SELECT current_user, current_database();
```

Resultado: `analista`, `db_20441231_zadkiel_quintero`.

También se consultó la vista `public.v_analitica_clientes` con `LIMIT 5`, y se obtuvieron cinco filas de resultados.

**Estado:** Aplicado y verificado. El rol `analista` conserva su capacidad de conexión y consulta de la vista, mientras que `PUBLIC` ya no tiene el permiso general `CONNECT` sobre esta base de datos.

## Cambio 7. Establecer un límite de consultas para el rol `analista`

| Campo | Descripción |
|---|---|
| Objeto modificado | Configuración del rol `analista`. |
| Parámetro | `statement_timeout`. |
| Valor anterior | `60s`, heredado de la configuración global. |
| Valor nuevo | `30s` para las nuevas sesiones de `analista`. |
| Comando ejecutado | `ALTER ROLE analista SET statement_timeout = '30s';` |
| Motivo | Limitar el tiempo de ejecución de consultas del rol de análisis y evitar consultas prolongadas. |
| Verificación | Consultar `pg_roles.rolconfig` y ejecutar `SHOW statement_timeout;` desde una nueva sesión de `analista`. |
| Estado | Marcar como aplicado y verificado únicamente después de confirmar el valor `30s` desde la conexión de `analista`.