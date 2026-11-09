# Evidencia 05 — Accesos exitosos y fallidos

## 1. Generación de intentos de conexión

Desde una terminal de PowerShell se realizaron tres conexiones por red a `127.0.0.1`:

```powershell
psql "postgresql://app_ventas:incorrecta@127.0.0.1/comercial" -c "SELECT 1"
psql "postgresql://usuario_inexistente:x@127.0.0.1/comercial" -c "SELECT 1"
psql "postgresql://app_ventas:<contraseña>@127.0.0.1/comercial?application_name=app-ventas-web" -c "SELECT count(*) FROM clientes"
```

| Intento | Usuario | Contraseña | Resultado en el cliente |
|---|---|---|---|
| 1 | app_ventas | incorrecta | `FATAL: la autentificación password falló para el usuario «app_ventas»` |
| 2 | usuario_inexistente | x | `FATAL: la autentificación password falló para el usuario «usuario_inexistente»` |
| 3 | app_ventas | correcta | Conexión exitosa; `SELECT count(*) FROM clientes` devolvió 5 |

**Interpretación:**

Para el cliente, el intento con un usuario que existe pero con contraseña incorrecta y el intento con un usuario que no existe producen exactamente el mismo mensaje. Desde fuera no se puede distinguir una situación de la otra.

## 2. Búsqueda de los intentos en la bitácora

Se filtró la bitácora por la dirección del cliente:

```sql
SELECT linea FROM dba.bitacora WHERE linea LIKE '%client=127.0.0.1%' ORDER BY num;
```

**Resultado:** 10 filas.

| Intento | Hora | PID | Evento registrado |
|---|---|---|---|
| 1 | 18:56:59.296 | 7468 | Conexión recibida desde `127.0.0.1`, puerto 59720 (usuario aún desconocido) |
| 1 | 18:56:59.330 | 7468 | `FATAL`: falló la autenticación por contraseña del usuario `app_ventas` |
| 1 | 18:56:59.330 | 7468 | `DETALLE`: la conexión coincidió con `pg_hba.conf` línea 115 (`host all all 127.0.0.1/32 scram-sha-256`) |
| 2 | 18:57:57.331 | 12744 | Conexión recibida desde `127.0.0.1`, puerto 59896 (usuario aún desconocido) |
| 2 | 18:57:57.363 | 12744 | `FATAL`: falló la autenticación por contraseña del usuario `usuario_inexistente` |
| 2 | 18:57:57.363 | 12744 | `DETALLE`: no existe el rol `usuario_inexistente` |
| 3 | 18:58:14.836 | 15908 | Conexión recibida desde `127.0.0.1`, puerto 59908 (usuario aún desconocido) |
| 3 | 18:58:14.868 | 15908 | Conexión autenticada: `app_ventas`, método `scram-sha-256`, `pg_hba.conf` línea 115 |
| 3 | 18:58:14.868 | 15908 | Conexión autorizada: usuario `app_ventas`, base `comercial`, aplicación `app-ventas-web` |
| 3 | 18:58:14.978 | 15908 | Desconexión: duración de sesión 0:00:00.180, `app=app-ventas-web` |

**Interpretación:**

- Cada intento tiene su propio PID, lo que permite separar los eventos de cada conexión.
- Los dos intentos fallidos quedaron registrados con la regla de `pg_hba.conf` que se aplicó y, en el segundo, con el motivo real (el rol no existe).
- La conexión exitosa muestra la secuencia completa: recibida, autenticada, autorizada y desconectada.
- El `SELECT count(*) FROM clientes` del intento 3 **no aparece**, porque `log_statement = 'ddl'` solo registra sentencias de definición. La bitácora prueba que `app_ventas` entró, pero no lo que consultó.

## 3. Lectura de una línea campo por campo

Línea analizada:

```
2026-11-08 18:56:59.330 CST [7468] user=app_ventas db=comercial app=[desconocido] client=127.0.0.1 FATAL:  la autentificación password falló para el usuario «app_ventas»
```

| Campo | Valor | Significado |
|---|---|---|
| Fecha y hora | 2026-11-08 18:56:59.330 CST | Momento del evento, con milisegundos, en la zona horaria del servidor |
| PID | 7468 | Proceso del servidor que atendió esa conexión; identifica todas las líneas del mismo intento |
| Usuario | app_ventas | Nombre de usuario que el cliente indicó al conectarse (no está verificado, porque la autenticación falló) |
| Base de datos | comercial | Base de datos que el cliente solicitó |
| Aplicación | [desconocido] | Nombre de aplicación; todavía no se había aplicado a la sesión |
| Cliente | 127.0.0.1 | Dirección desde la que llegó la conexión |
| Severidad | FATAL | La sesión se terminó por el error |
| Mensaje | la autentificación password falló | Motivo del rechazo |
| Regla aplicada | pg_hba.conf línea 115 | Regla de autenticación que coincidió con la conexión |

