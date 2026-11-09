# Evidencia 08 — Errores y operaciones rechazadas

## 1. Preparación del rol `soporte_ana`

El rol `soporte_ana` se había creado sin contraseña, y `pg_hba.conf` exige `scram-sha-256` para las conexiones por red. Con ese rol, el primer intento de conexión fue rechazado en la autenticación (`la autentificación password falló`), antes de poder ejecutar cualquier sentencia.

Para poder simular al analista de soporte, el administrador asignó la contraseña con `\password`, que calcula el resumen SCRAM en el cliente y evita escribir la contraseña dentro de una sentencia SQL:

```
\password soporte_ana
```

## 2. Operación rechazada por falta de privilegios

El analista de soporte intenta borrar un registro, conectándose por red:

```powershell
psql "postgresql://soporte_ana:<contraseña>@127.0.0.1/comercial" -c "DELETE FROM clientes WHERE id = 5"
```

**Resultado:**

```
ERROR:  permiso denegado a la tabla clientes
```

## 3. Operación rechazada por dependencias

El administrador intenta eliminar un rol que todavía tiene privilegios:

```sql
DROP ROLE soporte_ana;
```

**Resultado:**

```
ERROR:  no se puede eliminar el rol «soporte_ana» porque otros objetos dependen de él
DETALLE:  privilegios para tabla clientes
```

## 4. Comprobación de que no hubo daño

```sql
SELECT count(*) FROM clientes;
```

| count |
|---|
| 5 |

**Interpretación:**

La tabla conserva sus 5 registros, por lo que el `DELETE` fue rechazado sin modificar ningún dato.

## 5. Búsqueda de los errores en la bitácora

```sql
SELECT linea FROM dba.bitacora
WHERE linea ~ '(ERROR|SENTENCIA|STATEMENT|DETALLE|DETAIL):  (permiso|permission|privilegios|privileges|no se puede eliminar|cannot be dropped|DELETE|DROP)'
ORDER BY num;
```

El filtro acepta los textos en español y en inglés, porque este servidor escribe sus mensajes en español.

**Resultado:** 8 filas.

| Hora | PID | Usuario | Cliente | Tipo | Contenido |
|---|---|---|---|---|---|
| 19:34:01.007 | 17360 | postgres | ::1 | ERROR | No se puede eliminar el rol `soporte_ana` porque otros objetos dependen de él |
| 19:34:01.007 | 17360 | postgres | ::1 | DETALLE | Privilegios para tabla clientes |
| 19:34:01.007 | 17360 | postgres | ::1 | SENTENCIA | `DROP ROLE soporte_ana;` |
| 19:34:27.218 | 17360 | postgres | ::1 | ERROR | No se puede eliminar el rol `soporte_ana` porque otros objetos dependen de él |
| 19:34:27.218 | 17360 | postgres | ::1 | DETALLE | Privilegios para tabla clientes |
| 19:34:27.218 | 17360 | postgres | ::1 | SENTENCIA | `DROP ROLE soporte_ana;` |
| 19:38:13.884 | 15508 | soporte_ana | 127.0.0.1 | ERROR | Permiso denegado a la tabla clientes |
| 19:38:13.884 | 15508 | soporte_ana | 127.0.0.1 | SENTENCIA | `DELETE FROM clientes WHERE id = 5` |

**Interpretación:**

- Las sentencias que provocan un error quedan registradas junto con el error, gracias a `log_min_error_statement = error`, independientemente del valor de `log_statement`. El `DELETE` aparece aunque `log_statement = 'mod'` habría registrado solo las sentencias ejecutadas con éxito.
- Cada error va acompañado de la línea `SENTENCIA` con el texto exacto que lo causó, lo que permite saber qué se intentó.
- El intento de `soporte_ana` queda atribuido: usuario `soporte_ana`, aplicación `psql`, cliente `127.0.0.1`, hora con milisegundos y PID 15508. A diferencia de un fallo de autenticación, la aplicación ya aparece en el prefijo porque la sesión sí se estableció.
- El `DROP ROLE` aparece dos veces (19:34:01 y 19:34:27), porque se ejecutó dos veces y falló en ambas. Cada intento queda registrado por separado.

