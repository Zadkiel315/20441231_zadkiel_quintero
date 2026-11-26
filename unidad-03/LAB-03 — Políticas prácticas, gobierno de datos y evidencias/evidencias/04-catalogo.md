# Actividad 4 — Catalogo minimo de datos

## Objetivo

Obtener informacion tecnica de las tablas y vistas de PostgreSQL e integrar los conjuntos de datos identificados en MongoDB para conocer sus responsables, clasificacion y finalidad.

## 1. Inventario tecnico de PostgreSQL

Se consultaron las tablas de la base de datos `comercial`. Tambien se revisaron las vistas disponibles en los esquemas que no pertenecen al sistema.

### Tablas identificadas

| Esquema | Tabla | Propietario tecnico | Filas estimadas | Tamaño |
|---|---|---|---:|---|
| auditoria | cambios_clientes | postgres | 10 | 32 kB |
| gobierno | solicitudes_cambio | postgres | No medido | No medido |
| public | clientes | postgres | 7 | 24 kB |

### Vista identificada

| Esquema | Vista | Propietario tecnico | Finalidad |
|---|---|---|---|
| dba | bitacora | postgres | Consultar los registros de actividad y sentencias de PostgreSQL |

Las consultas confirmaron que las tablas pertenecen tecnicamente al usuario `postgres` y que `dba.bitacora` es una vista. El propietario tecnico no necesariamente es el propietario organizacional de los datos.

## 2. Catalogo de datos

| ID | Conjunto de datos | Motor | Ubicacion | Propietario | Custodio | Clasificacion | Datos personales | Finalidad | Conservacion | Diccionario |
|---|---|---|---|---|---|---|---|---|---|---|
| CAT-01 | Clientes | PostgreSQL 18.6 | comercial.public.clientes | Gerencia Comercial | DBA | Confidencial | Si | Administrar informacion y contacto de clientes | Segun POL-03 | diccionario-clientes.csv |
| CAT-02 | Auditoria de clientes | PostgreSQL 18.6 | comercial.auditoria.cambios_clientes | Auditoria Interna | DBA | Confidencial | Si | Registrar cambios realizados a los datos de clientes | Segun POL-03 | Sin diccionario independiente |
| CAT-03 | Solicitudes de cambio | PostgreSQL 18.6 | comercial.gobierno.solicitudes_cambio | Comite de cambios | DBA | Interno | Puede contener datos personales | Registrar solicitudes, responsables y autorizaciones de cambios | Segun POL-03 | Comentarios de tabla |
| CAT-04 | Bitacora de PostgreSQL | PostgreSQL 18.6 | comercial.dba.bitacora (vista) | Seguridad de la Informacion | DBA | Confidencial | Puede contener datos personales | Consultar actividad y sentencias registradas en PostgreSQL | Segun POL-03 | No aplica |
| CAT-05 | Clientes (tienda) | MongoDB 7 Community | comercial.clientes | Gerencia Comercial | Administrador MongoDB | Confidencial | Si | Administrar informacion de clientes en MongoDB | Segun POL-03 | No disponible |
| CAT-06 | Perfilador de operaciones | MongoDB 7 Community | comercial.system.profile | Seguridad de la Informacion | Administrador MongoDB | Confidencial | Puede contener datos personales | Registrar operaciones del perfilador y apoyar el analisis de rendimiento | Segun POL-03 | No aplica |

**Nota sobre el inventario:** Los objetos de PostgreSQL fueron verificados mediante consultas a `pg_tables` y `pg_views`. Los conjuntos de datos de MongoDB se identificaron mediante las evidencias generadas en LAB-02, especialmente `evidencias/E6-mongodb/09-comparacion.md` y `evidencias/E6-mongodb/system-profile.json`. La ubicacion fisica y el estado actual del contenedor de MongoDB no se verificaron en esta actividad.

Los propietarios organizacionales, custodios, clasificaciones y periodos de conservacion son propuestas de gobierno de datos para este laboratorio; no representan permisos tecnicos ni politicas institucionales formalmente aprobadas.

## 3. Preguntas

### 1. ¿Por que CAT-02 y CAT-06 contienen datos personales aunque su proposito sea la auditoria?

Porque al registrar operaciones tambien pueden guardar informacion relacionada con los clientes, como RFC, nombres o filtros utilizados en las consultas. Aunque su finalidad sea auditar, siguen manejando informacion personal y por eso necesitan proteccion.

### 2. ¿Que pasa si CAT-01 y CAT-05 tienen propietarios distintos y el RFC de un cliente difiere entre ambos motores?

Puede haber problemas porque no se sabria cual RFC es el correcto. Tambien podria provocar errores en facturacion o duplicacion de informacion. Por eso es importante definir un responsable que autorice las correcciones y mantener los datos sincronizados entre los dos motores.

### 3. ¿Que informacion del catalogo cambia con mas frecuencia y quien debe actualizarla?

La cantidad de registros, el tamaño de las tablas, la ubicacion tecnica y los custodios pueden cambiar con el tiempo. El DBA o administrador de cada motor debe actualizar la informacion tecnica, mientras que los propietarios de los datos deben revisar la finalidad, clasificacion y reglas de negocio.

## Conclusion

Con esta actividad se obtuvo un inventario tecnico de PostgreSQL y se integro informacion de MongoDB a partir de las evidencias del laboratorio anterior. Se identificaron tablas, una vista y colecciones de ambos motores. Tambien se observo que el propietario tecnico de un objeto no necesariamente es el responsable organizacional de los datos.