## 4. Preguntas

**Pregunta 1. La bitácora registra el usuario `app_ventas` en el intento fallido. ¿Eso prueba que la aplicación de ventas intentó entrar? ¿Qué prueba realmente?**

No lo prueba. El nombre de usuario lo escribe el cliente al conectarse y el servidor lo registra tal como llega, sin verificarlo, porque la autenticación falló. Cualquier persona o programa que conozca o adivine el nombre `app_ventas` puede presentarlo.

Lo que se demuestra realmente es que, a las 18:56:59, alguien se conectó desde `127.0.0.1` presentando el usuario `app_ventas` y una contraseña que no era válida. No se puede saber si fue la aplicación con una contraseña desactualizada, un error de escritura o una persona probando contraseñas.

**Pregunta 2. ¿Qué información adicional registra PostgreSQL cuando el rol no existe? ¿Por qué aparece en la bitácora y no en el mensaje que recibe el cliente?**

Registra una línea `DETALLE` con el motivo real: `No existe el rol «usuario_inexistente»`. El intento con un usuario que sí existe pero contraseña incorrecta no incluye ese motivo.

No se le envía al cliente porque permitiría **enumerar usuarios**: un atacante podría probar nombres hasta ver cuáles producen el mensaje "el rol no existe" y quedarse con los nombres válidos para atacar sus contraseñas. Por eso el cliente siempre recibe el mismo mensaje genérico (como se observó en la sección 1), y el detalle queda solo en la bitácora, a la que solo accede el administrador.

**Pregunta 3. ¿Por qué `app=[desconocido]` en el intento fallido, pero `app=app-ventas-web` en la desconexión?**

El nombre de aplicación solo se aplica a la sesión cuando la conexión ya fue autenticada y autorizada. En el intento fallido la sesión se terminó antes de llegar a ese punto, por lo que el prefijo no tiene ese dato.

Esto también se observa en el intento exitoso: las líneas de "conexión recibida", "autenticada" y "autorizada" muestran `app=[desconocido]` en el prefijo, aunque la línea de autorización sí menciona `nombre_de_aplicación=app-ventas-web` en el texto del mensaje. El prefijo recién muestra `app=app-ventas-web` en la desconexión, cuando la sesión ya estaba establecida.

**Pregunta 4. ¿Qué patrón de varias líneas te haría sospechar de un ataque de fuerza bruta? Escribe la consulta que contaría los intentos fallidos por usuario.**

Patrones sospechosos:

- Muchas líneas `FATAL` de autenticación fallida en poco tiempo, desde la misma dirección de cliente.
- Muchos intentos contra el mismo usuario, que indican adivinación de la contraseña.
- Intentos contra muchos nombres de usuario distintos, y líneas `DETALLE` de "no existe el rol", que indican búsqueda de usuarios válidos.
- Intervalos regulares y muy cortos entre intentos (automatización), y puertos de origen consecutivos.
- Una conexión exitosa justo después de una serie de fallos.

Consulta para contar los intentos fallidos por usuario y cliente (el filtro `FATAL:.*password` funciona con el mensaje en español o en inglés):

```sql
SELECT substring(linea FROM 'user=(\S+)')   AS usuario,
       substring(linea FROM 'client=(\S+)') AS cliente,
       count(*)                             AS intentos_fallidos,
       min(substring(linea FROM '^\S+ \S+')) AS primer_intento,
       max(substring(linea FROM '^\S+ \S+')) AS ultimo_intento
FROM dba.bitacora
WHERE linea ~ 'FATAL:.*password'
GROUP BY 1, 2
ORDER BY intentos_fallidos DESC;
```

Un usuario o cliente con muchos intentos en un intervalo de segundos o minutos sería candidato a investigarse.

## 5. Conclusión

Con la configuración de la actividad 4, la bitácora permite reconstruir los accesos: cada intento queda con hora, PID, usuario, base de datos, cliente, regla de `pg_hba.conf` aplicada y, en los fallidos, el motivo del rechazo. Esto resuelve parte de lo que faltaba en el incidente de la actividad 3.

Sin embargo, la evidencia tiene límites. El usuario registrado en un intento fallido es el que declaró el cliente y no prueba quién fue; el nombre de aplicación solo aparece cuando la sesión se establece; y las sentencias `SELECT` no se registran con `log_statement = 'ddl'`. Tampoco se puede distinguir entre un error legítimo y un ataque a partir de un solo evento, por lo que el análisis debe basarse en patrones y en el conteo de intentos.