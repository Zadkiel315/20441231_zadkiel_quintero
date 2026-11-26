# Expediente de auditoria interna — Base comercial

## 1. Alcance

El presente expediente reúne los resultados de las actividades de auditoria, calidad de datos, gobierno de datos, conservacion y politicas realizadas sobre la base comercial.

**Sistemas revisados:**

| Sistema | Version / despliegue | Elementos revisados |
|---|---|---|
| PostgreSQL | 18.6, instalacion local en Windows | Base `comercial`, tablas `public.clientes`, `auditoria.cambios_clientes`, `gobierno.solicitudes_cambio` y vista `dba.bitacora` |
| MongoDB Community | Version 7, despliegue mediante Docker en LAB-02 | Base `comercial`, colecciones `clientes` y `system.profile`, bitacora del servidor y registros del contenedor |

**Periodo revisado:** del 18 de octubre al 24 de noviembre de 2026, considerando los archivos de bitacora y las muestras de auditoria disponibles.

**Responsable:** estudiante encargado de integrar el expediente. La validacion de hallazgos y la aceptacion de riesgos corresponden a los responsables de cada sistema y a las areas propietarias de los datos.

El alcance se limita a la informacion disponible en los laboratorios. No representa una auditoria completa de todos los servidores, usuarios o periodos de operacion.

## 2. Configuracion de auditoria (A3)

### PostgreSQL — LAB-01

Se identificaron los siguientes mecanismos:

- `log_connections = on`: registra conexiones.
- `log_disconnections = on`: registra desconexiones.
- `log_statement = mod`: registra sentencias de modificacion.
- `log_line_prefix = %m [%p] user=%u db=%d app=%a client=%h`: permite identificar fecha, proceso, usuario, base, aplicacion y cliente.
- `log_min_error_statement = error`: registra sentencias relacionadas con errores de nivel error.
- Tabla `auditoria.cambios_clientes` y disparador `trg_auditoria_clientes` para registrar operaciones sobre clientes.
- Vista `dba.bitacora` para consultar registros disponibles.

**Evidencias:**

- `evidencias/E1-configuracion-registro.txt`
- `evidencias/E3-disparadores.txt`
- `evidencias/E4-muestra-auditoria.txt`
- `evidencias/E5-bitacora-postgresql.log`

En E3 se observo que el disparador `trg_auditoria_clientes` tiene el estado `O`, lo que significa que esta habilitado normalmente.

**Limitaciones:** `logging_collector = on` : se encuentra habilitado segun la evidencia E1. Esto permite que PostgreSQL administre sus archivos de registro mediante el recolector de registros. Tampoco se cuenta con evidencia de que se haya instalado `pgaudit`.

### MongoDB Community — LAB-02

Se utilizaron los siguientes mecanismos:

- `system.profile` para conservar informacion de operaciones perfiladas.
- Bitacora del proceso `mongod`.
- Registros completos del contenedor Docker.

**Evidencias:**

- `evidencias/E6-mongodb/system-profile.json`
- `evidencias/E6-mongodb/bitacora-mongod.log`
- `evidencias/E6-mongodb/docker-logs-completo.log`
- `evidencias/E6-mongodb/hashes.sha256`
- `evidencias/E6-mongodb/09-comparacion.md`

MongoDB Community no cuenta con la auditoria nativa disponible en MongoDB Enterprise. Por ello, los mecanismos utilizados permiten obtener informacion parcial, pero no garantizan el registro de todas las operaciones.

## 3. Bitacora interpretada (A3, A5)

Se revisaron eventos de PostgreSQL y MongoDB para identificar quien realizo las operaciones, cuando ocurrieron, desde donde se ejecutaron y que evidencia quedo registrada.

### Evento 1. Cambio de RFC en PostgreSQL

| Campo | Interpretacion |
|---|---|
| Identificador | `id_evento = 1` |
| Quien | Usuario de sesion `app_ventas`; usuario efectivo `postgres` por el uso de `SECURITY DEFINER` |
| Cuando | 25/10/2026 22:50:52.903439 UTC |
| Desde donde | Aplicacion `app-ventas-web`, IP `127.0.0.1` |
| Que ocurrio | Se actualizo el RFC del cliente con ID 3, de `GAMA780912XYZ` a `GAMA780912ZZZ` |
| Tipo de evento | UPDATE de datos personales |
| Que prueba | Registro de auditoria `auditoria.cambios_clientes`, evento 1, LAB-01 Actividad 12 |

