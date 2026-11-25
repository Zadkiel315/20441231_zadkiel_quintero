# POL-02 — Respaldo

**Objetivo:** Evitar la perdida de informacion importante por fallas del servidor, errores humanos, daños en los archivos o problemas en el sistema.

**Alcance:** Aplica a las bases de datos PostgreSQL y MongoDB, incluyendo tablas de clientes, registros de auditoria, configuraciones importantes y registros necesarios para investigar incidentes.

**Regla:**
1. La informacion de produccion debe respaldarse diariamente y debe conservarse una copia semanal para contar con un punto de recuperacion adicional.
2. Los respaldos deben almacenarse en una ubicacion separada del servidor original y tener acceso restringido.
3. El DBA o administrador debe verificar que los respaldos se hayan generado correctamente y que los archivos no esten dañados.

**Responsable:** El DBA y el administrador de MongoDB ejecutan y revisan los respaldos. El propietario de los datos decide cuales conjuntos de informacion deben incluirse.

**Excepciones:** Se puede cambiar la frecuencia cuando exista una justificacion tecnica aprobada por el responsable del sistema y el propietario de los datos. La excepcion debe quedar documentada.

**Evidencia:**
- LAB-01: existe `evidencias/bitacora-lab01.log` y su archivo `bitacora-lab01.sha256`, pero son evidencia de auditoria e integridad, no respaldos de la base de datos.
- LAB-02: existen registros y archivos de comparacion de MongoDB, pero no demuestran por si solos que exista un respaldo recuperable.
- Actualmente no existe evidencia de una politica de respaldos ejecutada ni de una restauracion comprobada.

**Revision:** Cada seis meses o despues de un cambio importante en la infraestructura.

**Nota:** El procedimiento tecnico se definira en la Unidad V.