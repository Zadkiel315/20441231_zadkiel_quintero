# Evidencia 03 — Perfilador (nivel 2)

## 1. Activar el perfilador

Con el usuario `admin`, entrando a la base `comercial`, activé el nivel 2 (registra todas las operaciones):

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.setProfilingLevel(2)'
```
```
{ was: 0, slowms: 100, sampleRate: 1, ok: 1 }
```

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.getProfilingStatus()'
```
```
{ was: 2, slowms: 100, sampleRate: 1, ok: 1 }
```

**Qué significa:** `setProfilingLevel` devuelve en `was` el nivel **anterior** (0, apagado). La segunda llamada, `getProfilingStatus`, ya muestra el nivel vigente: 2.

## 2. Operaciones de la aplicación

Con el usuario `app_ventas` (`appName=app-ventas-web`) ejecuté una consulta, una actualización y una eliminación:

```bash
docker exec dba-u3-mongo mongosh "mongodb://app_ventas:<REDACTED>@127.0.0.1:27017/comercial?appName=app-ventas-web" --quiet --eval 'db.clientes.find({ ciudad: "Culiacán" }, { nombre: 1, ciudad: 1 }).toArray(); db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XYZ" } }); db.clientes.deleteOne({ _id: 2 });'
```
```
{ acknowledged: true, deletedCount: 1 }
```

**Qué significa:** la salida solo muestra el resultado de la última instrucción (`deleteOne`), porque `--eval` imprime lo último que se evalúa. Las tres operaciones se ejecutaron, y lo comprobé en la sección 4.

## 3. Consulta al perfilador

Con `admin` consulté `system.profile`:

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.system.profile.find({ ns: "comercial.clientes" }, { op: 1, ns: 1, command: 1, user: 1, client: 1, appName: 1, ts: 1, millis: 1, nreturned: 1, docsExamined: 1, nModified: 1, ndeleted: 1 }).sort({ ts: 1 }).toArray()'
```
```
[
  {
    op: 'query',
    ns: 'comercial.clientes',
    command: {
      find: 'clientes',
      filter: { ciudad: 'Culiacán' },
      projection: { nombre: 1, ciudad: 1 },
      lsid: { id: UUID('387fcfb6-700b-4bef-bcb9-51701efd97ec') },
      '$db': 'comercial'
    },
    docsExamined: 5,
    nreturned: 3,
    millis: 0,
    ts: ISODate('2026-11-13T05:29:40.267Z'),
    client: '127.0.0.1',
    appName: 'app-ventas-web',
    user: 'app_ventas@comercial'
  },
  {
    op: 'update',
    ns: 'comercial.clientes',
    command: {
      q: { _id: 3 },
      u: { '$set': { rfc: 'GAMA780912XYZ' } },
      multi: false,
      upsert: false
    },
    docsExamined: 1,
    nModified: 1,
    millis: 0,
    ts: ISODate('2026-11-13T05:29:40.271Z'),
    client: '127.0.0.1',
    appName: 'app-ventas-web',
    user: 'app_ventas@comercial'
  },
  {
    op: 'remove',
    ns: 'comercial.clientes',
    command: { q: { _id: 2 }, limit: 1 },
    docsExamined: 1,
    ndeleted: 1,
    millis: 0,
    ts: ISODate('2026-11-13T05:29:40.275Z'),
    client: '127.0.0.1',
    appName: 'app-ventas-web',
    user: 'app_ventas@comercial'
  }
]
```

## 4. Estado final de los datos

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval 'db.clientes.find({}, { nombre: 1, rfc: 1 }).toArray()'
```
```
[
  { _id: 1, nombre: 'Ana López', rfc: 'LOAA850315ABC' },
  { _id: 3, nombre: 'María García', rfc: 'GAMA780912XYZ' },
  { _id: 4, nombre: 'Luis Torres', rfc: 'TOLU920201JKL' },
  { _id: 5, nombre: 'Laura Sánchez', rfc: 'SALA880525MNO' }
]
```

