# Baseline de seguridad — LAB-04

## Actividad 1. Estado inicial de la superficie de ataque

**Versión instalada:** PostgreSQL 18.6 en Windows de 64 bits. La guía del laboratorio menciona PostgreSQL 16, por lo que existe una diferencia de versión que debe tenerse en cuenta.

| Parámetro | Valor inicial | Observación |
|---|---|---|
| Puerto | `5432` | Puerto configurado para PostgreSQL. |
| `listen_addresses` | `*` | Escucha en todas las interfaces disponibles, sujeto a las reglas de red y autenticación. |
| `ssl` | `off` | SSL/TLS está desactivado en la configuración actual del servidor. |
| `password_encryption` | `scram-sha-256` | Método configurado para almacenar nuevas contraseñas cuando se establecen o cambian. |
| Usuario observado | `postgres` | Se observa en las conexiones realizadas desde pgAdmin. |
| Dirección de conexión observada | `::1` | Corresponde a la dirección local de IPv6. |
| Conexiones remotas | No confirmadas en esta revisión | Las conexiones identificadas muestran `::1`; esto no demuestra por sí solo que el acceso remoto esté bloqueado. |

**Riesgos iniciales identificados:**

- La configuración `listen_addresses = '*'` puede exponer PostgreSQL en interfaces que no sean necesarias.
- SSL/TLS está desactivado, por lo que el servidor no proporciona cifrado TLS para las conexiones.
- Es necesario revisar las reglas de `pg_hba.conf`, los permisos de los usuarios y las restricciones del firewall antes de determinar el nivel real de exposición.

**Estado:** revisión inicial registrada. Todavía no se han aplicado cambios de hardening.

## Actividad 2. Archivos de configuración y registros

| Parámetro | Valor inicial |
|---|---|
| `config_file` | `C:/Program Files/PostgreSQL/18/data/postgresql.conf` |
| `hba_file` | `C:/Program Files/PostgreSQL/18/data/pg_hba.conf` |
| `ident_file` | `C:/Program Files/PostgreSQL/18/data/pg_ident.conf` |
| `data_directory` | `C:/Program Files/PostgreSQL/18/data` |
| `log_directory` | `log` |
| `log_connections` | Valor vacío en `pg_settings`; origen `default` |
| `log_disconnections` | `off` |

Los archivos de configuración, autenticación y datos se encuentran dentro del directorio de instalación de PostgreSQL. La revisión de los permisos del sistema operativo y de la generación efectiva de registros queda pendiente.

## Actividad 3. Configuración de interfaces de escucha

| Parámetro | Estado inicial |
|---|---|
| `listen_addresses` | `*` |
| Alcance configurado | Todas las interfaces disponibles |
| Riesgo identificado | Podría aceptar conexiones por interfaces innecesarias, según las reglas de red y autenticación. |
| Cambio aplicado | Ninguno; solo se revisó la configuración. |

Se recomienda limitar las interfaces de escucha a las necesarias para el uso previsto del servidor, después de confirmar si requiere conexiones desde otros equipos.

## Actividad 4. Configuración inicial de `pg_hba.conf`

| Elemento | Estado inicial |
|---|---|
| Reglas locales | 2 reglas de tipo `local` |
| Reglas IPv4 | 2 reglas para `127.0.0.1`: acceso general y replicación |
| Reglas IPv6 | 2 reglas para `::1`: acceso general y replicación |
| Bases de datos | `{all}` y `{replication}` |
| Usuarios | `{all}` |
| Método de autenticación | `scram-sha-256` en todas las reglas consultadas |
| Regla `0.0.0.0/0` | No aparece en los resultados |
| Regla `::/0` | No aparece en los resultados |
| Cambios aplicados | Ninguno |

Las reglas de tipo `host` están limitadas a las direcciones de loopback. Las reglas generales permiten la autenticación de todos los usuarios y bases de datos desde esas direcciones, mientras que las reglas de replicación se aplican a las conexiones de replicación. Se recomienda conservar el acceso local necesario y revisar las restricciones de usuarios y bases de datos de acuerdo con los requerimientos del entorno.

## Actividad 5. Análisis de una regla de acceso permisiva

| Elemento | Análisis |
|---|---|
| Regla analizada | `host all all 0.0.0.0/0 scram-sha-256` |
| Alcance | Todas las bases de datos, todos los usuarios y cualquier dirección IPv4 de origen |
| Método de autenticación | `scram-sha-256` |
| Riesgo identificado | Permite intentos de conexión desde cualquier origen IPv4 que pueda alcanzar el servidor, aunque la autenticación sigue siendo necesaria |
| Presencia en la configuración real | No se identificó en las reglas consultadas de `pg_hba.conf` |
| Cambio aplicado | Ninguno; se analizó una regla hipotética |

La regla se considera permisiva porque no limita el origen de las conexiones, las bases de datos ni los usuarios. Se recomienda definir restricciones según los equipos, las cuentas y las bases de datos que realmente necesiten conectarse.

## Actividad 6. Propuesta de acceso con mínimo privilegio

| Elemento | Configuración propuesta |
|---|---|
| Base de datos | `db_20441231_zadkiel_quintero` |
| Usuario | `usuario_app` (hipotético; existencia no confirmada) |
| Origen | `127.0.0.1/32` |
| Método de autenticación | `scram-sha-256` |
| Regla propuesta | `host db_20441231_zadkiel_quintero usuario_app 127.0.0.1/32 scram-sha-256` |
| Estado | Propuesta conceptual; no aplicada |

