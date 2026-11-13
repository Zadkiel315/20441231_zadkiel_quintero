# Evidencia 08 — Conservación: exportar antes de perder

## 1. Estado antes de reiniciar

Con `admin` revisé tres cosas antes de reiniciar el contenedor:

```js
db.getProfilingStatus()
```
```
{
  was: 1,
  slowms: 100,
  sampleRate: 1,
  filter: { op: { '$in': [ 'insert', 'remove', 'update' ] } },
  note: 'When a filter expression is set, slowms and sampleRate are not used for profiling and slow-query log lines.',
  ok: 1
}
```

```js
db.system.profile.countDocuments()
```
```
2
```

```js
db.adminCommand({ getLog: "global" }).log.length
```
```
638
```

## 2. Exportar system.profile

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'EJSON.stringify(db.system.profile.find({}, { op: 1, ns: 1, user: 1, client: 1, appName: 1, ts: 1, "command.q": 1, "command.u": 1 }).toArray(), null, 2)' > evidencias/system-profile.json
```

Contenido exportado:

```json
[
  {
    "op": "update",
    "ns": "comercial.clientes",
    "command": { "q": { "_id": 1 }, "u": { "$set": { "telefono": "6670000000" } } },
    "ts": { "$date": "2026-11-13T05:34:28.702Z" },
    "client": "127.0.0.1",
    "appName": "app-ventas-web",
    "user": "app_ventas@comercial"
  },
  {
    "op": "command",
    "ns": "comercial.system.profile",
    "command": {},
    "ts": { "$date": "2026-11-13T05:51:38.955Z" },
    "client": "127.0.0.1",
    "appName": "mongosh 2.14.2",
    "user": "admin@admin"
  }
]
```

(El JSON real está formateado en más líneas; aquí lo compacté para que se lea mejor.)

**Qué significa:** hay 2 documentos. El primero es el `update` del teléfono de la Actividad 4, hecho por `app_ventas`. El segundo es un comando de `admin` sobre `comercial.system.profile` a las 05:51:38 UTC; cae justo cuando activé el nivel 2 en la Actividad 7, así que casi seguro es la propia llamada `setProfilingLevel(2)`. Este documento no contiene el `grantRolesToUser`. Los documentos de las Actividades 2 y 3 ya no están, porque en la Actividad 4 borré `system.profile` (esa evidencia quedó copiada en las evidencias 02 y 03).

## 3. Exportar la bitácora

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.adminCommand({ getLog: "global" }).log.join("\n")' > evidencias/bitacora-mongod.log
```

```bash
wc -l evidencias/bitacora-mongod.log
```
```
1360 evidencias/bitacora-mongod.log
```

```bash
grep -c '^{"t"' evidencias/bitacora-mongod.log
```
```
680
```

**Qué significa:** `wc -l` cuenta líneas de texto, no eventos, y dio 1360, que es más de lo que `getLog` puede devolver (1024). Por eso conté los eventos con `grep` por las líneas que empiezan con `{"t"`: son 680 eventos. Es más que los 638 que vi antes del export porque entre las dos consultas corrí más comandos, y cada conexión genera eventos nuevos. Cada evento ocupa más de una línea en el archivo, por eso `wc -l` da casi el doble.

Además exporté la bitácora completa del contenedor, que guarda más historia que `getLog`:

```bash
docker logs dba-u3-mongo > evidencias/docker-logs-completo.log 2>&1
```

## 4. Revisión de contraseñas

```bash
grep -c "Practica_2026" evidencias/system-profile.json evidencias/bitacora-mongod.log evidencias/docker-logs-completo.log
```
```
evidencias/system-profile.json:0
evidencias/bitacora-mongod.log:0
evidencias/docker-logs-completo.log:0
```

**Qué significa:** ninguno de los tres archivos contiene las contraseñas de práctica, así que se pueden subir al repositorio.

## 5. Hashes SHA-256

```bash
cd evidencias
sha256sum system-profile.json bitacora-mongod.log docker-logs-completo.log > hashes.sha256
cat hashes.sha256
```
```
1ff6108613adcdf9e142a473a38d63c69bbb8215effdf33ec71289840d35bf6c  system-profile.json
d6da9e207a385c54a6c140a2b989521e32e8ec78c9496e9c4d274fa008cabd4b  bitacora-mongod.log
ebd3faa3c55c712796896d28d1864ee4554ade694bf00994abea969029d07e62  docker-logs-completo.log
```

