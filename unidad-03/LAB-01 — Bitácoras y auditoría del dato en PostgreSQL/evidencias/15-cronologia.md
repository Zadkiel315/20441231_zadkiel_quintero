# Evidencia 15 — Conservación de la bitácora y reconstrucción de la cronología

## 1. Exportación y resumen criptográfico de la bitácora (Actividad 16)

Se exportó la bitácora vigente a `evidencias/bitacora-lab01.log` y se calculó su resumen SHA-256, guardado en `evidencias/bitacora-lab01.sha256`:

```powershell
Get-FileHash evidencias/bitacora-lab01.log -Algorithm SHA256
```

**Resultado:**

```
8A7D8EFB558CE1F668690ED48E60DCF36BD463CA5698E0BA7FE9AB0FCB138578
```

**Características del archivo exportado:**

| Dato | Valor |
|---|---|
| Tamaño | 71 504 bytes (439 líneas) |
| Primer y último evento | 2026-11-08 18:49:16.492 y 22:19:03.023 (CST, UTC-6) |
| Codificación | UTF-16 LE (los acentos aparecen alterados, por ejemplo `conexi¾n`) |
| Verificación | Al recalcular el SHA-256 del archivo, coincide con el valor guardado en `bitacora-lab01.sha256` |

**Nota para el informe sobre la sustitución de contraseñas:**

El archivo se exportó con la contraseña de la Actividad 6 sustituida por `<REDACTED>` (por ejemplo, en la línea 47, `CREATE ROLE rol_temporal ... PASSWORD '<REDACTED>'`). Al revisar la primera exportación (hash `FBC40AAB…FEC76E`) se detectó que todavía contenía otros secretos que esa sustitución no cubría:

- Línea 119: la sentencia `ALTER USER "soporte_ana" PASSWORD ...` contenía el verificador SCRAM de la contraseña de ese rol.
- Línea 419: la sentencia `ALTER ROLE postgres WITH PASSWORD ...`, ejecutada desde pgAdmin 4, contenía la contraseña del rol `postgres` en texto claro.

Ambos valores se sustituyeron por `<REDACTED>`, se recalculó el hash y se descartó la primera versión. Al comparar las dos exportaciones, ambas tienen 439 líneas y difieren únicamente en las líneas 119 y 419, por lo que los números de línea de la cronología siguen siendo válidos. Como la contraseña de `postgres` estuvo expuesta en la primera exportación, se cambió después de detectarlo; la bitácora conserva el momento en que se fijó la anterior (línea 419), pero ya no su valor.

También conviene registrar que el comando de exportación indicado falló dos veces (líneas 347 y 369, a las 22:10:07 y 22:11:36) con el error `secuencia de bytes no válida para codificación «UTF8»`, porque la bitácora contiene caracteres en la codificación de Windows. El archivo entregado es, por tanto, una exportación con conversión de codificación y no el resultado literal de ese comando.

### Preguntas de la Actividad 16

**Pregunta 1. Un resumen SHA-256, ¿impide que alguien modifique la bitácora? ¿Qué permite demostrar?**

No lo impide. Un hash no protege el archivo: cualquiera con acceso podría editarlo. Lo que permite es **detectar** la modificación: si cambia un solo carácter, el resumen calculado será distinto al guardado. Así se demuestra la **integridad**: que el archivo que se presenta hoy es idéntico al que existía cuando se calculó el hash. No demuestra quién lo creó, ni que su contenido fuera correcto desde el origen, ni que no se alterara antes de calcular el hash. Esta práctica lo ilustra: la primera y la segunda exportación difieren en solo dos líneas, y sus hashes son completamente distintos.

**Pregunta 2. ¿Dónde debería guardarse el hash para que sea útil como control de integridad?**

En un lugar distinto e independiente del archivo, que no pueda modificar la misma persona que administra el servidor o la bitácora: por ejemplo, entregado al área de auditoría o a Dirección en el informe firmado, en un sistema de tickets o repositorio con historial inmutable, o en un almacenamiento de solo escritura. Si el hash se guarda junto al archivo y con los mismos permisos (como ocurre en esta práctica, con ambos en la carpeta `evidencias/`), quien altere la bitácora puede recalcular y reemplazar también el hash, y el control pierde su valor.

