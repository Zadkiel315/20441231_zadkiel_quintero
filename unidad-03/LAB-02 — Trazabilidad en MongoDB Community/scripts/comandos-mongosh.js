// LAB-02 — comandos de mongosh por actividad
// (admin = DBA, app_ventas = la aplicación)


// ===== Preparación =====
// Crea los usuarios y mete los 5 clientes
//use admin
db.createUser({ user: "admin", pwd: "<REDACTED>", roles: ["root"] })
db.auth("admin", "<REDACTED>")

//use comercial
db.createUser({ user: "app_ventas", pwd: "<REDACTED>", roles: [{ role: "readWrite", db: "comercial" }] })

db.clientes.insertMany([
  { _id: 1, nombre: "Ana López", correo: "ana.lopez@example.test", telefono: "6671234567", rfc: "LOAA850315ABC", edad: 41, ciudad: "Culiacán", codigo_postal: "80000" },
  { _id: 2, nombre: "Carlos Pérez", correo: "carlos.perez@example.test", telefono: "6672345678", rfc: "PECA900720DEF", edad: 35, ciudad: "Culiacán", codigo_postal: "80100" },
  { _id: 3, nombre: "María García", correo: "maria.garcia@example.test", telefono: "6673456789", rfc: "GAMA780912GHI", edad: 47, ciudad: "Mazatlán", codigo_postal: "82000" },
  { _id: 4, nombre: "Luis Torres", correo: "luis.torres@example.test", telefono: "6674567890", rfc: "TOLU920201JKL", edad: 34, ciudad: "Los Mochis", codigo_postal: "81200" },
  { _id: 5, nombre: "Laura Sánchez", correo: "laura.sanchez@example.test", telefono: "6675678901", rfc: "SALA880525MNO", edad: 38, ciudad: "Culiacán", codigo_postal: "80200" }
])


// ===== Actividad 1 (admin) =====
// Versión, edición (modules vacío = Community) y configuración de arranque
db.version()
db.adminCommand({ buildInfo: 1 }).modules
db.serverCmdLineOpts().parsed


// ===== Actividad 2 =====
// (admin) Función para leer la bitácora de mongod; se define una vez por sesión
function bitacora() {
  return db.adminCommand({ getLog: "global" }).log.map(l => JSON.parse(l))
}

// (admin) Perfilador apagado y RFC original
db.getProfilingStatus()
db.clientes.find({ _id: 3 }, { nombre: 1, rfc: 1 }).toArray()

// (app_ventas) Cambia el RFC
db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XXX" } })

// (admin) Busca evidencia: debe dar 0, 0 y solo eventos de conexión
db.system.profile.countDocuments()
bitacora().filter(e => JSON.stringify(e).includes("GAMA780912XXX")).length
bitacora().filter(e => JSON.stringify(e).includes("app-ventas-web")).map(e => ({ t: e.t, c: e.c, ctx: e.ctx, msg: e.msg }))


// ===== Actividad 3 =====
// (admin) Activa el perfilador en nivel 2
db.setProfilingLevel(2)
db.getProfilingStatus()

// (app_ventas) Una consulta, una actualización y un borrado
db.clientes.find({ ciudad: "Culiacán" }, { nombre: 1, ciudad: 1 }).toArray()
db.clientes.updateOne({ _id: 3 }, { $set: { rfc: "GAMA780912XYZ" } })
db.clientes.deleteOne({ _id: 2 })

// (admin) Ve qué registró el perfilador y cómo quedaron los datos
db.system.profile.find({ ns: "comercial.clientes" }, { op: 1, ns: 1, command: 1, user: 1, client: 1, appName: 1, ts: 1, millis: 1, nreturned: 1, docsExamined: 1, nModified: 1, ndeleted: 1 }).sort({ ts: 1 }).toArray()
db.clientes.find({}, { nombre: 1, rfc: 1 }).toArray()


// ===== Actividad 4 =====
// (admin) Apaga, borra system.profile y lo vuelve a activar solo para insert/update/remove
db.setProfilingLevel(0)
db.system.profile.drop()
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })
db.getProfilingStatus()

// (app_ventas) Una consulta y una actualización (el filtro solo deja pasar el update)
db.clientes.find({ _id: 1 }).toArray()
db.clientes.updateOne({ _id: 1 }, { $set: { telefono: "6670000000" } })

// (admin) Debe salir un solo documento: el update
db.system.profile.find({}, { op: 1, ns: 1, user: 1, appName: 1, "command.q": 1, "command.u": 1, ts: 1 }).toArray()


