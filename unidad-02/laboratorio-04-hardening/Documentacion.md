### Actividad 1. Identificación de la superficie de ataque

| Elemento | Estado actual | ¿Es necesario? | Riesgo |
|---|---|---|---|
| Puerto PostgreSQL | 5432 | Sí, para permitir las conexiones configuradas | Si queda accesible desde redes no autorizadas, pueden intentar conectarse al servidor. |
| Interfaces de escucha | `*` | Debe escuchar solo en las interfaces necesarias | Puede aceptar conexiones por distintas interfaces de red, según las reglas del sistema y del firewall. |
| Conexiones remotas | Las conexiones observadas utilizan `::1`, que corresponde a la dirección local IPv6 | Solo deben permitirse conexiones remotas autorizadas | Una conexión local no demuestra que el acceso remoto esté restringido. |
| Usuarios administrativos | Se observa el usuario `postgres` en las conexiones de pgAdmin | Sí, para tareas administrativas | Si se utiliza para aplicaciones o tareas cotidianas, aumenta el riesgo por sus privilegios elevados. |
| SSL/TLS | Desactivado (`off`) | Se debe evaluar y habilitar si se requiere proteger conexiones mediante TLS | Las conexiones no tienen cifrado TLS proporcionado por PostgreSQL. |
| Métodos de autenticación | `scram-sha-256` | Sí, debe usarse un método de autenticación seguro | Es necesario revisar también las reglas de acceso y los permisos de cada usuario. |

**¿Por qué conocer la superficie de ataque debe preceder al hardening?**

Porque primero se necesita conocer cómo está configurado el servidor, quién puede conectarse y qué riesgos existen. Así se pueden identificar los puntos débiles y decidir qué cambios son necesarios sin afectar el funcionamiento de la base de datos.

### Actividad 2. Identificar los archivos de configuración

| Elemento | Ruta o valor obtenido | Función |
|---|---|---|
| Archivo principal (`config_file`) | `C:/Program Files/PostgreSQL/18/data/postgresql.conf` | Contiene los parámetros generales del servidor. |
| Archivo de autenticación (`hba_file`) | `C:/Program Files/PostgreSQL/18/data/pg_hba.conf` | Define las reglas que controlan qué conexiones se permiten y cómo se autentican. |
| Archivo de identificación (`ident_file`) | `C:/Program Files/PostgreSQL/18/data/pg_ident.conf` | Contiene las asignaciones de identificación de usuarios cuando se utiliza este mecanismo. |
| Directorio de datos (`data_directory`) | `C:/Program Files/PostgreSQL/18/data` | Almacena los datos y otros archivos internos de PostgreSQL. |
| Directorio de logs (`log_directory`) | `log` | Indica el directorio configurado para los registros del servidor. Al ser una ruta relativa, se interpreta normalmente respecto al directorio de datos. |
| Registro de conexiones (`log_connections`) | Valor vacío; origen: `default` | El parámetro aparece sin un valor explícito en las consultas realizadas. |
| Registro de desconexiones (`log_disconnections`) | `off` | Indica que el registro de desconexiones está desactivado. |

**¿Por qué es importante conocer la ubicación física de estos archivos?**

Porque permite localizar y revisar la configuración, las reglas de autenticación, los datos y los registros del servidor. También ayuda a verificar que los archivos estén protegidos contra accesos no autorizados y facilita realizar respaldos, auditorías y cambios de forma segura.

### Actividad 3. Revisar `listen_addresses`

**Configuración encontrada:** `*`, lo que indica que PostgreSQL escucha en todas las interfaces disponibles.

**Interfaces necesarias:** La interfaz local para utilizar PostgreSQL desde pgAdmin en el mismo equipo. Si se necesitan conexiones desde otros equipos, deberán habilitarse únicamente las interfaces privadas necesarias.

**Interfaces innecesarias:** Las interfaces públicas o externas que no se requieran para conexiones autorizadas.

**Comparación de arquitecturas**

La segunda arquitectura reduce mejor la exposición porque mantiene PostgreSQL dentro de una red privada, protegida por un firewall, y evita su acceso directo desde Internet. De esta manera, las conexiones pueden limitarse a los equipos y redes autorizados.

En la primera arquitectura, si el firewall permite conexiones externas al puerto 5432, el servidor podría recibir intentos de conexión desde Internet. Por eso, también deben revisarse las reglas del firewall y de `pg_hba.conf`.

### Actividad 4. Revisar `pg_hba.conf`

**Reglas locales:** Se encontraron dos reglas de tipo `local`: una para todas las bases de datos y todos los usuarios, y otra para conexiones de replicación. No especifican una dirección IP.

**Reglas para conexiones IPv4:** Se encontraron dos reglas que permiten conexiones desde `127.0.0.1`: una para todas las bases de datos y usuarios, y otra para replicación.

**Reglas para conexiones IPv6:** Se encontraron dos reglas que permiten conexiones desde `::1`: una para todas las bases de datos y usuarios, y otra para replicación.

**Bases de datos afectadas:** Las reglas utilizan `{all}` para permitir el acceso a todas las bases de datos y `{replication}` para las conexiones de replicación.

**Usuarios afectados:** Las reglas utilizan `{all}`, por lo que no restringen el acceso a un usuario específico.

**Redes permitidas:** Para las reglas de tipo `host`, se permiten las direcciones de loopback `127.0.0.1` (IPv4) y `::1` (IPv6). Estas direcciones corresponden al propio equipo.

**Métodos de autenticación:** Todas las reglas utilizan `scram-sha-256`, un método de autenticación basado en contraseñas que ofrece una protección más sólida que mecanismos heredados como `md5`.

**Reglas excesivamente amplias:** En los resultados no aparecen las redes `0.0.0.0/0` ni `::/0`. Las reglas de conexión por red están limitadas a las direcciones de loopback, por lo que no se observa una regla que permita conexiones desde cualquier dirección IP.

**Aspecto por considerar:** Aunque las reglas de red están limitadas a direcciones locales, las reglas que utilizan `{all}` no restringen por sí mismas las bases de datos ni los usuarios. Por ello, deben evaluarse junto con los privilegios de los roles y los demás controles de seguridad.

