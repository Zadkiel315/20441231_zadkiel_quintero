# LAB-03 - Ciclo de vida y derecho de oposicion

## 1. Objetivo

Entender que pasa con los datos personales cuando una persona solicita que se eliminen o que dejen de utilizarse para una finalidad.

## 2. Procedimiento

### Actividad 8 - Derecho de cancelacion y ciclo de vida

Antes de eliminar un registro de la tabla principal, es importante revisar donde mas podria estar guardada esa informacion.

El mapa seria el siguiente:

```text
clientes
   |
   |-- respaldos
   |-- replicas
   |-- reportes
   |-- exportaciones
   |-- sistemas externos
   |-- tablas relacionadas
   |-- registros de auditoria
```

**Por que eliminar un registro de una tabla no significa que toda la informacion haya desaparecido?**

Porque los datos pueden estar guardados en otros lugares, como respaldos, reportes o sistemas externos. Aunque se elimine el registro de `clientes`, las otras copias pueden seguir existiendo. Por eso, primero se debe revisar donde se encuentra la informacion y como se debe tratar cada copia.

### Actividad 9 - Derecho de oposicion

**Es necesario eliminar inmediatamente todos sus datos de la base?**

No necesariamente. Depende de la finalidad para la que se usan los datos y de la decision que tome el area responsable. Oponerse a una finalidad no significa que todos los datos tengan que eliminarse de inmediato.

**Que informacion podria necesitar mantenerse?**

Podrian mantenerse los datos necesarios para cumplir con obligaciones pendientes, conservar registros que deban guardarse o atender otros procesos autorizados.

**Que informacion podria dejar de utilizarse para determinada finalidad?**

Los datos que se utilizan para enviar promociones podrian dejar de usarse para ese objetivo, si la solicitud procede. Por ejemplo, se podria evitar que el cliente siga apareciendo en las listas de promociones.

**Que mecanismos tecnicos podrian separar las finalidades?**

Se pueden crear vistas diferentes, limitar permisos de acceso y utilizar una lista de clientes que no deben recibir promociones. Tambien se pueden configurar controles para que los datos no se utilicen en actividades que ya no correspondan.

**Por que la decision final no debe ser tomada unicamente por el DBA?**

Porque el DBA se encarga de la parte tecnica de la base de datos, pero no es quien debe decidir por su cuenta si la solicitud procede. El area responsable de privacidad o cumplimiento debe revisar el caso y comunicar que acciones se deben realizar.

## 3. Resultado

Se identifico que los datos pueden encontrarse en diferentes lugares, incluso despues de eliminar un registro de la tabla principal. Tambien se reviso que una solicitud de oposicion puede limitar el uso de los datos para una finalidad especifica sin que necesariamente se eliminen todos.

## 4. Analisis

Estas actividades me ayudaron a entender que no basta con modificar una tabla para asegurar que se cumpla una solicitud. Tambien se deben revisar las copias de los datos y los sistemas donde se utilizan. Ademas, es importante que las decisiones se tomen con apoyo del area responsable y que el DBA realice los cambios tecnicos que correspondan.

## 5. Conclusion

Antes de eliminar datos o dejar de utilizarlos para una finalidad, se debe revisar donde se encuentran y que tratamiento necesitan. Tener controles y conocer el ciclo de vida de la informacion ayuda a evitar que los datos sigan utilizandose de una manera que ya no corresponde.