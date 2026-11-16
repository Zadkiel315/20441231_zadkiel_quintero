# Informe — LAB-02: Trazabilidad en MongoDB Community

## 1. Despliegue, edición y limitación

Usé MongoDB 7.0.48 en un contenedor `mongo:7` dentro de GitHub Codespaces, con autorización habilitada. Lo verifiqué con tres datos: `buildInfo.modules` salió vacío (en Enterprise aparecería `"enterprise"`), `serverCmdLineOpts().parsed` solo mostró `net` y `security`, sin opciones de auditoría, y el log de arranque trae `"modules":[]`.

**Lo que no existe en Community es la auditoría nativa** (REF-U3-04), que solo está en Enterprise y Atlas M10 o superior. Lo que sí tiene Community es el perfilador y la bitácora de `mongod`, y este laboratorio trabaja con esos dos. Ninguno de los dos es una auditoría de seguridad.

## 2. Perfilador

- Con el perfilador apagado (nivel 0), el cambio del RFC no dejó ningún rastro: `system.profile` tenía 0 documentos (Act. 2).
- Con el nivel 2 quedaron `query`, `update` y `remove`, cada una con usuario (`app_ventas@comercial`), cliente (`127.0.0.1`), aplicación (`app-ventas-web`) y hora. Las tres ocurrieron en 8 ms (Act. 3).
- El perfilador **no guarda el valor anterior** (el `update` solo trae el `$set` nuevo) ni **los datos del documento borrado** (el `remove` solo trae el filtro).
- **Costo:** el nivel 2 registra también las lecturas, y el `command` guarda los filtros completos. Si una consulta busca por RFC o correo, esos datos personales quedan en `system.profile`. Además, la documentación advierte de pérdida de rendimiento y de uso de disco, y la colección es capped de 1 MB.
- El filtro (`insert`, `update`, `remove`) redujo el volumen. A cambio se pierde la visibilidad de las lecturas (Act. 4).

## 3. Bitácora de mongod

- **Dónde se escribe:** en la salida estándar del proceso, no en un archivo. Se lee con `docker logs`, y con `getLog` desde mongosh (Act. 1).
- **Accesos:** la bitácora registró dos intentos fallidos (contraseña incorrecta, `result` 18, y usuario inexistente, `result` 11) y un acceso exitoso con `app-ventas-web`. El cliente recibe el mismo mensaje en ambos fallos, y el detalle real queda solo en la bitácora (Act. 5). Hubo 3 líneas de fallo para 2 intentos, porque el usuario inexistente produjo dos líneas.
- **Cambios de configuración:** `Profiler settings changed` no trae usuario. Lo obtuve correlacionando el `ctx` con el evento `Successfully authenticated` de la misma conexión: los tres cambios (conn23, conn43, conn51) fueron de `admin` (Act. 6). La correlación solo vale dentro del mismo arranque del servidor.
- **Estructura:** `createCollection` de una colección de prueba quedó registrado, pero la línea no trae usuario.

## 4. Privilegios

- **Evidencia disponible:** ninguna en el perfilador ni en la bitácora. Las búsquedas de `grantRolesToUser` dieron 0 y 0 (Act. 7).
- **Control compensatorio:** instantáneas de privilegios en `auditoria.instantaneas_privilegios`. Las dos instantáneas (05:51:08 y 05:51:50 UTC) mostraron que `app_ventas` pasó de `readWrite` a `readWrite` + `dbAdmin`.
- **Su límite:** detecta que cambió y qué rol, pero **no quién ni cuándo exactamente** (solo que fue dentro de una ventana de 42 segundos). `tomada_por` es quien tomó la instantánea, no quien hizo el cambio.
- **Limitaciones de mi implementación:** solo recorrí la base `comercial`, así que un cambio de roles de `admin` (que vive en la base `admin`) no se detectaría. Además la escribió `admin` (`root`), que podría alterarla.
- **Un hallazgo sin explicar:** al pasar a nivel 2, el `filter` de la Act. 4 siguió visible en el estado. En nivel 2 el perfilador sí registró un comando de `admin` sobre `system.profile`, pero no el `grantRolesToUser`. No pude determinar por qué.

## 5. Conservación

Riesgos que observé:

- El reinicio del contenedor devolvió el perfilador a nivel 0 sin avisar, y `getLog` pasó de 638 a 111 eventos. `system.profile` conservó sus 2 documentos.
- El Codespace se apagó por inactividad en medio del laboratorio, con el mismo efecto.
- `system.profile` es capped de 1 MB: la evidencia se sobrescribe sola.
- Borrar `system.profile` (Act. 4) destruyó los documentos de las Act. 2 y 3. Esa evidencia quedó solo copiada a mano en los `.md`.

Exporté `system.profile`, la bitácora de `getLog` (680 eventos) y `docker logs`, y calculé el SHA-256 de los tres archivos. Revisé que ninguno contuviera las contraseñas de práctica. La configuración permanente (`systemLog` a archivo, `operationProfiling`) no la apliqué, porque en mi contenedor implicaría recrearlo y perder los datos.

Como en la Actividad 4 borré `system.profile` antes de exportar, el primer export no tenía operaciones `query` ni `remove`. Repetí operaciones de `app_ventas` con el nivel 2 sobre un cliente temporal, restablecí el filtro y volví a exportar `system.profile`; recalculé su hash, y los de la bitácora no cambiaron.

## 6. Comparación

Resumen de la Actividad 9:

