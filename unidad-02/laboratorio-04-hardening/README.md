# LAB-04 — Hardening y configuración segura de PostgreSQL

## Objetivo

Analizar la configuración de seguridad de PostgreSQL, identificar posibles riesgos y aplicar medidas de hardening para reducir la superficie de ataque, mejorar la supervisión de las conexiones y establecer controles de acceso y límites de ejecución.

## Entorno

- **Sistema operativo:** Windows.
- **Sistema gestor de bases de datos:** PostgreSQL 18.6, 64 bits.
- **Herramienta de administración:** pgAdmin 4.
- **Puerto configurado:** 5432.
- **Archivo principal de configuración:** `C:\Program Files\PostgreSQL\18\data\postgresql.conf`.
- **Archivo de control de acceso:** `C:\Program Files\PostgreSQL\18\data\pg_hba.conf`.
- **Base de datos utilizada para las pruebas:** `db_20441231_zadkiel_quintero`.
- **Roles revisados:** `postgres` y `analista`.

## Superficie de ataque inicial

Durante la inspección inicial se identificaron distintos elementos relevantes para la seguridad del servidor:

- PostgreSQL estaba configurado para escuchar en todas las interfaces mediante `listen_addresses = '*'`.
- La autenticación de las conexiones locales y de loopback utilizaba `scram-sha-256`.
- El parámetro `ssl` estaba desactivado, por lo que la conexión comprobada no utilizaba TLS.
- Los registros de conexiones y desconexiones no estaban habilitados.
- Los límites globales de duración de consultas y de inactividad dentro de transacciones estaban configurados en `0`, lo que significaba que no tenían un límite establecido por esos parámetros.
- El registro de duración de consultas estaba desactivado mediante `log_min_duration_statement = -1`.
- El rol `analista` existía, pero inicialmente no podía iniciar sesión.
- Se revisaron los permisos de los roles, las extensiones instaladas, los archivos de configuración y los permisos del directorio de datos.

Estos elementos permitieron establecer una línea base para comparar la configuración inicial con los cambios posteriores.

## Hallazgos

Los principales hallazgos de la revisión fueron los siguientes:

1. **Escucha en todas las interfaces:** la configuración inicial de `listen_addresses` ampliaba la exposición potencial del servicio a interfaces de red distintas de las locales.
2. **Supervisión limitada:** los registros de conexiones, desconexiones y consultas lentas no estaban habilitados inicialmente.
3. **Ausencia de límites globales de tiempo:** las consultas y las transacciones inactivas no tenían límites establecidos por los parámetros revisados.
4. **Separación de funciones:** el rol `analista` existía, pero no podía iniciar sesión. Se necesitaba habilitar su acceso sin concederle privilegios administrativos.
5. **Permisos de conexión generales:** `PUBLIC` tenía el permiso `CONNECT` sobre la base de datos examinada.
6. **Cifrado de transporte:** TLS estaba desactivado en la configuración examinada.
7. **Controles sin cambios:** las reglas de `pg_hba.conf`, las reglas del firewall y los permisos del sistema operativo fueron revisados, pero no modificados durante esta práctica.

## Cambios realizados

Se aplicaron siete cambios de seguridad:

1. **Restricción de interfaces de escucha:** se cambió `listen_addresses = '*'` por `listen_addresses = 'localhost'`.
2. **Registro de conexiones y desconexiones:** se activaron `log_connections = on` y `log_disconnections = on`.
3. **Límites globales de tiempo:** se estableció `statement_timeout = '60s'` y `idle_in_transaction_session_timeout = '5min'`.
4. **Habilitación del rol `analista`:** se ejecutó `ALTER ROLE analista LOGIN`, conservando sus restricciones administrativas.
5. **Registro de consultas lentas:** se configuró `log_min_duration_statement = '1000ms'`.
6. **Restricción del permiso general de conexión:** se revocó `CONNECT` a `PUBLIC` y se concedió explícitamente a `postgres` y `analista`.
7. **Límite de consultas para `analista`:** se configuró `statement_timeout = '30s'` para las nuevas sesiones de este rol, estableciendo un límite más estricto que el global.


## Justificación de los cambios

Las modificaciones se realizaron con los siguientes propósitos:

