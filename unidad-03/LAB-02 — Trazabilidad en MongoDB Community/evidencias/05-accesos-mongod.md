# Evidencia 05 — Accesos en la bitácora de mongod

## 1. Intentos fallidos

Generé dos intentos de acceso con credenciales malas, a propósito y sin `appName`: uno con contraseña incorrecta de un usuario real y otro con un usuario que no existe.

```bash
docker exec dba-u3-mongo mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
```
```
MongoServerError: Authentication failed.
```

```bash
docker exec dba-u3-mongo mongosh "mongodb://usuario_inexistente:<REDACTED>@127.0.0.1:27017/comercial" --quiet --eval "db.clientes.countDocuments()"
```
```
MongoServerError: Authentication failed.
```

Después generé un acceso exitoso de la aplicación:

```bash
docker exec dba-u3-mongo mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.countDocuments()'
```
```
4
```

**Qué significa:** los dos intentos malos recibieron exactamente el mismo mensaje. El acceso bueno devolvió 4 (ya solo quedan 4 clientes desde la Actividad 3).

## 2. Accesos fallidos en la bitácora

Con `admin` consulté la bitácora (función `bitacora()` definida en la sesión):

```js
bitacora().filter(e => e.c === "ACCESS" && e.msg === "Failed to authenticate").map(e => ({ t: e.t, id: e.id, ctx: e.ctx, user: e.attr.user, client: e.attr.client, error: e.attr.error, result: e.attr.result, app: e.attr.doc.application.name }))
```
```
[
  {
    t: { '$date': '2026-11-13T05:38:25.382+00:00' },
    id: 5286307,
    ctx: 'conn67',
    user: 'app_ventas',
    client: '127.0.0.1:46156',
    error: 'AuthenticationFailed: SCRAM authentication failed, storedKey mismatch',
    result: 18,
    app: 'mongosh 2.14.2'
  },
  {
    t: { '$date': '2026-11-13T05:38:43.630+00:00' },
    id: 5286307,
    ctx: 'conn69',
    user: 'usuario_inexistente',
    client: '127.0.0.1:54428',
    error: 'UserNotFound: Could not find user "usuario_inexistente" for db "comercial"',
    result: 11,
    app: 'mongosh 2.14.2'
  },
  {
    t: { '$date': '2026-11-13T05:38:43.632+00:00' },
    id: 5286307,
    ctx: 'conn69',
    user: 'usuario_inexistente',
    client: '127.0.0.1:54428',
    error: 'UserNotFound: Could not find user "usuario_inexistente" for db "comercial"',
    result: 11,
    app: 'mongosh 2.14.2'
  }
]
```

**Qué significa:** salieron 3 líneas, pero fueron **2 intentos**. El usuario inexistente produjo dos líneas casi idénticas (05:38:43.630 y .632) en la misma conexión `conn69`: una es la autenticación especulativa y la otra la normal. Por eso hay que contar intentos y no líneas.

| Intento | Hora (UTC) | Conexión | Usuario | Origen | Error | result |
|---|---|---|---|---|---|---|
| 1 | 05:38:25 | conn67 | app_ventas | 127.0.0.1:46156 | AuthenticationFailed (storedKey mismatch) | 18 |
| 2 | 05:38:43 | conn69 | usuario_inexistente | 127.0.0.1:54428 | UserNotFound | 11 |

## 3. Último acceso exitoso de la aplicación

```js
bitacora().filter(e => e.msg === "Successfully authenticated" && e.attr.user === "app_ventas").slice(-1).map(e => ({ t: e.t, id: e.id, ctx: e.ctx, client: e.attr.client, result: e.attr.result, app: e.attr.doc.application.name }))
```
```
[
  {
    t: { '$date': '2026-11-13T05:38:50.117+00:00' },
    id: 5286306,
    ctx: 'conn73',
    client: '127.0.0.1:57810',
    result: 0,
    app: 'app-ventas-web'
  }
]
```

**Qué significa:** `app_ventas` se autenticó bien a las 05:38:50 UTC (22:38:50 hora de Culiacán), desde `127.0.0.1:57810`, con la aplicación `app-ventas-web`. El origen aparece con puerto porque es el puerto temporal de esa conexión.

## 4. Preguntas

**1. ¿Qué campo distingue un acceso fallido de uno exitoso?**

El campo más claro es `result`: en el exitoso vale `0` y en los fallidos es distinto de cero (18 y 11). También cambian `msg` (`Successfully authenticated` contra `Failed to authenticate`) y el `id` del mensaje (5286306 para el éxito, 5286307 para el fallo). Los fallidos además traen el campo `error` con la causa.

**2. ¿Qué diferencia hay entre el error de contraseña incorrecta y el de usuario inexistente? ¿Por qué el cliente recibe el mismo mensaje en ambos casos?**

En la bitácora son distintos: con contraseña mala sale `AuthenticationFailed: SCRAM authentication failed, storedKey mismatch` (result 18), o sea que el usuario existe pero la clave no coincide. Con usuario falso sale `UserNotFound: Could not find user ...` (result 11).

Al cliente le llega el mismo `Authentication failed` en ambos casos a propósito. Si el servidor dijera "ese usuario no existe", un atacante podría probar nombres hasta descubrir cuáles son válidos y luego solo atacar sus contraseñas. El detalle real queda solo en la bitácora, que ve el DBA.

**3. ¿Por qué el nombre de la aplicación del intento fallido es `mongosh 2.14.2` y no `app-ventas-web`?**

Porque en los intentos fallidos no puse `?appName=app-ventas-web` en la cadena de conexión. Cuando no se indica, mongosh usa su nombre por defecto, que es `mongosh` con su versión (aquí 2.14.2; en la guía salía 2.10.0 por usar otra versión). Esto también muestra que el `appName` lo declara el cliente, así que no es una prueba confiable de quién se conectó.

## 5. Conclusión

La bitácora de `mongod` sí registra los accesos: quién intentó entrar, desde qué origen, con qué resultado y por qué falló. Eso sirve para detectar intentos sospechosos. Pero solo dice que alguien se autenticó, no qué hizo después, y el origen y la aplicación son datos que declara el cliente. Además, la bitácora en memoria (`getLog`) se vacía al reiniciar, así que hay que exportarla (Actividad 8).