# Informe — LAB-01: Bitácoras y auditoría del dato en PostgreSQL

## 1. Despliegue y situación inicial

### 1.1 Despliegue

El laboratorio se ejecutó sobre una instalación nativa de PostgreSQL **18.6** en Windows (x86_64-windows), no sobre PostgreSQL 16 como indica la guía. Las rutas, obtenidas desde el motor con `SHOW`, son (Evidencia 01):

| Elemento | Valor |
|---|---|
| Directorio de datos | `C:/Program Files/PostgreSQL/18/data` |
| Archivo de configuración | `C:/Program Files/PostgreSQL/18/data/postgresql.conf` |
| Archivo de autenticación | `C:/Program Files/PostgreSQL/18/data/pg_hba.conf` |

Las sesiones por red se hicieron con `psql` desde PowerShell hacia `127.0.0.1`, como indica la guía. La sesión de administrador usó `psql -U postgres -d comercial` y llegó al servidor por TCP a `::1`, no por socket. Por eso `client=::1` aparece en la bitácora y `ip_cliente` no quedó vacía en las altas y bajas del administrador. En Linux habría quedado `NULL`.

### 1.2 Qué registraba el servidor al empezar

El estado inicial no coincidió con el que describe la guía (Evidencia 01):

| Parámetro | Guía (por defecto) | Este servidor | Origen |
|---|---|---|---|
| `logging_collector` | off | **on** | configuration file |
| `log_connections` | off | **on** | configuration file |
| `log_disconnections` | off | **on** | configuration file |
| `log_line_prefix` | `%m [%p]` | **`%t`** | configuration file |
| `log_statement` | none | none | default |
| `log_timezone` | Etc/UTC | **America/Chihuahua** | configuration file |

La autenticación tampoco requirió ajuste. Las reglas `local`, `127.0.0.1` y `::1` de `pg_hba.conf` ya usaban `scram-sha-256`, así que no fue necesario editar el archivo y los accesos fallidos podían observarse desde el principio.

### 1.3 Por qué no podía responder a Dirección

Aunque el servidor registraba conexiones, no podía responder las cinco preguntas, por dos razones:

- **El prefijo `%t` solo muestra la hora.** Sin `%u`, `%d`, `%a` ni `%h`, una línea puede decir qué ocurrió pero no quién ni desde dónde.
- **`log_statement = none` no registra ninguna sentencia.** El `UPDATE` del RFC (Actividad 3) solo dejó una sesión de `app_ventas` de 0.092 s. La sentencia, la fila afectada y el valor anterior no quedaron en ninguna parte.

Los privilegios de la Unidad II no impidieron el cambio y no debían impedirlo: `app_ventas` tiene `UPDATE` sobre `clientes`. El control de acceso responde quién puede hacer algo. No deja evidencia de quién lo hizo.

---

## 2. Configuración aplicada

| Parámetro | Valor final | Cómo se cambió | Recarga o reinicio | Justificación |
|---|---|---|---|---|
| `logging_collector` | on | Ya estaba activo; `ALTER SYSTEM` no cambió nada (`pending_restart = f`) | Reinicio (contexto `postmaster`); no se necesitó | El servidor escribe su propia bitácora y la lee con SQL sin depender del despliegue |
| `log_connections` | on | `ALTER SYSTEM` | Recarga | Registrar cada acceso, exitoso o fallido |
| `log_disconnections` | on | `ALTER SYSTEM` | Recarga | Duración de la sesión y cierre |
| `log_line_prefix` | `%m [%p] user=%u db=%d app=%a client=%h ` | `ALTER SYSTEM` | Recarga | Responde quién, cuándo, desde dónde y con qué aplicación; el PID agrupa las líneas de una sesión |
| `log_statement` | `ddl` y después `mod` | `ALTER SYSTEM` | Recarga | `ddl` cubre privilegios y estructura; `mod` agrega INSERT, UPDATE y DELETE sin registrar todas las lecturas |
| `log_min_error_statement` | error (por defecto) | — | — | Registra la sentencia que causó cada error, sin importar `log_statement` |

