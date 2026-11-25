# Actividad 4 — Catalogo minimo de datos

## Objetivo

Obtener informacion tecnica de las tablas de PostgreSQL e integrar los datos con el inventario de MongoDB para identificar los conjuntos de datos, sus responsables y su finalidad.

## 1. Inventario tecnico de PostgreSQL

Se ejecuto `ANALYZE` para actualizar las estadisticas y despues se consultaron las tablas de la base de datos `comercial`.

| Esquema | Tabla | Propietario tecnico | Filas estimadas | Tamaño |
|---|---|---|---:|---|
| auditoria | cambios_clientes | postgres | 10 | 32 kB |
| public | clientes | postgres | 7 | 24 kB |

Se observa que ambas tablas pertenecen tecnicamente al usuario `postgres`. Sin embargo, el propietario organizacional de los datos de clientes es Gerencia Comercial.

## 2. Catalogo de datos

| ID | Conjunto de datos | Motor | Ubicacion | Propietario | Custodio | Clasificacion | Contiene datos personales | Finalidad | Conservacion | Diccionario |
|---|---|---|---|---|---|---|---|---|---|---|
| CAT-01 | Clientes | PostgreSQL 18.6 | localhost / comercial / public.clientes | Gerencia Comercial | DBA | Confidencial | Si | Administrar informacion y contacto de clientes | Segun politica de conservacion de la organizacion | diccionario-clientes.csv |
| CAT-02 | Auditoria de clientes | PostgreSQL 18.6 | localhost / comercial / auditoria.cambios_clientes | Auditoria Interna | DBA | Confidencial | Si | Registrar cambios realizados a los datos de clientes | Segun politica de conservacion de auditoria | Pendiente |
| CAT-03 | Registro de cambios | PostgreSQL 18.6 | Pendiente / comercial / gobierno.solicitudes_cambio | Pendiente | DBA | Pendiente | Puede contener datos personales | Registrar solicitudes y autorizaciones de cambios | Pendiente | Pendiente |
| CAT-04 | Clientes (tienda) | MongoDB 7 | Pendiente / comercial / clientes | Gerencia Comercial | Administrador MongoDB | Confidencial | Si | Administrar informacion de clientes en MongoDB | Segun politica de conservacion de la organizacion | Pendiente |
| CAT-05 | Perfilado | MongoDB 7 | Pendiente / comercial / system.profile | Seguridad de la Informacion | Administrador MongoDB | Confidencial | Si | Registrar operaciones y apoyar el analisis de rendimiento y auditoria | Segun politica de conservacion de auditoria | Pendiente |

**Nota:** Los responsables y periodos de conservacion son propuestas de gobierno de datos. Los datos tecnicos de MongoDB y las ubicaciones de sus servidores quedan pendientes de verificar. CAT-03 se completara en la Actividad 7.

## 3. Preguntas

### 1. ¿Por que CAT-02 y CAT-05 contienen datos personales aunque su proposito sea la auditoria?

Porque al registrar operaciones tambien pueden guardar informacion relacionada con los clientes, como RFC, nombres, correos o filtros utilizados en las consultas. Aunque su finalidad sea auditar, siguen manejando informacion personal y por eso necesitan proteccion.

### 2. ¿Que pasa si CAT-01 y CAT-04 tienen propietarios distintos y el RFC de un cliente difiere entre ambos motores?

Puede haber problemas porque no se sabria cual RFC es el correcto. Tambien podria provocar errores en facturacion o duplicacion de informacion. Por eso es importante definir un responsable que autorice las correcciones y mantener los datos sincronizados entre los dos motores.

### 3. ¿Que informacion del catalogo cambia con mas frecuencia y quien debe actualizarla?

La cantidad de registros, el tamaño de las tablas, la ubicacion tecnica y los custodios pueden cambiar con el tiempo. El DBA o administrador de cada motor debe actualizar la informacion tecnica, mientras que los propietarios de los datos deben revisar la finalidad, clasificacion y reglas de negocio.

## Conclusion

Con esta actividad se obtuvo un inventario tecnico de PostgreSQL y se comenzo a integrar el catalogo de datos. Tambien se identifico que el propietario tecnico de una tabla no necesariamente es el responsable de los datos dentro de la organizacion.