# LAB-03 - Privacidad, cumplimiento y gobierno

## 1. Objetivo

Analizar los datos que se guardan en la tabla `clientes` y revisar como se pueden proteger mejor. Tambien se busca limitar el acceso a la informacion segun las funciones de cada area, para evitar que los empleados consulten datos que no necesitan.

## 2. Procedimiento

Para realizar las actividades, primero se revisaron los campos de la tabla `clientes` y se identifico para que sirve cada uno. Despues se analizo que datos necesita el area de soporte, como se pueden preparar estadisticas para analitica y como limitar los permisos mediante roles y vistas en PostgreSQL.

## 3. Resultado

### Actividad 1 - Inventario y finalidad de los datos

| Campo | ¿Es dato personal? | Finalidad | ¿Es necesario? | Nivel de acceso | Retencion |
|---|---|---|---|---|---|
| id | No directamente, pero identifica un registro | Identificar cada registro | Si | Personal autorizado | Mientras se necesite el registro |
| nombre | Si | Identificar al cliente | Si | Atencion al cliente y personal autorizado | Mientras sea necesario |
| correo | Si | Contactar al cliente | Si, cuando se necesita | Atencion al cliente | Mientras sea necesario |
| telefono | Si | Contactar al cliente | Si, cuando se utiliza ese medio | Atencion al cliente | Mientras sea necesario |
| rfc | Si | Facturacion y tramites fiscales | Solo cuando se requiera | Facturacion y personal autorizado | Segun las obligaciones aplicables |
| edad | Si | Estadisticas o verificar requisitos | No siempre | Personal autorizado | Mientras sea necesaria |
| ciudad | Puede ayudar a identificar | Ubicacion y estadisticas | Si se necesita | Personal autorizado y analitica | Mientras sea necesaria |
| codigo_postal | Puede ayudar a identificar | Ubicacion o facturacion | Solo cuando se requiera | Personal autorizado | Mientras sea necesario |
| fecha_alta | Puede relacionarse con el cliente | Saber cuando se registro | Si | Personal autorizado | Segun la finalidad |

Las decisiones se tomaron considerando para que sirve cada dato. Por ejemplo, el RFC puede ser necesario para facturacion, pero no para todas las actividades de soporte. La edad y el codigo postal tampoco deberian solicitarse si no existe una razon para hacerlo.

### Actividad 2 - Principio de minimizacion

La tabla que se propone para soporte contiene varios campos que no siempre son necesarios. Si el area solamente necesita contactar a los clientes, puede trabajar con su identificador, nombre, correo y telefono.

**¿Todos los campos son necesarios para atencion al cliente?**

No, porque algunos datos no se utilizan para resolver dudas o contactar a los clientes.

**¿Por que soporte necesitaria conocer el RFC?**

Normalmente no lo necesita. Podria ocuparlo en algun caso relacionado con una factura, pero no deberia consultarlo si no es necesario.

**¿Necesita conocer la edad?**

No siempre. Si solo va a responder preguntas o ayudar a los clientes, no necesita ese dato.

**¿Necesita conocer el codigo postal?**

Depende de las tareas que realice. Podria necesitarlo para revisar una entrega, pero no para todas las consultas.

**¿Que principio de privacidad esta relacionado con esta decision?**

El principio de minimizacion de datos, porque se debe utilizar solamente la informacion necesaria para cumplir una finalidad.

### Actividad 3 - Separacion por finalidad

El area de analitica necesita obtener estadisticas sobre las ciudades y los rangos de edad. Para esto no necesita consultar nombres, correos, telefonos ni RFC.


**¿Por que esta informacion puede ser mas apropiada para analitica que entregar directamente la tabla completa de clientes?**

Porque permite obtener las estadisticas sin mostrar todos los datos personales. De esta manera, el area puede hacer su trabajo sin tener acceso a informacion que no necesita.

### Actividad 4 - Control de acceso relacionado con la finalidad


**¿Que informacion puede consultar el rol?**

Puede consultar la ciudad y el rango de edad que aparecen en la vista, siempre que tenga los permisos necesarios.

**¿Puede consultar directamente clientes?**

No con los permisos otorgados en este ejercicio, siempre que no tenga otros permisos concedidos por separado.

**¿Puede obtener nombre, correo y RFC?**

No mediante la vista creada, porque esos campos no estan incluidos.

**¿Que principio de privacidad estas aplicando?**

La minimizacion de datos, porque solamente se comparte la informacion necesaria.

**¿Que principio de seguridad estas aplicando?**

El minimo privilegio, porque el rol recibe solamente los permisos necesarios para realizar su trabajo.

## 4. Analisis

Con estas actividades se puede ver que no todos los empleados necesitan tener acceso a toda la informacion de los clientes. Por ejemplo, soporte puede utilizar los datos de contacto, mientras que analitica puede trabajar con informacion agrupada para obtener estadisticas.

Tambien es importante revisar los permisos de cada rol, porque crear una vista con informacion limitada no sirve de mucho si el usuario sigue teniendo acceso directo a la tabla original. Por eso, los permisos deben revisarse para evitar accesos adicionales.

## 5. Conclusion

Con este laboratorio entendi que proteger una base de datos no consiste solamente en evitar que otras personas entren. Tambien es importante controlar que informacion puede consultar cada usuario y para que la necesita. Usar tablas con menos datos, consultas agrupadas y vistas ayuda a reducir la exposicion de informacion personal.