**Interpretacion:** el cambio fue ejecutado mediante la cuenta de sesion `app_ventas`. El usuario efectivo aparece como `postgres` porque la funcion del disparador utiliza `SECURITY DEFINER`. Por eso es importante conservar ambos datos para identificar correctamente quien inicio la operacion.

### Evento 2. Cambio de RFC en MongoDB Community

| Campo | Interpretacion |
|---|---|
| Identificador | Documento de `system.profile`, LAB-02 Actividad 3 |
| Quien | `app_ventas@comercial` |
| Cuando | 25/10/2026 22:52:45.909 UTC |
| Desde donde | Aplicacion `app-ventas-web`, IP `127.0.0.1` |
| Que ocurrio | Se modifico el RFC del documento con `_id: 3`, estableciendo el valor `GAMA780912XYZ` |
| Tipo de evento | UPDATE de datos personales |
| Que prueba | Documento de `system.profile` y `evidencias/E6-mongodb/09-comparacion.md` |

**Interpretacion:** el perfilador permitio identificar al usuario, la aplicacion, la direccion del cliente y el valor nuevo enviado en la operacion. Sin embargo, el registro no contiene el valor anterior del RFC, por lo que no permite reconstruir completamente el cambio.

### Evento 3. Desactivacion temporal del disparador de auditoria

| Campo | Interpretacion |
|---|---|
| Identificador | Registros de `dba.bitacora`, LAB-01 Actividad 14 |
| Quien | Usuario administrador `postgres` |
| Cuando | Fecha y hora de la actividad segun la bitacora original de LAB-01 |
| Desde donde | Aplicacion `psql`, cliente local |
| Que ocurrio | Se desactivo temporalmente `trg_auditoria_clientes`, se modifico el RFC del cliente con ID 3 y despues se habilito nuevamente el disparador |
| Tipo de evento | Cambio administrativo y modificacion de datos |
| Que prueba | Bitacora PostgreSQL y revision de los registros de `auditoria.cambios_clientes`, LAB-01 Actividad 14 |

**Interpretacion:** la modificacion administrativa no genero un registro correspondiente en la tabla de auditoria porque el disparador estaba desactivado durante la operacion. Esto demuestra que un administrador con privilegios suficientes puede interrumpir el mecanismo de auditoria. La bitacora del servidor conserva las sentencias, pero la tabla de auditoria no registra el cambio de la misma manera que cuando el disparador esta habilitado.

### Evento 4. Cambio de estructura en PostgreSQL

| Campo | Interpretacion |
|---|---|
| Identificador | Registro 139 de `dba.bitacora` |
| Quien | `postgres` |
| Cuando | 24/11/2026 23:41:29.809, hora local registrada |
| Desde donde | Aplicacion y direccion cliente no determinadas en el extracto consultado |
| Que ocurrio | Se ejecuto `ALTER TABLE clientes ADD COLUMN canal_alta VARCHAR(20)` |
| Tipo de evento | Cambio de estructura (DDL) |
| Que prueba | Registro 139 de `dba.bitacora` y `evidencias/06-conciliacion.md` |

**Interpretacion:** se agrego una columna a la tabla de clientes. La solicitud `CAM-2026-014` se inserto posteriormente, por lo que no se puede demostrar que existiera autorizacion previa al cambio.

### Evento complementario. Incidente de RFC sin trazabilidad suficiente en MongoDB

En LAB-02, Actividad 2, se modifico el RFC de Maria Garcia a `GAMA780912XXX`. Sin embargo, el perfilador estaba desactivado y no se encontro el detalle de la operacion en `system.profile` ni en la bitacora de `mongod`.

La bitacora del servidor permitio observar informacion de conexion y autenticacion, pero no identificar la sentencia exacta ni demostrar quien realizo la modificacion.

**Interpretacion:** este caso demuestra que registrar conexiones no equivale a registrar operaciones sobre los datos. La falta de perfilado impidio reconstruir el cambio con la evidencia disponible.

### Muestra complementaria de auditoria (E4)

La evidencia E4 contiene una muestra de 10 registros de la tabla `auditoria.cambios_clientes`. Esta muestra corresponde a operaciones registradas entre el 8 y el 24 de noviembre de 2026.

El registro con `id_evento=1` muestra una actualizacion realizada por `app_ventas`, mediante la aplicacion `app-ventas-web`, sobre el cliente 3, el 8 de noviembre de 2026. Los registros del 2 al 8 corresponden a operaciones ejecutadas por `postgres` desde `psql`. Finalmente, los registros 9 y 10 muestran inserciones de los clientes 7 y 8, realizadas el 24 de noviembre.

