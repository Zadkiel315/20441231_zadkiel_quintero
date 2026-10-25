# LAB-03 - Privacidad por diseno y controles

## 1. Objetivo

Entender como proteger los datos personales desde el diseño de una aplicacion y reconocer la diferencia entre los controles tecnicos y administrativos.

## 2. Procedimiento

### Actividad 12 - Privacidad por diseno

Una nueva aplicacion propone guardar muchos datos de los clientes, con la idea de que tal vez se necesiten en el futuro.

**1. Que problemas identificas?**

El problema es que se quieren guardar muchos datos sin saber si realmente se necesitan. Esto aumenta los riesgos si alguien consigue acceso a la base de datos y hace mas complicado proteger la informacion.

**2. Que principio de privacidad se esta ignorando?**

Se esta ignorando el principio de minimizacion de datos, porque se pretende recopilar toda la informacion posible en lugar de guardar solo la necesaria.

**3. Que preguntas realizarias antes de aprobar el diseno?**

- Para que se necesita cada dato?
- Quien va a utilizar esa informacion?
- Es necesario guardar todos esos datos?
- Cuanto tiempo se conservaran?
- Como se van a proteger?
- Que pasaria si alguien accede sin autorizacion?

**4. Que datos eliminarias?**

Quitaria los campos que no tengan una finalidad clara. Por ejemplo, si la aplicacion solo necesita registrar y contactar clientes, no agregaria salario, ocupacion, estado civil o fecha de nacimiento si no son necesarios para el servicio.

**5. Que datos requeririan una justificacion adicional?**

El RFC, la fecha de nacimiento, el salario, la ocupacion y el estado civil necesitan una explicacion de por que se van a recopilar. Tambien revisaria si es necesario guardar la direccion completa o si basta con la ciudad y el codigo postal.

**6. Como aplicarias privacidad por defecto?**

Dejaria solamente los campos necesarios desde el inicio. Tambien configuraria permisos para que cada usuario consulte solo la informacion que necesita y evitaria que todos tengan acceso a la tabla completa.

### Actividad 13 - Diferenciar controles tecnicos y administrativos

La siguiente tabla clasifica las medidas segun el tipo de control que representan.

| Medida | Tecnico | Administrativo | Justificacion |
|---|---|---|---|
| Crear roles de PostgreSQL | X | | Permite controlar que usuarios pueden acceder a la base de datos. |
| Politica de retencion | | X | Establece cuanto tiempo se deben conservar los datos. |
| Cifrado de datos | X | | Ayuda a proteger la informacion para que no pueda leerse facilmente sin autorizacion. |
| Procedimiento para solicitudes ARCO | | X | Indica como se reciben y atienden las solicitudes de los titulares. |
| Vista con informacion limitada | X | | Permite mostrar solamente los datos necesarios para una actividad. |
| Clasificacion de informacion | | X | Ayuda a identificar que datos necesitan mayor proteccion. |
| Registro de auditoria | X | | Permite registrar accesos y cambios realizados en el sistema. |
| Politica de control de acceso | | X | Define quien puede consultar la informacion y bajo que condiciones. |

Algunas medidas pueden involucrar ambos tipos de control. Por ejemplo, una politica de control de acceso es administrativa, pero se puede aplicar tecnicamente mediante roles y permisos de PostgreSQL.

## 3. Resultado

Se identificaron datos que no deberian recopilarse sin una finalidad clara y se clasificaron diferentes medidas de proteccion en tecnicas y administrativas.

## 4. Analisis

Considero que es mejor guardar solamente los datos que se necesitan, en lugar de acumular informacion por si algun dia sirve. Tambien es importante combinar las reglas de la organizacion con herramientas tecnicas para proteger la base de datos.

## 5. Conclusion

La privacidad debe tomarse en cuenta desde que se diseña una aplicacion. Si se limitan los datos y se establecen controles adecuados desde el principio, es mas facil proteger la informacion de los clientes y evitar accesos innecesarios.