Los valores provienen de `postgresql.auto.conf` (columna `sourcefile` de `pg_settings`, Evidencia 04). Esto confirma que el cambio se hizo con `ALTER SYSTEM` y no a mano. `pg_reload_conf()` devolvió `t` pero es asíncrono, así que la verificación se hizo en una consulta posterior.

**Particularidades de este servidor:**

- **Mensajes en español.** La etiqueta de las sentencias es `sentencia:` y no `statement:`, y los errores aparecen como `SENTENCIA:` y `DETALLE:`. Las consultas de la guía devolvieron 0 filas hasta que los filtros aceptaron ambos idiomas (Evidencias 13 y 14).
- **Codificación.** La bitácora está en Windows-1252 y la base en UTF8. La vista `dba.bitacora` lee el archivo con `pg_read_binary_file` y `convert_from(..., 'LATIN1')` (Evidencia 02).
- **`statement_timeout`.** Está fijado en 60 s en `postgresql.conf`. Canceló el `pg_sleep(90)` de la Actividad 9 a los 60 s (L149 y L161).

---

## 3. Eventos observados

Un ejemplo interpretado de cada tipo. Las líneas son de `evidencias/bitacora-lab01.log`.

| Tipo | Evento | Fuente | Interpretación |
|---|---|---|---|
| **Acceso (fallido)** | 18:56:59.330, `user=app_ventas client=127.0.0.1`, `FATAL: la autentificación password falló` | L11 | Alguien presentó el nombre `app_ventas` con una contraseña inválida. El nombre lo declara el cliente y no está verificado, así que no prueba que fuera la aplicación. La línea `DETALLE` indica la regla aplicada (`pg_hba.conf` línea 115). |
| **Acceso (rol inexistente)** | 18:57:57.363, `user=usuario_inexistente` | L17 | El cliente recibe el mismo mensaje genérico. Solo la bitácora conserva el motivo real (el rol no existe), lo que evita que un atacante enumere usuarios. |
| **Acceso (exitoso)** | 18:58:14.868, `app_ventas` autenticado con `scram-sha-256` y autorizado con `app-ventas-web` | L25, L27 | Secuencia completa: recibida, autenticada, autorizada y desconectada, todo bajo el PID 15908. |
| **Privilegio** | 19:07:27, `REVOKE UPDATE ... FROM soporte_ana` y `GRANT UPDATE ... TO app_ventas`, por `postgres` | L41, L43 | `GRANT` y `REVOKE` se clasifican como `ddl`. La bitácora registra la sentencia, no su efecto: ambas aparecen aunque no cambiaron ningún permiso. |
| **Estructura** | 19:07:28.888, `ALTER TABLE clientes ADD COLUMN segmento` | L45 | Atribuido a `postgres`, aplicación `psql`, cliente `::1`, PID 17360. |
| **Datos** | 19:20:56.389, `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` por `app_ventas` desde `app-ventas-web` | L75 | Con `mod` aparecen quién, cuándo, desde dónde y qué sentencia. No aparece el teléfono anterior. |
| **Error (autorización)** | 19:38:13.884, `soporte_ana`: `permiso denegado a la tabla clientes` y su `SENTENCIA: DELETE FROM clientes WHERE id = 5` | L129 | El intento no causó daño (la tabla conserva 5 filas). Es un `ERROR` con sesión ya establecida, distinto del `FATAL` de autenticación. |
| **Configuración** | 19:19:51.024, `ALTER SYSTEM SET log_statement = 'mod'` por `postgres` | L63 | Se registra porque `log_statement` ya valía `ddl`. Los `ALTER SYSTEM` de la Actividad 4 no quedaron, porque entonces valía `none`. |

**Dos hallazgos que difieren de la guía:**

- **Avisos `parameter ... changed to ...`.** No se observaron en ninguno de los archivos consultados (Evidencias 04 y 07). La recarga coincidió con un cambio de archivo de bitácora, y el cambio de configuración quedó documentado por el `ALTER SYSTEM` registrado (L63) y por la consulta a `pg_settings`.
- **`pg_stat_activity` frente a la bitácora (Evidencia 09).** La vista mostró en vivo la sesión de `soporte_ana` (PID 6528, `reporte-mensual`). Al terminar, desapareció de la vista, y el PID permitió recuperar todo su ciclo de vida en la bitácora (conexión, sentencia cancelada, duración de 0:01:00.174).

