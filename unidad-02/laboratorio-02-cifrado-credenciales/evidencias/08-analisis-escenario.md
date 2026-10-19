# Actividad 8 — Analizar un escenario de seguridad

## Pregunta 1. ¿Cuáles son los principales riesgos?

Los principales riesgos son que la información de la empresa pueda quedar expuesta si alguien consigue acceder a la base de datos o a sus archivos.

- **Contraseñas en texto claro:** si alguien obtiene la información, puede ver las contraseñas directamente.
- **RFC en texto claro:** los datos personales de los clientes quedan expuestos.
- **Conexiones sin validar correctamente el servidor:** existe el riesgo de conectarse a un servidor que no sea el correcto, aunque se utilice una conexión cifrada.
- **Claves criptográficas en archivos SQL:** otras personas podrían encontrar las claves y utilizarlas para acceder a información protegida.
- **Respaldos sin protección:** si alguien consigue un respaldo, podría consultar la información que contiene.

## Pregunta 2. ¿Qué mecanismo utilizarías para cada elemento?

| **Elemento** | **Mecanismo de protección** |
|---|---|
| Nombre | Controlar quién puede consultar los datos y limitar los permisos. |
| Correo electrónico | Limitar el acceso y cifrarlo si el nivel de riesgo lo requiere. |
| Contraseña | Guardarla mediante un hash seguro, como `bcrypt`, nunca en texto claro. |
| RFC | Cifrarlo con una herramienta como `pgcrypto` y proteger la clave. |
| Información financiera | Cifrar los datos sensibles y limitar quién puede consultarlos. |
| Claves criptográficas | Guardarlas en un lugar seguro, separado de los archivos SQL, y limitar su acceso. |
| Conexiones a la base de datos | Utilizar TLS y validar correctamente el certificado y el nombre del servidor. |
| Respaldos | Cifrarlos y controlar quién puede acceder a ellos. |

## Pregunta 3. ¿Cuál de los problemas consideras más crítico y por qué?

Considero que guardar las contraseñas en texto claro es uno de los problemas más críticos, porque si alguien obtiene acceso a la base de datos puede verlas directamente. Además, si una persona utiliza la misma contraseña en otros sitios, también podrían quedar en riesgo sus otras cuentas.

También me parece muy grave guardar las claves criptográficas en archivos SQL, porque alguien podría utilizarlas para descifrar información que se supone que está protegida.

## Pregunta 4. ¿Tener correctamente configurados los usuarios y permisos elimina estos riesgos? Justifica tu respuesta.

No, porque aunque los usuarios y permisos estén bien configurados, todavía existen otros riesgos. Por ejemplo, las contraseñas pueden quedar expuestas si se guardan en texto claro, y los respaldos pueden ser leídos si no están cifrados.

Por eso, además de controlar quién entra a la base de datos, también es importante cifrar la información sensible, proteger las claves, asegurar las conexiones y cuidar los respaldos.

## Conclusión

Con este escenario entendí que no basta con tener usuarios y permisos bien configurados para mantener segura una base de datos. También hay que proteger la información almacenada, las conexiones y los respaldos. Si se descuida alguno de estos puntos, la información de la empresa y de sus clientes puede quedar expuesta.