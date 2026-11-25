# Actividad 7. Registro de cambios y conciliacion

## 1. Objetivo

Registrar los cambios realizados en la base de datos comercial y compararlos con las solicitudes de cambio para identificar si fueron ejecutados correctamente y si cuentan con evidencia de autorizacion.

## 2. Registro de cambios

Se creo el esquema `gobierno` y la tabla `gobierno.solicitudes_cambio`, donde se almacenan los folios, responsables, ambiente y ventanas de mantenimiento.

Se registro la solicitud CAM-2026-014 para agregar la columna `canal_alta` a la tabla `clientes`.

## 3. Tabla de conciliacion

| Momento | Usuario | Sentencia o cambio | Folio | Autorizado | Hallazgo |
|---|---|---|---|---|---|
| 2026-11-24 23:40:45 | postgres | CREATE SCHEMA gobierno | No aplica | Preparacion | Se creo el esquema para el registro de cambios. |
| 2026-11-24 23:40:45 | postgres | REVOKE ALL ON SCHEMA gobierno FROM PUBLIC | No aplica | Preparacion | Se retiraron los permisos generales del esquema. |
| 2026-11-24 23:40:45 | postgres | CREATE TABLE gobierno.solicitudes_cambio | No aplica | Preparacion | Se creo la tabla para registrar solicitudes. |
| 2026-11-24 23:41:29 | postgres | ALTER TABLE clientes ADD COLUMN canal_alta VARCHAR(20) | CAM-2026-014 | No comprobado previamente | El cambio se ejecuto antes de insertar la solicitud. |
| 2026-11-24 23:42:58 | postgres | INSERT INTO gobierno.solicitudes_cambio | CAM-2026-014 | Registrado despues del cambio | La solicitud se registro despues de ejecutar el cambio. |
| 2026-11-24 23:43:08 | postgres | ALTER TABLE clientes ADD COLUMN canal_alta VARCHAR(20) | CAM-2026-014 | No aplica | El intento repetido fallo porque la columna ya existia. |

## 4. Resultado de la verificacion

La consulta de la solicitud devolvio el siguiente resultado:

- Folio: CAM-2026-014.
- Aprobado por: Comite de cambios.
- Dentro de la ventana: verdadero.

La ventana de mantenimiento estaba vigente al momento de consultar el registro. Sin embargo, esto no demuestra que el cambio original haya sido autorizado antes de ejecutarse, ya que la solicitud se inserto despues del primer ALTER TABLE.

## 5. Hallazgos

1. El cambio de estructura de la tabla clientes se ejecuto correctamente.
2. La solicitud CAM-2026-014 fue registrada despues de aplicar el cambio, por lo que no existe evidencia de autorizacion previa en el orden de ejecucion observado.
3. Se intento agregar nuevamente la columna canal_alta, pero PostgreSQL rechazo la operacion porque ya existia.
4. La bitacora permite identificar al usuario que ejecuto las sentencias y el momento en que fueron registradas.
5. La conciliacion depende de que los cambios tengan un folio registrado y una autorizacion verificable.

## 6. Preguntas de analisis

**¿Que cambios aparecen en la bitacora sin folio?**

La creacion del esquema gobierno, la revocacion de permisos y la creacion de la tabla solicitudes_cambio no tienen un folio asociado. Son operaciones de preparacion de la actividad. El primer cambio de canal_alta tampoco tenia una solicitud registrada previamente.

**¿Como se clasifican los cambios?**

Los cambios del esquema y de la tabla de solicitudes corresponden a preparacion del mecanismo de gobierno. El agregado de canal_alta corresponde a un cambio de estructura que debia estar respaldado por una solicitud y autorizacion previa.

**¿Que gravedad tiene desactivar un trigger de auditoria?**

Es un hallazgo grave porque puede permitir modificaciones sin que se registren en la tabla de auditoria. Debe investigarse quien lo hizo, durante cuanto tiempo estuvo desactivado y si hubo cambios en ese periodo.

**¿Cual es la diferencia entre que un usuario de aplicacion y postgres desactiven un trigger?**

Si lo hace un usuario de aplicacion, puede indicar que sus permisos son excesivos. Si lo hace postgres, puede tratarse de una operacion administrativa, pero tambien debe estar justificada y documentada. En ambos casos se debe investigar.

**¿Que limitacion existe si log_statement estaba configurado en none?**

Las sentencias ejecutadas durante ese periodo pueden no aparecer en la bitacora. Por eso no siempre se puede reconstruir todo el historial de cambios.

**¿Quien debe realizar la conciliacion?**

El DBA debe reunir y organizar las evidencias tecnicas, mientras que Auditoria Interna o el responsable de gobierno de datos debe revisar que los cambios tengan autorizacion y correspondan con las solicitudes registradas.

## 7. Conclusion

La actividad permitio crear un registro de solicitudes de cambio y comparar sus datos con la bitacora de PostgreSQL. Se comprobo que la columna canal_alta fue agregada correctamente, pero tambien se identifico que la solicitud se registro despues de ejecutar el cambio. Esto demuestra la importancia de registrar y aprobar los cambios antes de aplicarlos, asi como conservar evidencias que permitan revisar las operaciones realizadas.