Esta muestra es independiente del evento detallado en la Actividad 12 de LAB-01, ocurrido el 25 de octubre de 2026. Por lo tanto, ambos registros se documentan por separado.

### Resultado de la interpretacion

Los eventos muestran que PostgreSQL permite combinar la bitacora del servidor con un disparador para obtener mayor detalle sobre las modificaciones. MongoDB Community permite observar operaciones mediante `system.profile`, pero su cobertura depende de la configuracion del perfilador. Ninguno de estos mecanismos debe considerarse una garantia de auditoria completa frente a administradores con privilegios elevados.

## 4. Elementos de gobierno (A1, A2)

### Responsables

Se establecio la siguiente matriz de responsabilidades:

| Conjunto de datos | Propietario | Custodio | Usuarios |
|---|---|---|---|
| `public.clientes` | Gerencia Comercial | DBA | `app_ventas`, `soporte_ana` |
| `auditoria.cambios_clientes` | Auditoria Interna | DBA | Auditoria y personal autorizado |
| `gobierno.solicitudes_cambio` | Comite de cambios | DBA | Personal autorizado |
| `dba.bitacora` | Seguridad de la Informacion | DBA / administrador del servidor | Auditoria y Seguridad autorizadas |
| `comercial.clientes` (MongoDB) | Gerencia Comercial | Administrador MongoDB | Usuarios autorizados |
| `comercial.system.profile` | Seguridad de la Informacion | Administrador MongoDB | Personal autorizado |

Los responsables y usuarios anteriores representan la matriz de gobierno propuesta en la Actividad 2. No significa que todos esos permisos esten configurados actualmente en ambos motores.

**Evidencia:** `evidencias/02-responsables.md`.

### Catalogo de datos

En la Actividad 4 se completo un catalogo de seis conjuntos de datos:

| ID | Conjunto de datos | Motor |
|---|---|---|
| CAT-01 | Clientes | PostgreSQL |
| CAT-02 | Auditoria de clientes | PostgreSQL |
| CAT-03 | Solicitudes de cambio | PostgreSQL |
| CAT-04 | Bitacora de PostgreSQL | PostgreSQL |
| CAT-05 | Clientes (tienda) | MongoDB Community |
| CAT-06 | Perfilador de operaciones | MongoDB Community |

Los objetos de PostgreSQL se verificaron mediante consultas a `pg_tables` y `pg_views`. Los conjuntos de datos de MongoDB se identificaron mediante las evidencias generadas en LAB-02. La ubicacion fisica y el estado actual del contenedor de MongoDB no se verificaron en esta actividad.

Los propietarios organizacionales, custodios, clasificaciones y periodos de conservacion son propuestas de gobierno de datos y no representan permisos tecnicos ni politicas institucionales formalmente aprobadas.

**Evidencia:** `evidencias/04-catalogo.md`.

### Diccionario de datos

Se agregaron comentarios a la tabla `public.clientes` y a sus diez columnas. Los comentarios describen la finalidad y el significado de los campos.

El diccionario se exporto a CSV e incluye nombre de columna, tipo de dato, longitud, aceptacion de nulos y descripcion.

**Evidencias:**

- `evidencias/03-diccionario.md`
- `evidencias/diccionario-clientes.csv`
- `sql/02-comentarios-diccionario.sql`

## 5. Conservacion (A3)

En la Actividad 5 se propusieron los siguientes plazos de conservacion:

| Tipo de registro | Plazo propuesto |
|---|---:|
| Accesos y conexiones PostgreSQL | 12 meses |
| Cambios de privilegios y estructura | 24 meses |
| Modificaciones de datos registradas en bitacora | 12 meses |
| Auditoria de cambios de clientes | 24 meses |
| Bitacora de MongoDB (`mongod`) | 12 meses |
| `system.profile` de MongoDB | 30 dias |
| Instantaneas de privilegios de MongoDB | 24 meses |

Estos plazos son criterios propuestos para el ejercicio y no se presentan como obligaciones legales verificadas. Antes de aplicarlos en produccion deben ser revisados por Seguridad de la Informacion, los propietarios de los datos y el area juridica.

Tambien se considero la necesidad de restringir el acceso a las bitacoras, proteger su integridad mediante hashes y revisar los requisitos de conservacion de datos personales antes de eliminarlos.

**Evidencia:** `evidencias/05-conservacion.md`.

## 6. Politicas (A4)

