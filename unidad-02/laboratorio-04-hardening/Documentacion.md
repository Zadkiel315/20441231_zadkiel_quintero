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

### Actividad 5. Analizar una regla permisiva

**Regla analizada:**

`host    all    all    0.0.0.0/0    scram-sha-256`

**¿Qué bases de datos permite?**
Permite conexiones a todas las bases de datos de PostgreSQL.

**¿Qué usuarios permite?**
Permite conexiones de cualquier usuario, siempre que cumpla con el método de autenticación configurado.

**¿Qué direcciones de origen permite?**
Permite conexiones desde cualquier dirección IPv4, debido al rango `0.0.0.0/0`.

**¿Qué método de autenticación utiliza?**
Utiliza `scram-sha-256`, un método de autenticación mediante contraseña.

**¿Por qué puede representar una exposición innecesaria?**
Porque acepta conexiones desde cualquier dirección IPv4 y no restringe las bases de datos ni los usuarios en la propia regla. Aunque utiliza un método de autenticación sólido, amplía la superficie de exposición y puede facilitar intentos de acceso no autorizado.

**¿Qué información necesitarías para restringirla?**
Necesitaría conocer la dirección IP o red de origen autorizada, la base de datos a la que se requiere acceso, el usuario específico que utilizará la conexión y el método de autenticación compatible con el entorno.

**Regla actual:**

`host    all    all    0.0.0.0/0    scram-sha-256`

**Problema:**
Permite conexiones desde cualquier dirección IPv4, para todas las bases de datos y todos los usuarios.

**Origen que realmente necesita acceso:**
La dirección IP o red privada autorizada que requiera conectarse al servidor. Debe confirmarse de acuerdo con las necesidades reales del entorno.

**Base de datos:**
La base de datos específica que necesita utilizar la aplicación o el usuario autorizado.

**Usuario:**
La cuenta específica que necesita conectarse, con los privilegios mínimos necesarios.

**Regla propuesta:**

`host    nombre_bd    usuario_app    IP_O_RED_AUTORIZADA    scram-sha-256`

Esta regla es conceptual: los valores `nombre_bd`, `usuario_app` e `IP_O_RED_AUTORIZADA` deben sustituirse por los datos reales antes de aplicarla.

### Actividad 6. Aplicar mínimo privilegio a conexiones

**Regla propuesta:**

`host    db_20441231_zadkiel_quintero    usuario_app    127.0.0.1/32    scram-sha-256`

**Base de datos:** `db_20441231_zadkiel_quintero`, que corresponde a la base de datos identificada durante la inspección inicial.

**Usuario:** `usuario_app`, como nombre conceptual para una cuenta específica de aplicación. Su existencia debe confirmarse antes de utilizar la regla.

**Origen:** `127.0.0.1/32`, que limita las conexiones IPv4 al propio equipo.

**Método de autenticación:** `scram-sha-256`.

La regla propuesta limita el acceso a una base de datos específica, un usuario determinado y una dirección de origen concreta. Esto reduce la exposición frente a una regla que permita todas las bases de datos, todos los usuarios y cualquier dirección IPv4.

La regla es una propuesta conceptual y no se ha aplicado. Antes de implementarla, se debe confirmar que la cuenta de aplicación existe y que necesita conectarse mediante TCP/IP. Si no se requieren conexiones remotas, no es necesario habilitar una red externa.

### Actividad 7. Revisar autenticación

**Configuración encontrada:** `password_encryption = scram-sha-256`.

**1. ¿Qué diferencia existe entre autenticación y autorización?**

La autenticación verifica la identidad del usuario que intenta conectarse a PostgreSQL. La autorización determina qué acciones puede realizar ese usuario según los permisos que tenga asignados.

**2. ¿Qué protege `scram-sha-256`?**

Protege el proceso de autenticación mediante un mecanismo de desafío y respuesta basado en SHA-256, evitando que la contraseña se envíe directamente como texto plano durante el proceso normal de autenticación. Además, permite almacenar un verificador de contraseña en lugar de la contraseña original.

