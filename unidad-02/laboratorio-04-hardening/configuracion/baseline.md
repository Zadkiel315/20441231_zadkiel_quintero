## Actividad 1. Estado inicial de la superficie de ataque

**Versión instalada:** PostgreSQL 18.6 en Windows de 64 bits. La guía del laboratorio menciona PostgreSQL 16, por lo que existe una diferencia de versión que debe tenerse en cuenta.

| Parámetro | Valor inicial | Observación |
|---|---|---|
| Puerto | `5432` | Puerto configurado para PostgreSQL. |
| `listen_addresses` | `*` | Escucha en todas las interfaces disponibles, sujeto a las reglas de red y autenticación. |
| `ssl` | `off` | SSL/TLS está desactivado en la configuración actual del servidor. |
| `password_encryption` | `scram-sha-256` | Método predeterminado configurado para el almacenamiento de contraseñas. |
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