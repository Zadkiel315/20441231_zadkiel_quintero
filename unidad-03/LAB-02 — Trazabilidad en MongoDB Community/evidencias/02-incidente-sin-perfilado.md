# Evidencia 02 — El incidente sin perfilado

## 1. Estado inicial

Antes de simular el incidente revisé el perfilador y el RFC de María García (`_id: 3`), con el usuario `admin`.

```js
db.getProfilingStatus()
```
```
{ was: 0, slowms: 100, sampleRate: 1, ok: 1 }
```

```js
db.clientes.find({ _id: 3 }, { nombre: 1, rfc: 1 }).toArray()
```
```
[ { _id: 3, nombre: 'María García', rfc: 'GAMA780912GHI' } ]
```

**Qué significa:** `was: 0` quiere decir que el perfilador está apagado, o sea que MongoDB no guarda nada de las operaciones. El RFC original es `GAMA780912GHI`.

## 2. Simulación del cambio

Con el usuario `app_ventas` (la app de la tienda), conectándome con `appName=app-ventas-web`, cambié el RFC:

```bash
docker exec dba-u3-mongo mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XXX" } })'
```
```
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
```

**Qué significa:** `modifiedCount: 1`, el cambio sí se hizo. El RFC pasó de `GAMA780912GHI` a `GAMA780912XXX`. Ocurrió el 2026-11-13 a las 05:22:38 UTC (22:22:38 hora de Culiacán).

Nota: antes intenté correr `mongosh` directo en la terminal de Codespaces y salió `command not found`. Ese intento no llegó al servidor y no cambió nada; el `mongosh` está dentro del contenedor, por eso uso `docker exec`.

## 3. Búsqueda de evidencia

Con `admin` busqué rastros en las dos fuentes que tiene Community. Primero definí la función auxiliar:

```js
function bitacora() {
  return db.adminCommand({ getLog: "global" }).log.map(l => JSON.parse(l))
}
```

```js
db.system.profile.countDocuments()
```
```
0
```

```js
bitacora().filter(e => JSON.stringify(e).includes("GAMA780912XXX")).length
```
```
0
```

```js
bitacora().filter(e => JSON.stringify(e).includes("app-ventas-web")).map(e => ({ t: e.t, c: e.c, ctx: e.ctx, msg: e.msg }))
```

Resultado resumido (el filtro devolvió 16 eventos, en dos grupos):

| Hora (UTC) | Conexión | Componente | Mensaje |
|---|---|---|---|
| 05:20:28.957 | conn1 | NETWORK | client metadata |
| 05:20:28.957 | conn1 | ACCESS | Connection not authenticating |
| 05:20:28.976 | conn2 | NETWORK | client metadata |
| 05:20:28.988 | conn2 | ACCESS | Successfully authenticated |
| 05:20:29.457 – 05:20:29.468 | conn3, conn4 | NETWORK / ACCESS | client metadata + Successfully authenticated |
| 05:22:38.312 | conn13 | NETWORK | client metadata |
| 05:22:38.312 | conn13 | ACCESS | Connection not authenticating |
| 05:22:38.318 | conn14 | NETWORK | client metadata |
| 05:22:38.325 | conn14 | ACCESS | Successfully authenticated |
| 05:22:38.447 – 05:22:38.456 | conn15, conn16 | NETWORK / ACCESS | client metadata + Successfully authenticated |

**Qué significa:**

- `system.profile` tiene 0 documentos, porque el perfilador estaba apagado.
- El nuevo RFC (`GAMA780912XXX`) no aparece en ninguna línea de la bitácora, o sea que la operación no quedó registrada.
- Lo único que aparece son eventos de conexión. El primer grupo (conn1 a conn4, 05:20:28) es mi verificación de `countDocuments()` con `app_ventas`. El segundo grupo (conn13 a conn16, 05:22:38) es el `updateOne` del RFC. Los dos tienen el mismo patrón, porque ambos usaron el `appName=app-ventas-web`.
- La bitácora empieza a las 05:20 porque el contenedor se reinició (el Codespace se había apagado) y la memoria de `getLog` empieza de cero cada vez que arranca el servidor.

## 4. Preguntas

**1. ¿Puedo demostrar qué cambió? ¿Y quién se conectó a esa hora?**

Qué cambió: **no**. Ni el perfilador ni la bitácora guardaron el `updateOne`, ni el campo, ni el valor viejo, ni el nuevo. Solo sé que cambió porque lo vi directo en la colección.

Quién se conectó: **en parte sí**. La bitácora muestra que a las 05:22:38 UTC hubo una sesión con la aplicación `app-ventas-web` que se autenticó. Pero eso solo prueba que hubo una conexión, no que esa conexión hizo el cambio; lo deduzco por la coincidencia de hora. Además, `app_ventas` es una cuenta de aplicación, no una persona, y el `appName` lo escribe el cliente al conectarse, así que cualquiera podría poner el mismo.

**2. ¿Por qué mongosh abre varias conexiones (conn13, conn14, ...) para una sola instrucción? ¿Cuál es la que se autentica?**

Aunque yo mando una sola instrucción, mongosh abre varias conexiones al servidor. Una es de monitoreo: la usa el driver para vigilar el estado del servidor, por eso aparece como `Connection not authenticating` (conn13). Las otras son conexiones de trabajo del driver, que sí se autentican con el usuario y la contraseña de la cadena (conn14, conn15 y conn16, con `Successfully authenticated`). Con lo que muestra la bitácora no puedo saber cuál de las tres ejecutó el `updateOne`, solo que las tres se autenticaron.

## 5. Conclusión

El cambio del RFC ocurrió, pero con el perfilador apagado no quedó evidencia de la operación. Solo hay eventos de conexión y autenticación. Los privilegios de la Unidad II permitieron el cambio, porque `app_ventas` tiene `readWrite` y está autorizada, pero los privilegios solo controlan **quién puede** hacer algo, no dejan registro de **quién lo hizo**. Lo que no se registró antes del incidente no se puede reconstruir después, por eso el registro hay que activarlo antes.