---

## 4. Auditoría del dato

### 4.1 Diseño de la tabla

`auditoria.cambios_clientes` (Evidencia 10) está en un esquema sin acceso para `PUBLIC` (`nspacl = {postgres=UC/postgres}`). Cada campo responde a una pregunta de Dirección:

| Campo | Pregunta | Nulo | Motivo |
|---|---|---|---|
| `id_evento` | ¿En qué orden? | No | Clave primaria; permite detectar huecos en la secuencia |
| `momento` (TIMESTAMPTZ) | ¿Cuándo? | No | Instante absoluto, comparable con la bitácora sin ambigüedad de zona |
| `usuario_sesion` | ¿Quién? | No | Rol con que se autenticó la sesión |
| `usuario_efectivo` | ¿Con qué privilegios? | No | Dentro de la función es el propietario |
| `aplicacion` | ¿Desde qué aplicación? | Sí | La declara el cliente |
| `ip_cliente` (INET) | ¿Desde dónde? | Sí | `NULL` si la conexión no usa red |
| `operacion` | ¿Qué se hizo? | No | INSERT, UPDATE o DELETE |
| `id_cliente` | ¿Sobre qué registro? | Sí | Sin clave foránea, para que el registro sobreviva al borrado del cliente |
| `valores_antes` / `valores_despues` (JSONB) | ¿Qué valor había y cuál quedó? | Sí | Nulos en INSERT y DELETE respectivamente; el registro completo resiste cambios de estructura |

La tabla contiene RFC y correos. Debe clasificarse al menos como `clientes`, y más delicada, porque conserva datos de clientes ya eliminados y valores anteriores.

### 4.2 Función, disparador y los roles de sesión

`auditoria.registrar_cambio_cliente()` y el disparador `trg_auditoria_clientes` (`AFTER INSERT OR UPDATE OR DELETE ... FOR EACH ROW`) se verificaron en `pg_trigger` con `tgenabled = O` (Evidencia 11).

- **`SECURITY DEFINER`.** La función corre con los privilegios de su propietario. Así `app_ventas` provoca la escritura en la auditoría sin tener acceso al esquema.
  - *Hipótesis previa:* sin `SECURITY DEFINER` el `INSERT` del disparador fallaría con `permiso denegado` y cancelaría toda la operación de `app_ventas`.
  - *Resultado:* el `UPDATE` funcionó y el `SELECT` directo sobre la auditoría fue rechazado (`permiso denegado al esquema auditoria`). Eso respalda la hipótesis de forma indirecta. La prueba directa (quitar `SECURITY DEFINER` y repetir el `UPDATE`) no se hizo.
- **`SET search_path = pg_catalog, public`.** Impide que un usuario cree objetos con nombres iguales en otro esquema y los haga usar a una función que corre con privilegios de propietario.
- **`session_user` y `current_user`.** Dentro de la función, `current_user` es el propietario. Por eso el evento 1 muestra `usuario_efectivo = postgres` y `usuario_sesion = app_ventas`. Si solo se guardara `current_user`, todos los cambios parecerían hechos por `postgres`.
- **`REVOKE ALL ON FUNCTION ... FROM PUBLIC`.** Evita que cualquier rol ejecute a mano una función `SECURITY DEFINER` que escribe en la auditoría. El disparador sigue funcionando porque la función corre con los permisos de su propietario.

### 4.3 Resultado del incidente auditado (Evidencia 11, sección «El incidente auditado»)

Cambio del RFC del cliente 3 por la aplicación (`UPDATE` a las 21:38:57), tal como lo muestra la auditoría:

| id_evento | momento | usuario_sesion | usuario_efectivo | aplicacion | ip_cliente | campo | antes | después |
|---|---|---|---|---|---|---|---|---|
| 1 | 2026-11-08 21:38:57.39961-06 | app_ventas | postgres | app-ventas-web | 127.0.0.1 | rfc | `GAMA780912XYZ` | `GAMA780912ZZZ` |

Con esto sí se responde quién (la cuenta), cuándo, desde dónde y qué valor tenía antes. El mismo evento aparece en la bitácora (L263), así que las dos fuentes se corroboran. La sentencia que restauraría el valor anterior es `UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3;`, y generaría a su vez un nuevo evento de auditoría.