**Pregunta 3. La guía NIST SP 800-92 trata la conservación y protección de bitácoras (REF-U3-03). ¿Qué riesgos tiene conservar la bitácora solo en el servidor que la produce?**

- **Pérdida de disponibilidad:** si el servidor se reinstala, falla el disco o la bitácora rota y se sobrescribe, la evidencia desaparece. En este laboratorio, la bitácora vigente empieza a las 18:49:16 y ya no contiene lo ocurrido antes (por ejemplo, la sesión de la Actividad 3, a las 18:35:34).
- **Pérdida de integridad:** quien controle el servidor (un administrador o un intruso) puede alterar o borrar las líneas que lo incriminan; es lo que se vio en la Actividad 14.
- **Sin copia independiente para comparar:** no hay forma de contrastar la bitácora con otra fuente para detectar manipulaciones.
- **Riesgo de confidencialidad:** la bitácora contiene datos sensibles (RFC, correos, secretos de roles); mientras esté solo en el servidor, queda bajo los mismos controles que el sistema que se audita.

Por eso se recomienda enviar las bitácoras a un sistema externo y protegido, administrado por otra área.

**Pregunta 4. Propón durante cuánto tiempo conservarías esta bitácora y justifica tu criterio.**

Propongo conservarla **12 meses** en línea (consultable) y archivarla de forma protegida por un periodo adicional definido con el área legal, ampliable si hay una investigación en curso. Criterios: (1) los incidentes suelen detectarse semanas o meses después, por lo que un plazo corto dejaría sin evidencia a una investigación tardía; (2) la bitácora contiene datos personales y secretos, así que conservarla indefinidamente contradice el principio de minimización y la política de retención; (3) existen obligaciones legales o contractuales que pueden exigir un plazo mayor, que corresponde fijar al responsable de los datos; (4) el costo de almacenamiento es bajo frente al valor de la evidencia. El criterio formal se completa en el LAB-03.

## 2. Cronología reconstruida (Actividad 17)

La cronología se construyó con la bitácora exportada (`bitacora-lab01.log`), con la tabla `auditoria.cambios_clientes` y, para los eventos anteriores al inicio del archivo o que no quedaron registrados, con las Evidencias 03 y 07 (consultas hechas durante la práctica). Todas las horas están en CST (UTC-6), la misma zona de ambas fuentes.

**Cómo leer la columna Fuente:** `L63` es la línea 63 de `bitacora-lab01.log` tal como fue exportado (entre cada evento hay una línea en blanco, por la conversión de saltos de línea). `Aud #1` es el `id_evento` 1 de la tabla de auditoría. `Ev. 03` y `Ev. 07` son las evidencias de las Actividades 3 y 7. La columna Cliente es la dirección de origen que registra el servidor (`client=`).