**Qué significa:** el hash es una huella de cada archivo. Si alguien lo modifica después, aunque sea una coma, el hash cambia, y así se puede demostrar que la evidencia no se alteró desde que la exporté. Esto solo prueba integridad desde ese momento, no que el contenido original sea auténtico.

## 6. Reinicio: qué se pierde y qué no

```bash
docker restart dba-u3-mongo
```

Comparé lo mismo que antes:

| Qué | Antes del reinicio | Después del reinicio |
|---|---|---|
| Perfilador (`getProfilingStatus`) | nivel 1 con filtro | **nivel 0** (`was: 0`) |
| Documentos en `system.profile` | 2 | **2** (siguen ahí) |
| Eventos en `getLog` | 638 | **111** |

```
{ was: 0, slowms: 100, sampleRate: 1, ok: 1 }
2
111
```

**Qué significa:** el reinicio apagó el perfilador sin que nadie lo pidiera y vació casi toda la memoria de la bitácora, pero los documentos ya guardados en `system.profile` sobrevivieron. Desde el reinicio ya no se registra ninguna operación, y nada avisa de eso. Los 111 eventos que hay ahora son del arranque nuevo.

## 7. Configuración permanente (no aplicada)

La guía dice que es opcional. No la apliqué porque en mi contenedor implicaría montar un `mongod.conf` y recrear el contenedor, y recrearlo borraría los usuarios y los datos. Lo que resolvería es este fragmento de configuración:

```yaml
security:
  authorization: enabled
systemLog:
  destination: file
  path: <ruta del archivo de bitácora>
  logAppend: true
operationProfiling:
  mode: all
```

| Opción | Efecto |
|---|---|
| `systemLog.destination: file` y `systemLog.path` | La bitácora se escribe en un archivo y sobrevive a los reinicios |
| `systemLog.logAppend: true` | Al reiniciar agrega al final en vez de reemplazar el archivo |
| `operationProfiling.mode` | `off`, `slowOp` o `all`; equivale a los niveles 0, 1 y 2, para todas las bases y desde el arranque |

Con eso el perfilador no volvería a nivel 0 tras un reinicio, y la bitácora quedaría en un archivo. El modo `all` tiene costo de rendimiento y de disco.

## 8. Preguntas

**1. Menciona tres formas en que la evidencia del perfilador o de la bitácora puede perderse sin que nadie la borre deliberadamente.**

- **`system.profile` se sobrescribe sola:** es una colección limitada de 1 MB, y al llenarse reemplaza los documentos más antiguos.
- **Un reinicio del servidor:** vacía la memoria de `getLog` (lo vi: de 638 a 111 eventos) y regresa el perfilador a nivel 0, así que deja de registrar sin avisar. En mi caso también se me apagó el Codespace por inactividad.
- **Límites de la bitácora y del contenedor:** `getLog` solo guarda los últimos 1024 eventos, y los de `docker logs` desaparecen si se elimina el contenedor. En una instalación con archivo, la rotación de bitácoras también puede borrar historia.

**2. ¿Por qué el tamaño de 1 MB de `system.profile` es un problema de conservación y no solo de espacio?**

Porque la evidencia desaparece sola, sin aviso y sin que nadie la borre, y lo que se pierde primero es lo más antiguo, que justo puede ser lo del incidente que se investiga tarde. Con el nivel 2 y consultas frecuentes se llena rápido. No es un tema de que falte disco, sino de que no se puede confiar en que el rastro siga ahí cuando se necesite.

**3. ¿Por qué `getLog` sirve para interpretar pero no para conservar?**

Es una ventana en memoria con solo los 1024 eventos más recientes. Sirve para consultar y filtrar de forma cómoda desde mongosh, como hice en las Actividades 5 y 6. Pero se vacía al reiniciar y no es un archivo que se pueda resguardar, comparar o protegerse con un hash, así que hay que exportarlo antes de perderlo.

## 9. Conclusión

La evidencia de Community es frágil: el perfilador se apaga solo al reiniciar, `system.profile` se sobrescribe y `getLog` se vacía. La exportación con hash sirve para conservar lo que había en un momento dado, pero no resuelve el problema de fondo, que se resuelve con configuración permanente (`systemLog` a archivo, `operationProfiling` desde el arranque) y con exportaciones periódicas.