**3. ¿Por qué una contraseña almacenada mediante un mecanismo de autenticación no debe confundirse con cifrado reversible?**

Porque el verificador de contraseña no está diseñado para descifrarse y recuperar la contraseña original. Se utiliza para comprobar las credenciales mediante cálculos criptográficos, a diferencia del cifrado reversible, que permite recuperar los datos originales con la clave correspondiente.

**4. ¿Qué sucede si una cuenta tiene permisos excesivos aunque utilice una contraseña fuerte?**

Si la cuenta es comprometida, un atacante podría aprovechar todos los privilegios que tenga asignados. Por ello, una contraseña fuerte debe complementarse con el principio de mínimo privilegio, otorgando únicamente los permisos necesarios para las funciones de cada usuario.

### Actividad 8. Revisar usuarios y privilegios

Se consultaron los roles registrados en PostgreSQL para identificar sus permisos y capacidades de acceso.

| Rol | LOGIN | SUPERUSER | CREATEROLE | CREATEDB | Función |
|---|---|---|---|---|---|
| `analista` | No | No | No | No | Rol de análisis; no puede iniciar sesión directamente. |
| `pg_checkpoint` | No | No | No | No | Rol predefinido de PostgreSQL relacionado con operaciones de checkpoint. |
| `pg_create_subscription` | No | No | No | No | Rol predefinido relacionado con la creación de suscripciones. |
| `pg_database_owner` | No | No | No | No | Rol predefinido asociado al propietario de cada base de datos. |
| `pg_execute_server_program` | No | No | No | No | Rol predefinido relacionado con la ejecución de programas en el servidor. |
| `pg_maintain` | No | No | No | No | Rol predefinido para determinadas tareas de mantenimiento. |
| `pg_monitor` | No | No | No | No | Rol predefinido para supervisión del servidor. |
| `pg_read_all_data` | No | No | No | No | Rol predefinido para leer todos los datos. |
| `pg_read_all_settings` | No | No | No | No | Rol predefinido para consultar la configuración. |
| `pg_read_all_stats` | No | No | No | No | Rol predefinido para consultar estadísticas. |
| `pg_read_server_files` | No | No | No | No | Rol predefinido relacionado con la lectura de archivos del servidor. |
| `pg_signal_autovacuum_worker` | No | No | No | No | Rol predefinido relacionado con señales a procesos de autovacuum. |
| `pg_signal_backend` | No | No | No | No | Rol predefinido que permite enviar señales a determinados procesos de PostgreSQL. |
| `pg_stat_scan_tables` | No | No | No | No | Rol predefinido para determinadas operaciones de análisis de tablas. |
| `pg_use_reserved_connections` | No | No | No | No | Rol predefinido para utilizar conexiones reservadas. |
| `pg_write_all_data` | No | No | No | No | Rol predefinido para escribir todos los datos. |
| `pg_write_server_files` | No | No | No | No | Rol predefinido relacionado con la escritura de archivos del servidor. |
| `postgres` | Sí | Sí | Sí | Sí | Cuenta administrativa con privilegios de superusuario. |

**Identificación de roles y privilegios**

- **Superusuarios:** `postgres`.
- **Roles que pueden iniciar sesión:** `postgres`.
- **Roles con `CREATEROLE`:** `postgres`.
- **Roles con `CREATEDB`:** `postgres`.
- **Roles de aplicaciones:** se identificó `analista`, pero no puede iniciar sesión directamente y los resultados no permiten confirmar que se utilice en una aplicación.
- **Cuentas posiblemente innecesarias:** no se puede determinar únicamente con esta consulta. Los roles predefinidos pertenecen a PostgreSQL y no deben considerarse innecesarios por defecto.

**Pregunta: ¿Por qué no debería utilizarse una cuenta `SUPERUSER` como cuenta normal de una aplicación?**

