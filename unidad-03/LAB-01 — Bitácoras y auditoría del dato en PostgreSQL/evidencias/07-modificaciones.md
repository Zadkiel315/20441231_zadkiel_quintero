# Evidencia 07 — Modificaciones de datos: `ddl` frente a `mod`

**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Actividad:** 7 — Modificaciones de datos: `ddl` frente a `mod`  
**Motor:** PostgreSQL 18.6  
**Sistema operativo:** Windows 64 bits  
**Base de datos:** comercial

## 1. Repetición del cambio del incidente con `log_statement = 'ddl'`

Con el registro en nivel `ddl`, se repitió el cambio de la actividad 3 conectándose por red como la aplicación de ventas:

```powershell
psql "postgresql://app_ventas:<contraseña>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XYZ' WHERE id = 3"
```

**Resultado:**

```
UPDATE 1
```

Se buscó el rastro en la bitácora:

```sql
SELECT linea FROM dba.bitacora WHERE linea LIKE '%user=app_ventas%' ORDER BY num DESC LIMIT 3;
```

**Resultado:** 3 filas.

| Hora | PID | Aplicación (prefijo) | Evento |
|---|---|---|---|
| 19:19:27.836 | 18264 | app-ventas-web | Desconexión: duración de sesión 0:00:00.093, host `127.0.0.1`, puerto 60942 |
| 19:19:27.811 | 18264 | [desconocido] | Conexión autorizada: usuario `app_ventas`, base `comercial`, aplicación `app-ventas-web` |
| 19:19:27.811 | 18264 | [desconocido] | Conexión autenticada: `app_ventas`, método `scram-sha-256`, `pg_hba.conf` línea 115 |

**Interpretación:**

Aparecen la conexión y la desconexión de `app_ventas`, pero **no el `UPDATE`**. Con `log_statement = 'ddl'` solo se registran las sentencias de definición, por lo que la modificación de datos no deja rastro de la sentencia. El cambio sí se aplicó: el RFC del cliente 3 quedó en `GAMA780912XYZ`.

## 2. Cambio de nivel a `mod`

En la sesión de administrador se cambió el nivel de registro y se recargó la configuración:

```sql
ALTER SYSTEM SET log_statement = 'mod';
SELECT pg_reload_conf();
```

| Sentencia | Resultado |
|---|---|
| `ALTER SYSTEM SET log_statement = 'mod'` | `ALTER SYSTEM` |
| `SELECT pg_reload_conf()` | `t` |

## 3. Modificación y consulta con `log_statement = 'mod'`

Se ejecutaron, en una sola conexión, una modificación y una consulta (cada `-c` es una sentencia distinta):

```powershell
psql "postgresql://app_ventas:<contraseña>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET telefono = '6679990000' WHERE id = 3" -c "SELECT nombre, rfc FROM clientes WHERE id = 3"
```

**Resultado:**

| Sentencia | Respuesta |
|---|---|
| `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` | `UPDATE 1` |
| `SELECT nombre, rfc FROM clientes WHERE id = 3` | María García, `GAMA780912XYZ` |

## 4. Consulta de la bitácora

```sql
SELECT linea
FROM dba.bitacora
WHERE linea LIKE '%log_statement%'
   OR linea ~ 'user=app_ventas.*(statement|sentencia):'
ORDER BY num;
```

El filtro acepta `statement:` y `sentencia:` porque este servidor escribe sus mensajes en español.

**Resultado:** 2 filas.

| Hora | PID | Usuario | Base | Aplicación | Cliente | Sentencia registrada |
|---|---|---|---|---|---|---|
| 19:19:51.024 | 17360 | postgres | comercial | psql | ::1 | `ALTER SYSTEM SET log_statement = 'mod';` |
| 19:20:56.389 | 8064 | app_ventas | comercial | app-ventas-web | 127.0.0.1 | `UPDATE clientes SET telefono = '6679990000' WHERE id = 3` |

