# LAB-03 - Evaluacion integral

## 1. Objetivo

Identificar los problemas que existen en el manejo de los datos de los clientes y proponer algunas medidas para mejorar su proteccion.

## 2. Procedimiento

### Actividad 14 - Escenario integral

En este escenario se identificaron los siguientes problemas y riesgos:

| Problema | Principio afectado | Riesgo | Control propuesto |
|---|---|---|---|
| 1. Todos los empleados de analitica pueden consultar la tabla completa. | Minimizacion y control de acceso | Que alguien consulte datos que no necesita. | Crear roles y permisos limitados. |
| 2. Analitica puede ver nombres y correos aunque solo genera estadisticas. | Minimizacion de datos | Exposicion innecesaria de datos personales. | Crear una vista con datos agrupados. |
| 3. Los datos se conservan desde hace 12 años. | Limitacion de conservacion | Guardar informacion que ya no se necesita. | Revisar que datos siguen siendo necesarios. |
| 4. No existe una politica de retencion documentada. | Gobierno de datos | No saber cuando corresponde eliminar o revisar la informacion. | Crear y documentar una politica de retencion. |
| 5. Los desarrolladores reciben copias completas de la base de datos. | Minimizacion y confidencialidad | Que mas personas tengan acceso a datos personales. | Darles solamente los datos necesarios para las pruebas. |
| 6. Las copias de desarrollo contienen informacion real. | Privacidad y seguridad | Exponer datos de clientes durante las pruebas. | Usar datos ficticios o anonimizados. |
| 7. Marketing utiliza los correos para promociones. | Limitacion de la finalidad | Utilizar los datos para una finalidad que no se ha revisado correctamente. | Revisar y documentar si ese uso corresponde y que condiciones debe cumplir. |
| 8. No esta claro para que se utiliza cada dato. | Transparencia y finalidad | Usar informacion sin una razon definida. | Documentar la finalidad de cada campo. |
| 9. No se indica que personal necesita cada dato. | Control de acceso | Accesos innecesarios a informacion personal. | Definir permisos segun las funciones de cada area. |
| 10. No se menciona una revision de los datos antiguos. | Calidad y minimizacion | Mantener informacion desactualizada o incorrecta. | Revisar y actualizar los registros cuando corresponda. |
| 11. No se menciona un control sobre las copias de la base de datos. | Seguridad y confidencialidad | Que las copias queden guardadas en lugares sin proteccion. | Limitar quien puede crearlas, consultarlas y eliminarlas. |
| 12. No hay documentacion clara sobre el uso de los datos. | Gobierno y responsabilidad | Tener dificultades para comprobar por que se usan los datos. | Mantener documentacion de las finalidades, permisos y periodos de retencion. |

## 3. Resultado

Se identificaron 12 problemas relacionados con los permisos, la conservacion de los datos, las copias de desarrollo y el uso de los correos para promociones. Tambien se propusieron controles para reducir esos riesgos.

## 4. Analisis

Considero que el problema principal es que se tiene mucha informacion disponible, pero no hay reglas claras sobre quien puede usarla ni durante cuanto tiempo. Por ejemplo, analitica solo necesita hacer estadisticas mensuales, asi que no tiene mucho sentido que todos sus empleados puedan consultar los datos completos de los clientes.

Tambien me parece importante dejar de usar informacion real en las pruebas, porque eso expone datos que no son necesarios para desarrollar una aplicacion.

## 5. Conclusion

La empresa necesita organizar mejor el uso de los datos y limitar los accesos segun las funciones de cada area. Tambien debe establecer una politica de retencion y revisar las finalidades para las que utiliza la informacion. Con estos cambios se pueden reducir riesgos y proteger mejor los datos de los clientes.