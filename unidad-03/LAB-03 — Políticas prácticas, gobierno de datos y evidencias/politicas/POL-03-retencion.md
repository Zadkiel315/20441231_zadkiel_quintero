# POL-03 — Retencion

**Objetivo:** Evitar que los datos y registros se conserven por tiempo indefinido, reduciendo el riesgo de exposicion de informacion personal y la perdida de evidencia importante.

**Alcance:** Aplica a las tablas de PostgreSQL, colecciones de MongoDB, bitacoras del servidor, registros de auditoria y archivos exportados.

**Regla:**
1. Los datos de clientes se conservaran mientras exista una finalidad valida para utilizarlos y de acuerdo con las obligaciones aplicables.
2. Las bitacoras de accesos y modificaciones se conservaran por el periodo establecido en el catalogo de conservacion de LAB-03, Actividad 5.
3. Antes de eliminar registros de auditoria que contengan datos personales, se debe comprobar que no exista una investigacion o solicitud pendiente. Cuando sea posible, se deben anonimizar los datos personales sin perder la evidencia necesaria.

**Responsable:** El propietario del dato define la necesidad de conservar la informacion. Seguridad de la Informacion y el area juridica revisan los riesgos y obligaciones. El DBA ejecuta las acciones autorizadas.

**Excepciones:** Se puede ampliar el periodo cuando exista una investigacion, auditoria u obligacion legal pendiente. La ampliacion debe ser aprobada por el responsable correspondiente y quedar documentada.

**Evidencia:**
- LAB-03, Actividad 5: archivo `evidencias/05-conservacion.md`, con los periodos propuestos.
- LAB-01: `evidencias/bitacora-lab01.log` y `evidencias/bitacora-lab01.sha256`.
- LAB-02: `evidencias/09-comparacion.md` y los registros exportados de MongoDB.
- Actualmente no existe un registro automatico que demuestre la eliminacion o anonimización de datos al vencer su periodo.

**Revision:** Cada seis meses y cuando cambien las obligaciones legales o las necesidades del negocio.