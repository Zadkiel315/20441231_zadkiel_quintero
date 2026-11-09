# Evidencia 06 — Cambios de privilegios y de estructura

## 1. Estado previo

Antes de ejecutar los cambios se comprobó el usuario de la sesión y el valor de `log_statement`:

```sql
SELECT current_user;
SHOW log_statement;
```

| Consulta | Resultado |
|---|---|
| `current_user` | postgres |
| `log_statement` | ddl |

**Interpretación:**

La sesión pertenece al administrador y el servidor registra las sentencias de definición (`ddl`), configuración aplicada en la actividad 4.

## 2. Cambios de privilegios y de estructura

En la sesión de administrador se ejecutaron tres cambios:

```sql
REVOKE UPDATE ON clientes FROM soporte_ana;
GRANT UPDATE ON clientes TO app_ventas;
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);
```

| Sentencia | Tipo de cambio | Resultado |
|---|---|---|
| `REVOKE UPDATE ON clientes FROM soporte_ana` | Privilegio | `REVOKE` |
| `GRANT UPDATE ON clientes TO app_ventas` | Privilegio | `GRANT` |
| `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)` | Estructura | `ALTER TABLE` |

**Interpretación:**

El `REVOKE` sobre un privilegio que `soporte_ana` no tenía no produce error, y el `GRANT` sobre un privilegio que `app_ventas` ya tenía tampoco. Son ejemplos de revisiones periódicas de privilegios, cuyas sentencias también deben quedar registradas.

## 3. La bitácora también puede filtrar secretos

Se creó un rol desechable escribiendo la contraseña dentro de la sentencia, y después se eliminó:

```sql
CREATE ROLE rol_temporal LOGIN PASSWORD 'Temporal_Practica_2026';
DROP ROLE rol_temporal;
```

| Sentencia | Resultado |
|---|---|
| `CREATE ROLE rol_temporal LOGIN PASSWORD '...'` | `CREATE ROLE` |
| `DROP ROLE rol_temporal` | `DROP ROLE` |

## 4. Consulta de las sentencias registradas

Se consultaron las sentencias que quedaron en la bitácora. El filtro acepta el texto en inglés (`statement:`) y en español (`sentencia:`), porque este servidor escribe sus mensajes en español:

```sql
SELECT linea
FROM dba.bitacora
WHERE linea ~ 'LOG: +(statement|sentencia):'
ORDER BY num;
```

**Resultado:** 5 filas.

| Hora | PID | Usuario | Base | Aplicación | Cliente | Sentencia registrada |
|---|---|---|---|---|---|---|
| 19:07:27.141 | 17360 | postgres | comercial | psql | ::1 | `REVOKE UPDATE ON clientes FROM soporte_ana;` |
| 19:07:27.154 | 17360 | postgres | comercial | psql | ::1 | `GRANT UPDATE ON clientes TO app_ventas;` |
| 19:07:28.888 | 17360 | postgres | comercial | psql | ::1 | `ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);` |
| 19:07:41.025 | 17360 | postgres | comercial | psql | ::1 | `CREATE ROLE rol_temporal LOGIN PASSWORD 'Temporal_Practica_2026';` |
| 19:07:42.114 | 17360 | postgres | comercial | psql | ::1 | `DROP ROLE rol_temporal;` |

**Interpretación:**

- Con el prefijo configurado en la actividad 4, cada cambio queda atribuido: quién lo hizo (`postgres`), en qué base (`comercial`), con qué aplicación (`psql`), desde qué cliente (`::1`) y a qué hora, con milisegundos.
- Las cinco sentencias pertenecen a la misma sesión (PID 17360), lo que permite reconstruir la secuencia de los cambios.
- La bitácora registra la **sentencia ejecutada**, no su efecto. El `REVOKE` y el `GRANT` aparecen aunque no cambiaron ningún permiso, por lo que la bitácora por sí sola no permite saber si el privilegio existía antes.
- Las consultas `SELECT current_user`, `SHOW log_statement` y las consultas a la bitácora **no aparecen**, porque no son sentencias de definición.
- **La contraseña del rol quedó en texto claro** en la línea del `CREATE ROLE`, y el `DROP ROLE` posterior no la borró de la bitácora.

