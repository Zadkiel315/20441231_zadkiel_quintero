# LAB-03 - Finalidad secundaria y derechos ARCO

## 1. Objetivo

Analizar que el uso de los datos personales debe tener una finalidad definida y revisar que cambios se pueden realizar en la base de datos cuando una persona solicita ejercer sus derechos ARCO.

## 2. Procedimiento

### Actividad 5 - Analizar una finalidad secundaria

La empresa quiere utilizar los datos de los clientes para enviar promociones personalizadas basadas en su edad, ciudad y comportamiento de compra.

**1. El hecho de que la organizacion ya tenga los datos significa que puede utilizarlos para cualquier finalidad?**

No, tener los datos guardados no significa que se puedan usar para cualquier cosa. Antes de utilizarlos para otra finalidad, la organizacion debe revisar si ese uso es adecuado y si corresponde con la finalidad para la que fueron recopilados.

**2. Que preguntas deberia realizar la organizacion antes de implementar este tratamiento?**

- Para que se recopilaron originalmente los datos?
- Se informo a los clientes sobre el uso de sus datos?
- Es necesario utilizar la edad, ciudad y comportamiento de compra?
- Que personas tendrian acceso a esta informacion?
- Como se protegerian los datos?
- Como podria un cliente oponerse a recibir promociones, cuando corresponda?

**3. Que datos serian realmente necesarios?**

Se podria utilizar la ciudad y un rango de edad si son suficientes para organizar las promociones. Para conocer el comportamiento de compra, se podria trabajar con categorias o datos resumidos. No seria necesario utilizar el RFC, telefono o correo en el analisis si no se requieren para esa tarea.

**4. Necesitaria el area de marketing acceso directo a clientes?**

No necesariamente. Marketing podria trabajar con informacion agrupada o con una vista que muestre unicamente los datos necesarios. El acceso a los datos de contacto deberia limitarse al personal que realmente necesite utilizarlos para enviar las promociones.

**5. Que controles tecnicos podrian limitar la informacion entregada?**

- Crear vistas con los campos necesarios.
- Dar permisos unicamente al personal autorizado.
- Evitar que marketing tenga acceso directo a toda la tabla `clientes`.
- Utilizar datos agrupados cuando sea suficiente.
- Registrar los accesos y cambios importantes.
- Revisar periodicamente los permisos otorgados.

### Actividad 6 - Derecho de acceso


**Que informacion adicional deberia proporcionar la organizacion ademas del resultado de esta consulta?**

Ademas de mostrar los datos encontrados, la organizacion deberia explicar de manera clara que informacion tiene registrada y, segun corresponda, para que la utiliza. Tambien tendria que comprobar que la solicitud pertenece al titular correcto y revisar si existen otros datos relacionados que deban considerarse. La respuesta final debe ser revisada por el area responsable de privacidad.

Desde el punto de vista tecnico, es importante localizar los registros correctos, evitar mostrar datos de otra persona y proteger la informacion durante su consulta y entrega.

### Actividad 7 - Derecho de rectificacion

**Como podria comprobarse que el cambio fue autorizado?**

Se podria revisar la solicitud recibida, verificar la identidad del titular y confirmar que el cambio corresponde a la persona correcta antes de modificar el registro.

**Deberia registrarse quien realizo el cambio?**

Si, seria recomendable guardar quien hizo el cambio, la fecha, el dato que se modifico y la autorizacion correspondiente, evitando registrar informacion innecesaria.

**Por que la trazabilidad sera importante?**

Porque permite saber quien realizo una modificacion, cuando se hizo y cual fue el motivo. Si aparece un error o una modificacion no autorizada, el registro ayuda a investigar lo ocurrido.

## 3. Resultado

Se analizaron los riesgos de utilizar datos personales para una finalidad secundaria y se identificaron medidas para limitar el acceso a la informacion. Tambien se revisaron consultas SQL para localizar los datos de un titular y corregir su correo electronico.

## 4. Analisis

Estas actividades muestran que no basta con tener una base de datos para poder utilizar toda su informacion sin restricciones. Es importante revisar la finalidad del tratamiento, limitar los permisos y mantener registros de los cambios. De esta manera, se puede reducir el riesgo de accesos indebidos y errores en los datos de los clientes.

## 5. Conclusion

La base de datos debe utilizarse de forma responsable y solo con los datos necesarios para cada actividad. Los derechos ARCO tambien tienen una parte tecnica, porque pueden requerir consultas, modificaciones y controles para asegurar que las acciones se realicen correctamente.