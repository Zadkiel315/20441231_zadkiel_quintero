# Evidencia 01 — Edición de MongoDB y limitación de la auditoría

## 1. Cómo monté el servidor

Mi compu no puede correr MongoDB 7 directo porque tiene un Intel Pentium Silver N5000, que no trae instrucciones AVX (MongoDB 5.0 en adelante las necesita). Entonces usé GitHub Codespaces y levanté el servidor en un contenedor Docker con la imagen oficial `mongo:7`:

```bash
docker run --name dba-u3-mongo -p 27017:27017 -d mongo:7 --auth
```

El `--auth` es lo que activa el control de acceso. Todo lo de esta evidencia lo hice con el usuario `admin` (rol `root`), entrando a la base `comercial` pero autenticándome contra `admin`:

```bash
docker exec dba-u3-mongo mongosh "mongodb://admin:<REDACTED>@127.0.0.1:27017/comercial?authSource=admin" --quiet --eval '...'
```

## 2. Versión del servidor

```js
db.version()
```

```
7.0.48
```

**Qué significa:** tengo MongoDB 7.0.48. La guía muestra 7.0.43, pero solo cambia el número de parche, no afecta nada de las actividades.

## 3. Edición: módulos

```js
db.adminCommand({ buildInfo: 1 }).modules
```

```
[]
```

**Qué significa:** el arreglo `modules` salió vacío. Si fuera Enterprise ahí aparecería `"enterprise"`, así que lo que tengo es **MongoDB Community Edition**. Esto mismo se ve en el log de arranque, en la línea `Build Info`, que también dice `"modules":[]`.

## 4. Configuración con la que arrancó

```js
db.serverCmdLineOpts().parsed
```

```
{ net: { bindIp: '*' }, security: { authorization: 'enabled' } }
```

**Qué significa:**

| Sección | Valor | Qué quiere decir |
|---|---|---|
| `net.bindIp` | `*` | Escucha en todas las interfaces del contenedor |
| `security.authorization` | `enabled` | El control de acceso está activo |
| `systemLog` | No aparece | No configuré archivo de bitácora |
| `operationProfiling` | No aparece | El perfilador no está configurado desde el arranque |
| `auditLog` / `--auditDestination` | No aparece | No hay auditoría nativa configurada |

## 5. A dónde va la bitácora

```bash
docker logs dba-u3-mongo | head -5
```

```
{"t":{"$date":"2026-11-13T03:30:47.945+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"parallel execution pool","numThreads":0,"minThreads":0,"maxThreads":128}}
{"t":{"$date":"2026-11-13T03:30:47.948+00:00"},"s":"I",  "c":"CONTROL",  "id":23285,   "ctx":"main","msg":"Automatically disabling TLS 1.0, to force-enable TLS 1.0 specify --sslDisabledProtocols 'none'"}
{"t":{"$date":"2026-11-13T03:30:47.949+00:00"},"s":"I",  "c":"NETWORK",  "id":4915701, "ctx":"main","msg":"Initialized wire specification","attr":{"spec":{"incomingExternalClient":{"minWireVersion":0,"maxWireVersion":21},"incomingInternalClient":{"minWireVersion":0,"maxWireVersion":21},"outgoing":{"minWireVersion":6,"maxWireVersion":21},"isInternalClient":true}}}
{"t":{"$date":"2026-11-13T03:30:47.949+00:00"},"s":"I",  "c":"NETWORK",  "id":4648601, "ctx":"main","msg":"Implicit TCP FastOpen unavailable. If TCP FastOpen is required, set tcpFastOpenServer, tcpFastOpenClient, and tcpFastOpenQueueSize."}
{"t":{"$date":"2026-11-13T03:30:47.950+00:00"},"s":"I",  "c":"EXECUTOR", "id":11280000,"ctx":"main","msg":"Starting thread pool","attr":{"poolName":"OCSPCache","numThreads":0,"minThreads":0,"maxThreads":8}}
```

**Qué significa:** cada línea es un JSON con `t` (fecha y hora), `s` (severidad), `c` (componente), `id`, `ctx` (contexto), `msg` y `attr`. Salen por la salida estándar del proceso y Docker las agarra y las muestra con `docker logs`.

## 6. Preguntas

**1. ¿Qué edición de MongoDB estoy usando? ¿Qué evidencia lo demuestra?**

Estoy usando **MongoDB Community Edition 7.0.48** (imagen oficial `mongo:7`). Lo comprobé con tres cosas:

- `buildInfo.modules` salió `[]`. En Enterprise traería `"enterprise"`.
- `serverCmdLineOpts().parsed` no muestra ninguna opción de auditoría (`auditLog`, `--auditDestination`).
- La línea `Build Info` del log de arranque también trae `"modules":[]`.

**2. ¿A dónde escribe mi servidor su bitácora? ¿Cómo lo sé?**

A la **salida estándar del proceso** (stdout), y Docker la captura con `docker logs dba-u3-mongo`. Lo sé porque en `serverCmdLineOpts().parsed` no aparece `systemLog.destination` ni `systemLog.path`, así que MongoDB usa lo que trae por defecto, y además `docker logs` sí me muestra las líneas JSON. No hay archivo de bitácora dentro del contenedor a menos que configure `systemLog.path`.

**3. Según REF-U3-04, ¿qué cuatro categorías de eventos registraría la auditoría nativa?**

1. Cambios de esquema (DDL).
2. Eventos de conjuntos de réplicas y clústeres fragmentados.
3. Autenticación y autorización.
4. Operaciones CRUD (para esto hay que poner `auditAuthorizationSuccess: true`).

Los eventos se pueden mandar a la consola, a syslog, a un archivo JSON o a un archivo BSON con `--auditDestination`. Todo esto existe solo en Enterprise y Atlas (M10 o superior), no en Community.

**4. ¿Qué tendría que evaluar una organización antes de licenciar Enterprise o migrar a Atlas solo para tener auditoría?**

- **Costo:** lo que cuesta la licencia de Enterprise o el clúster Atlas M10+, comparado con lo que realmente vale tener auditoría.
- **Si de verdad lo necesitan:** si hay una norma, contrato o política que exija auditoría nativa, o si con trazabilidad parcial les alcanza.
- **Impacto en rendimiento y espacio:** auditar CRUD genera un montón de eventos y se come disco y recursos.
- **Esfuerzo de migrar:** cambiar de edición o de plataforma implica pruebas, ventanas de mantenimiento y capacitar a la gente. En Atlas además se pierde algo de control sobre la infraestructura.
- **Qué eventos necesitan:** definir qué auditar y filtrarlo, para no registrar todo.
- **Alternativas:** ver si un control compensatorio (como instantáneas de privilegios o el perfilador con filtro) cubre el riesgo más barato, y qué riesgo se queda sin cubrir.
- **Dónde se guarda y quién lo lee:** los registros de auditoría tienen que estar protegidos y con acceso controlado.

## 7. Conclusión

Mi servidor es MongoDB 7.0.48 **Community**, con autorización activada y la bitácora saliendo por la salida estándar. La auditoría nativa no existe en esta edición, y lo demostré con `modules: []` y con que no hay ninguna opción de auditoría en la configuración de arranque.

Con Community solo tengo el perfilador y la bitácora del servidor. Los dos dan trazabilidad parcial, pero no son una auditoría de seguridad. En las siguientes actividades voy a ver qué sí y qué no se puede demostrar con ellos.