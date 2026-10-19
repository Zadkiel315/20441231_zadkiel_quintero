# Actividad 10 — Crear una política mínima de protección de claves

## Objetivo

Proponer algunas reglas para cuidar las claves criptográficas y evitar que otras personas puedan usarlas sin permiso.

## Política de protección de claves

1. **Generación:** Crear las claves con herramientas seguras para que sean difíciles de adivinar.
2. **Almacenamiento:** Guardar las claves en un lugar seguro, separado del código y los archivos SQL.
3. **Acceso:** Dar acceso a las claves solamente a las personas que las necesiten.
4. **Rotación:** Cambiar las claves de vez en cuando o si existe la sospecha de que alguien las consiguió.
5. **Respaldo:** Tener copias de seguridad protegidas para no perder las claves importantes.
6. **Revocación:** Desactivar una clave cuando ya no se necesite o cuando se sospeche que fue robada.
7. **Exposición accidental:** Si una clave se publica por error, cambiarla y revisar si alguien pudo utilizarla.
8. **Eliminación:** Borrar las claves de forma segura cuando ya no se vayan a utilizar.
9. **Uso de las claves:** No compartirlas por mensajes o archivos sin protección.

## Conclusión

Con esta actividad entendí que las claves son importantes porque permiten proteger información. Por eso, no basta con crear una clave difícil de adivinar, también hay que guardarla bien y tener cuidado con quién puede utilizarla.


# Verificacion Final

### 1. Credenciales

**¿Una contraseña debe cifrarse o protegerse mediante un mecanismo de derivación de claves para contraseñas?**

Debe guardarse usando un hash seguro, como bcrypt, para que no se pueda ver la contraseña original directamente.

### 2. Datos sensibles

**¿Qué diferencia existe entre enmascaramiento, seudonimización y cifrado?**

- **Enmascaramiento:** oculta parte de un dato, como mostrar solo algunos caracteres de un correo.
- **Seudonimización:** cambia los datos que identifican a una persona por otros valores, pero todavía podría identificarse con información adicional.
- **Cifrado:** convierte la información en algo que no se puede leer sin la clave correcta.

### 3. Comunicaciones

**¿Qué problema resuelve TLS?**

Protege la información que se envía entre el cliente y el servidor para que otras personas no puedan leerla fácilmente si interceptan la conexión. También ayuda a comprobar la identidad del servidor cuando se configura correctamente.

### 4. Claves

**¿Dónde debería almacenarse una clave criptográfica en un entorno real?**

En un lugar seguro, como un sistema especializado para guardar claves, donde solo puedan acceder las personas autorizadas.

### 5. Repositorio

**¿Es correcto subir una contraseña o clave real a GitLab aunque el repositorio sea privado?**

No.

Aunque el repositorio sea privado, sigue siendo peligroso subir contraseñas o claves reales, porque podrían quedar expuestas o llegar a manos de alguien que no debería tener acceso.