## 5. Análisis

1. **Ahora sí queda quién, cuándo, desde dónde, con qué aplicación y qué sentencia.** La línea del `UPDATE` muestra el usuario `app_ventas`, la hora con milisegundos, el cliente `127.0.0.1`, la aplicación `app-ventas-web` y el texto completo de la sentencia.
2. **El `SELECT nombre, rfc ...` no aparece.** Con `mod` solo se registran las sentencias que modifican datos; las lecturas no quedan registradas.
3. **La bitácora muestra lo que se escribió, pero no el valor anterior.** La línea registra `telefono = '6679990000'`, pero no cuál era el teléfono antes del cambio, ni cuántas filas se afectaron.
4. **El `ALTER SYSTEM` sí aparece**, porque `log_statement` valía `ddl` cuando se ejecutó.
5. **No se observó el aviso de cambio de parámetro** (`parameter "log_statement" changed to "mod"`) en la bitácora consultada, igual que ocurrió en la actividad 4.
6. **El `UPDATE` del RFC (sección 1) quedó sin registrar**, porque ocurrió con nivel `ddl`. Esa modificación ya no puede reconstruirse desde la bitácora.

## 6. Preguntas

**Pregunta 1. ¿Qué nivel habría registrado la lectura del RFC? ¿Qué costo tendría en un servidor con miles de consultas por minuto?**

El nivel `all`, que registra todas las sentencias, incluidos los `SELECT`.

En un servidor con miles de consultas por minuto el costo sería alto:

- Un volumen muy grande de bitácora, con escritura constante a disco y archivos que crecen y rotan con rapidez.
- Sobrecarga en el servidor por el trabajo adicional de escribir cada sentencia.
- Ruido: los eventos importantes (cambios, fallos de acceso) quedarían enterrados entre miles de lecturas rutinarias.
- Más datos sensibles en la bitácora, porque el texto de las consultas puede contener valores de clientes.

Para casos puntuales hay alternativas más selectivas, como una extensión de auditoría (`pgaudit`) para registrar solo ciertas tablas o roles.

**Pregunta 2. ¿Qué le falta a esta bitácora para revertir el cambio con certeza?**

Le falta el **valor anterior** de los datos. La bitácora conserva la sentencia con el valor nuevo, pero no el que había antes. Por ejemplo, en este laboratorio el RFC del cliente 3 pasó por tres valores, y el único registro de los anteriores está en las consultas que se hicieron durante la práctica, no en la bitácora:

| Momento | RFC del cliente 3 | ¿Está en la bitácora? |
|---|---|---|
| Datos iniciales | GAMA780912GHI | No |
| Actividad 3 | GAMA780912XXX | No (`log_statement = none`) |
| Actividad 7, con `ddl` | GAMA780912XYZ | No (`log_statement = ddl`) |

Además, la bitácora tampoco indica cuántas filas se afectaron, si la transacción se confirmó o se revirtió, ni qué persona estaba detrás de la cuenta compartida `app_ventas`. Para revertir con certeza se necesita registrar dentro de los datos el valor anterior y el nuevo de cada cambio, por ejemplo mediante una tabla de auditoría alimentada por un disparador, que es lo que se aborda en la Parte B.

## 7. Conclusión

El nivel de registro determina qué evidencia existe. Con `ddl`, el `UPDATE` de la aplicación de ventas no dejó rastro de la sentencia; con `mod`, el mismo tipo de cambio quedó identificado con usuario, hora, cliente, aplicación y sentencia completa. Lo que ocurrió antes del cambio de nivel no se puede recuperar.

Aun con `mod`, la bitácora tiene límites: no registra las lecturas, no guarda el valor anterior de los datos y además copia en texto claro los valores escritos en las sentencias, como el teléfono. Por eso la bitácora del servidor debe complementarse con una auditoría dentro de los datos y su acceso debe restringirse.