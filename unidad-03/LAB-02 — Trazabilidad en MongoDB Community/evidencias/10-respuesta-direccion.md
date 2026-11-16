# Evidencia 10 — Respuesta a Dirección

Respondo solo con la evidencia de este laboratorio. Cuando no la hay, lo digo así: "No hay evidencia con esta edición". Todas las horas están en UTC (hora de Culiacán = UTC − 7).

## 1. ¿Quién cambió el RFC de María García?

**Actividad 2 (perfilador apagado):** No hay evidencia con esta edición. El perfilador estaba en nivel 0 y `system.profile` tenía 0 documentos. La bitácora de `mongod` no contiene el `updateOne` ni el valor nuevo (0 coincidencias). Solo muestra que la cuenta `app_ventas` se autenticó a las 05:22:38 con la aplicación `app-ventas-web`. Que esa sesión haya hecho el cambio es algo que deduzco por la hora, no algo que la bitácora demuestre.

**Actividad 3 (perfilador en nivel 2):** El perfilador registró el `update` como hecho por la cuenta `app_ventas@comercial`. Esto identifica una cuenta de aplicación, no una persona: cualquiera que use esa cuenta aparecería igual.

## 2. ¿Cuándo y desde qué aplicación?

**Actividad 2:** No hay evidencia con esta edición de cuándo se ejecutó la operación. Solo hay eventos de conexión a las 05:22:38 (22:22:38 en Culiacán) con `appName: app-ventas-web`.

**Actividad 3:** El `update` quedó registrado el 2026-11-13 a las 05:29:40.271 (22:29:40 en Culiacán), desde el cliente `127.0.0.1` y con `appName: app-ventas-web`. Ese `appName` lo escribe el propio cliente en la cadena de conexión, por lo que no es prueba fiable de qué aplicación fue.

## 3. ¿Qué valor tenía antes?

**Actividad 2:** No hay evidencia con esta edición. Sé que era `GAMA780912GHI` solo porque consulté la colección directamente antes del cambio. Eso es una consulta del estado, no un rastro del servidor.

**Actividad 3:** No hay evidencia con esta edición. El `update` del perfilador solo trae el valor nuevo (`GAMA780912XYZ`). Sé que antes era `GAMA780912XXX` solo porque lo cambié yo mismo en la Actividad 2 y lo tenía anotado; el perfilador no guarda el valor anterior.

## 4. ¿Cambió alguien los privilegios de `app_ventas`?

**Sí cambiaron, pero no se puede saber quién.**

- Lo que sí está demostrado: la instantánea de las 05:51:08 muestra a `app_ventas` solo con `readWrite`, y la de las 05:51:50 muestra `readWrite` y `dbAdmin`. Entonces se agregó `dbAdmin` en `comercial`, entre esas dos horas.
- Quién lo agregó: No hay evidencia con esta edición. `tomada_por` en la instantánea indica quién tomó la instantánea, no quién cambió el rol. El perfilador y la bitácora dieron 0 coincidencias para `grantRoles`.
- Cuándo exactamente: No hay evidencia con esta edición. Solo sé que fue dentro de esa ventana de 42 segundos.
- Limitación adicional: en el perfilador hay un comando de `admin` sobre `comercial.system.profile` a las 05:51:38, dentro de esa ventana. No lo atribuyo al cambio de privilegios, porque no trae el comando ni su contenido.
- La revocación del rol tampoco quedó registrada ni tiene una instantánea posterior; el cambio lo comprobé después con `getUsers()`.

## Resumen para Dirección

Con MongoDB Community pudimos saber **qué** cambió y **cuándo ocurrió aproximadamente**, siempre que el perfilador estuviera activo, pero no **quién** (solo la cuenta, no la persona) ni el valor anterior. Los cambios de privilegios no dejaron rastro en ninguna fuente, y solo los detecté con instantáneas que armé yo. La auditoría nativa existe en Enterprise/Atlas, pero no la practiqué. Si se necesita atribuir cambios de privilegios, hay que evaluar esa opción.