De `ip_cliente` y `aplicacion`, la primera conserva más valor porque la determina el servidor. La segunda la declara el propio cliente (`?application_name=...`), así que distingue aplicaciones legítimas pero no es evidencia fuerte de identidad.

**Altas y bajas (Evidencia 12).** El alta y la baja de `Pedro Ruiz` (id 6) dejaron los eventos 2 y 3 con el registro completo. Aunque el cliente ya no existe en `clientes`, su historial sigue en la auditoría. Esto genera un conflicto con la política de retención de la Unidad II, que debe resolver el responsable de los datos con las áreas legal y de cumplimiento. El DBA solo lo implementa.

---

## 5. Limitaciones

### 5.1 Administrador con control total (Evidencia 13)

La cuenta de la aplicación quedó bien limitada. `app_ventas` no pudo borrar la auditoría (`permiso denegado al esquema auditoria`) ni desactivar el disparador (`debe ser dueño de la tabla clientes`). Con `postgres` el resultado fue distinto:

| Paso | Hora | Fuente |
|---|---|---|
| `DISABLE TRIGGER` | 21:54:23.187 | L313 |
| `UPDATE clientes SET rfc = 'GAMA780912GHI' WHERE id = 3` | 21:54:23.203 | L315 |
| `ENABLE TRIGGER` | 21:54:23.223 | L317 |

La auditoría siguió en 3 eventos, sin ese cambio. El cambio sin auditar se detecta por tres vías combinadas:

- La bitácora conserva las tres sentencias.
- El conteo de la auditoría no creció tras un `UPDATE 1`.
- El RFC actual del cliente 3 (`...GHI`) no coincide con el último `valores_despues` auditado (`...ZZZ`).

Ningún mecanismo dentro del servidor protege contra un administrador con control total, porque quien controla el servidor puede además alterar la bitácora. Lo que reduce el riesgo son controles organizacionales:

- Separar a quien opera la base de quien custodia la evidencia.
- Enviar las bitácoras a un sistema externo administrado por otra área.
- Hacer revisiones independientes y exigir cuentas nombradas.

### 5.2 Lecturas (Evidencia 14)

`soporte_ana` leyó nombre, RFC y teléfono de María García. Esa lectura no dejó rastro: los disparadores de fila no se activan con `SELECT` y `mod` no registra consultas. No hay evidencia de quién consultó ese RFC.

Registrar lecturas exigiría `log_statement = 'all'`, funciones que registren el uso del dato o `pgaudit` con auditoría de objeto (Parte C, no realizada). Cada alternativa tiene un costo en volumen, cambios en la aplicación o instalación de una extensión.

### 5.3 Volumen (Evidencia 14)

Un `UPDATE clientes SET segmento = 'regular'` sin `WHERE` modificó 5 filas. La bitácora registró **1 línea** (sin el número de filas) y la auditoría **5 eventos**, uno por fila.

Con un millón de registros el disparador generaría un millón de eventos con dos documentos JSONB cada uno, en la misma transacción. El resultado sería crecimiento súbito de disco, sentencia lenta y reversión total si algo fallara. La depuración de `auditoria.cambios_clientes` no debe decidirla el DBA solo. La autorizarían el responsable de los datos, auditoría o seguridad de la información, y legal o cumplimiento.

### 5.4 Otros límites

- **La cuenta no es la persona.** `app_ventas` es una cuenta compartida; en ningún caso la evidencia identifica a la persona detrás de ella.
- **Equipo de origen.** `127.0.0.1` y `::1` son direcciones de bucle local. No consta el nombre del equipo.
- **La bitácora registra la sentencia, no su efecto.** `GRANT` y `REVOKE` aparecen aunque no cambiaran nada.
- **Alcance de la vista.** `dba.bitacora` solo lee el archivo vigente. Los eventos anteriores al cambio de archivo (como la Actividad 3) quedaron fuera.

---

## 6. Riesgos de la bitácora

### 6.1 Secretos expuestos

La bitácora resultó ser un activo sensible. En este laboratorio quedaron secretos en ella (Evidencias 03, 06 y 15):