| # | Fecha y hora | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente |
|---|---|---|---|---|---|---|---|
| 1 | 2026-11-08 18:35:34 (hora de la sesión; la sentencia no tiene hora registrada) | app_ventas | 127.0.0.1 | Datos | Sesión de 0.092 s con la aplicación `app-ventas-web` (puerto 58453) que coincide con el `UPDATE` del RFC del cliente 3: `GAMA780912GHI` → `GAMA780912XXX` (Actividad 3). La sentencia no se registró (`log_statement = none`) | Sí | Ev. 03 (fuera del archivo exportado, que empieza a las 18:49:16) |
| 2 | 18:49:16.517 | postgres | ::1 | Acceso | Sesión del administrador autenticada con `scram-sha-256` (aplicación `psql`, PID 17360) | Sí | L3 |
| 3 | 18:56:59.330 | app_ventas | 127.0.0.1 | Acceso | Conexión rechazada: contraseña incorrecta (PID 7468) | No | L11 |
| 4 | 18:57:57.363 | usuario_inexistente | 127.0.0.1 | Acceso | Conexión rechazada: el rol no existe (PID 12744) | No | L17 |
| 5 | 18:58:14.868 | app_ventas | 127.0.0.1 | Acceso | Conexión autenticada y autorizada con la aplicación `app-ventas-web` (PID 15908) | Sí | L25, L27 |
| 6 | 19:07:27.141 y .154 | postgres | ::1 | Privilegio | `REVOKE UPDATE` sobre `clientes` a `soporte_ana` y `GRANT UPDATE` a `app_ventas` | Sí | L41, L43 |
| 7 | 19:07:28.888 | postgres | ::1 | Estructura | `ALTER TABLE clientes ADD COLUMN segmento` | Sí | L45 |
| 8 | 19:07:41.025 y 19:07:42.114 | postgres | ::1 | Privilegio | Se crea y se elimina el rol `rol_temporal` (contraseña sustituida por `<REDACTED>` en la exportación) | Sí | L47, L49 |
| 9 | 19:19:27.811 (hora de la sesión; la sentencia no tiene hora registrada) | app_ventas | 127.0.0.1 | Datos | Sesión de 0.093 s con `app-ventas-web` (PID 18264, puerto 60942) que coincide con el `UPDATE` del RFC: `GAMA780912XXX` → `GAMA780912XYZ` (Actividad 7). Con `log_statement = ddl`, la sentencia no se registró | Sí | L55, L57, L59, L61; Ev. 07 |
| 10 | 19:19:51.024 | postgres | ::1 | Configuración | `ALTER SYSTEM SET log_statement = 'mod'` (desde aquí la bitácora registra también cambios de datos) | Sí | L63 |
| 11 | 19:20:56.389 | app_ventas | 127.0.0.1 | Datos | `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` (aplicación `app-ventas-web`, PID 8064) | Sí | L75 (sin auditoría: el disparador aún no existía) |
| 12 | 19:33:15.553 | soporte_ana | 127.0.0.1 | Acceso | Conexión rechazada: el rol no tiene contraseña asignada (PID 6964) | No | L85 |
| 13 | 19:34:01.000 y 19:34:27.217 | postgres | ::1 | Privilegio | Dos intentos de `DROP ROLE soporte_ana`; fallan porque el rol tiene privilegios sobre `clientes` | No | L91, L93, L99 |
| 14 | 19:35:54.213 | soporte_ana | 127.0.0.1 | Acceso | Segunda conexión rechazada por la misma causa (PID 11144) | No | L113 |
| 15 | 19:37:54.566 | postgres | ::1 | Privilegio | `ALTER USER soporte_ana PASSWORD ...` (asigna contraseña al rol) | Sí | L119 |
| 16 | 19:38:13.877 | soporte_ana | 127.0.0.1 | Error | `DELETE FROM clientes WHERE id = 5`: permiso denegado a la tabla `clientes` (PID 15508) | No | L127, L129 |
| 17 | 19:45:15.896 y 19:46:25.802 | soporte_ana | 127.0.0.1 | Error | Dos reportes `reporte-mensual` (`SELECT pg_sleep(90)`, PID 6528 y 12856) cancelados a los 60 s por el límite de tiempo de sentencias | No | L149, L161 |
| 18 | 19:55:31.609 a 19:55:33.527 | postgres | ::1 | Estructura | `CREATE SCHEMA auditoria`, `REVOKE ALL ... FROM PUBLIC` y `CREATE TABLE auditoria.cambios_clientes` | Sí | L167, L169, L171 |
| 19 | 20:18:22.542 a 20:18:25.160 | postgres | ::1 | Estructura | Se crea la función `registrar_cambio_cliente()`, se le revoca el acceso a `PUBLIC` y se crea el disparador `trg_auditoria_clientes` | Sí | L199, L245, L247 |
| 20 | 21:38:57.401 | app_ventas | 127.0.0.1 | Datos | `UPDATE` del RFC del cliente 3: `GAMA780912XYZ` → `GAMA780912ZZZ` (PID 10748) | Sí | L263; Aud #1 |
| 21 | 21:39:05.491 | app_ventas | 127.0.0.1 | Error | `SELECT * FROM auditoria.cambios_clientes`: permiso denegado al esquema `auditoria` (PID 10900) | No | L273 |
| 22 | 21:48:56.667 y .678 | postgres | ::1 | Datos | `INSERT` y `DELETE` del cliente `Pedro Ruiz` (id 6) | Sí | L283, L287; Aud #2 y #3 |
| 23 | 21:54:04.120 a .147 | app_ventas | 127.0.0.1 | Intento de manipulación | `DELETE FROM auditoria.cambios_clientes` y `ALTER TABLE clientes DISABLE TRIGGER`; ambos denegados (PID 7220) | No | L299, L301, L305, L307 |
| 24 | 21:54:23.187 a .223 | postgres | ::1 | Datos / manipulación | Se desactiva el disparador, se hace `UPDATE` del RFC del cliente 3 a `GAMA780912GHI` y se reactiva | Sí | L313, L315, L317; Aud: sin evento |
| 25 | 21:59:53.467 | postgres | ::1 | Datos | `UPDATE clientes SET segmento = 'regular'` sin `WHERE` (5 filas) | Sí | L331; Aud: 5 eventos `UPDATE` nuevos |
| 26 | 22:11:20.865 | postgres | ::1 | Acceso | Conexión rechazada: contraseña incorrecta (PID 2812) | No | L357 |
| 27 | 22:17:45.335 | postgres | ::1 | Privilegio | `ALTER ROLE postgres WITH PASSWORD ...` desde pgAdmin 4 (el valor de la contraseña fue sustituido por `<REDACTED>` en la exportación) | Sí | L419 |