Porque tiene privilegios administrativos muy amplios y puede eludir muchas restricciones de seguridad. Si sus credenciales se ven comprometidas, un atacante podría acceder o modificar información y realizar operaciones administrativas. Por eso, las aplicaciones deben utilizar cuentas con los permisos mínimos necesarios.

### Actividad 9. Separar cuentas administrativas y de aplicación

Se propone separar las cuentas según sus responsabilidades para reducir los riesgos y aplicar el principio de mínimo privilegio.

| Cuenta | Propósito | LOGIN | Privilegios |
|---|---|---|---|
| DBA | Administración de PostgreSQL | Sí | Administrativos, únicamente cuando sean necesarios. |
| APP | Conexión utilizada por la aplicación | Sí | Mínimos, limitados a las operaciones que necesita la aplicación. |
| CONSULTA | Consultas de información | Sí | Solo lectura sobre las bases de datos y tablas autorizadas. |

**Pregunta: ¿Qué riesgo existe si la aplicación se conecta utilizando una cuenta administrativa?**

Si la aplicación utiliza una cuenta administrativa y sus credenciales se ven comprometidas, un atacante podría realizar operaciones administrativas, acceder a información sensible, modificar o eliminar datos y afectar el funcionamiento del servidor. Por eso, la aplicación debe utilizar una cuenta independiente con permisos mínimos.

### Actividad 10. Revisar extensiones

Se consultaron las extensiones instaladas en PostgreSQL mediante la vista `pg_extension`.

| Extensión | Versión | Función |
|---|---|---|
| `pgcrypto` | 1.4 | Proporciona funciones criptográficas, como funciones de hash y generación de datos aleatorios. |
| `plpgsql` | 1.0 | Permite utilizar el lenguaje procedural PL/pgSQL para crear funciones y procedimientos. |

**Análisis:**

- **Extensiones existentes:** se encontraron `pgcrypto` y `plpgsql`.
- **Extensiones necesarias:** `plpgsql` suele utilizarse para funciones y procedimientos escritos en este lenguaje. La necesidad de `pgcrypto` depende de si alguna aplicación o práctica utiliza sus funciones.
- **Extensiones instaladas para prácticas:** con los resultados disponibles no se puede confirmar si `pgcrypto` se instaló específicamente para el laboratorio.
- **Funcionalidad potencialmente innecesaria:** `pgcrypto` podría no ser necesaria si ninguna aplicación o práctica utiliza sus funciones. Debe verificarse su uso antes de proponer cambios.

La presencia de una extensión no significa que sea insegura. El hardening consiste en habilitar únicamente la funcionalidad necesaria para el propósito del sistema.

**Cambios aplicados:** ninguno; solo se realizó una consulta de inspección.

### Actividad 11. Revisar configuración relacionada con conexiones

Se consultaron los parámetros de PostgreSQL relacionados con el número de conexiones y los tiempos límite.

| Parámetro | Valor actual | Función |
|---|---|---|
| `max_connections` | `100` | Establece el máximo de conexiones simultáneas permitidas al servidor. |
| `superuser_reserved_connections` | `3` | Reserva tres conexiones para que los superusuarios puedan acceder cuando se alcanza el límite de conexiones ordinarias. |
| `statement_timeout` | `0` | No establece un límite de tiempo para la ejecución de instrucciones SQL. |
| `idle_in_transaction_session_timeout` | `0` | No establece un límite de tiempo para sesiones inactivas que mantienen una transacción abierta. |

**Pregunta: ¿Por qué mantener conexiones indefinidamente abiertas puede representar un problema de disponibilidad o consumo de recursos?**

Porque cada conexión consume recursos del servidor, como memoria y procesos de trabajo. Si muchas conexiones permanecen abiertas sin utilizarse, pueden agotarse las conexiones disponibles e impedir que otros usuarios o aplicaciones accedan al sistema. Además, las transacciones abiertas durante mucho tiempo pueden dificultar el mantenimiento de la base de datos.

