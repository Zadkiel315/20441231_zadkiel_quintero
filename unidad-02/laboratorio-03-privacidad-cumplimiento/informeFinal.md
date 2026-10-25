# LAB-03: Privacidad, cumplimiento y gobierno de datos

## 1. Introduccion

En este laboratorio se reviso la importancia de proteger los datos personales dentro de una base de datos. El problema principal es que muchas veces se guardan mas datos de los necesarios, se dan permisos muy amplios a los usuarios o se conserva informacion durante mucho tiempo sin revisar si todavia se necesita.

Para trabajar con esto se utilizo como ejemplo la tabla `clientes` de PostgreSQL, que contiene informacion como nombre, correo, telefono, RFC, edad, ciudad y codigo postal. Se revisaron diferentes formas de limitar el acceso a los datos, reducir la informacion almacenada y definir como deberia utilizarse y conservarse.

## 2. Inventario de datos

Se identificaron los siguientes campos en la tabla `clientes`:

| Campo | Clasificacion | Motivo |
|---|---|---|
| id | Identificador | Permite distinguir cada registro. |
| nombre | Dato personal | Identifica a la persona. |
| correo | Dato personal | Permite contactar directamente al cliente. |
| telefono | Dato personal | Permite comunicarse con el cliente. |
| RFC | Dato personal de identificacion fiscal | Puede identificar a una persona y requiere proteccion. |
| edad | Dato personal | Describe una caracteristica de la persona. |
| ciudad | Dato de ubicacion | Da informacion sobre donde vive o se encuentra el cliente. |
| codigo_postal | Dato de ubicacion | Puede ayudar a identificar la zona donde vive. |
| fecha_alta | Dato relacionado con el registro | Indica cuando se agrego el cliente al sistema. |

No todos los campos tienen el mismo nivel de riesgo. Por ejemplo, el nombre, el correo, el telefono y el RFC necesitan mas cuidado porque pueden ayudar a identificar directamente a una persona.

## 3. Finalidades

Los datos deben utilizarse solamente para los propositos que se hayan definido y que sean validos para el tratamiento de esa informacion.

Algunos ejemplos son:

- Utilizar el nombre y los datos de contacto para atender al cliente.
- Consultar informacion de la cuenta cuando sea necesario para dar soporte.
- Usar la ciudad y la edad agrupada para realizar estadisticas.
- Mantener los datos que sean necesarios para cumplir con las obligaciones correspondientes.

Si se quieren utilizar los correos para enviar promociones, primero se debe revisar si ese uso esta permitido y si se cumplen las condiciones necesarias. No porque una empresa ya tenga los datos significa que puede utilizarlos para cualquier cosa.

## 4. Minimizacion

El principio de minimizacion consiste en guardar y utilizar solamente los datos que realmente se necesitan.

En este laboratorio se propuso limitar la informacion que se entrega a cada area. Por ejemplo, el personal de soporte podria trabajar con el identificador, nombre, correo y telefono, sin tener acceso automatico al RFC, la edad o el codigo postal.

Para los reportes estadisticos se pueden utilizar datos agrupados, como el total de clientes por ciudad o por rango de edad, sin mostrar los nombres ni los correos.

En el archivo `sql/01-minimizacion.sql` se creo una tabla llamada `clientes_soporte` con algunos campos necesarios para soporte. En `sql/02-finalidad.sql` se prepararon consultas para obtener estadisticas por ciudad y rango de edad.

Con esto se reduce la cantidad de informacion expuesta cuando un usuario no necesita consultar todos los datos.

## 5. Control de acceso

Los permisos deben relacionarse con las funciones que realiza cada usuario. No todos necesitan consultar o modificar la misma informacion.

Por ejemplo:

- Soporte necesita los datos necesarios para atender a los clientes.
- Analitica necesita principalmente estadisticas y datos agrupados.
- Los desarrolladores deberian trabajar con datos de prueba siempre que sea posible.
- El DBA administra los permisos y los controles tecnicos de la base de datos.

En `sql/03-control-acceso.sql` se creo el rol `analista` y una vista llamada `v_analitica_clientes`, que muestra la ciudad, el rango de edad y el total de clientes, en lugar de mostrar los datos personales de cada registro.

Despues se otorgaron permisos de lectura sobre esa vista. La idea es que el analista pueda consultar la informacion que necesita sin recibir acceso directo a toda la tabla `clientes`.

Los permisos deben revisarse para evitar que se acumulen accesos que ya no sean necesarios.

## 6. Derechos ARCO

Los derechos ARCO son acceso, rectificacion, cancelacion y oposicion. Para atenderlos tambien se necesitan acciones tecnicas dentro de la base de datos.