La propuesta restringe la conexión a una base de datos, un usuario y una dirección de origen. Antes de aplicarla, se debe confirmar que el usuario exista y que la aplicación requiera conexiones TCP/IP desde esa dirección.

## Actividad 7. Configuración de autenticación

| Parámetro | Estado inicial |
|---|---|
| `password_encryption` | `scram-sha-256` |
| Método configurado para establecer nuevas contraseñas | `scram-sha-256` |
| Cambio aplicado | Ninguno; solo se revisó la configuración |

SCRAM-SHA-256 es el mecanismo configurado para almacenar las contraseñas cuando se establecen o cambian. Esta configuración no implica que todas las contraseñas existentes se hayan actualizado automáticamente.

La autenticación verifica la identidad del usuario, mientras que la autorización determina las operaciones que puede realizar. El uso de SCRAM-SHA-256 debe complementarse con contraseñas seguras y permisos limitados para cada cuenta.

## Actividad 8. Roles y privilegios

| Elemento | Estado inicial |
|---|---|
| Roles consultados | 18 |
| Rol con `LOGIN` | `postgres` |
| Rol con `SUPERUSER` | `postgres` |
| Rol con `CREATEROLE` | `postgres` |
| Rol con `CREATEDB` | `postgres` |
| Rol de análisis identificado | `analista` (`LOGIN = false`) |
| Cambios aplicados | Ninguno; solo se consultaron los roles |

La consulta mostró que `postgres` es el único rol con capacidad de iniciar sesión y con los privilegios `SUPERUSER`, `CREATEROLE` y `CREATEDB` entre los roles obtenidos. El rol `analista` no puede iniciar sesión directamente.

Los demás roles identificados corresponden a roles predefinidos de PostgreSQL. No deben considerarse innecesarios únicamente por aparecer en la lista. Para determinar los permisos efectivos de cada cuenta, se requiere revisar también sus membresías y privilegios.

Se recomienda evitar el uso de `postgres` como cuenta habitual de una aplicación, debido a sus privilegios administrativos amplios. Las aplicaciones deben utilizar cuentas con los permisos mínimos necesarios para sus operaciones.

## Actividad 9. Separación de cuentas

| Cuenta propuesta | Propósito | LOGIN | Privilegios |
|---|---|---|---|
| DBA | Administración de PostgreSQL | Sí | Administrativos, según necesidad. |
| APP | Conexión de la aplicación | Sí | Mínimos necesarios para su funcionamiento. |
| CONSULTA | Consultas de información | Sí | Solo lectura sobre los objetos autorizados. |

**Estado:** diseño conceptual. Las cuentas no se han creado ni se han modificado los privilegios existentes.

**Recomendación:** utilizar cuentas independientes para la administración, la aplicación y las consultas, evitando conceder permisos administrativos a cuentas que no los necesitan.

## Actividad 10. Extensiones instaladas

| Extensión | Versión inicial | Observación |
|---|---|---|
| `pgcrypto` | `1.4` | Proporciona funciones criptográficas. Su necesidad debe confirmarse según el uso del entorno. |
| `plpgsql` | `1.0` | Lenguaje procedural utilizado para crear funciones y procedimientos en PostgreSQL. |

**Riesgo y recomendación:** no se identificó un riesgo únicamente por la presencia de estas extensiones. Se recomienda comprobar cuáles son necesarias para las aplicaciones y prácticas antes de considerar cualquier modificación.

**Estado:** extensiones identificadas. No se ha eliminado ni modificado ninguna.

## Actividad 11. Configuración relacionada con conexiones

| Parámetro | Valor inicial | Observación |
|---|---|---|
| `max_connections` | `100` | Permite hasta 100 conexiones simultáneas, sujeto a las conexiones reservadas. |
| `superuser_reserved_connections` | `3` | Reserva tres conexiones para superusuarios. |
| `statement_timeout` | `0` | No se establece un límite de tiempo para ejecutar instrucciones SQL. |
| `idle_in_transaction_session_timeout` | `0` | No se establece un límite para sesiones inactivas dentro de una transacción abierta. |

**Riesgo identificado:** al no existir límites de tiempo para las instrucciones SQL ni para las sesiones inactivas dentro de una transacción, algunas conexiones podrían permanecer ocupadas durante periodos prolongados.

**Recomendación:** evaluar límites de tiempo adecuados según las necesidades de las aplicaciones y del entorno, evitando interrumpir operaciones legítimas.

**Estado:** configuración inicial registrada. No se han aplicado cambios.

## Actividad 12. Permisos del sistema operativo

| Elemento | Resultado inicial |
|---|---|
| `postgresql.conf` | Control total para Administradores, SYSTEM, usuario de Windows y NETWORK SERVICE. |
| `pg_hba.conf` | Control total para Administradores, SYSTEM, usuario de Windows y NETWORK SERVICE. |
| Directorio `data` | Entradas directas `RX` para NETWORK SERVICE y usuario de Windows; también existen entradas heredables de control total. |
| Permisos modificados | Ninguno; solo se realizó una inspección. |

**Observación:** los permisos de los archivos de configuración y del directorio de datos son relevantes para impedir modificaciones o lecturas por usuarios no autorizados. Los resultados no muestran entradas explícitas para `Everyone` o `Users`, pero para evaluar la seguridad completa también deben considerarse las pertenencias a grupos y los permisos efectivos.

**Recomendación:** mantener el acceso limitado a las cuentas que necesitan administrar o ejecutar PostgreSQL. No modificar los permisos sin verificar primero los requisitos del servicio y las cuentas utilizadas por la instalación.