### Actividad 12. Revisar permisos del sistema operativo

La revisión de permisos se realizó desde PowerShell, debido a que PostgreSQL está instalado en Windows.

**Rutas revisadas:**

| Elemento | Ruta |
|---|---|
| Directorio de datos | `C:\Program Files\PostgreSQL\18\data` |
| Archivo de configuración | `C:\Program Files\PostgreSQL\18\data\postgresql.conf` |
| Archivo de autenticación | `C:\Program Files\PostgreSQL\18\data\pg_hba.conf` |

**Resultados de la revisión de permisos:**

Los archivos `postgresql.conf` y `pg_hba.conf` presentan permisos de control total (`F`) para los siguientes usuarios y grupos:

- `BUILTIN\Administradores`
- `NT AUTHORITY\SYSTEM`
- `LEN-V130-15IGM\Zadkiel Quintero`
- `NT AUTHORITY\NETWORK SERVICE`

En el directorio `data`, `NETWORK SERVICE` y el usuario de Windows aparecen con permisos de lectura y ejecución (`RX`) en una entrada directa. También tienen entradas con control total (`F`) heredables para los archivos y subdirectorios, indicadas mediante las marcas `(OI)` y `(CI)`. Administradores y SYSTEM también cuentan con entradas de control total.

No se observaron entradas explícitas para `Everyone` o `Users` en los resultados proporcionados. Esto no descarta que existan permisos adicionales por pertenencia a grupos o por otras vías de acceso.

**Pregunta: ¿Por qué no es suficiente proteger PostgreSQL mediante GRANT y REVOKE si cualquier usuario del sistema operativo puede leer archivos sensibles?**

Porque `GRANT` y `REVOKE` controlan los privilegios dentro de PostgreSQL, pero no sustituyen los permisos del sistema operativo. Si una persona puede leer archivos sensibles directamente desde Windows, podría obtener información de configuración sin utilizar los permisos normales de la base de datos. Por eso, también es necesario restringir el acceso a los archivos y al directorio de datos.

**Cambios aplicados:** ninguno. Solo se inspeccionaron los permisos existentes.

### Actividad 13. Revisar exposición de red

**Dirección de escucha:**
- `0.0.0.0`: todas las interfaces IPv4.
- `::`: todas las interfaces IPv6.

**Puerto:** `5432`.

**Proceso asociado:** PID `8988`.

**¿Está expuesto fuera de la interfaz necesaria?**

Sí, la configuración de escucha permite que PostgreSQL escuche en todas las interfaces IPv4 e IPv6, en lugar de limitarse a la interfaz local. Esto aumenta la superficie potencial de exposición. Sin embargo, el resultado no demuestra por sí solo que el servicio sea accesible desde otros equipos, ya que también depende de las reglas del firewall y de la configuración de red.

**Cambios aplicados:** ninguno; solo se verificó el puerto de escucha.

### Actividad 14. Diseñar una política de firewall

**Datos del escenario:**

- **Servidor PostgreSQL:** `10.10.10.20`
- **Puerto:** `5432`
- **Red autorizada (DBA):** `10.10.10.0/24`

**Política conceptual de firewall:**

| Origen | Destino | Puerto | Acción |
|---|---|---|---|
| `10.10.10.0/24` | PostgreSQL (`10.10.10.20`) | `5432/TCP` | Permitir |
| Cualquier otro origen | PostgreSQL (`10.10.10.20`) | `5432/TCP` | Denegar |

**Pregunta: ¿Por qué `pg_hba.conf` y el firewall no son controles equivalentes?**

El firewall controla el tráfico de red que puede llegar al servidor, permitiendo o bloqueando conexiones según reglas como la dirección de origen, el destino y el puerto. En cambio, `pg_hba.conf` controla qué conexiones a PostgreSQL pueden autenticarse, según el tipo de conexión, la base de datos, el usuario, la dirección de origen y el método de autenticación.

