# Evidencia 07 — Cambios de privilegios: control compensatorio

## 1. Primera instantánea (antes del cambio)

Con `admin`, en una sola sesión de mongosh, definí una función `instantanea()` que guarda en `auditoria.instantaneas_privilegios` la fecha, quién la tomó y los usuarios con sus roles (es el mismo `insertOne` de la guía):

```js
function instantanea() {
  return db.getSiblingDB("auditoria").instantaneas_privilegios.insertOne({
    momento: new Date(),
    tomada_por: db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers,
    usuarios: db.getUsers().users.map(u => ({ user: u.user, db: u.db, roles: u.roles }))
  })
}
instantanea()
```
```
{
  acknowledged: true,
  insertedId: ObjectId('6af6a54c7364e392383242e3')
}
```

## 2. Activar nivel 2 y otorgar el rol

```js
db.setProfilingLevel(2)
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
db.getProfilingStatus()
```
```
{
  was: 2,
  slowms: 100,
  sampleRate: 1,
  filter: { op: { '$in': [ 'insert', 'remove', 'update' ] } },
  note: 'When a filter expression is set, slowms and sampleRate are not used for profiling and slow-query log lines.',
  ok: 1
}
```

```js
db.grantRolesToUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])
```
```
{ ok: 1 }
```

**Qué significa:** `app_ventas` recibió el rol extra `dbAdmin`. Ojo: aunque el nivel ya es 2, el `filter` de la Actividad 4 sigue apareciendo en el estado, porque `setProfilingLevel(2)` no lo quitó. Lo anoto como limitación en la sección 6.

## 3. Búsqueda de evidencia del cambio

```js
db.system.profile.countDocuments({ "command.grantRolesToUser": { $exists: true } })
```
```
0
```

```js
bitacora().filter(e => JSON.stringify(e).includes("grantRoles")).length
```
```
0
```

**Qué significa:** ni el perfilador ni la bitácora de `mongod` tienen rastro del `grantRolesToUser`. No hay evidencia de quién otorgó el rol, ni cuándo, ni desde dónde.

## 4. Segunda instantánea y comparación

```js
instantanea()
```
```
{
  acknowledged: true,
  insertedId: ObjectId('6af6a5767364e392383242e4')
}
```

```js
db.getSiblingDB("auditoria").instantaneas_privilegios.find({}, { _id: 0 }).sort({ momento: 1 }).toArray()
```
```
[
  {
    momento: ISODate('2026-11-13T05:51:08.622Z'),
    tomada_por: [ { user: 'admin', db: 'admin' } ],
    usuarios: [
      {
        user: 'app_ventas',
        db: 'comercial',
        roles: [ { role: 'readWrite', db: 'comercial' } ]
      }
    ]
  },
  {
    momento: ISODate('2026-11-13T05:51:50.413Z'),
    tomada_por: [ { user: 'admin', db: 'admin' } ],
    usuarios: [
      {
        user: 'app_ventas',
        db: 'comercial',
        roles: [
          { role: 'dbAdmin', db: 'comercial' },
          { role: 'readWrite', db: 'comercial' }
        ]
      }
    ]
  }
]
```

| Pregunta | ¿La instantánea responde? | Con qué |
|---|---|---|
| ¿Cambiaron los privilegios de `app_ventas`? | **Sí** | Los roles de la primera y la segunda instantánea son distintos |
| ¿Qué rol se agregó? | **Sí** | Apareció `dbAdmin` en `comercial` |
| ¿Quién lo agregó? | **No** | `tomada_por` dice quién tomó la instantánea, no quién cambió el rol |
| ¿Cuándo exactamente? | **No** | Solo sé que ocurrió entre 05:51:08 y 05:51:50 UTC (42 segundos) |

## 5. Revertir y restablecer el filtro

```js
db.revokeRolesFromUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])
```
```
{ ok: 1 }
```

```js
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })
```
```
{
  was: 2,
  slowms: 100,
  sampleRate: 1,
  filter: { op: { '$in': [ 'insert', 'remove', 'update' ] } },
  note: 'When a filter expression is set, slowms and sampleRate are not used for profiling and slow-query log lines.',
  ok: 1
}
```