- Reducir la exposición de PostgreSQL al limitar la escucha a las interfaces locales.
- Mejorar la trazabilidad mediante registros de conexiones y desconexiones.
- Reducir el riesgo de consultas excesivamente prolongadas y transacciones que permanezcan inactivas durante demasiado tiempo.
- Separar las tareas de análisis de las tareas administrativas mediante el uso del rol `analista`.
- Facilitar la identificación de consultas lentas.
- Aplicar el principio de mínimo privilegio al limitar el permiso general `CONNECT` de `PUBLIC`.

No se modificaron controles que requerían intervenciones adicionales, como TLS, las reglas del firewall y los permisos de Windows. Por ello, estos aspectos se mantienen identificados como áreas pendientes de evaluación o mejora.

## Verificación

Los cambios se comprobaron mediante consultas SQL, inspección de registros y comandos de PowerShell.

- **Interfaces de escucha:** se ejecutó `Get-NetTCPConnection -State Listen -LocalPort 5432`. Después del cambio, se observaron las direcciones `127.0.0.1` y `::1`.
- **Registros de conexiones:** se consultaron `SHOW log_connections;` y `SHOW log_disconnections;`. Ambos devolvieron `on`, y se observaron mensajes relacionados con las conexiones.
- **Límites de tiempo:** se verificaron `statement_timeout` e `idle_in_transaction_session_timeout`, con valores efectivos de `60s` y `5min`.
- **Rol `analista`:** se comprobaron sus atributos en `pg_roles` y se verificó que podía iniciar sesión sin privilegios de superusuario, creación de roles o creación de bases de datos.
- **Permisos de lectura:** desde la conexión de `analista`, se consultó `public.v_analitica_clientes` y se obtuvieron resultados. También se comprobaron los permisos de lectura y modificación sobre `public.clientes`.
- **Consultas lentas:** se verificó `log_min_duration_statement = '1s'` y se ejecutó `SELECT pg_sleep(1.2);`. Se encontró la entrada correspondiente en los registros.
- **Permiso `CONNECT`:** se comprobó que `postgres` y `analista` podían conectarse, mientras que `PUBLIC` ya no tenía el permiso general `CONNECT` sobre la base de datos examinada.


## Checklist de hardening

| Control | Estado | Observación |
|---|---|---|
| Puerto documentado | Verificado | Puerto 5432 |
| Interfaces de escucha | Verificado | Escucha local mediante `localhost` |
| `pg_hba.conf` | Revisado | No se modificó |
| Autenticación | Verificado | Se conserva `scram-sha-256` |
| Superusuarios | Revisado | Se conserva el rol administrativo `postgres` |
| Rol de análisis | Verificado | `analista` puede iniciar sesión sin privilegios administrativos |
| Privilegios de lectura y modificación | Verificado | Se comprobaron los permisos sobre la tabla y la vista |
| Extensiones | Revisado | `pgcrypto` y `plpgsql` permanecen instaladas |
| TLS | Revisado | `ssl = off`; no se habilitó TLS |
| Archivos de configuración | Revisados | Se inspeccionaron los permisos |
| Directorio de datos | Revisado | Se inspeccionaron los permisos |
| Firewall | Pendiente de implementación | Se documentó una propuesta, pero no se modificaron las reglas |
| Actualizaciones | Pendiente de verificación | No se documentó una comprobación final |
| Registros de conexiones | Verificado | Conexiones y desconexiones habilitadas |
| Límites de tiempo | Verificado | 60 segundos y 5 minutos |
| Registro de consultas lentas | Verificado | Umbral de 1 segundo |
| Permiso `CONNECT` | Verificado | Revocado a `PUBLIC` y concedido explícitamente a los roles necesarios |
| Registro de cambios | Verificado | Se documentaron seis cambios |
| Configuración final | Verificada | Se comprobaron los parámetros y accesos modificados |

## Conclusiones

La práctica permitió revisar la configuración inicial de PostgreSQL e identificar oportunidades de mejora en la exposición de red, la supervisión de las conexiones, los límites de ejecución y el control de acceso a la base de datos.

Se aplicaron seis cambios de hardening y se comprobaron sus resultados mediante consultas SQL, registros del servidor y comandos de PowerShell. También se verificó que el rol `analista` pudiera realizar consultas autorizadas sin disponer de privilegios administrativos.

Sin embargo, el hardening no debe considerarse completo. TLS permanece desactivado, no se modificaron las reglas del firewall ni los permisos del sistema operativo y queda pendiente documentar el estado de las actualizaciones. Estos controles requieren una evaluación adicional antes de considerar el servidor preparado para un entorno de producción.
