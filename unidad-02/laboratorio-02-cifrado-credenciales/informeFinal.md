## 1. Introducción

En este laboratorio trabajé con diferentes formas de proteger la información que se guarda en una base de datos. Aprendí que no basta con tener usuarios y permisos bien configurados, porque también hay que cuidar las contraseñas, los datos personales, las conexiones y las claves que se utilizan para cifrar la información.

El objetivo fue conocer algunos mecanismos de seguridad de PostgreSQL y entender cómo se pueden utilizar para evitar que la información quede expuesta.

## 2. Protección de credenciales

Durante la práctica revisé la diferencia entre guardar una contraseña en texto claro, utilizar un hash y utilizar cifrado.

El **texto claro** significa guardar la contraseña tal como es, por lo que cualquiera que pueda consultar ese dato podría verla directamente.

El **hash** transforma la contraseña en un resultado que no se puede revertir directamente para recuperar la original. Para las contraseñas se puede utilizar bcrypt, que hace más difícil probar contraseñas de manera masiva.

Por otro lado, el **cifrado** transforma la información para que no se pueda leer sin la clave correcta. A diferencia del hash, el cifrado permite recuperar el dato original cuando se tiene la clave adecuada.

Con esto entendí que las contraseñas deben guardarse mediante un hash seguro, mientras que otros datos que necesitamos recuperar, como un RFC, pueden protegerse mediante cifrado.

## 3. Protección de datos sensibles

En la práctica trabajé con el RFC de un cliente utilizando las funciones de `pgcrypto` de PostgreSQL.

Para guardar el RFC utilicé `pgp_sym_encrypt()`, que permite cifrar la información mediante una clave. Después utilicé `pgp_sym_decrypt()` para recuperar el dato original con la misma clave.

El RFC utilizado en el ejemplo fue `LOPA900101ABC`, correspondiente a un dato ficticio para la práctica.

Esto me ayudó a entender que los datos personales no deberían guardarse directamente en texto claro cuando necesitan una protección adicional. También comprendí que la clave debe mantenerse segura, porque alguien que consiga tanto la información cifrada como la clave podría descifrarla.

## 4. TLS

TLS sirve para proteger la información mientras viaja entre un cliente y un servidor. Por ejemplo, ayuda a evitar que alguien pueda leer fácilmente los datos que se envían entre una aplicación y PostgreSQL si logra interceptar la comunicación.

En pgAdmin ejecuté varias consultas para revisar la configuración de PostgreSQL y el estado de la conexión actual.

Los resultados que obtuve fueron los siguientes:

- SSL: `off`.
- Versión mínima de TLS: `TLSv1.2`.
- Puerto: `5432`.
- Direcciones de escucha: `*`.
- Dirección del cliente: `::1`.
- Puerto del cliente: `53578`.
- Estado de TLS de la conexión actual: `off`.

Con estos resultados comprobé que mi conexión actual no estaba utilizando TLS. Aunque la versión mínima configurada era `TLSv1.2`, eso no significa que todas las conexiones estén cifradas.

También aprendí que `::1` es una dirección local de IPv6 y que el valor `*` indica que PostgreSQL está configurado para escuchar en todas las interfaces de red disponibles.

La actividad de conexión mediante `psql` quedó pendiente porque la página `terminal.ficlabs.com.mx` estaba caída y no pude acceder a la terminal para realizar esa prueba.

## 5. Gestión de claves

Las claves criptográficas son importantes porque permiten cifrar y recuperar información protegida. Por eso, no deben guardarse junto con los scripts o el código del proyecto.

Si una clave real se publica accidentalmente en GitLab, alguien podría obtenerla y utilizarla para intentar descifrar los datos protegidos. Esto puede ocurrir incluso cuando el repositorio es privado.

Por eso, las claves deben guardarse en un lugar seguro, separado del código, y solo las personas autorizadas deben poder utilizarlas.

También es importante cambiarlas si se sospecha que fueron expuestas y eliminarlas de forma segura cuando ya no sean necesarias.

## 6. Resultados

Durante el laboratorio aprendí y revisé los siguientes puntos:

- La diferencia entre guardar contraseñas en texto claro y protegerlas mediante un hash.
- El uso de `pgcrypto` para cifrar y descifrar información sensible.
- La importancia de mantener las claves criptográficas seguras.
- Cómo revisar la configuración de SSL y TLS en PostgreSQL.
- Cómo comprobar si la conexión actual utiliza TLS mediante la vista `pg_stat_ssl`.
- La importancia de revisar los archivos antes de subirlos a GitLab para evitar publicar secretos.

En mi conexión de pgAdmin, el resultado de SSL fue `off`, por lo que comprobé que esa conexión no utilizaba TLS. La prueba de conexión desde la terminal quedó pendiente debido a que la página no estaba disponible.

## 7. Problemas encontrados

El principal problema que encontré fue que la página `terminal.ficlabs.com.mx` estaba caída cuando necesitaba realizar la actividad de conexión mediante `psql`. Por ese motivo no pude completar esa prueba desde la terminal.

Sin embargo, pude realizar las consultas de revisión de SSL y TLS desde el Query Tool de pgAdmin y obtener los resultados de la conexión actual.

Esto me permitió continuar con el análisis de las demás actividades, aunque la prueba de terminal quedó pendiente.

## 8. Conclusiones

Con este laboratorio aprendí que proteger una base de datos no consiste solamente en crear usuarios y asignar permisos. También es necesario proteger las contraseñas, cifrar los datos sensibles cuando sea necesario, asegurar las conexiones y cuidar las claves criptográficas.

También entendí que tener TLS configurado como opción no significa que una conexión lo esté utilizando, por lo que es importante revisar el estado de la conexión real.

En un entorno de trabajo aplicaría estas medidas junto con el control de acceso, la protección de los respaldos y una revisión de los archivos antes de subirlos a un repositorio.

---

# Preguntas de reflexión

### 1. ¿Por qué una contraseña no debe almacenarse como texto claro?

Porque si alguien consigue acceso a la base de datos puede ver las contraseñas directamente. Por eso es mejor guardarlas mediante un hash seguro, como bcrypt.

### 2. ¿Por qué un hash no es equivalente a un cifrado?

Porque el hash no está diseñado para recuperar el dato original, mientras que el cifrado sí permite recuperarlo si se tiene la clave correcta.

### 3. ¿Por qué el cifrado de una columna no sustituye al control de acceso?

Porque aunque los datos estén cifrados, todavía hay que controlar quién puede consultar la tabla y quién puede utilizar la clave para descifrarlos.

### 4. ¿Por qué TLS no sustituye a los mecanismos de autorización de PostgreSQL?

Porque TLS protege la comunicación entre el cliente y el servidor, pero no decide qué puede hacer cada usuario dentro de la base de datos. Para eso se necesitan permisos y roles.

### 5. ¿Qué ocurriría si una organización pierde una clave utilizada para cifrar información?

Podría perder el acceso a los datos cifrados, porque ya no tendría la clave necesaria para recuperarlos. Por eso es importante tener respaldos seguros de las claves y un plan para recuperarlas.

### 6. ¿Qué ocurriría si una clave criptográfica se publica accidentalmente en GitLab?

Alguien podría obtenerla y utilizarla para intentar descifrar la información protegida. En ese caso habría que cambiar la clave y revisar si los datos estuvieron en riesgo.

### 7. ¿Por qué un repositorio privado no debe considerarse un almacén de secretos?

Porque, aunque sea privado, otras personas autorizadas podrían acceder al repositorio y los permisos podrían cambiar. Además, el historial de Git puede conservar información que después se elimina del archivo.

### 8. ¿Qué diferencia existe entre proteger información almacenada y proteger información durante su transmisión?

La información almacenada se protege mientras está guardada en la base de datos o en archivos. La información durante su transmisión se protege mientras viaja entre un cliente y un servidor, por ejemplo, mediante TLS.

### 9. ¿Por qué la gestión de claves es tan importante como el algoritmo criptográfico?

Porque no sirve de mucho utilizar un buen algoritmo si la clave se guarda en un lugar donde cualquiera puede encontrarla. Si alguien obtiene la clave, podría utilizarla para acceder a la información protegida.

### 10. ¿Qué mecanismo adicional implementarías en una organización para proteger los respaldos de las bases de datos?

Implementaría el cifrado de los respaldos y los guardaría en un lugar seguro, con acceso limitado. También mantendría copias adicionales y comprobaría periódicamente que se puedan recuperar correctamente.