# Evidencia 03 — El incidente sin bitácora

## 1. Estado inicial

Antes de simular el incidente se consultó el RFC del cliente con `id = 3` y el valor de `log_statement`.

```sql
SELECT id, nombre, rfc FROM clientes WHERE id = 3;
SELECT name, setting FROM pg_settings WHERE name = 'log_statement';
```

| id | nombre | rfc |
|---|---|---|
| 3 | María García | GAMA780912GHI |

| Parámetro | Valor |
|---|---|
| log_statement | none |

**Interpretación:**

El RFC original del cliente es `GAMA780912GHI` y el servidor no registra sentencias SQL (`log_statement = none`).

## 2. Simulación del cambio reportado por facturación

El rol `app_ventas` se había creado sin contraseña, y `pg_hba.conf` exige `scram-sha-256` para las conexiones por red. Por eso, como administrador, se le asignó una contraseña antes de la prueba:

```sql
ALTER ROLE app_ventas PASSWORD '<contraseña de práctica>';
```

Después, desde una terminal de PowerShell, se simuló la aplicación de ventas conectándose por red (`127.0.0.1`) con el nombre de aplicación `app-ventas-web`:

```powershell
psql "postgresql://app_ventas:<contraseña>@127.0.0.1/comercial?application_name=app-ventas-web" -c "UPDATE clientes SET rfc = 'GAMA780912XXX' WHERE id = 3"
```

**Resultado:**

```
UPDATE 1
```

## 3. Verificación del cambio

Desde la sesión de administrador se consultó nuevamente el registro:

```sql
SELECT id, nombre, rfc FROM clientes WHERE id = 3;
```

| id | nombre | rfc |
|---|---|---|
| 3 | María García | GAMA780912XXX |

**Interpretación:**

El RFC pasó de `GAMA780912GHI` a `GAMA780912XXX`. El cambio ocurrió y quedó guardado en la tabla.

## 4. Búsqueda de evidencia en la bitácora

Se consultó la vista `dba.bitacora` en busca de la sentencia `UPDATE` o de cualquier rastro de `app_ventas`:

```sql
SELECT linea FROM dba.bitacora
WHERE linea ILIKE '%update%' OR linea LIKE '%app_ventas%';
```

**Resultado:** 6 filas.

| Hora | Tipo de línea | Contenido | ¿Prueba el UPDATE? |
|---|---|---|---|
| 18:03:54 | SENTENCIA | Consulta de la propia vista, ejecutada en la actividad 2 (`ILIKE '%update%'`) | No. No tiene relación con el incidente. |
| 18:34:40 | SENTENCIA | Texto de un comando pegado por error en la sesión de administrador; esa sentencia falló y quedó registrada por `log_min_error_statement = error` (ocupa 2 filas) | No. Fue una sesión de `postgres` y la sentencia no se ejecutó. |
| 18:35:34 | LOG | Conexión autenticada: `app_ventas`, método `scram-sha-256`, regla `pg_hba.conf` línea 115 | No. Solo muestra que alguien se autenticó. |
| 18:35:34 | LOG | Conexión autorizada: usuario `app_ventas`, base `comercial`, aplicación `app-ventas-web` | No. Solo muestra a qué base entró. |
| 18:35:34 | LOG | Desconexión: duración de sesión 0:00:00.092, usuario `app_ventas`, host `127.0.0.1`, puerto 58453 | No. Solo muestra la duración y el origen. |

**Interpretación:**

La sentencia `UPDATE clientes SET rfc = ...` ejecutada por `app_ventas` **no aparece** en la bitácora, porque `log_statement = none`. Lo único que existe del incidente son los eventos de conexión: una sesión de `app_ventas` de menos de una décima de segundo, desde `127.0.0.1`, con el nombre de aplicación `app-ventas-web`.

Además, el prefijo de las líneas (`log_line_prefix = %t`) solo incluye la hora, por lo que el usuario únicamente aparece dentro del texto de los eventos de conexión. La línea de "conexión recibida" no menciona al usuario, por lo que el filtro no la devuelve.

Las líneas de las 18:03:54 y 18:34:40 corresponden a sentencias de la sesión de administrador y no deben confundirse con evidencia del cambio. Una de ellas contiene en texto claro la contraseña del rol, lo que muestra que la bitácora también puede exponer datos sensibles.