Verifiqué que todo quedó como antes:

```js
db.getUsers().users.map(u => ({ user: u.user, roles: u.roles }))
```
```
[
  {
    user: 'app_ventas',
    roles: [ { role: 'readWrite', db: 'comercial' } ]
  }
]
```

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

**Qué significa:** `app_ventas` volvió a tener solo `readWrite` y el perfilador quedó en nivel 1 con el filtro de la Actividad 4. Tampoco quedó registrado en la bitácora ni en el perfilador el `revokeRolesFromUser` (no lo busqué, pero es el mismo tipo de comando).

## 6. Limitaciones que noté

- **En nivel 2 el perfilador sí registró un comando de `admin` sobre `system.profile`, pero no el `grantRolesToUser`.** No pude determinar por qué. Lo firme es que ni el perfilador ni la bitácora de `mongod` me dieron autor ni hora del cambio de privilegios.
- **La instantánea solo vio a `app_ventas`.** `db.getUsers()` lista los usuarios de la base activa (`comercial`). `admin` vive en la base `admin`, así que si alguien cambiara sus roles, esta instantánea no lo detectaría. Un control completo tendría que recorrer también la base `admin`.
- **La instantánea solo detecta, no atribuye.** Dice que algo cambió y qué, pero no quién ni cuándo.

## 7. Preguntas

**1. ¿Por qué un cambio de privilegios es uno de los eventos auditables más importantes?**

Porque quien consigue más permisos puede leer, modificar o borrar casi todo, y hasta quitar los controles que lo vigilan (como apagar el perfilador). Es el paso previo de casi cualquier abuso. Si no se registra quién dio los permisos y cuándo, un acceso de más puede quedarse meses sin que nadie lo note. Aquí `app_ventas` pasó de poder leer y escribir datos a poder administrar la base, y ni el perfilador ni la bitácora lo registraron.

**2. ¿Con qué frecuencia tomaría instantáneas? ¿Qué factores influyen?**

Dependería del riesgo. Para un sistema sensible, tomaría una instantánea frecuente (cada hora, por ejemplo) y otra siempre antes y después de cualquier ventana de cambios planeada. Para uno menos crítico, una diaria. Lo que influye:

- Qué tan sensibles son los datos.
- Cuántas veces cambian los roles normalmente.
- Cuánto tiempo sin saber qué pasó se está dispuesto a aceptar: la instantánea solo dice "ocurrió entre estas dos horas", así que entre más seguidas, más corta es esa ventana.
- El costo de guardarlas y de revisarlas, porque una instantánea que nadie compara no sirve.

**3. ¿Quién debería poder escribir en `auditoria.instantaneas_privilegios`?**

Una cuenta dedicada, con permiso solo para insertar en esa colección y nada más. No debería ser `app_ventas`, y de preferencia tampoco quien administra los privilegios, porque esa persona podría borrar o alterar la instantánea que delata su cambio. Los demás deberían tener, como mucho, permiso de lectura. En este laboratorio la escribió `admin` (`root`), que puede hacer todo, y por eso no es un control confiable frente a un administrador malintencionado.

**4. Redacta en tres líneas cómo comunicaría esta limitación a Dirección.**

1. Con la edición Community de MongoDB podemos detectar que los privilegios de la aplicación cambiaron y qué rol se agregó, comparando instantáneas periódicas.
2. No podemos saber quién hizo el cambio ni la hora exacta, porque Community no tiene auditoría nativa y ni el perfilador ni la bitácora registraron la operación.
3. Las instantáneas son un control compensatorio que reduce el riesgo, no sustituyen la auditoría nativa de Enterprise o Atlas; si se requiere atribución, hay que evaluar esa opción.

## 8. Conclusión

El cambio de privilegios fue invisible para el perfilador y para la bitácora de `mongod`. Las instantáneas permitieron saber que el cambio ocurrió y cuál fue, pero no quién lo hizo ni cuándo exactamente. Es un control compensatorio útil, con límites claros (solo ve la base donde se consulta, depende de la frecuencia y de quién puede escribir en la colección), y no equivale a la auditoría nativa de Enterprise y Atlas, que no está disponible en Community.