# Actividad 5 — Criterio de conservacion de bitacoras

## Objetivo

Proponer un criterio para conservar las bitacoras y registros de auditoria de PostgreSQL y MongoDB, tomando en cuenta su importancia, sensibilidad y los riesgos de perdida observados en los laboratorios anteriores.

## 1. Tabla de conservacion

| Registro | Ubicacion actual | Riesgo de perdida observado | Sensibilidad | Periodo propuesto | Justificacion | Donde se conserva | Quien puede leerlo | Accion al vencer |
|---|---|---|---|---|---|---|---|---|
| Accesos de PostgreSQL | Archivo del colector (`pg_current_logfile()`) | Rotacion del archivo, reinstalacion o recreacion del servidor | Alta | 12 meses | Permite investigar accesos sospechosos y conocer quien se conecto | Archivo externo de auditoria con acceso restringido | DBA y Seguridad de la Informacion | Eliminar de forma segura despues de revisar que no exista una investigacion pendiente |
| Cambios de privilegios y estructura | Archivo del colector | Rotacion del archivo o eliminacion accidental | Alta | 24 meses | Estos cambios pueden afectar la seguridad y los permisos de la base de datos | Repositorio externo de auditoria con acceso restringido | DBA, Seguridad y Auditoria Interna | Eliminar de forma segura cuando termine el periodo y no existan investigaciones pendientes |
| Modificaciones de datos (`log_statement = 'mod'`) | Archivo del colector | Rotacion del archivo y perdida del servidor | Alta | 12 meses | Permite revisar modificaciones realizadas en las tablas | Archivo externo protegido | DBA y Auditoria Interna autorizados | Eliminar despues de verificar que no existan investigaciones pendientes |
| `auditoria.cambios_clientes` | Tabla en `comercial` | Eliminacion de registros, fallas del servidor o modificaciones no autorizadas | Alta | 24 meses | Permite conocer los cambios realizados a la informacion de clientes | Base de datos y exportaciones protegidas de auditoria | Auditoria Interna y DBA autorizado | Aplicar la politica de eliminacion o anonimizar los datos cuando corresponda |
| Bitacora de `mongod` | `systemLog.path` o salida estandar; `getLog` solo en memoria | Reinicio, rotacion o perdida de archivos del servidor | Alta | 12 meses | Ayuda a investigar errores, conexiones y operaciones del servidor | Archivos externos protegidos | Administrador MongoDB y Seguridad | Eliminar de forma segura despues de comprobar que no existan investigaciones pendientes |
| `system.profile` | Coleccion limitada de 1 MB | Se sobrescribe sola | Alta | 30 dias | Sirve para revisar operaciones y consultas recientes, pero puede contener datos personales | Exportacion controlada y protegida cuando sea necesaria | Administrador MongoDB y DBA autorizado | Eliminar las copias vencidas y revisar que no contengan informacion necesaria para investigaciones |
| Instantaneas de privilegios (MongoDB) | `auditoria.instantaneas_privilegios` | Eliminacion de coleccion o perdida de registros | Alta | 24 meses | Permite comparar permisos y detectar cambios no autorizados | Base de datos y exportaciones externas protegidas | Seguridad, Auditoria Interna y Administrador MongoDB | Eliminar de forma segura despues de verificar que no existan investigaciones pendientes |


## 2. Consideraciones encontradas en los laboratorios

En LAB-01 se observo que la bitacora de PostgreSQL puede registrar informacion sensible, incluso contraseñas en texto claro. Por eso no se deben compartir los archivos sin revisar y ocultar primero los secretos.

En LAB-02 se observo que `system.profile` puede registrar informacion de las consultas y que su espacio es limitado, por lo que puede sobrescribir registros anteriores.

Tambien se debe considerar que conservar registros de auditoria puede entrar en conflicto con la eliminacion de datos personales. Por ejemplo, una bitacora puede contener el RFC o correo de una persona. En esos casos se debe revisar si es necesario conservar el dato completo, si puede anonimizarse o si debe eliminarse conforme a la politica aplicable.

## 3. Preguntas

### 1. ¿Por que la bitacora de cambios de privilegios merece mas tiempo de conservacion que la de consultas rutinarias?

Porque los cambios de privilegios pueden permitir accesos no autorizados o modificar la seguridad de toda la base de datos. Tener esos registros durante mas tiempo ayuda a investigar incidentes y conocer quien realizo los cambios. Las consultas rutinarias normalmente tienen menor impacto y pueden revisarse durante un periodo mas corto.

### 2. ¿Que control de integridad aplicaras a las bitacoras exportadas?

Aplicaria un hash SHA-256 a cada archivo exportado. De esta manera se puede comprobar si el archivo fue modificado despues de generarlo. Tambien guardaria el hash junto con el archivo y restringiria los permisos de acceso.

### 3. ¿Que diferencia hay entre conservar una bitacora y respaldar una base de datos?

Conservar una bitacora significa guardar los registros de eventos y operaciones para poder revisarlos posteriormente. En cambio, respaldar una base de datos significa guardar una copia de la informacion para poder recuperarla si ocurre una falla o se pierden los datos.

## 4. Conclusion

Con esta actividad se establecieron periodos propuestos para conservar los diferentes registros de PostgreSQL y MongoDB. Tambien se identifico la importancia de proteger las bitacoras, comprobar su integridad y evitar que la informacion personal se conserve mas tiempo del necesario.