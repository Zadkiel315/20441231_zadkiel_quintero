# POL-04 — Restauracion

**Objetivo:** Evitar que una restauracion provoque perdida de informacion, inconsistencias o reemplazo de datos sin autorizacion.

**Alcance:** Aplica a las bases de datos PostgreSQL y MongoDB, principalmente en el ambiente de produccion, aunque tambien contempla pruebas de recuperacion en ambientes separados.

**Regla:**
1. Toda restauracion debe contar con una solicitud que indique el motivo, la informacion que se recuperara y el punto al que se desea regresar.
2. El propietario del dato y el responsable del sistema deben aprobar la restauracion antes de ejecutarla. El DBA o administrador del motor sera quien la realice.
3. Antes de restaurar en produccion, se debe revisar el impacto sobre los datos actuales y comprobar que la informacion recuperada sea consistente.

**Responsable:** El propietario del dato y el responsable del sistema autorizan. El DBA o administrador de MongoDB ejecuta la restauracion y documenta el resultado.

**Excepciones:** En una emergencia que afecte la disponibilidad del servicio, el responsable de Seguridad de la Informacion o el responsable del sistema puede autorizar una restauracion urgente. La decision debe documentarse y notificarse al propietario del dato.

**Evidencia:**
- Actualmente no existe evidencia de una restauracion comprobada de PostgreSQL o MongoDB en estos laboratorios.
- LAB-01 y LAB-02 contienen registros de auditoria y archivos exportados, pero no demuestran que una base de datos haya sido restaurada.
- Se debe generar un registro de cada prueba o restauracion realizada, con fecha, responsable, motivo y resultado.

**Revision:** Cada seis meses y despues de cada restauracion importante.

**Nota:** El procedimiento tecnico se definira en la Unidad V.