// ===== Actividad 5 (admin) =====
// (Los dos intentos fallidos se hacen desde la terminal con credenciales malas)
// Accesos fallidos en la bitácora
bitacora().filter(e => e.c === "ACCESS" && e.msg === "Failed to authenticate").map(e => ({ t: e.t, id: e.id, ctx: e.ctx, user: e.attr.user, client: e.attr.client, error: e.attr.error, result: e.attr.result, app: e.attr.doc.application.name }))

// Último acceso exitoso de app_ventas
bitacora().filter(e => e.msg === "Successfully authenticated" && e.attr.user === "app_ventas").slice(-1).map(e => ({ t: e.t, id: e.id, ctx: e.ctx, client: e.attr.client, result: e.attr.result, app: e.attr.doc.application.name }))


// ===== Actividad 6 (admin) =====
// Cambios de configuración del perfilador (traen ctx, no usuario)
bitacora().filter(e => e.msg === "Profiler settings changed").map(e => ({ t: e.t, ctx: e.ctx, msg: e.msg, attr: e.attr }))

// Quién se autenticó en cada ctx (conn51, conn23 y conn43 en mi caso)
bitacora().filter(e => e.ctx === "conn51" && e.msg === "Successfully authenticated").map(e => ({ t: e.t, ctx: e.ctx, user: e.attr.user, db: e.attr.db, client: e.attr.client }))
bitacora().filter(e => e.ctx === "conn23" && e.msg === "Successfully authenticated").map(e => ({ t: e.t, ctx: e.ctx, user: e.attr.user, db: e.attr.db, client: e.attr.client }))
bitacora().filter(e => e.ctx === "conn43" && e.msg === "Successfully authenticated").map(e => ({ t: e.t, ctx: e.ctx, user: e.attr.user, db: e.attr.db, client: e.attr.client }))


// ===== Actividad 7 (admin) =====
// Función que guarda una instantánea de usuarios y roles
function instantanea() {
  return db.getSiblingDB("auditoria").instantaneas_privilegios.insertOne({
    momento: new Date(),
    tomada_por: db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers,
    usuarios: db.getUsers().users.map(u => ({ user: u.user, db: u.db, roles: u.roles }))
  })
}

// Primera instantánea (antes del cambio)
instantanea()

// Activa nivel 2 y le da dbAdmin a app_ventas
db.setProfilingLevel(2)
db.getProfilingStatus()
db.grantRolesToUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])

// Busca rastro del cambio: debe dar 0 y 0
db.system.profile.countDocuments({ "command.grantRolesToUser": { $exists: true } })
bitacora().filter(e => JSON.stringify(e).includes("grantRoles")).length

// Segunda instantánea y comparación de las dos
instantanea()
db.getSiblingDB("auditoria").instantaneas_privilegios.find({}, { _id: 0 }).sort({ momento: 1 }).toArray()

// Revierte el rol y restablece el filtro
db.revokeRolesFromUser("app_ventas", [{ role: "dbAdmin", db: "comercial" }])
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })

// Comprueba que todo quedó como antes
db.getUsers().users.map(u => ({ user: u.user, roles: u.roles }))
db.getProfilingStatus()


// ===== Actividad 8 (admin) =====
// Estado antes y después de reiniciar (nivel, documentos de system.profile y eventos de getLog)
db.getProfilingStatus()
db.system.profile.countDocuments()
db.adminCommand({ getLog: "global" }).log.length


// ===== Actividad 9 (admin) =====
// Crea una colección de prueba, busca su evento en la bitácora y la borra
db.createCollection("prueba_ddl")
db.adminCommand({ getLog: "global" }).log.filter(l => l.includes("prueba_ddl"))
db.prueba_ddl.drop()


// ===== Re-exportación de system.profile =====
// (admin) Nivel 2 sin filtro
db.setProfilingLevel(0)
db.setProfilingLevel(2)
db.getProfilingStatus()

// (app_ventas) Insert, consulta, update y delete de un cliente temporal
db.clientes.insertOne({ _id: 99, nombre: "Temporal", rfc: "TEMP000000AAA", ciudad: "Culiacán" })
db.clientes.find({ ciudad: "Culiacán" }, { nombre: 1, ciudad: 1 }).toArray()
db.clientes.updateOne({ _id: 99 }, { $set: { rfc: "TEMP000000BBB" } })
db.clientes.deleteOne({ _id: 99 })

// (admin) Restablece el filtro de la Actividad 4
db.setProfilingLevel(1, { filter: { op: { $in: ["insert", "update", "remove"] } } })