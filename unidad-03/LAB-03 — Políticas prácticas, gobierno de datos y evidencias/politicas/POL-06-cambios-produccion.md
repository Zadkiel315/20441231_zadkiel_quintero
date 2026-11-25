# POL-06 — Cambios en produccion

**Objetivo:** Evitar cambios no autorizados o errores que puedan afectar la disponibilidad, seguridad e integridad de los datos.

**Alcance:** Aplica a los cambios realizados en el ambiente de produccion definido en la Unidad I, incluyendo PostgreSQL y MongoDB. Tambien contempla los cambios que primero se prueban en desarrollo y pruebas antes de llegar a produccion.

**Regla:**
1. Antes de realizar un cambio en produccion, debe existir una solicitud con su descripcion, motivo, responsable y aprobacion del propietario del dato o del comite de cambios.
2. Durante el cambio, el DBA o administrador debe trabajar dentro de la ventana autorizada y registrar las operaciones realizadas.
3. Despues del cambio, se debe comprobar que funcione correctamente y comparar la solicitud aprobada con los eventos registrados en la bitacora. Cualquier diferencia debe documentarse.

**Responsable:** El propietario del dato o el comite de cambios autoriza. El DBA o administrador del motor ejecuta el cambio y verifica el resultado. Seguridad de la Informacion revisa los cambios que afecten la seguridad.

**Excepciones:** Un cambio urgente puede ser autorizado por el responsable del sistema y Seguridad de la Informacion cuando exista un riesgo importante. Se debe registrar el motivo y obtener la aprobacion correspondiente despues de atender la emergencia.

**Evidencia:**
- LAB-01, Actividad 6: lineas de bitacora con sentencias `GRANT`, `REVOKE`, `CREATE` y `ALTER`.
- LAB-03, Actividad 7: tabla `gobierno.solicitudes_cambio`, que permitira relacionar cada cambio con su solicitud y ventana autorizada.
- Actualmente la tabla de solicitudes de cambio todavia no se ha creado; se completara en la Actividad 7.

**Revision:** Cada mes y despues de un cambio importante en produccion.