## 3. Respuestas a Dirección

Las respuestas se basan solo en la evidencia. Cuando no la hay, se indica explícitamente.

**Pregunta 1. ¿Quién cambió el RFC la primera vez (Actividad 3)? ¿Y en las Actividades 7, 12 y 14?**

| Actividad | Cuenta | Persona | Evidencia |
|---|---|---|---|
| 3 | `app_ventas`, aplicación `app-ventas-web`, `127.0.0.1`, sesión de las 18:35:34 (indicio, no prueba) | **No hay evidencia.** | La bitácora no registró la sentencia (`log_statement = none`); solo conservó la conexión, la autorización y la desconexión de una sesión de 0.092 s. La relación con el cambio se deduce por la coincidencia de hora. Esas líneas no están en la bitácora exportada, que empieza a las 18:49:16 (se conocen por la Evidencia 03). |
| 7 | `app_ventas`, aplicación `app-ventas-web`, `127.0.0.1`, sesión de las 19:19:27.811, PID 18264 (indicio, no prueba) | **No hay evidencia.** | Con `log_statement = ddl` la sentencia no se registró; la bitácora solo muestra la conexión, la autorización y la desconexión (L55 a L61). La relación con el cambio se deduce por la coincidencia de hora. |
| 12 | `app_ventas`, aplicación `app-ventas-web`, `127.0.0.1`, a las 21:38:57.401 (PID 10748) | **No hay evidencia** de qué persona estaba detrás de la cuenta | Bitácora L263 y auditoría, id_evento 1 (`usuario_sesion = app_ventas`). |
| 14 | `postgres`, aplicación `psql`, `::1`, a las 21:54:23.203 (PID 17360), con el disparador desactivado entre las 21:54:23.187 y las 21:54:23.223 | Cuenta de administrador; no hay evidencia de qué persona | Solo en la bitácora (L313 a L317); la tabla de auditoría no registró el cambio. |

En todos los casos, `app_ventas` es una cuenta de aplicación compartida y el nombre `app-ventas-web` lo declara el propio cliente, por lo que la evidencia permite identificar la cuenta, no a la persona.

**Pregunta 2. ¿Quién cambió el teléfono?**

La cuenta `app_ventas`, desde `app-ventas-web`, dirección `127.0.0.1`, a las 19:20:56.389 (PID 8064), mediante `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` (bitácora L75). Es el único `UPDATE` de teléfono que aparece en la bitácora exportada. No hay evidencia de la persona detrás de la cuenta ni del valor anterior del teléfono: la bitácora solo guarda el texto de la sentencia (con el valor nuevo) y el disparador de auditoría aún no existía.

**Pregunta 3. ¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?**

Sí, cinco. Todos provienen de la propia máquina (direcciones de bucle local), sin evidencia de ningún origen remoto.

