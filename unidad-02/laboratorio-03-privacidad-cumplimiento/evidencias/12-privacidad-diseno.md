# LAB-03 - Privacidad por diseno

## 1. Objetivo

Analizar como se puede diseñar una base de datos para guardar solamente los datos necesarios de los clientes y evitar recopilar informacion que no se va a utilizar.

## 2. Procedimiento

### Actividad 12 - Privacidad por diseno

**1. Que problemas identificas?**

El principal problema es que se quieren guardar muchos datos sin saber si realmente se necesitan. Esto puede ocupar espacio, complicar el manejo de la informacion y aumentar los riesgos si alguien consigue acceso a la base de datos.

**2. Que principio de privacidad se esta ignorando?**

Se esta ignorando el principio de minimizacion de datos, porque se pretende recopilar toda la informacion posible en lugar de guardar solamente la necesaria para el servicio.

**3. Que preguntas realizarias antes de aprobar el diseno?**

- Para que se necesita cada dato?
- Quien va a utilizar esa informacion?
- Es obligatorio guardar ese dato?
- Cuanto tiempo se necesita conservar?
- Como se va a proteger?
- Que pasaria si alguien obtiene acceso sin autorizacion?

**4. Que datos eliminarias?**

Quitaria los campos que no tengan una finalidad clara. Por ejemplo, si la aplicacion solo necesita registrar clientes y contactarlos, no agregaria salario, ocupacion,