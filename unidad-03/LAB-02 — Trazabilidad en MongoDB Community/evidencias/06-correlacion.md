# Evidencia 06 — Correlacionar un cambio de configuración con su autor

## 1. Cambios de configuración del perfilador

Con `admin` busqué en la bitácora los eventos `Profiler settings changed` (función `bitacora()` definida en la sesión):

```js
bitacora().filter(e => e.msg === "Profiler settings changed").map(e => ({ t: e.t, ctx: e.ctx, msg: e.msg, attr: e.attr }))
```
```
[
  {
    t: { '$date': '2026-11-13T05:28:59.413+00:00' },
    ctx: 'conn23',
    msg: 'Profiler settings changed',
    attr: {
      from: { level: 0, slowms: 100, sampleRate: 1 },
      to: { level: 2, slowms: 100, sampleRate: 1 },
      db: 'comercial'
    }
  },
  {
    t: { '$date': '2026-11-13T05:34:06.266+00:00' },
    ctx: 'conn43',
    msg: 'Profiler settings changed',
    attr: {
      from: { level: 2, slowms: 100, sampleRate: 1 },
      to: { level: 0, slowms: 100, sampleRate: 1 },
      db: 'comercial'
    }
  },
  {
    t: { '$date': '2026-11-13T05:34:14.860+00:00' },
    ctx: 'conn51',
    msg: 'Profiler settings changed',
    attr: {
      from: { level: 0, slowms: 100, sampleRate: 1 },
      to: {
        level: 1,
        slowms: 100,
        sampleRate: 1,
        filter: { op: { '$in': [ 'insert', 'remove', 'update' ] } }
      },
      db: 'comercial'
    }
  }
]
```

**Qué significa:** hay tres cambios, que corresponden a las Actividades 3 y 4: 0→2 (activar nivel 2), 2→0 (apagar) y 0→1 con filtro. Ninguna línea dice qué usuario lo hizo, pero todas traen el `ctx` (la conexión).

## 2. Buscar la autenticación de cada conexión

Para el último cambio (el del filtro, `conn51`):

```js
bitacora().filter(e => e.ctx === "conn51" && e.msg === "Successfully authenticated").map(e => ({ t: e.t, ctx: e.ctx, user: e.attr.user, db: e.attr.db, client: e.attr.client }))
```
```
[
  {
    t: { '$date': '2026-11-13T05:34:14.692+00:00' },
    ctx: 'conn51',
    user: 'admin',
    db: 'admin',
    client: '127.0.0.1:40094'
  }
]
```

Hice lo mismo con los otros dos cambios:

```js
bitacora().filter(e => e.ctx === "conn23" && e.msg === "Successfully authenticated").map(e => ({ t: e.t, ctx: e.ctx, user: e.attr.user, db: e.attr.db, client: e.attr.client }))
```
```
[
  {
    t: { '$date': '2026-11-13T05:28:59.251+00:00' },
    ctx: 'conn23',
    user: 'admin',
    db: 'admin',
    client: '127.0.0.1:50774'
  }
]
```

```js
bitacora().filter(e => e.ctx === "conn43" && e.msg === "Successfully authenticated").map(e => ({ t: e.t, ctx: e.ctx, user: e.attr.user, db: e.attr.db, client: e.attr.client }))
```
```
[
  {
    t: { '$date': '2026-11-13T05:34:06.136+00:00' },
    ctx: 'conn43',
    user: 'admin',
    db: 'admin',
    client: '127.0.0.1:45928'
  }
]
```

Nota: la primera vez que busqué dejé `connXX` sin sustituir y devolvió `[]`; después usé los `ctx` reales. También pegué por error un comando de terminal dentro de mongosh y dio `SyntaxError`, sin ejecutar nada.

## 3. Resumen de la correlación

| Hora del cambio (UTC) | ctx | Cambio | Autenticación en ese ctx | Usuario |
|---|---|---|---|---|
| 05:28:59.413 | conn23 | nivel 0 → 2 | 05:28:59.251 | admin (base admin) |
| 05:34:06.266 | conn43 | nivel 2 → 0 | 05:34:06.136 | admin (base admin) |
| 05:34:14.860 | conn51 | nivel 0 → 1 con filtro | 05:34:14.692 | admin (base admin) |

**Qué significa:** en los tres casos la autenticación ocurrió una fracción de segundo antes del cambio, en la misma conexión y desde `127.0.0.1`.

## 4. Preguntas

**1. ¿Qué usuario cambió la configuración del perfilador? ¿Qué dos eventos lo demuestran?**

Lo cambió `admin`. Lo demuestran dos eventos unidos por el mismo `ctx` (`conn51` para el último cambio):

- `Profiler settings changed` (05:34:14.860): dice **qué** pasó (de nivel 0 a nivel 1 con filtro en `comercial`), pero no el usuario.
- `Successfully authenticated` (05:34:14.692): dice **quién** se autenticó en esa conexión (`admin`, base `admin`).

Ninguno por separado basta; juntos, por el `ctx`, atribuyen el cambio.

**2. ¿Qué condición debe cumplirse para que esta correlación sea válida?**

Que los dos eventos pertenezcan al **mismo arranque del servidor**. Los números `connN` se reinician cuando el servidor se reinicia, así que después de un reinicio `conn51` puede ser otra conexión distinta, y podría atribuirle el cambio al usuario equivocado. Además, los dos eventos deben seguir en la memoria de `getLog`, que solo guarda los 1024 más recientes y se vacía al reiniciar. Por eso hay que exportar la bitácora (Actividad 8) y comparar también las horas, no solo el `ctx`.

**3. ¿Por qué es relevante que quede registrado un cambio de configuración del propio mecanismo de registro?**

Porque quien quiera ocultar lo que hace puede apagar o reducir el perfilado antes. Si ese cambio queda registrado, al menos se sabe cuándo se dejó de registrar, quién lo hizo y qué periodo no tiene evidencia confiable. Aquí se ve claro: de 05:34:06 a 05:34:14 el perfilador estuvo en nivel 0 y no se habría guardado nada. Sin ese registro, un hueco en la evidencia pasaría desapercibido.

## 5. Conclusión

Con el `ctx` pude atribuir los tres cambios de configuración del perfilador a `admin`, combinando dos eventos de la bitácora. Funciona, pero depende de que ambos eventos sean del mismo arranque del servidor y sigan en memoria, y solo identifica la cuenta, no a la persona que la usó. Es una correlación manual que nos da trazabilidad parcial, no una auditoría nativa.