Por lo tanto, ambos controles se complementan: el firewall reduce el acceso de red al servidor y `pg_hba.conf` restringe qué conexiones acepta PostgreSQL. Ninguno sustituye al otro.

**Cambios aplicados:** ninguno. La política es conceptual y no se modificó ningún firewall.

### Actividad 15. Revisar TLS

**Configuración del servidor (`ssl`):** `off`.

**Versión mínima del protocolo (`ssl_min_protocol_version`):** `TLSv1.2`.

**¿La conexión actual utiliza TLS?** No. La columna `ssl` devuelve `false`.

**Versión:** No aplica; el resultado es `NULL` porque la conexión actual no utiliza TLS.

**Cipher:** No aplica; el resultado es `NULL` porque no se negoció un cifrado TLS para esta conexión.

**Relación con LAB-02 y LAB-04**

En LAB-02 se estudió el cifrado y TLS. En LAB-04 se verifica cómo se integra en la configuración del servidor y de los clientes. En este entorno, el servidor tiene `ssl = off` y la conexión actual no está cifrada mediante TLS. Aunque se configura `TLSv1.2` como versión mínima, este parámetro no habilita TLS por sí solo.

**Cambios aplicados:** ninguno; solo se verificó la configuración.

### Actividad 16. Comparar configuración antes y después

| Control | Antes | Después | Justificación |
|---|---|---|---|
| `listen_addresses` | `*` | `*` (sin cambios) | PostgreSQL escucha en todas las interfaces; conviene limitarlo a las necesarias. |
| `pg_hba.conf` | Reglas locales IPv4 e IPv6 y reglas de replicación; autenticación `scram-sha-256`. | Sin cambios; no se modificó el archivo. | Las reglas observadas limitan las conexiones TCP a loopback, pero permiten cualquier usuario y base de datos en esas reglas. |
| Método de autenticación | `scram-sha-256` | Sin cambios | Es un método de autenticación robusto; debe combinarse con restricciones de acceso y privilegios mínimos. |
| Usuarios administrativos | `postgres` tiene `LOGIN`, `SUPERUSER`, `CREATEROLE` y `CREATEDB`. | Sin cambios | Se recomienda reservar la cuenta administrativa para tareas que requieren esos privilegios. |
| Cuentas de aplicación | No se confirmó una cuenta específica para aplicaciones; `APP` se propuso conceptualmente. | Sin cambios; no se creó ninguna cuenta. | Una cuenta de aplicación debe tener solo los permisos necesarios. |
| Puerto | `5432` | `5432` (sin cambios) | Es el puerto configurado para PostgreSQL; el acceso debe restringirse según las necesidades. |
| TLS | `ssl = off`; la conexión actual devuelve `ssl = false`. | Sin cambios | Se debe evaluar la habilitación de TLS y verificar las conexiones cifradas. |
| Permisos SO | Archivos de configuración con control total para Administradores, SYSTEM, usuario de Windows y NETWORK SERVICE. | Sin cambios | Los permisos deben limitarse a las cuentas que necesitan acceder a los archivos. |
| Extensiones | `pgcrypto` 1.4 y `plpgsql` 1.0. | Sin cambios | Se debe confirmar cuáles son necesarias; no se eliminó ninguna extensión. |
| Conexiones | `max_connections = 100`; 3 reservadas para superusuarios; ambos tiempos de espera consultados están en `0`. | Sin cambios | Conviene evaluar límites de tiempo adecuados para reducir conexiones ocupadas durante periodos prolongados. |

**Resultado de la comparación:** durante las actividades documentadas se inspeccionó la configuración y se identificaron riesgos y recomendaciones, pero no se aplicaron cambios de hardening. Por tanto, el estado posterior registrado permanece igual al inicial. Esta comparación no demuestra que los controles hayan sido endurecidos; documenta el estado actual y las medidas pendientes.