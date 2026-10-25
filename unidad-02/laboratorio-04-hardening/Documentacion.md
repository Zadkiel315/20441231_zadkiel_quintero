### Actividad 1. Identificación de la superficie de ataque

| Elemento | Estado actual | ¿Es necesario? | Riesgo |
|---|---|---|---|
| Puerto PostgreSQL | 5432 | Sí, para permitir las conexiones configuradas | Si queda accesible desde redes no autorizadas, pueden intentar conectarse al servidor. |
| Interfaces de escucha | `*` | Debe escuchar solo en las interfaces necesarias | Puede aceptar conexiones por distintas interfaces de red, según las reglas del sistema y del firewall. |
| Conexiones remotas | Las conexiones observadas utilizan `::1`, que corresponde a la dirección local IPv6 | Solo deben permitirse conexiones remotas autorizadas | Una conexión local no demuestra que el acceso remoto esté restringido. |
| Usuarios administrativos | Se observa el usuario `postgres` en las conexiones de pgAdmin | Sí, para tareas administrativas | Si se utiliza para aplicaciones o tareas cotidianas, aumenta el riesgo por sus privilegios elevados. |
| SSL/TLS | Desactivado (`off`) | Se debe evaluar y habilitar si se requiere proteger conexiones mediante TLS | Las conexiones no tienen cifrado TLS proporcionado por PostgreSQL. |
| Métodos de autenticación | `scram-sha-256` | Sí, debe usarse un método de autenticación seguro | Es necesario revisar también las reglas de acceso y los permisos de cada usuario. |

**¿Por qué conocer la superficie de ataque debe preceder al hardening?**

Porque primero se necesita conocer cómo está configurado el servidor, quién puede conectarse y qué riesgos existen. Así se pueden identificar los puntos débiles y decidir qué cambios son necesarios sin afectar el funcionamiento de la base de datos.