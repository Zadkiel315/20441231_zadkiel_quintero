## 30. Informe

### 1. ¿Cuál era la principal superficie de ataque?

La principal superficie de ataque estaba relacionada con la exposición de las interfaces de escucha de PostgreSQL, ya que inicialmente el parámetro `listen_addresses = '*'` permitía escuchar en todas las interfaces de red disponibles. También se consideraron relevantes los permisos de conexión a la base de datos, los privilegios de los roles y la falta de registros de conexiones y consultas lentas.

### 2. ¿Qué configuración representaba el mayor riesgo?

La configuración `listen_addresses = '*'` representaba un riesgo importante porque permitía que PostgreSQL escuchara en interfaces distintas de las locales. Esto podía aumentar la posibilidad de recibir conexiones desde otras redes, dependiendo de las reglas del firewall y de `pg_hba.conf`. Por ello, se cambió a `listen_addresses = 'localhost'`, ya que el servidor se utiliza localmente mediante pgAdmin.

### 3. ¿Qué cambio produjo la mayor reducción de exposición?

El cambio de `listen_addresses = '*'` a `listen_addresses = 'localhost'` produjo la mayor reducción directa de exposición de red, porque limitó la escucha a las interfaces locales. La comprobación posterior mostró las direcciones `127.0.0.1` y `::1` en el puerto 5432. Este cambio redujo la exposición de red, aunque no sustituye las demás medidas de seguridad.

### 4. ¿Qué diferencia existe entre firewall y `pg_hba.conf`?

El firewall controla el tráfico de red que puede entrar o salir del equipo según sus reglas, direcciones, puertos y protocolos. En cambio, `pg_hba.conf` define qué conexiones PostgreSQL acepta según el tipo de conexión, la base de datos, el usuario, la dirección del cliente y el método de autenticación. Ambos controles son complementarios: el firewall limita el tráfico que llega al servidor y `pg_hba.conf` determina qué conexiones puede aceptar PostgreSQL. En este laboratorio se revisó `pg_hba.conf`, pero no se modificaron las reglas del firewall.

### 5. ¿Qué diferencia existe entre autenticación y autorización?

La autenticación comprueba la identidad de quien intenta conectarse, por ejemplo, mediante una contraseña validada con el método `scram-sha-256`. La autorización determina qué acciones puede realizar esa identidad después de autenticarse, como consultar una tabla, modificar datos o conectarse a una base de datos. En el laboratorio se revisaron ambos aspectos al comprobar la autenticación y los privilegios del rol `analista`.

### 6. ¿Por qué una cuenta de aplicación no debe ser `SUPERUSER`?

Una cuenta de aplicación no debe ser `SUPERUSER` porque tendría privilegios administrativos muy amplios, lo que aumentaría las consecuencias de una contraseña comprometida, un error de programación o una consulta maliciosa. Aplicar el principio de mínimo privilegio significa conceder únicamente los permisos necesarios para realizar las tareas asignadas. En esta práctica se verificó que `analista` no tuviera privilegios de superusuario, creación de roles ni creación de bases de datos.

### 7. ¿Por qué cambiar el puerto de PostgreSQL no constituye hardening suficiente?

Cambiar el puerto predeterminado puede reducir algunos intentos automatizados que buscan servicios en el puerto habitual, pero no impide que un atacante descubra el puerto nuevo. No corrige problemas de autenticación, permisos excesivos, exposición de red, configuración del firewall ni vulnerabilidades del servidor. Por eso, la seguridad debe basarse en controles complementarios, como limitar las interfaces de escucha, controlar los accesos, utilizar autenticación segura y mantener actualizado PostgreSQL.

### 8. ¿Por qué `listen_addresses='*'` puede ser innecesario?

El valor `listen_addresses='*'` puede ser innecesario cuando PostgreSQL solo necesita recibir conexiones desde el mismo equipo. En ese escenario, escuchar en todas las interfaces aumenta la exposición potencial sin aportar una ventaja funcional. En este laboratorio se cambió a `localhost`, porque el acceso requerido era local mediante pgAdmin. En un servidor de producción, la configuración debe responder a las necesidades reales de conexión de las aplicaciones y los administradores.

### 9. ¿Qué papel tiene el sistema operativo en la seguridad de PostgreSQL?

El sistema operativo protege los archivos de configuración, el directorio de datos, los registros y el proceso del servidor. Los permisos excesivos sobre esos recursos podrían permitir que usuarios no autorizados accedieran a información, modificaran la configuración o interfirieran con el servicio. También intervienen el firewall, las actualizaciones del sistema y la protección de las credenciales. En el laboratorio se inspeccionaron los permisos de Windows mediante `icacls`, pero no se modificaron.

### 10. ¿Qué controles deberían revisarse periódicamente?

Deberían revisarse periódicamente las interfaces de escucha, las reglas de `pg_hba.conf`, las reglas del firewall, los roles y sus privilegios, los métodos de autenticación, el uso de TLS, las actualizaciones de PostgreSQL, las extensiones instaladas y los permisos del sistema operativo. También es importante revisar los registros de conexiones, desconexiones y consultas lentas, los límites de ejecución, las copias de seguridad y la capacidad de recuperación. Estas revisiones ayudan a detectar cambios de configuración, accesos no autorizados y nuevos riesgos.

---

## 31. Reflexión

Si recibiera la responsabilidad de asegurar un servidor PostgreSQL que ya se encuentra funcionando en producción, primero evaluaría su exposición de red y determinaría desde qué equipos y aplicaciones necesita recibir conexiones. Si comprobara que escucha en todas las interfaces sin que sea necesario, priorizaría restringir las interfaces de escucha y verificar las reglas del firewall y de `pg_hba.conf`.

Elegiría comenzar por esta medida porque puede reducir directamente la exposición del servicio sin cambiar de inmediato los datos ni los permisos de las aplicaciones. Sin embargo, antes de aplicarla revisaría las dependencias, las conexiones actuales y los requisitos de continuidad para evitar interrumpir servicios legítimos.

También comprobaría los privilegios de las cuentas, la autenticación, el uso de TLS cuando las conexiones atraviesan redes, las actualizaciones y las copias de seguridad. Antes de realizar cambios en producción, prepararía un respaldo de la configuración, establecería un plan de reversión y probaría las modificaciones en un entorno controlado siempre que fuera posible.

Consideraría el riesgo y el impacto de cada medida, priorizando las que reduzcan una exposición innecesaria sin comprometer la disponibilidad ni la continuidad del servicio. El objetivo sería mejorar la seguridad mediante cambios controlados, verificables y compatibles con las necesidades reales del sistema, en lugar de modificar múltiples parámetros sin evaluar sus consecuencias.
