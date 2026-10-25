# LAB-03 - Matriz de gobierno de datos

## 1. Objetivo

Organizar los datos de los clientes e identificar para que se utilizan, quien es responsable, que usuarios pueden consultarlos y que proteccion necesitan.

## 2. Procedimiento

### Actividad 11 - Diseñar una matriz de gobierno de datos

| Dato | Finalidad | Responsable | Usuarios autorizados | Proteccion | Retencion | Accion al finalizar |
|---|---|---|---|---|---|---|
| nombre | Identificar al cliente | Atencion al cliente | Atencion al cliente, facturacion | Acceso restringido | Mientras sea necesario | Eliminar cuando ya no se necesite |
| correo | Contactar al cliente | Atencion al cliente | Atencion al cliente y personal autorizado | Acceso restringido y evitar su uso indebido | Mientras se necesite para el servicio | Eliminar o actualizar segun corresponda |
| telefono | Contactar al cliente | Atencion al cliente | Atencion al cliente | Acceso restringido | Mientras se necesite para el servicio | Eliminar cuando ya no sea necesario |
| rfc | Facturacion | Facturacion | Personal de facturacion autorizado | Acceso limitado | Durante el periodo necesario por obligaciones aplicables | Eliminar cuando ya no exista motivo para conservarlo |
| edad | Clasificar clientes para analisis | Analitica | Analitica autorizada | Preferir rangos de edad y no datos individuales | Mientras sea necesaria para el analisis | Eliminar o convertir en datos agrupados |
| ciudad | Analisis por ubicacion | Analitica | Analitica y direccion autorizada | Limitar el acceso segun la finalidad | Mientras sea necesaria para el analisis | Eliminar o conservar solo datos agrupados si es suficiente |
| codigo_postal | Datos de ubicacion para el servicio | Atencion al cliente | Atencion al cliente y personal autorizado cuando lo necesite | Acceso restringido | Mientras sea necesario para el servicio | Eliminar cuando ya no sea necesario |

Los periodos de retencion de la tabla son una propuesta general. La organizacion tendria que definir los periodos reales segun la finalidad y las obligaciones que correspondan.

## 3. Resultado

Se creo una matriz para organizar los principales datos de la tabla `clientes`. Se asignaron responsables y usuarios autorizados dependiendo de la actividad que realiza cada area.

## 4. Analisis

Con esta matriz se puede ver que no todos los empleados necesitan consultar los mismos datos. Por ejemplo, facturacion puede necesitar el RFC, pero el area de analitica puede trabajar con cantidades agrupadas sin consultar directamente los datos personales de cada cliente.

## 5. Conclusion

El gobierno de datos ayuda a tener mas claro quien puede consultar la informacion y para que se utiliza. Tambien permite limitar los accesos y establecer que se debe hacer con los datos cuando dejan de ser necesarios.