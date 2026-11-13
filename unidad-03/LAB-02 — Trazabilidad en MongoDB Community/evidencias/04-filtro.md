# Evidencia 04 — Reducir el volumen con un filtro

## 1. Aplicar el filtro

El nivel 2 registra todo, incluso lecturas. Para quedarme solo con las modificaciones apagué el perfilador, borré `system.profile` y lo volví a activar en nivel 1 con un filtro. Lo hice con `admin`, en la base `comercial`. La evidencia de la Actividad 3 ya estaba copiada en `03-perfilador.md` antes de borrar.

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.setProfilingLevel(0)'
```
```
{ was: 2, slowms: 100, sampleRate: 1, ok: 1 }
```

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.system.profile.drop()'
```
```
true
```

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })'
```
```
{
  was: 0,
  slowms: 100,
  sampleRate: 1,
  note: 'When a filter expression is set, slowms and sampleRate are not used for profiling and slow-query log lines.',
  ok: 1
}
```

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.getProfilingStatus()'
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

**Qué significa:** el primer `was: 2` es el nivel que tenía antes de apagarlo, y el `was: 0` del tercer comando es el nivel justo antes de poner el filtro. El último comando ya muestra lo vigente: nivel 1 con un filtro que deja pasar solo `insert`, `update` y `remove`. Con un filtro, `slowms` y `sampleRate` ya no se usan (lo dice la nota que devuelve MongoDB).

## 2. Operaciones de la aplicación

Con `app_ventas` (`appName=app-ventas-web`) hice una consulta y una actualización:

```bash
docker exec dba-u3-mongo mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.find({ _id: 1 }).toArray(); db.clientes.updateOne({ _id: 1 }, { $set: { telefono: "6670000000" } })'
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

**Qué significa:** la salida solo muestra el resultado de lo último que se evaluó (el `updateOne`). El `find` también se ejecutó, pero `--eval` no imprime su resultado.

## 3. Consulta al perfilador

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.system.profile.find({}, { op: 1, ns: 1, user: 1, appName: 1, "command.q": 1, "command.u": 1, ts: 1 }).toArray()'
```
```
[
  {
    op: 'update',
    ns: 'comercial.clientes',
    command: { q: { _id: 1 }, u: { '$set': { telefono: '6670000000' } } },
    ts: ISODate('2026-11-13T05:34:28.702Z'),
    appName: 'app-ventas-web',
    user: 'app_ventas@comercial'
  }
]
```

**Qué significa:** solo aparece el `update` (usuario `app_ventas@comercial`, aplicación `app-ventas-web`, 2026-11-13 05:34:28 UTC). La consulta `find` se ejecutó, pero el filtro la dejó fuera.

## 4. Preguntas

**1. ¿Qué perdí de evidencia al aplicar el filtro? ¿Qué gané?**

**Perdí:** el registro de las lecturas (`query`) y de cualquier operación que no sea `insert`, `update` o `remove`. Ya no puedo saber quién consultó datos ni qué buscó. También perdí lo que había en `system.profile` al borrarla, aunque eso ya lo había copiado en la evidencia 03.

**Gané:** menos volumen. `system.profile` es una colección de solo 1 MB que se sobrescribe, así que si solo guardo modificaciones la evidencia importante dura más antes de perderse. También baja el costo de rendimiento y de disco, y quedan guardados menos filtros con datos personales (como un `find` por RFC o correo).

**2. ¿Qué filtro usaría si solo me interesaran operaciones sobre la colección `clientes`?**

Filtraría por el espacio de nombres (`ns`):

```js
db.setProfilingLevel(1, { filter: { ns: "comercial.clientes" } })
```

Si además quisiera solo las modificaciones sobre esa colección, combinaría las dos condiciones:

```js
db.setProfilingLevel(1, { filter: { ns: "comercial.clientes", op: { $in: ["insert", "update", "remove"] } } })
```

## 5. Conclusión

El filtro redujo lo que se guarda: ahora `system.profile` conserva solo las modificaciones. Se gana duración de la evidencia y menos costo, pero se pierde la visibilidad de las lecturas. Es una decisión sobre qué eventos importan más, y sigue sin ser una auditoría de seguridad.