## 5. Preguntas

**Pregunta 1. ¿Qué tipo de evento es cada una de las tres primeras sentencias (privilegio o estructura)?**

| Sentencia | Tipo de evento | Qué modifica |
|---|---|---|
| `REVOKE UPDATE ON clientes FROM soporte_ana` | Privilegio | Quién puede actualizar la tabla (control de acceso) |
| `GRANT UPDATE ON clientes TO app_ventas` | Privilegio | Quién puede actualizar la tabla (control de acceso) |
| `ALTER TABLE clientes ADD COLUMN segmento ...` | Estructura | La definición de la tabla (se agrega una columna) |

**Pregunta 2. ¿Por qué `GRANT` y `REVOKE` quedan registrados con `log_statement = 'ddl'`?**

Porque PostgreSQL clasifica `GRANT` y `REVOKE` junto con `CREATE`, `ALTER` y `DROP` como sentencias de definición: modifican el catálogo del sistema y no los datos de las tablas.

Además, un cambio de privilegios altera la postura de seguridad de la base de datos. Una auditoría necesita poder reconstruir quién concedió o quitó un permiso y cuándo, porque es lo que explica por qué un rol pudo (o no pudo) hacer algo en un momento dado.

**Pregunta 3. Si la bitácora contiene contraseñas, ¿quién debería poder leerla? Relaciónalo con la gestión de secretos de la Unidad II.**

Solo el administrador o un rol de auditoría con permisos otorgados de forma explícita; nunca los roles de aplicación (`app_ventas`) ni de soporte (`soporte_ana`). Una bitácora que puede contener contraseñas es tan sensible como las propias credenciales y debe protegerse con el mismo nivel.

Esto se relaciona con los principios de gestión de secretos de la Unidad II:

- **Mínimo privilegio:** el acceso a la bitácora, a la vista `dba.bitacora` y al archivo del servidor debe limitarse a quien lo necesite.
- **Los secretos no deben viajar en texto claro:** las contraseñas no deben escribirse dentro de sentencias SQL. Con `\password` el cliente calcula el resumen SCRAM y solo ese resumen llega al servidor y a la bitácora, aunque el resumen sigue siendo información sensible.
- **Un secreto expuesto se considera comprometido:** una contraseña que apareció en la bitácora debe cambiarse, aunque el rol o la sentencia ya no existan. En este laboratorio ocurrió lo mismo con la contraseña de `app_ventas`, que quedó registrada en un archivo de bitácora anterior cuando se registró una sentencia con error (actividad 3).
- **Conservación controlada:** los archivos de bitácora deben tener una política de rotación y retención, porque lo que contienen permanece hasta que se eliminan.

## 6. Conclusión

Con `log_statement = 'ddl'`, los cambios de privilegios (`REVOKE`, `GRANT`) y de estructura (`ALTER TABLE`) quedaron registrados con su autor, base, aplicación, cliente y hora, lo que permite reconstruir la secuencia de cambios de una sesión de administración.

La actividad también mostró el costo de registrar sentencias: la bitácora puede capturar secretos escritos en las sentencias, y eliminar el rol no elimina la contraseña de los archivos. Por ello, la bitácora debe tratarse como un activo sensible, con acceso restringido, y las contraseñas deben gestionarse con mecanismos que no las expongan, como `\password`.

También se observó que la bitácora registra lo que se intentó ejecutar y no su efecto, y que `log_statement = 'ddl'` no registra sentencias de datos como `UPDATE`, por lo que un incidente como el de la actividad 3 seguiría sin dejar evidencia de la sentencia.