- **Acceso:** consultar los datos que tiene registrados el sistema sobre una persona.
- **Rectificacion:** corregir informacion que sea incorrecta o este desactualizada.
- **Cancelacion:** revisar y ejecutar la eliminacion o el bloqueo de los datos cuando corresponda, considerando las obligaciones aplicables.
- **Oposicion:** revisar si debe detenerse un uso especifico de los datos cuando corresponda.

Para atender una solicitud se debe verificar la identidad de la persona, localizar sus registros y revisar si existen copias en respaldos, reportes, replicas o sistemas relacionados.

Por ejemplo, una consulta SQL puede ayudar a localizar los datos por correo o identificador. Para corregir un correo se puede utilizar un `UPDATE`, pero antes se debe verificar que la solicitud sea valida y que se este modificando el registro correcto.

El DBA ayuda con las consultas y los cambios tecnicos, pero no deberia decidir por su cuenta todas las cuestiones legales relacionadas con la solicitud.

## 7. Retencion

El periodo de conservacion debe definirse segun la finalidad de los datos, el tiempo durante el cual son necesarios y las obligaciones que correspondan.

No es recomendable conservar toda la informacion para siempre sin una razon. Mientras mas tiempo se guarden datos personales que ya no se necesitan, mayor puede ser el riesgo de exposicion o uso incorrecto.

Una politica de retencion deberia indicar:

- Para que se conserva cada tipo de dato.
- Durante cuanto tiempo se necesita.
- Por que se establecio ese periodo.
- Quien autoriza y revisa la politica.
- Que se hara cuando termine el periodo de conservacion.

Al terminar el periodo, se debe revisar si corresponde eliminar, bloquear o conservar la informacion por alguna obligacion aplicable. Tambien se deben considerar los respaldos y las copias que puedan existir fuera de la tabla principal.

## 8. Gobierno de datos

El gobierno de datos ayuda a definir quien es responsable de la informacion, para que se utiliza, quien puede consultarla y que medidas se deben aplicar.

| Dato | Finalidad principal | Area responsable | Acceso recomendado | Proteccion |
|---|---|---|---|---|
| Nombre | Identificar al cliente | Servicio al cliente | Personal autorizado | Control de acceso |
| Correo | Contactar al cliente | Servicio al cliente | Personal que lo necesite | Permisos limitados |
| Telefono | Comunicacion con el cliente | Servicio al cliente | Personal que lo necesite | Permisos limitados |
| RFC | Identificacion fiscal | Area autorizada | Acceso restringido | Proteccion adicional |
| Edad | Estadisticas o servicios que la requieran | Area responsable del servicio | Preferentemente por rangos para analitica | Minimizacion |
| Ciudad | Estadisticas y datos de ubicacion | Analitica o servicio | Segun la finalidad | Acceso limitado |
| Codigo postal | Ubicacion cuando sea necesaria | Area responsable del servicio | Solo si se necesita | Minimizacion |
| Fecha de alta | Control del registro | Administracion del sistema | Personal autorizado | Control de acceso |

Los periodos de conservacion deben definirse de acuerdo con la finalidad y las obligaciones aplicables. La tabla es una propuesta general y debe revisarse con las areas responsables antes de utilizarse como politica definitiva.

El DBA se encarga de la parte tecnica, como los permisos, las vistas, los respaldos y la administracion de la base de datos. Las decisiones sobre las finalidades y los periodos de conservacion deben involucrar a las areas responsables de privacidad, cumplimiento y del uso de los datos.

## 9. Evaluacion integral

Durante la revision se identificaron varios riesgos que pueden afectar la privacidad de los clientes.

| Riesgo encontrado | Posible consecuencia | Medida propuesta |
|---|---|---|
| Dar acceso directo a toda la tabla | Exposicion de datos que no se necesitan | Limitar permisos por funcion |
| Mostrar nombres y correos en reportes | Exposicion innecesaria de datos personales | Utilizar estadisticas agrupadas |
| Conservar datos durante demasiado tiempo | Acumulacion de informacion innecesaria | Definir una politica de retencion |
| No documentar la retencion | No saber cuando revisar o eliminar datos | Registrar periodos y responsables |
| Entregar bases completas a desarrolladores | Mayor cantidad de informacion expuesta | Entregar solo los datos necesarios |
| Utilizar datos reales en desarrollo | Exposicion durante las pruebas | Preferir datos ficticios o anonimizados |
| Usar correos para promociones sin revisar la finalidad | Uso de datos para un proposito no validado | Revisar las condiciones antes de utilizarlos |
| No definir las finalidades | Uso poco claro de la informacion | Documentar los propositos |
| No revisar los permisos | Usuarios con accesos que ya no necesitan | Revisar y retirar permisos innecesarios |
| No revisar datos antiguos | Mantener informacion incorrecta o innecesaria | Establecer revisiones periodicas |
| No controlar las copias de la base de datos | Perdida de control sobre los datos | Controlar su creacion, acceso y eliminacion |
| No documentar el uso de los datos | Dificultad para comprobar las decisiones tomadas | Mantener registros y procedimientos |