## 6. Preguntas

**Pregunta 1. ¿El intento de `soporte_ana` causó algún daño? ¿Por qué debe auditarse de todos modos?**

No causó daño: el `DELETE` fue rechazado, la tabla sigue con sus 5 registros y el registro 5 permanece intacto.

Debe auditarse de todos modos por varias razones:

- Muestra una intención de hacer algo fuera de lo que permite el rol. Puede ser un error, un abuso, una cuenta comprometida o un permiso mal diseñado, y la bitácora es la única evidencia de que el intento ocurrió.
- Un evento aislado puede ser inocente, pero la repetición de intentos rechazados es una señal de alerta que solo se detecta si se registran.
- Como las credenciales eran válidas, el evento identifica la cuenta y el cliente desde el que se hizo, lo que permite investigar si fue la propia persona o alguien que usó su cuenta.
- Confirma que el control de privilegios funcionó como se diseñó.

**Pregunta 2. ¿Qué diferencia hay entre un error de autorización (esta actividad) y uno de autenticación (actividad 5)?**

| Aspecto | Autenticación (actividad 5) | Autorización (esta actividad) |
|---|---|---|
| Qué comprueba | **Quién eres**: que la contraseña sea válida | **Qué puedes hacer**: que el rol tenga el privilegio |
| Momento | Al conectarse, antes de crear la sesión | Al ejecutar una sentencia, con la sesión ya abierta |
| Severidad en la bitácora | `FATAL` (la sesión termina) | `ERROR` (la sesión continúa) |
| Mensaje | La autentificación password falló | Permiso denegado a la tabla clientes |
| Sentencia registrada | No hay sentencia, nunca se ejecutó | Sí, la línea `SENTENCIA` con el texto intentado |
| Aplicación en el prefijo | `[desconocido]` | Ya aparece (`psql`) |
| Qué prueba | Alguien presentó un nombre de usuario sin credenciales válidas | Una cuenta con credenciales válidas intentó una acción no permitida |

**Pregunta 3. ¿Qué indica el error de `DROP ROLE` sobre el orden correcto para dar de baja a un usuario?**

Indica que un rol no se puede eliminar mientras tenga privilegios u objetos asociados. El detalle del error (`privilegios para tabla clientes`) señala qué falta limpiar. El orden correcto sería:

1. Bloquear el acceso: `ALTER ROLE soporte_ana NOLOGIN;`
2. Cerrar sus sesiones activas, si las tiene.
3. Retirar sus privilegios: `REVOKE ALL ON clientes FROM soporte_ana;` o `DROP OWNED BY soporte_ana;`.
4. Reasignar los objetos que posea: `REASSIGN OWNED BY soporte_ana TO ...;`
5. Eliminar el rol: `DROP ROLE soporte_ana;`

Como los roles son comunes a todo el servidor, los pasos 3 y 4 deben repetirse en cada base de datos donde el rol tenga privilegios u objetos. Estos pasos no se ejecutaron en el laboratorio; el rol `soporte_ana` se conserva. Cada uno de esos cambios es una modificación de privilegios y también queda registrado con `log_statement = 'ddl'` o superior.

## 7. Conclusión

La bitácora registra tanto las operaciones exitosas como las rechazadas. Los dos errores de esta actividad quedaron documentados con usuario, cliente, hora, motivo y sentencia exacta, aunque ninguno modificó datos: el `DELETE` de `soporte_ana` fue bloqueado por los privilegios y el `DROP ROLE` fue bloqueado por las dependencias del rol.

Las sentencias que provocan errores se registran gracias a `log_min_error_statement = error`, sin depender de `log_statement`. Esto permite detectar intentos no autorizados que, aunque hayan fallado, son señales útiles para la seguridad. También permite distinguir entre fallos de autenticación (no se pudo comprobar quién es) y de autorización (se sabe quién es, pero no tiene permiso para esa acción).