Se elaboraron seis politicas para establecer reglas de gobierno y controles verificables:

| Codigo | Politica | Archivo |
|---|---|---|
| POL-01 | Acceso | `politicas/POL-01-acceso.md` |
| POL-02 | Respaldo | `politicas/POL-02-respaldo.md` |
| POL-03 | Retencion | `politicas/POL-03-retencion.md` |
| POL-04 | Restauracion | `politicas/POL-04-restauracion.md` |
| POL-05 | Datos sensibles | `politicas/POL-05-datos-sensibles.md` |
| POL-06 | Cambios en produccion | `politicas/POL-06-cambios-produccion.md` |

Las politicas incluyen objetivo, alcance, regla verificable, responsable, excepciones, evidencia y revision.

**Nota:** la existencia de una politica documentada no demuestra que el control ya se encuentre implementado. En particular, los procedimientos tecnicos de respaldo y restauracion quedan pendientes de definirse y probar en la unidad correspondiente.

## 7. Conciliacion de cambios (A5)

En la Actividad 7 se creo el esquema `gobierno` y la tabla `gobierno.solicitudes_cambio` para registrar solicitudes, responsables, ambiente, aprobacion y ventanas de mantenimiento.

Se registro la solicitud:

- Folio: `CAM-2026-014`.
- Descripcion: agregar la columna `canal_alta` a `clientes`.
- Solicitante: Gerencia Comercial.
- Aprobador registrado: Comite de cambios.
- Ambiente: produccion.

La conciliacion con `dba.bitacora` mostro lo siguiente:

| Registro | Evento | Resultado |
|---|---|---|
| 123 | CREATE SCHEMA gobierno | Registrado |
| 124 | REVOKE ALL ON SCHEMA gobierno FROM PUBLIC | Registrado |
| 125 | CREATE TABLE gobierno.solicitudes_cambio | Registrado |
| 139 | ALTER TABLE clientes ADD COLUMN canal_alta VARCHAR(20) | Cambio ejecutado |
| 142 | INSERT de CAM-2026-014 | Solicitud registrada despues del cambio |
| 143 | Segundo intento de agregar canal_alta | Error: la columna ya existia |

El registro 139 demuestra que el cambio se ejecuto antes de insertar la solicitud en el registro de cambios (registro 142). Por lo tanto, no se puede demostrar que existiera autorizacion previa.

El registro 143 corresponde a un segundo intento de ejecutar el mismo cambio y no a una segunda columna creada.

**Resultado:** se identifico una deficiencia en la secuencia de autorizacion y ejecucion de cambios. La solicitud debe registrarse y aprobarse antes de ejecutar modificaciones en produccion.

**Evidencias:**

- `evidencias/06-conciliacion.md`
- `sql/04-registro-cambios.sql`
- `evidencias/E5-bitacora-postgresql.log`

## 8. Hallazgos