| Secreto | Dónde quedó | Tratamiento |
|---|---|---|
| Contraseña de `rol_temporal` | `CREATE ROLE ... PASSWORD '...'` en texto claro (L47) | Sustituida por `<REDACTED>` en la exportación; el `DROP ROLE` no la borró del archivo |
| Contraseña de `app_ventas` | Archivo de bitácora anterior, por una sentencia con error registrada por `log_min_error_statement` (Actividad 3) | Debe considerarse expuesta y cambiarse; el archivo anterior no se exportó |
| Verificador SCRAM de `soporte_ana` | `ALTER USER "soporte_ana" PASSWORD ...` (L119), generado con `\password` | Sustituido por `<REDACTED>`. `\password` evita el texto claro, pero el resumen sigue siendo sensible |
| Contraseña de `postgres` en texto claro | `ALTER ROLE postgres WITH PASSWORD ...` desde pgAdmin 4 (L419) | Sustituida por `<REDACTED>` en la exportación. La contraseña se cambió después de detectar la exposición |

La primera exportación solo cubría la contraseña de `rol_temporal`. Al revisarla se detectaron los otros dos secretos, se sustituyeron, se recalculó el hash y se descartó la primera versión. Ambas versiones difieren solo en las líneas 119 y 419, así que la numeración de la cronología sigue siendo válida.

**Lección:** una bitácora debe revisarse antes de entregarla, y una contraseña que apareció en ella se considera comprometida aunque el rol ya no exista.

### 6.2 Pérdida

Si la bitácora vive solo en el servidor que la produce, se pierde con una reinstalación, una falla de disco o una rotación. Además, quien controle el servidor puede alterarla (Actividad 14). En este laboratorio, la bitácora vigente empieza a las 18:49:16 y no contiene la Actividad 3.

La exportación tuvo además dos fallos con el comando de la guía, por la codificación (L347 y L369, `secuencia de bytes no válida para codificación «UTF8»`). El archivo entregado es una exportación con conversión de codificación, en UTF-16 LE, con los acentos alterados (por ejemplo `conexi¾n`), y no el resultado literal de ese comando.

### 6.3 Integridad y acceso de terceros

- **Integridad.** El SHA-256 del archivo entregado es `8A7D8EFB558CE1F668690ED48E60DCF36BD463CA5698E0BA7FE9AB0FCB138578` (439 líneas, 71 504 bytes). Se recalculó y coincide con `bitacora-lab01.sha256`.
  - El hash no impide modificar el archivo. Permite detectar un cambio y demostrar que el archivo es el mismo que cuando se calculó.
  - Como el hash y el archivo están en la misma carpeta con los mismos permisos, quien altere uno puede alterar el otro. Debería entregarse al área de auditoría o guardarse en un sistema de solo escritura.
- **Acceso de terceros.** La vista `dba.bitacora` se ejecuta con los privilegios de su propietario, y cualquier rol con `SELECT` sobre ella leería el archivo. Solo debe poder consultarla el administrador o un rol de auditoría explícito. Como medida adicional, la vista puede crearse con `security_invoker = on` (Evidencia 02); en este laboratorio no se aplicó.
- **Retención propuesta.** 12 meses consultable y archivo protegido adicional definido con el área legal, ampliable ante una investigación. La bitácora contiene datos personales y secretos, por lo que no debe conservarse sin límite. El criterio formal se completa en el LAB-03.

---

## 7. Cronología y conclusión

### 7.1 Cronología resumida

El detalle completo (27 eventos) está en `evidencias/15-cronologia.md`. Resumen de los eventos principales:

| # | Hora (CST) | Usuario | Tipo | Qué ocurrió | ¿Exitoso? | Fuente |
|---|---|---|---|---|---|---|
| 1 | 18:35:34 (sesión; sentencia sin hora) | app_ventas | Datos | Sesión de 0.092 s que coincide con el `UPDATE` del RFC `GHI` → `XXX` | Sí | Ev. 03 (fuera del archivo exportado) |
| 2 | 18:49:16.517 | postgres | Acceso | Sesión del administrador (PID 17360) | Sí | L3 |
| 3 | 18:56:59.330 | app_ventas | Acceso | Contraseña incorrecta | No | L11 |
| 4 | 18:57:57.363 | usuario_inexistente | Acceso | Rol inexistente | No | L17 |
| 5 | 19:07:27.141 | postgres | Privilegio | `REVOKE` y `GRANT` sobre `clientes` | Sí | L41, L43 |
| 6 | 19:07:28.888 | postgres | Estructura | `ALTER TABLE ... ADD COLUMN segmento` | Sí | L45 |
| 7 | 19:19:27.811 (sesión; sentencia sin hora) | app_ventas | Datos | Sesión de 0.093 s que coincide con el `UPDATE` del RFC `XXX` → `XYZ` | Sí | L55–L61; Ev. 07 |
| 8 | 19:19:51.024 | postgres | Configuración | `log_statement = 'mod'` | Sí | L63 |
| 9 | 19:20:56.389 | app_ventas | Datos | `UPDATE` del teléfono del cliente 3 | Sí | L75 |
| 10 | 19:38:13.884 | soporte_ana | Error | `DELETE` denegado | No | L129 |
| 11 | 19:55:31–19:55:33 | postgres | Estructura | Esquema y tabla `auditoria` | Sí | L167–L171 |
| 12 | 20:18:22–20:18:25 | postgres | Estructura | Función y disparador | Sí | L199, L245, L247 |
| 13 | 21:38:57.401 | app_ventas | Datos | `UPDATE` del RFC `XYZ` → `ZZZ` | Sí | L263; Aud #1 |
| 14 | 21:54:04.120–.147 | app_ventas | Manipulación | Intento de borrar la auditoría y desactivar el disparador | No | L299–L307 |
| 15 | 21:54:23.187–.223 | postgres | Datos / manipulación | Disparador desactivado, RFC → `GHI`, disparador reactivado | Sí | L313–L317; Aud: sin evento |
| 16 | 21:59:53.467 | postgres | Datos | `UPDATE` masivo de `segmento` (5 filas) | Sí | L331; Aud: 5 eventos |
| 17 | 22:17:45.335 | postgres | Privilegio | `ALTER ROLE postgres WITH PASSWORD` desde pgAdmin 4 | Sí | L419 |

### 7.2 Respuestas a Dirección (solo con la evidencia)

**¿Quién cambió el RFC?**

| Cambio | Cuenta | Persona | Base de la respuesta |
|---|---|---|---|
| Actividad 3 (`GHI` → `XXX`) | `app_ventas` (indicio) | **No hay evidencia** | Solo se conserva la sesión de las 18:35:34; la hora de la sentencia es un hueco |
| Actividad 7 (`XXX` → `XYZ`) | `app_ventas` (indicio) | **No hay evidencia** | Solo se conserva la sesión de las 19:19:27.811; la hora de la sentencia es un hueco |
| Actividad 12 (`XYZ` → `ZZZ`) | `app_ventas`, `app-ventas-web`, `127.0.0.1`, 21:38:57.401 | **No hay evidencia** de la persona | Bitácora L263 y auditoría #1 |
| Actividad 14 (`ZZZ` → `GHI`) | `postgres`, `psql`, `::1`, 21:54:23.203 | **No hay evidencia** de la persona | Solo la bitácora (L313–L317); la auditoría no lo registró |

**¿Quién cambió el teléfono?** La cuenta `app_ventas` desde `app-ventas-web` y `127.0.0.1`, a las 19:20:56.389 (L75). No hay evidencia de la persona ni del valor anterior del teléfono.

**¿Hubo accesos fallidos?** Sí, cinco, todos de direcciones de bucle local:

- `app_ventas` con contraseña incorrecta (L11).
- `usuario_inexistente` (L17).
- `soporte_ana` dos veces, porque su rol no tenía contraseña (L85 y L113).
- `postgres` con contraseña incorrecta (L357).

Siete conexiones entre las 22:10 y las 22:18 no tienen resultado registrado. No hay evidencia de si fueron fallidas o abandonadas, por lo que no se cuentan. La bitácora exportada tampoco cubre lo anterior a las 18:49:16.

**¿Qué valor tenía el RFC antes de cada cambio?**

