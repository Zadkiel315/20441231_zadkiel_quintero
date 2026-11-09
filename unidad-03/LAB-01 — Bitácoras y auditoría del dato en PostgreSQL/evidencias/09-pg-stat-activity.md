# Evidencia 09 — Sesiones activas con `pg_stat_activity`

## 1. Simulación de un reporte de larga duración

En una segunda terminal se simuló un reporte mensual de larga duración, conectándose como `soporte_ana` con el nombre de aplicación `reporte-mensual`:

```powershell
psql "postgresql://soporte_ana:<contraseña>@127.0.0.1/comercial?application_name=reporte-mensual" -c "SELECT pg_sleep(90)"
```

**Resultado:**

```
ERROR:  cancelando la sentencia debido a que se agotó el tiempo de espera de sentencias
```

**Interpretación:**

El reporte no llegó a los 90 segundos: el servidor lo canceló por exceder el tiempo límite de sentencias (sección 3). Mientras estuvo en ejecución se pudo observar en `pg_stat_activity`.

## 2. Sesiones activas mientras se ejecutaba el reporte

En la sesión de administrador se consultó la vista `pg_stat_activity`:

```sql
SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';
```

**Resultado:** 2 filas.

| pid | usename | application_name | client_addr | backend_start | state | query |
|---|---|---|---|---|---|---|
| 17360 | postgres | psql | ::1 | 2026-11-08 18:49:16.457308-06 | active | SELECT pid, usename, applicati |
| 6528 | soporte_ana | reporte-mensual | 127.0.0.1 | 2026-11-08 19:44:15.730582-06 | active | SELECT pg_sleep(90) |

**Interpretación:**

La vista muestra quién está conectado en ese instante: la sesión del administrador (la propia consulta, `active`) y la sesión del reporte (`soporte_ana`, aplicación `reporte-mensual`, desde `127.0.0.1`, ejecutando `SELECT pg_sleep(90)`). El PID de la sesión del reporte es **6528**.

## 3. Tiempo límite de sentencias

Para explicar la cancelación del reporte se revisó la configuración:

```sql
SELECT name, setting, unit, source, sourcefile
FROM pg_settings WHERE name = 'statement_timeout';

SELECT * FROM pg_db_role_setting;
```

| Parámetro | Valor | Unidad | Origen | Archivo |
|---|---|---|---|---|
| statement_timeout | 60000 | ms | configuration file | `C:/Program Files/PostgreSQL/18/data/postgresql.conf` |

| setdatabase | setrole | setconfig |
|---|---|---|
| 0 | 16488 | `{statement_timeout=30s}` |

**Interpretación:**

El servidor limita las sentencias a 60 segundos (`statement_timeout = 60000 ms`, definido en `postgresql.conf`). Además existe un valor propio de 30 segundos para el rol con OID 16488. La sesión de `soporte_ana` se canceló a los 60 segundos (sección 4), lo que indica que le aplicó el límite del servidor y que el valor de 30 segundos corresponde a otro rol.

## 4. Búsqueda del PID en la bitácora

Se buscó en la bitácora el PID observado en `pg_stat_activity`:

```sql
SELECT linea FROM dba.bitacora WHERE linea LIKE '%[6528]%' ORDER BY num;
```

**Resultado:** 6 filas.

| Hora | Usuario | Aplicación (prefijo) | Tipo | Evento |
|---|---|---|---|---|
| 19:44:15.781 | [desconocido] | [desconocido] | LOG | Conexión recibida desde `127.0.0.1`, puerto 62072 |
| 19:44:15.818 | soporte_ana | [desconocido] | LOG | Conexión autenticada: `scram-sha-256`, `pg_hba.conf` línea 115 |
| 19:44:15.818 | soporte_ana | [desconocido] | LOG | Conexión autorizada: base `comercial`, aplicación `reporte-mensual` |
| 19:45:15.896 | soporte_ana | reporte-mensual | ERROR | Sentencia cancelada por agotar el tiempo de espera de sentencias |
| 19:45:15.896 | soporte_ana | reporte-mensual | SENTENCIA | `SELECT pg_sleep(90)` |
| 19:45:15.904 | soporte_ana | reporte-mensual | LOG | Desconexión: duración de sesión 0:01:00.174 |

