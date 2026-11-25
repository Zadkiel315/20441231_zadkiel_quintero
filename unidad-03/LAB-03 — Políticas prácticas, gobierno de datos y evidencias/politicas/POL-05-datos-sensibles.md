# POL-05 — Uso de datos sensibles

**Objetivo:** Evitar la exposicion o uso incorrecto de datos personales y de informacion confidencial de los clientes.

**Alcance:** Aplica a los datos personales almacenados en PostgreSQL y MongoDB, incluyendo nombres, correos, telefonos, RFC, edad, ubicacion y registros de auditoria que puedan contener esos datos.

**Regla:**
1. Solamente los usuarios autorizados pueden consultar datos sensibles y deben tener una justificacion relacionada con sus actividades.
2. Para actividades de soporte, pruebas o reportes se deben utilizar datos enmascarados o anonimizados cuando no sea necesario conocer la informacion completa.
3. Los accesos y modificaciones relevantes deben quedar registrados y ser revisados por el personal autorizado.

**Responsable:** El propietario del dato autoriza su uso. Seguridad de la Informacion establece los controles y el DBA o administrador del motor los aplica.

**Excepciones:** Se permite consultar informacion completa cuando sea necesario para facturacion, atencion al cliente o investigacion de un incidente. Se requiere autorizacion del responsable correspondiente y debe quedar evidencia del motivo.

**Evidencia:**
- LAB-01, Actividad 6: permisos de `app_ventas` y `soporte_ana`.
- LAB-01, Parte B: tabla `auditoria.cambios_clientes` y su disparador de auditoria.
- LAB-01: vista de datos enmascarados para soporte y exportacion de bitacora con el secreto `Temporal_Practica_2026` sustituido por `<REDACTED>`.
- LAB-02: `system.profile` y `evidencias/09-comparacion.md`, que muestran las limitaciones de registro en MongoDB Community.
- Actualmente no existe un registro completo de justificaciones para cada consulta de datos sensibles.

**Revision:** Cada tres meses y despues de cualquier incidente relacionado con informacion personal.