Estos riesgos muestran que no basta con proteger la base de datos mediante contrasenas o permisos. Tambien es necesario revisar para que se usan los datos, cuanto tiempo se conservan y quien es responsable de cada decision.

## 10. Conclusiones

Con este laboratorio aprendi que la privacidad y la seguridad estan relacionadas, pero no significan exactamente lo mismo. La seguridad busca proteger la informacion contra accesos o cambios no autorizados, mientras que la privacidad tambien considera si los datos se utilizan para una finalidad adecuada y si se conserva solamente la informacion necesaria.

Tambien entendi que el DBA tiene una responsabilidad importante porque administra los permisos, las vistas, los respaldos y otros controles tecnicos. Sin embargo, no debe tomar todas las decisiones por su cuenta, ya que tambien se necesita la participacion de las areas que conocen la finalidad de los datos y las obligaciones correspondientes.

Otra cosa importante es que las copias de desarrollo, los reportes y los respaldos tambien pueden representar riesgos. Por eso, la proteccion de datos debe considerarse desde el diseño de la base de datos y mantenerse durante todo su ciclo de vida.

En general, el laboratorio me ayudo a entender que administrar una base de datos no consiste solamente en hacer que funcione, sino tambien en controlar como se utiliza la informacion y reducir los riesgos para las personas.

## 11. Preguntas de reflexion

### 1. ¿Una base de datos tecnicamente segura necesariamente cumple con todos los requisitos de privacidad?

No necesariamente. Puede tener contrasenas y permisos bien configurados, pero aun asi utilizar los datos para finalidades que no corresponden o conservar informacion que ya no se necesita. La privacidad tambien depende de como se usan los datos.

### 2. ¿Por que el principio de minimo privilegio tambien contribuye a la privacidad?

Porque cada usuario solamente puede consultar la informacion que necesita para realizar su trabajo. Asi se reduce la posibilidad de que vea, copie o utilice datos personales que no necesita.

### 3. ¿Por que el DBA no deberia decidir por si solo la finalidad del tratamiento de los datos?

Porque el DBA se encarga principalmente de la administracion tecnica. La finalidad debe definirse con las areas responsables del servicio, privacidad y cumplimiento, ya que son las que conocen para que se necesita la informacion y bajo que condiciones se puede utilizar.

### 4. ¿Por que los desarrolladores no deberian recibir automaticamente copias completas de bases de datos productivas?

Porque pueden recibir informacion personal que no necesitan para programar o realizar pruebas. Lo mejor es entregar solamente los datos necesarios y evitar dar acceso a toda la informacion de los clientes.

### 5. ¿Por que una copia utilizada para desarrollo tambien puede representar un riesgo de privacidad?

Porque puede contener nombres, correos, telefonos y otros datos reales. Si esa copia no tiene los mismos controles de seguridad, alguien podria acceder a informacion personal fuera del sistema de produccion.

### 6. ¿Por que la retencion debe formar parte del ciclo de vida de los datos?

Porque los datos no deberian guardarse para siempre sin una razon. Desde que se recopilan se debe considerar para que se necesitan, durante cuanto tiempo se conservaran y que se hara con ellos cuando ya no sean necesarios.

### 7. ¿Que relacion existe entre privacidad por diseño y diseño de bases de datos?

Que la privacidad se puede considerar desde que se planean las tablas, los campos, las relaciones y los permisos. Si desde el inicio se recopila solo lo necesario y se limita el acceso, es mas facil reducir los riesgos.

### 8. ¿Que controles tecnicos implementarias para reducir el riesgo de exposicion de datos personales?

Implementaria roles con permisos limitados, vistas que oculten los datos que no se necesitan, controles de acceso, respaldos protegidos y registros de auditoria. Tambien evitaria utilizar datos reales en desarrollo cuando no sea necesario.

### 9. ¿Que informacion deberia conocer un DBA para responder tecnicamente a una solicitud ARCO?

Deberia conocer como se identifican los registros de una persona, en que tablas se encuentran, que copias existen, quien tiene acceso y que procedimientos se utilizan para consultar, corregir, bloquear o eliminar informacion. Tambien debe conocer las instrucciones autorizadas para atender la solicitud.

### 10. ¿Que responsabilidades deberian corresponder al DBA, al responsable de privacidad, al area juridica y al propietario de los datos?

El DBA debe administrar la base de datos y aplicar los controles tecnicos. El responsable de privacidad debe coordinar la proteccion de los datos y los procedimientos relacionados. El area juridica debe orientar sobre las obligaciones y los requisitos aplicables. El propietario de los datos debe definir las necesidades de uso de la informacion y participar en las decisiones sobre su finalidad y conservacion.