| ID | Hallazgo | Fuente | Severidad | Impacto | Recomendacion | Decision requerida de |
|---|---|---|---|---|---|---|
| H-01 | Correo duplicado `ana.lopez@example.test` en los clientes con ID 1 y 7 | Actividad 1, `evidencias/01-calidad.md` | Media | Puede generar duplicidad de clientes y errores de comunicacion | Revisar los registros y determinar cual debe conservarse, sin eliminar datos automaticamente | Gerencia Comercial |
| H-02 | RFC invalido en el cliente 7 y RFC ausente en el cliente 8 | Actividad 1, `evidencias/01-calidad.md` | Alta | Los datos de identificacion pueden ser incorrectos o incompletos | Validar los RFC con la documentacion correspondiente y autorizar su correccion | Gerencia Comercial |
| H-03 | Correo invalido y edad negativa en el cliente 8 | Actividad 1, `evidencias/01-calidad.md` | Media | Reduce la confiabilidad de la informacion de clientes | Revisar el registro y establecer validaciones de formato y rango | Gerencia Comercial |
| H-04 | La solicitud CAM-2026-014 se registro despues de ejecutar el cambio de estructura | Actividad 7, registros 139 y 142 de `dba.bitacora` | Alta | No se puede demostrar una autorizacion previa del cambio | Exigir folio y aprobacion antes de ejecutar cambios en produccion | Comite de cambios |
| H-05 | Una modificacion administrativa posterior del RFC de Maria Garcia no genero un registro correspondiente en `auditoria.cambios_clientes` | LAB-01, Actividad 14 | Alta | No se puede reconstruir completamente la modificacion posterior | Investigar el cambio y fortalecer la auditoria frente a operaciones administrativas | Seguridad de la Informacion y DBA |
| H-06 | Los administradores pueden desactivar mecanismos de auditoria o modificar su configuracion | LAB-01, Actividad 14 | Alta | Puede existir perdida o alteracion de evidencia | Restringir privilegios administrativos, generar alertas y proteger las bitacoras fuera del servidor | Seguridad de la Informacion |
| H-07 | MongoDB Community no dispone de auditoria nativa Enterprise y `system.profile` tiene limitaciones | LAB-02, `evidencias/E6-mongodb/09-comparacion.md` | Media | No se garantiza la trazabilidad completa de todas las operaciones | Evaluar controles complementarios o una edicion con auditoria nativa | Administrador MongoDB y Seguridad de la Informacion |
| H-08 | Las lecturas no quedan cubiertas por `log_statement = mod` en PostgreSQL | E1 y comparacion de LAB-01 | Media | No existe evidencia completa de consultas de lectura mediante ese mecanismo | Evaluar `pgaudit` u otro mecanismo de auditoria de consultas | DBA y Seguridad de la Informacion |
| H-09 | `logging_collector` se encuentra habilitado, pero se requiere mantener controles de acceso e integridad sobre los archivos de registro | `evidencias/E1-configuracion-registro.txt` | Baja | Si los archivos no se protegen adecuadamente, la evidencia podria modificarse o eliminarse | Restringir el acceso y conservar copias protegidas de las bitacoras | DBA y Seguridad de la Informacion |
| H-10 | No se verifico la ubicacion fisica ni el estado actual del contenedor de MongoDB durante LAB-03 | `evidencias/E6-mongodb/09-comparacion.md` y revision de LAB-03 | Baja | No se puede confirmar el estado actual del servicio con las evidencias disponibles | Encender el entorno y documentar el contenedor y su ubicacion cuando se realice una nueva verificacion | Administrador MongoDB |

Los hallazgos se conservan como observaciones del laboratorio. No se consideran corregidos por el hecho de que se hayan documentado recomendaciones.

## 9. Limitaciones conocidas y riesgos aceptados (A6)

| Riesgo o limitacion | Estado | Consecuencia | Quien debe aceptar formalmente |
|---|---|---|---|
| MongoDB Community sin auditoria nativa Enterprise | Verificado en LAB-02 | No se cuenta con la misma cobertura de auditoria nativa que ofrece Enterprise | Responsable de TI y Seguridad de la Informacion |
| `system.profile` es limitado y puede sobrescribir registros | Limitacion del mecanismo utilizado | Puede perderse informacion historica de operaciones perfiladas | Administrador MongoDB y Seguridad de la Informacion |
| Lecturas no auditadas por `log_statement = mod` | Verificado por configuracion PostgreSQL | No se dispone de un registro completo de consultas SELECT mediante ese parametro | DBA y Seguridad de la Informacion |
| Administrador con capacidad de desactivar controles | Riesgo identificado en LAB-01 | Puede interrumpirse la captura de evidencia | Responsable de TI y Seguridad de la Informacion |
| Auditoria nativa de MongoDB Enterprise | Documentada, no practicada | No se verifico su configuracion ni funcionamiento en este laboratorio | Responsable de TI |
| Procedimientos tecnicos de respaldo y restauracion | Documentados en POL-02 y POL-04, pero no practicados en esta actividad | No se demuestra que los respaldos puedan restaurarse correctamente | DBA y responsable de TI |
| Valor de `logging_collector` | Proteccion de archivos de registro | Control pendiente de verificar | Aunque logging_collector esta habilitado, no se comprobo la proteccion externa de los archivos | DBA y Seguridad de la Informacion |
| Ubicacion fisica y estado actual del contenedor MongoDB | No verificado durante LAB-03 | No se confirma el estado actual del servicio con la evidencia disponible | Administrador MongoDB |

Los riesgos anteriores no se consideran aceptados automaticamente. La aceptacion debe quedar documentada por los responsables indicados, incluyendo fecha, justificacion y controles compensatorios.

## 10. Indice de evidencias

### Evidencias generales

