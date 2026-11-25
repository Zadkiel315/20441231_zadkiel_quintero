# POL-01 — Acceso

**Objetivo:** Evitar que personas sin autorizacion puedan consultar, modificar o eliminar informacion de la base de datos.

**Alcance:** Aplica a PostgreSQL, MongoDB y sus ambientes de desarrollo, pruebas y produccion. Incluye tablas de clientes, registros de auditoria, bitacoras y colecciones.

**Regla:**
1. Los usuarios o responsables de cada area pueden solicitar accesos indicando el motivo y los permisos que necesitan.
2. El propietario del dato debe aprobar la solicitud y el DBA o administrador del motor debe asignar solamente los permisos autorizados.
3. Los accesos deben revisarse cada tres meses y tambien cuando una persona cambie de puesto o deje de necesitar el permiso.

**Responsable:** El propietario del dato decide y aprueba. El DBA o administrador de MongoDB ejecuta los cambios de permisos.

**Excepciones:** Un acceso urgente puede autorizarlo el responsable de Seguridad de la Informacion, siempre que se documente el motivo y se informe al propietario del dato. El permiso temporal debe revisarse y retirarse al terminar la necesidad.

**Evidencia:**
- LAB-01, Actividad 6: registros de `GRANT` y `REVOKE` en la bitacora.
- LAB-01, E2: permisos observados para `app_ventas` y `soporte_ana`.
- LAB-03, Actividad 7: registro de cambios en `gobierno.solicitudes_cambio` para cambios relacionados con permisos.
- Actualmente no existe un registro formal de solicitudes de acceso; debe implementarse.

**Revision:** Cada tres meses o cuando cambien los responsables, puestos o permisos.