# Actividad 2 — Propietarios, custodios y usuarios

## Objetivo

Identificar quién es responsable de los datos, quién se encarga de administrarlos y qué usuarios pueden acceder a ellos. También se definen los responsables de aprobar los accesos y las correcciones.

## Matriz de responsables

| Conjunto de datos | Propietario | Custodio | Usuarios autorizados | Quién aprueba accesos | Quién aprueba correcciones |
|---|---|---|---|---|---|
| `comercial.public.clientes` (PostgreSQL) | Gerencia Comercial | DBA | `app_ventas`, `soporte_ana` | Gerencia Comercial | Gerencia Comercial |
| `auditoria.cambios_clientes` (PostgreSQL) | Auditoría Interna | DBA | Auditoría Interna y personal de seguridad autorizado | Responsable de Auditoría Interna | No se permiten correcciones directas de los registros de auditoría. Cualquier aclaración debe ser aprobada por Auditoría Interna. |
| Bitácora de PostgreSQL | Seguridad de la Información | DBA / Administrador del servidor | Auditoría Interna y personal de seguridad autorizado | Responsable de Seguridad de la Información | No se deben modificar los registros originales. Las aclaraciones deben documentarse por separado. |
| `comercial.clientes` (MongoDB) | Gerencia Comercial | Administrador de MongoDB | Aplicación de ventas y personal de soporte autorizado | Gerencia Comercial | Gerencia Comercial |
| `comercial.system.profile` (MongoDB) | Seguridad de la Información | Administrador de MongoDB | DBA y Auditoría Interna autorizados | Responsable de Seguridad de la Información | No se deben modificar los registros del perfilador. Las aclaraciones deben documentarse por separado. |

## Observaciones de los laboratorios anteriores

En el LAB-01 se identificaron los siguientes permisos en PostgreSQL:

- `app_ventas`: permisos SELECT y UPDATE sobre la tabla `clientes`.
- `soporte_ana`: permiso SELECT sobre la tabla `clientes`.

Esto demuestra que los usuarios tienen diferentes niveles de acceso según sus funciones.

También se observó que la bitácora puede almacenar información sensible, como contraseñas en texto claro. Por esta razón, su lectura debe estar limitada a personal autorizado y se deben proteger los archivos antes de compartirlos.

En el LAB-02 se comprobó que MongoDB Community puede registrar operaciones y filtros que contienen información personal. Por eso, el acceso a `system.profile` también debe estar restringido.

## Preguntas

### 1. ¿Por qué el propietario de `auditoria.cambios_clientes` no debería ser el mismo que opera `clientes`?

Porque si la misma persona o área que modifica los datos también controla su auditoría, podría alterar información y ocultar los cambios realizados.

Lo mejor es separar las responsabilidades. Gerencia Comercial debe ser responsable de los datos de los clientes, mientras que Auditoría Interna debe supervisar los registros de auditoría.

Así se tiene mayor independencia y es más difícil que alguien pueda modificar los datos y ocultar sus propias acciones.

### 2. ¿Quién debería poder leer las bitácoras y la vista `dba.bitacora`? Relaciónalo con lo observado en el LAB-01 (secretos en la bitácora).

Solamente deberían poder leerlas el DBA cuando sea necesario para sus funciones, el personal de Seguridad de la Información y Auditoría Interna cuando necesiten revisar algún evento.

En el LAB-01 observé que la bitácora podía almacenar una contraseña en texto claro. Esto representa un riesgo porque cualquier persona con acceso al archivo podría conocer información confidencial.

Por eso, no se debe permitir que todos los usuarios consulten las bitácoras. También es importante ocultar los secretos antes de exportar los registros y proteger los archivos de evidencia.

### 3. ¿Qué ocurre con la responsabilidad sobre un dato cuando nadie la tiene asignada? Relaciónalo con el problema inicial de la unidad.

Cuando nadie es responsable de un dato, pueden aparecer problemas porque no existe una persona o área que decida quién puede modificarlo, quién puede consultarlo o cómo deben corregirse los errores.

Esto se relaciona con el problema inicial de la unidad, donde se encontraron cambios en los datos sin tener completamente claro quién debía autorizarlos.

Por ejemplo, si aparece un RFC incorrecto, el DBA puede detectarlo, pero si no existe un propietario asignado, nadie sabe quién debe aprobar su corrección.

Por eso es importante establecer propietarios, custodios y usuarios para que cada persona conozca sus responsabilidades.

## Conclusión

En esta actividad se identificó la importancia de separar las responsabilidades sobre los datos.

El propietario decide cómo deben utilizarse los datos, el custodio se encarga de administrarlos y los usuarios solamente deben acceder a la información que necesitan para realizar sus actividades.

También se comprobó que las bitácoras y los registros de auditoría contienen información que debe protegerse, ya que pueden incluir datos personales o información confidencial.

Tener responsables definidos ayuda a evitar cambios sin autorización y permite identificar a quién corresponde tomar cada decisión.