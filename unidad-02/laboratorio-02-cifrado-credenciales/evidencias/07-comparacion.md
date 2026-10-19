# Actividad 7 — Comparar protección en reposo y protección en tránsito

## Objetivo

Identificar cómo se puede proteger la información de una base de datos, tanto cuando está guardada como cuando se está enviando.

## Tabla comparativa

| **Situación** | **Mecanismo apropiado** | **¿Qué protege?** |
|---|---|---|
| Contraseña de usuario | Hash con `bcrypt` | Evita que las contraseñas se guarden directamente y que sea fácil conocerlas si alguien accede a la base de datos. |
| RFC almacenado en una tabla | Cifrado con `pgp_sym_encrypt()` | Hace que el RFC no se pueda leer directamente sin tener la clave correcta. |
| Consulta enviada desde un cliente al servidor | TLS | Protege la información que se envía para que otras personas no puedan leerla fácilmente si interceptan la conexión. |
| Respaldo de una base de datos | Cifrado del respaldo | Evita que cualquiera pueda leer la información si consigue el archivo de respaldo. |
| Clave criptográfica | Guardarla en un lugar seguro | Evita que otras personas obtengan la clave y la usen para acceder a la información protegida. |

## Análisis

Cada caso necesita una forma diferente de protección. Por ejemplo, las contraseñas se guardan con un hash porque no es necesario recuperar la contraseña original. En cambio, un RFC cifrado sí se puede recuperar si se tiene la clave correcta.

TLS sirve para proteger la información mientras se envía entre el cliente y el servidor. El cifrado de respaldos protege los archivos guardados y las claves deben mantenerse en un lugar seguro para evitar que alguien las use sin permiso.

## Conclusión

Con esta actividad entendí que hay diferentes maneras de proteger la información, dependiendo de dónde se encuentre y para qué se utilice. No basta con proteger la base de datos; también hay que cuidar las contraseñas, las conexiones, los respaldos y las claves.