| Hora | Usuario | Origen | Motivo registrado | Fuente |
|---|---|---|---|---|
| 18:56:59.330 | app_ventas | 127.0.0.1, puerto 59720 | Contraseña incorrecta | L11 |
| 18:57:57.363 | usuario_inexistente | 127.0.0.1, puerto 59896 | El rol no existe | L17 |
| 19:33:15.553 | soporte_ana | 127.0.0.1, puerto 61461 | El rol no tenía contraseña asignada | L85 |
| 19:35:54.213 | soporte_ana | 127.0.0.1, puerto 61503 | El rol no tenía contraseña asignada | L113 |
| 22:11:20.865 | postgres | ::1, puerto 52745 | Contraseña incorrecta | L357 |

Además, hay siete conexiones recibidas entre las 22:10 y las 22:18 que no tienen ningún resultado registrado (ni autorización ni fallo): PID 13084, 10176, 11288, 7524, 8876, 9236 y 16372 (líneas 339, 353, 361, 375, 377, 421 y 431). **No hay evidencia** de si fueron fallidas o abandonadas, por lo que no se cuentan como intentos fallidos. La bitácora exportada tampoco cubre lo anterior a las 18:49:16.

**Pregunta 4. ¿Qué valor tenía el RFC antes de cada cambio?**

| Actividad | Valor anterior | Fuente del dato |
|---|---|---|
| 3 | `GAMA780912GHI` | Consulta del estado inicial en la Evidencia 03. No está en la bitácora ni en la auditoría. |
| 7 | `GAMA780912XXX` | Resultado de la Actividad 3, documentado en la Evidencia 07. No está en la bitácora ni en la auditoría. |
| 12 | `GAMA780912XYZ` | Auditoría, id_evento 1, `valores_antes`. |
| 14 | `GAMA780912ZZZ`, por deducción | El cambio no generó evento de auditoría. `ZZZ` es el valor posterior del evento 1, y la bitácora no muestra ningún otro `UPDATE` de RFC entre las 21:38:57 y las 21:54:23. Es una inferencia, no un dato registrado. |

Los valores de las Actividades 3 y 7 provienen de las consultas hechas durante la práctica, no de la bitácora ni de la auditoría; la bitácora, por sí sola, no permite conocer el valor anterior de ningún cambio.

### Las cinco preguntas de Dirección (sección 5 del laboratorio)

El enunciado de la Actividad 17 enumera cuatro preguntas, pero la sección 5 del laboratorio formula cinco: ¿quién hizo el cambio?, ¿cuándo?, ¿desde qué aplicación o equipo?, ¿hubo intentos de acceso fallidos antes del cambio? y ¿qué valor tenía el RFC antes? Las anteriores cubren la primera, la cuarta y la quinta; la siguiente tabla responde las cinco para cada cambio de RFC.

| Actividad | ¿Quién? | ¿Cuándo? | ¿Desde qué aplicación o equipo? | ¿Intentos fallidos antes del cambio? | ¿Valor anterior? |
|---|---|---|---|---|---|
| 3 | Cuenta `app_ventas`; persona: no hay evidencia | Sesión de las 18:35:34; la hora exacta del `UPDATE` es un hueco | `app-ventas-web`, `127.0.0.1` (puerto 58453) | **No hay evidencia** completa: la bitácora exportada empieza a las 18:49:16 y la consulta de la Evidencia 03 (filtrada por `update` y `app_ventas`) no mostró fallos de `app_ventas` | `GAMA780912GHI` |
| 7 | Cuenta `app_ventas`; persona: no hay evidencia | Sesión de las 19:19:27.811 (PID 18264); la hora exacta del `UPDATE` es un hueco | `app-ventas-web`, `127.0.0.1` (puerto 60942) | Sí, dos: `app_ventas` con contraseña incorrecta a las 18:56:59.330 (L11) y `usuario_inexistente` a las 18:57:57.363 (L17) | `GAMA780912XXX` |
| 12 | Cuenta `app_ventas`; persona: no hay evidencia | 21:38:57.401 | `app-ventas-web`, `127.0.0.1` (puerto 51212) | Sí, cuatro: las dos anteriores (L11, L17) y `soporte_ana` a las 19:33:15.553 y 19:35:54.213 (L85, L113) | `GAMA780912XYZ` (auditoría, id_evento 1) |
| 14 | Cuenta `postgres` (administrador); persona: no hay evidencia | 21:54:23.203 | `psql`, `::1` | Las mismas cuatro (L11, L17, L85, L113) | `GAMA780912ZZZ`, por deducción |