| Evento | PostgreSQL | MongoDB Community | Enterprise/Atlas |
|---|---|---|---|
| Accesos (éxito y fallo) | Sí | Sí | Documentado, no practicado |
| Cambio de privilegios | Sí (`log_statement = 'ddl'`) | No (solo instantáneas) | Documentado, no practicado |
| Cambio de estructura | Sí | Parcial (sin usuario) | Documentado, no practicado |
| Modificación de datos | Sí con `mod` y disparador | Parcial (solo con perfilador activo) | Documentado, no practicado |
| Valor anterior | Sí, solo con disparador | No | Documentado, no practicado |
| Lectura de datos sensibles | No con mi configuración | Parcial (solo nivel 2) | Documentado, no practicado |
| Cambio de configuración del registro | Parcial, no comprobado | Parcial (autor por `ctx`) | Documentado, no practicado |

La diferencia más importante: PostgreSQL registró los `GRANT` y `REVOKE`, y MongoDB Community no registró el cambio de privilegios.

## 7. Recomendación

Para una organización que necesite auditar cambios de privilegios en MongoDB, recomendaría **evaluar MongoDB Enterprise o Atlas (M10 o superior)** y no depender de Community.

**Hechos verificados en este laboratorio:**
- En Community, el cambio de privilegios no dejó rastro ni en el perfilador ni en la bitácora.
- Las instantáneas permiten detectar el cambio, pero no atribuirlo ni fecharlo con exactitud.
- El perfilador se apaga al reiniciar y `getLog` se vacía.

**Supuestos que no verifiqué:**
- Que la auditoría nativa registre los cambios de privilegios con autor y hora. Es lo que dice la documentación (categoría de autenticación y autorización, REF-U3-04), pero no la practiqué.
- Su costo de licencia o de clúster, su impacto en rendimiento y el esfuerzo de migrar.
- Que, si el requisito es solo detectar y no atribuir, las instantáneas frecuentes con una cuenta dedicada de solo inserción basten.

Antes de licenciar, habría que confirmar si el requisito es atribuir o solo detectar. Si basta con detectar, un control compensatorio mejor diseñado puede ser suficiente a menor costo, y debe documentarse como control compensatorio, no como auditoría.

## 8. Preguntas de reflexión

**1. ¿Por qué el perfilador no debe presentarse como un mecanismo de auditoría de seguridad?**

Porque fue diseñado para analizar desempeño, no para dejar evidencia de seguridad, y lo comprobé en el laboratorio:

- Está apagado por defecto y vuelve a nivel 0 al reiniciar, sin avisar.
- `system.profile` es una colección de 1 MB que se sobrescribe sola.
- Cualquier cuenta con permisos de administración puede apagarlo, cambiarlo o borrar la colección, y el rastro de ese cambio no trae usuario.
- No guarda el valor anterior ni los datos de lo borrado, y no registró el cambio de privilegios.
- El `appName` lo escribe el propio cliente, así que no es una prueba confiable.

La auditoría de seguridad necesita registros que no se pierdan por reinicios o por tamaño, que no los pueda alterar quien se audita y que atribuyan cada evento. El perfilador no cumple eso.

**2. ¿Por qué el perfilador sí aporta trazabilidad aunque no sea auditoría?**

Porque con el nivel 2 pude contestar qué se hizo, en qué colección, con qué cuenta, desde qué cliente y aplicación y a qué hora (Act. 3), algo imposible con el perfilador apagado (Act. 2). Con el filtro se conservan solo las modificaciones, y la bitácora de `mongod` completa los accesos y los cambios de configuración. Es trazabilidad parcial: sirve para reconstruir parte de un incidente si estaba activado antes, pero no es una auditoría.

**3. ¿Qué riesgo introduce el nivel 2 al registrar filtros de consultas que pueden contener datos personales?**

El campo `command` guarda la consulta completa. Si la aplicación busca por RFC, correo o teléfono, esos valores quedan en texto claro en `system.profile`, y quien pueda leer esa colección los ve sin pasar por los controles de acceso de la tabla de clientes. Además esos datos se copian a las exportaciones: mi propio `system-profile.json` contiene el teléfono `6670000000` del `update`. Con el nivel 2 también se registran lecturas de todos los usuarios, así que el volumen de datos personales guardado es mucho mayor. Por eso hay que restringir quién lee `system.profile` y las exportaciones, y usar un filtro.

**4. ¿Qué diferencia hay entre detectar un cambio y atribuirlo a alguien?**

Detectar es saber que algo cambió y qué cambió. Atribuir es saber quién lo hizo y cuándo. Las instantáneas de privilegios detectaron que `app_ventas` recibió `dbAdmin` (Act. 7), pero no dicen quién lo otorgó ni la hora exacta, solo una ventana de 42 segundos. Para atribuir se necesita un registro del evento con usuario y hora. Incluso con ese registro, lo que se atribuye es una cuenta, no una persona, si la cuenta se comparte, como `app_ventas`.

**5. ¿Por qué reconocer una limitación técnica es parte del trabajo profesional del DBA?**

Porque Dirección toma decisiones con lo que el DBA reporta. Si el DBA presenta el perfilador o las instantáneas como si fueran una auditoría, la organización cree tener un control que no tiene, y descubre el hueco después de un incidente, cuando ya no se puede reconstruir lo que no se registró. Decir "no hay evidencia con esta edición" y explicar el motivo técnico es lo que permite evaluar un cambio (Enterprise, Atlas o un control compensatorio) con información real. También sirve distinguir lo que se verificó de lo que solo se supone.