**Qué significa:** ya no está Carlos Pérez (`_id: 2`) y el RFC de María es `GAMA780912XYZ`. Los tres documentos del perfilador coinciden con lo que realmente pasó en los datos.

## 5. Interpretación (tabla 9.1)

Todas las horas son del 2026-11-13, en UTC (22:29:40 hora de Culiacán).

| # | op | Usuario | Cliente | Aplicación | Momento (UTC) | Qué hizo | Documentos afectados |
|---|---|---|---|---|---|---|---|
| 1 | query | app_ventas@comercial | 127.0.0.1 | app-ventas-web | 05:29:40.267 | Buscó clientes con `ciudad: "Culiacán"` y pidió solo `nombre` y `ciudad` | 5 examinados, 3 devueltos |
| 2 | update | app_ventas@comercial | 127.0.0.1 | app-ventas-web | 05:29:40.271 | Cambió el RFC del cliente `_id: 3` a `GAMA780912XYZ` con `$set` | 1 examinado, 1 modificado |
| 3 | remove | app_ventas@comercial | 127.0.0.1 | app-ventas-web | 05:29:40.275 | Borró el cliente `_id: 2` | 1 examinado, 1 eliminado |

**Qué significa:** las tres operaciones ocurrieron en solo 8 milisegundos, una detrás de otra, y las tres traen usuario, origen y aplicación. Con eso ya puedo contestar "quién, cuándo y desde qué aplicación", cosa que en la Actividad 2 era imposible. Todas duraron 0 ms.

## 6. Preguntas

**1. ¿Puedo saber cuál era el RFC antes del cambio con la información de `system.profile`?**

**No.** El documento `update` solo trae `u: { '$set': { rfc: 'GAMA780912XYZ' } }`, o sea el valor **nuevo**. El perfilador registra qué se pidió hacer, no cómo estaba el dato antes. El RFC anterior (`GAMA780912XXX`) solo lo sé porque yo mismo lo había cambiado en la Actividad 2 y lo tengo anotado; el perfilador no lo guarda.

**2. ¿Puedo saber qué datos tenía el documento eliminado?**

**No.** El documento `remove` solo trae el filtro `q: { _id: 2 }` y `limit: 1`, y `ndeleted: 1`. Sé que se borró un documento con `_id: 2`, pero no su nombre, correo, RFC ni ningún otro campo. Si no hay respaldo, esa información se pierde.

**3. A diferencia de `log_statement = 'mod'` en PostgreSQL, el nivel 2 sí registró la consulta. ¿Qué ventaja y qué riesgo tiene eso?**

- **Ventaja:** queda rastro de las lecturas, no solo de los cambios. Sirve para saber quién consultó datos, y ayuda a detectar accesos raros o consultas lentas.
- **Riesgo:** el `command` guarda los filtros completos. Si alguien busca por RFC, correo o teléfono, esos datos personales quedan guardados en `system.profile`, en texto claro. Además el nivel 2 registra todo, así que puede bajar el rendimiento, consume disco y, como la colección es de solo 1 MB, la evidencia útil se sobrescribe rápido.

**4. ¿Por qué el campo `user` incluye `@comercial`?**

Porque en MongoDB un usuario se identifica con **nombre + base donde se creó**. `app_ventas` se creó en la base `comercial`, así que su identidad completa es `app_ventas@comercial`. Podría existir otro `app_ventas` creado en otra base y sería un usuario distinto. Por eso el perfilador guarda el nombre completo.

## 7. Conclusión

Con el nivel 2 sí quedó registrada la actividad de `app_ventas`: operación, colección, usuario, cliente, aplicación y hora. Esto es trazabilidad que no existía en la Actividad 2. Pero tiene límites: no guarda el valor anterior de lo modificado ni el contenido de lo eliminado, no identifica a la persona detrás de la cuenta, y el `appName` lo declara el propio cliente. Por eso el perfilador es una herramienta de desempeño que aporta trazabilidad parcial, no una auditoría de seguridad.