Notas sobre la tabla:

- **"Equipo":** la bitácora solo registra la dirección de origen. `127.0.0.1` y `::1` son direcciones de bucle local, es decir, la conexión vino de la misma máquina del servidor; el nombre del equipo o de la persona no consta en ninguna fuente.
- **Intentos fallidos "antes del cambio":** solo el fallo de las 18:56:59 corresponde a la misma cuenta (`app_ventas`) que hizo los cambios de las Actividades 7 y 12; los demás son de otras cuentas, y no se debe deducir relación entre ellos sin más evidencia. Los fallos de `soporte_ana` ocurrieron antes de la Actividad 12, pero esa cuenta no tenía contraseña asignada, lo que explica el error.
- **Actividad 14:** a las 21:54:04, minutos antes del cambio, `app_ventas` intentó borrar la tabla de auditoría y desactivar el disparador, y ambos intentos fueron denegados (L299 y L305). No son accesos fallidos sino operaciones rechazadas, pero son un antecedente relevante.

## 4. Huecos de la evidencia

Un evento que no se registró no tiene hora: se declara como hueco y no se estima.

- **Antes de las 18:49:16:** la bitácora exportada no contiene nada anterior. La sesión del PID 524, que se desconecta a las 18:49:16 tras 6 min 41 s, indica actividad previa que no está en este archivo, entre ella la sesión de la Actividad 3 (18:35:34).
- **Sentencias de las Actividades 3 y 7:** los dos `UPDATE` de RFC no quedaron registrados (`log_statement = none` y `ddl`, respectivamente) y el disparador de auditoría no existía. Solo se conservan las sesiones de conexión; la hora de cada sentencia es un hueco.
- **Cambio del RFC a `GAMA780912GHI` (21:54:23):** hueco en la tabla de auditoría, que quedó sin ese evento. Solo lo documenta la bitácora, y no registra el valor anterior.
- **Lecturas de datos:** `soporte_ana` abrió una sesión a las 21:59:44.153 que duró 0.155 s (PID 16100), pero la bitácora no registra qué consultó, porque con `log_statement = 'mod'` no se registran los `SELECT`. Coincide con la lectura de la Actividad 15, pero esa correspondencia es una inferencia.
- **Valor anterior del teléfono:** sin registro (sección 3, pregunta 2).
- **Detalle de los 5 eventos del `UPDATE` masivo:** la tabla de auditoría los cuenta (6 `UPDATE` en total), pero en esta evidencia no se listaron individualmente.

## 5. Conclusión

La combinación de la bitácora del servidor y de la tabla de auditoría permitió reconstruir quién hizo qué y cuándo desde las 18:49: los accesos (cinco fallidos, todos locales), los cambios de privilegios y de estructura, los cambios de RFC de las Actividades 12 y 14, el cambio de teléfono y las operaciones sobre la tabla `clientes`. Cada fuente cubre lo que la otra no: la bitácora registró el cambio que se hizo con el disparador desactivado, y la tabla de auditoría conserva los valores anteriores que la bitácora no guarda.

La evidencia también tiene límites claros. Los cambios de RFC de las Actividades 3 y 7 solo dejaron sesiones de conexión de la cuenta `app_ventas`, sin la sentencia, y sus valores anteriores se conocen únicamente por las consultas de la práctica. El cambio de la Actividad 14 no tiene registro de auditoría, las lecturas no dejan rastro y, en ningún caso, la evidencia identifica a la persona detrás de una cuenta compartida. Esos huecos se declaran como tales y no se estiman.

Por último, la exportación mostró que la propia bitácora es un riesgo si no se protege: contenía contraseñas y datos sensibles que hubo que sustituir, depende de un hash guardado de forma independiente para demostrar su integridad, y debe conservarse fuera del servidor que la produce.