**Interpretación:**

Todas las líneas comparten el PID 6528, lo que permite reconstruir la vida completa de la sesión: cuándo llegó la conexión, quién se autenticó, con qué aplicación, qué sentencia se ejecutaba, por qué terminó y cuánto duró (1 minuto con 0.17 segundos). La hora de la conexión coincide con el `backend_start` de `pg_stat_activity` (19:44:15).

## 5. Sesiones después de que terminó el reporte

Se repitió la consulta a `pg_stat_activity`:

| pid | usename | application_name | client_addr | backend_start | state | query |
|---|---|---|---|---|---|---|
| 17360 | postgres | psql | ::1 | 2026-11-08 18:49:16.457308-06 | active | SELECT pid, usename, applicati |

**Interpretación:**

La sesión de `soporte_ana` (PID 6528) ya no aparece: `pg_stat_activity` solo muestra las sesiones que existen en ese momento y no conserva historial.

## 6. Preguntas

**Pregunta 1. ¿Qué columna permite relacionar una sesión con sus líneas de bitácora?**

La columna `pid` de `pg_stat_activity`. El prefijo de la bitácora (`log_line_prefix`) incluye el PID del proceso entre corchetes (`%p`, por ejemplo `[6528]`), de modo que filtrar la bitácora por `[pid]` devuelve todas las líneas de esa sesión. Como complemento, `backend_start`, `usename` y `application_name` permiten confirmar que se trata de la misma sesión. Conviene verificar también la hora, porque el sistema operativo puede reutilizar un PID en otra sesión posterior.

**Pregunta 2. Después de que termina el reporte, ¿qué fuente conserva evidencia de que existió?**

La bitácora. `pg_stat_activity` es una vista del estado actual: cuando la sesión termina, desaparece de ella. La bitácora conserva el historial: la conexión, la autenticación, la aplicación, la sentencia que se cancelaba, el motivo del error y la duración total de la sesión.

| Aspecto | `pg_stat_activity` | Bitácora |
|---|---|---|
| Qué muestra | Sesiones existentes en este momento | Eventos pasados |
| Después de terminar la sesión | Ya no aparece | Sigue registrada |
| Uso principal | Diagnóstico en vivo | Auditoría y reconstrucción de hechos |

**Pregunta 3. ¿Por qué `client_addr` aparece vacío en la sesión del administrador?**

`client_addr` queda vacío (`NULL`) cuando la conexión no usa red, es decir, cuando el cliente se conecta por un socket local de Unix. Por eso en un servidor Linux la sesión del administrador suele aparecer sin dirección.

En este laboratorio no ocurrió así: la sesión del administrador muestra `::1`. En Windows, `psql` se conecta por TCP a `localhost` y no por un socket de Unix, por lo que la conexión se registra con la dirección de bucle local IPv6 (`::1`). La misma dirección aparece como `client=::1` en la bitácora.

## 7. Conclusión

`pg_stat_activity` permitió ver en tiempo real quién estaba conectado, con qué aplicación, desde dónde y qué ejecutaba. La bitácora, por su parte, conservó el historial completo de la sesión del reporte una vez que desapareció de la vista, y el PID permitió relacionar ambas fuentes.

La actividad también mostró que el servidor aplica un tiempo límite de sentencias (`statement_timeout`), que canceló el reporte a los 60 segundos y dejó el rastro correspondiente en la bitácora. Las dos fuentes se complementan: una sirve para diagnosticar lo que está ocurriendo y la otra para reconstruir lo que ocurrió.