| Archivo | Contenido |
|---|---|
| `evidencias/01-calidad.md` | Resultados de calidad de datos |
| `evidencias/02-responsables.md` | Matriz de propietarios, custodios y usuarios |
| `evidencias/03-diccionario.md` | Clasificacion y descripcion del diccionario |
| `evidencias/04-catalogo.md` | Catalogo de seis conjuntos de datos |
| `evidencias/05-conservacion.md` | Criterio de conservacion |
| `evidencias/06-conciliacion.md` | Conciliacion de cambios |
| `evidencias/diccionario-clientes.csv` | Diccionario exportado |
| `evidencias/E1-configuracion-registro.txt` | Configuracion de auditoria |
| `evidencias/E2-privilegios.txt` | Privilegios vigentes |
| `evidencias/E3-disparadores.txt` | Estado de disparadores |
| `evidencias/E4-muestra-auditoria.txt` | Muestra de auditoria |
| `evidencias/E5-bitacora-postgresql.log` | Bitacora PostgreSQL exportada |
| `evidencias/E5-bitacora-postgresql.sha256` | Hash de la bitacora PostgreSQL |

### Evidencias MongoDB

| Archivo | Contenido |
|---|---|
| `evidencias/E6-mongodb/system-profile.json` | Registros de system.profile |
| `evidencias/E6-mongodb/bitacora-mongod.log` | Bitacora del proceso mongod |
| `evidencias/E6-mongodb/docker-logs-completo.log` | Registros completos del contenedor |
| `evidencias/E6-mongodb/hashes.sha256` | Manifiesto de hashes |
| `evidencias/E6-mongodb/09-comparacion.md` | Comparacion de mecanismos de auditoria |

### Hashes SHA-256

| Archivo | SHA-256 |
|---|---|
| `E5-bitacora-postgresql.log` | `C2C0B18DF569548D1129BEB88FE49216F3185BFB2D52E6055F708BD0108FFD16` |
| `system-profile.json` | `EAA22DEFCF2DCB24D46C5238B5E9C231ADD3FC9515DB203C32F4CF541832089D` |
| `bitacora-mongod.log` | `D6DA9E207A385C54A6C140A2B989521E32E8EC78C9496E9C4D274FA008CABD4B` |
| `docker-logs-completo.log` | `EBD3FAA3C55C712796896D28D1864EE4554ADE694BF00994ABEA969029D07E62` |

Los tres hashes de MongoDB coinciden con los valores del manifiesto `evidencias/E6-mongodb/hashes.sha256`. El hash de PostgreSQL se conserva en `evidencias/E5-bitacora-postgresql.sha256`.

Los archivos que no tienen hash individual en esta tabla no se presentan como verificados mediante SHA-256.

## 11. Verificacion final

| Requisito | Estado | Observacion |
|---|---|---|
| Hallazgos de calidad registrados con responsable de decision | Cumplido | Actividad 1 y H-01 a H-03 |
| Matriz de responsables con propietario, custodio y usuarios | Cumplido | Actividad 2 |
| Comentarios en la tabla y en todas las columnas de clientes | Cumplido | Diez columnas verificadas |
| Diccionario exportado en CSV y completado con clasificacion y finalidad | Cumplido | CSV y documento de Actividad 3 |
| Catalogo con al menos cinco conjuntos de datos de los dos motores | Cumplido | Seis conjuntos documentados en CAT-01 a CAT-06 |
| Criterio de conservacion para los siete tipos de registro | Cumplido | Actividad 5 |
| Seis politicas con regla verificable y evidencia nombrada | Cumplido | POL-01 a POL-06 |
| Registro de cambios creado y conciliacion con la bitacora | Cumplido con hallazgo | Actividad 7; autorizacion registrada despues del cambio |
| Evidencias E1 a E6 generadas | Cumplido | E1 a E6 integradas |
| EXPEDIENTE.md con al menos tres eventos interpretados | Cumplido | Seccion 3 |

**Nota:** los estados de esta tabla indican que los productos documentales y evidencias solicitados fueron integrados. No significan que todos los riesgos hayan sido corregidos ni que las politicas propuestas esten aprobadas institucionalmente.

## Conclusion

El laboratorio permitio identificar controles de auditoria, revisar la calidad de los datos, documentar responsables, completar un catalogo de datos de PostgreSQL y MongoDB, proponer criterios de conservacion y establecer politicas de gobierno.

Tambien se encontraron limitaciones importantes, como la falta de registro de una modificacion administrativa del RFC de Maria Garcia, la ausencia de auditoria nativa en MongoDB Community y la ejecucion de un cambio de estructura antes de registrar su solicitud.

El expediente conserva estos hallazgos y propone acciones para que las areas responsables puedan evaluarlos y decidir su tratamiento. Los riesgos no se consideran aceptados ni corregidos hasta contar con una decision y evidencia correspondiente.