| Cambio | Valor anterior | Origen |
|---|---|---|
| Actividad 3 | `GAMA780912GHI` | Consulta de la Evidencia 03; no está en la bitácora ni en la auditoría |
| Actividad 7 | `GAMA780912XXX` | Evidencia 07; no está en la bitácora ni en la auditoría |
| Actividad 12 | `GAMA780912XYZ` | Auditoría #1, `valores_antes` |
| Actividad 14 | `GAMA780912ZZZ` | **Deducción**, no dato registrado: es el valor posterior del evento 1 y la bitácora no muestra otro `UPDATE` de RFC entre las 21:38 y las 21:54 |

### 7.3 Conclusión

**¿Con esta configuración puede demostrarse quién cambió un dato sensible y qué valor tenía antes?**

**Parcialmente.** Con `log_line_prefix` completo, `log_statement = 'mod'` y el disparador de auditoría vigentes, un cambio hecho por la aplicación queda registrado con cuenta, hora, origen, sentencia y valores anterior y posterior, corroborado por dos fuentes independientes entre sí (caso del 21:38:57). Esa configuración no basta en cuatro situaciones:

1. **Cambios anteriores a la configuración.** Los cambios de las Actividades 3 y 7 no se pueden reconstruir. La auditoría no puede configurarse después del incidente.
2. **La persona.** Se identifica la cuenta, no a la persona, mientras `app_ventas` sea compartida.
3. **El administrador.** Un administrador con control total puede desactivar el disparador y cambiar un dato sin auditoría. La bitácora lo delata, pero esa misma bitácora está bajo su control si permanece en el servidor.
4. **Las lecturas.** No dejan rastro.

Para cerrar esas brechas hacen falta controles que el servidor no puede dar por sí solo: cuentas individuales, bitácoras enviadas a un sistema externo custodiado por otra área, el hash entregado de forma independiente, retención definida por el responsable de los datos y revisión periódica por alguien ajeno a quien opera la base.

---

## 8. Preguntas de reflexión

**1. ¿Por qué la auditoría no puede configurarse después de un incidente para investigarlo?**
Porque solo registra lo que ocurre mientras está activa. Los `UPDATE` de las Actividades 3 y 7 ocurrieron con `log_statement` en `none` y `ddl`, y no pudieron reconstruirse: solo quedaron sesiones de conexión sin sentencia, y la hora de cada cambio es un hueco.

**2. ¿Por qué conviene que la bitácora la administre el propio servidor y no el mecanismo de despliegue?**
Con `logging_collector = on`, PostgreSQL decide dónde y cómo escribe, y `pg_current_logfile()` y `pg_read_file` permiten leerla igual en Windows, Linux o contenedor. Con el colector apagado, el destino de `stderr` depende de cómo se arrancó el servicio y no hay un lugar único donde buscar evidencia.

**3. ¿Por qué el prefijo de línea es tan importante como el nivel de `log_statement`?**
El nivel decide qué se registra y el prefijo decide si la línea sirve como evidencia. Con `%t` el servidor ya registraba conexiones, pero no se sabía quién ni desde dónde. Con `user=%u db=%d app=%a client=%h` cada línea se atribuye.

**4. ¿Qué diferencia práctica hay entre registrar la sentencia y registrar el cambio en el dato?**
La sentencia dice qué se pidió (`telefono = '6679990000'`). El cambio dice qué había antes y qué quedó. La sentencia no guarda el valor anterior, no indica cuántas filas se afectaron (el `UPDATE` masivo dejó 1 línea frente a 5 eventos) y no sirve para restaurar el dato. La auditoría con disparador sí.

**5. ¿Qué evidencia ofrece `pg_stat_activity` que no ofrece la bitácora, y viceversa?**
`pg_stat_activity` muestra el estado actual: quién está conectado y qué ejecuta ahora. La bitácora conserva la historia. Después de terminar el reporte, solo la bitácora mostró la sesión del PID 6528 y su cancelación. El PID relaciona ambas fuentes.

**6. Si el administrador puede cambiar `log_statement` a `none` y desactivar el disparador, ¿quién audita al administrador?**
Nadie dentro del propio servidor. La respuesta está fuera de él: bitácoras enviadas a un sistema externo custodiado por otra área, cuentas nombradas para los administradores, revisión independiente de la bitácora contra los cambios autorizados, y separación entre quien opera la base y quien custodia la evidencia (principio de separación de funciones de la Unidad II).