## 5. Preguntas

**Pregunta 1. ¿Puedes demostrar quién modificó el RFC?**

No. La bitácora solo permite demostrar que hubo una sesión de `app_ventas` a las 18:35:34, desde `127.0.0.1`, que duró 0.092 segundos. No muestra qué sentencia se ejecutó, sobre qué fila ni cuál fue su resultado, y la relación con el cambio solo se deduce por la coincidencia de hora.

Tampoco identifica a una persona: `app_ventas` es una cuenta de aplicación que puede usar cualquier persona o proceso que conozca la contraseña. Además, el nombre `app-ventas-web` lo declara el propio cliente al conectarse, por lo que cualquiera puede escribirlo.

**Pregunta 2. ¿Puedes demostrar que el cambio no lo hizo `soporte_ana`?**

Se buscó el rol en la bitácora:

```sql
SELECT linea FROM dba.bitacora WHERE linea LIKE '%soporte_ana%';
```

**Resultado:** 0 filas. En el archivo de bitácora vigente no hay ningún evento de conexión de `soporte_ana`.

No obstante, la respuesta sigue siendo que no se puede demostrar. Que no haya conexiones registradas con su nombre es coherente con que ella no participó, pero no lo prueba: pudo usar la contraseña de `app_ventas`, en cuyo caso la bitácora solo mostraría al rol `app_ventas`; además, la bitácora solo cubre el archivo vigente. Con los privilegios que tiene (`SELECT` únicamente) `soporte_ana` no debería poder ejecutar un `UPDATE` sobre `clientes`, pero eso describe lo que se le permite y no lo que ocurrió. Podría haber usado la contraseña de `app_ventas`, y una sesión de un superusuario también habría podido hacer el cambio.

Como la bitácora no registra sentencias ni identifica a la persona detrás de la cuenta, no hay evidencia para descartar a nadie ni para acusar a nadie. La ausencia de pruebas no es una prueba de ausencia.

**Pregunta 3. Los privilegios de la Unidad II, ¿impidieron el cambio? ¿Debían impedirlo?**

No lo impidieron, y no debían impedirlo. Al rol `app_ventas` se le otorgó `UPDATE` sobre `clientes` (`GRANT SELECT, UPDATE ON clientes TO app_ventas`), por lo que el cambio estaba dentro de sus permisos y es una operación legítima para esa aplicación.

Los privilegios controlan **quién puede** hacer algo; no registran **quién lo hizo**. Son un mecanismo de prevención y no de evidencia. Para responder a un incidente se necesita la bitácora, que permite reconstruir los hechos.

**Pregunta 4. ¿Qué tendría que haber estado configurado antes del incidente?**

- `log_statement = 'mod'` (o `'all'`), para registrar las sentencias que modifican datos, como los `UPDATE`.
- Un `log_line_prefix` más completo, que incluya hora, proceso, usuario, base de datos, host y aplicación. Por ejemplo: `'%m [%p] %q%u@%d %h %a '`.
- `log_connections` y `log_disconnections` activados (ya lo estaban).
- Política de rotación y conservación de los archivos, para que la evidencia no se pierda.
- Acceso restringido a la bitácora, porque puede contener datos sensibles.
- Cuentas individuales en lugar de una cuenta compartida, para poder relacionar cada cambio con una persona.

Como complemento, se pueden usar una extensión de auditoría como `pgaudit` o columnas y tablas de auditoría dentro de los datos (quién y cuándo modificó cada registro).

## 6. Conclusión

El incidente se simuló correctamente: `app_ventas` modificó el RFC del cliente 3 y el cambio quedó guardado en la tabla, pero la bitácora no conserva la sentencia. Solo se encontraron los eventos de conexión y desconexión de la sesión, sin información suficiente para saber qué se hizo ni quién estuvo detrás de la cuenta.

Los privilegios de la Unidad II funcionaron como estaban diseñados: permitieron una operación autorizada. Su función es controlar el acceso, no dejar evidencia de lo ocurrido.

La auditoría no puede configurarse después para eventos que ya sucedieron. Lo que no se registró en su momento no puede reconstruirse, por lo que el registro de sentencias, un prefijo con usuario y origen, y la conservación de las bitácoras deben estar activos antes de que ocurra un incidente.