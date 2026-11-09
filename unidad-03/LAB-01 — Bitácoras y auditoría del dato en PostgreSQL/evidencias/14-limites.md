# Evidencia 14 — Límites de la auditoría: lecturas y volumen

## 1. Lectura de datos sensibles

Desde la cuenta de soporte se consultaron datos sensibles de un cliente:

```powershell
psql "postgresql://soporte_ana:<contraseña>@127.0.0.1/comercial" -c "SELECT nombre, rfc, telefono FROM clientes WHERE id = 3"
```

**Resultado:** 1 fila.

| nombre | rfc | telefono |
|---|---|---|
| María García | GAMA780912GHI | 6679990000 |

**Interpretación:**

`soporte_ana` puede leer el nombre, el RFC y el teléfono de un cliente. Es una lectura legítima para su función, pero se trata de datos personales. Más adelante se comprueba si esa lectura dejó algún rastro.

## 2. Cambio masivo de datos

En la sesión de administrador se actualizó toda la tabla, sin `WHERE`:

```sql
UPDATE clientes SET segmento = 'regular';
```

**Resultado:**

```
UPDATE 5
```

**Interpretación:**

Una sola sentencia modificó 5 filas, es decir, todos los clientes de la tabla.

## 3. Rastro del cambio masivo en la bitácora

```sql
SELECT count(*) AS lineas_bitacora FROM dba.bitacora
WHERE linea LIKE '%statement: UPDATE clientes SET segmento%';
```

**Resultado:**

| lineas_bitacora |
|---|
| 0 |

**Interpretación:**

La consulta devolvió 0 porque el patrón buscaba el texto `statement:` (mensajes en inglés), y el servidor de este laboratorio registra en español, con la etiqueta `sentencia:` (como se comprobó en la Evidencia 13). La búsqueda se repite con el patrón en español:

```sql
SELECT count(*) AS lineas_bitacora FROM dba.bitacora
WHERE linea LIKE '%sentencia: UPDATE clientes SET segmento%';
```

**Resultado:**

| lineas_bitacora |
|---|
| 1 |

**Interpretación:**

La bitácora registra la sentencia una sola vez, sin importar cuántas filas haya modificado: el `UPDATE` masivo de 5 filas produjo **una** línea.

## 4. Rastro del cambio masivo en la tabla de auditoría

```sql
SELECT operacion, count(*) FROM auditoria.cambios_clientes GROUP BY operacion ORDER BY operacion;
```

**Resultado:** 3 filas.

| operacion | count |
|---|---|
| DELETE | 1 |
| INSERT | 1 |
| UPDATE | 6 |

**Interpretación:**

Antes de esta actividad había 1 evento `UPDATE` (el cambio de RFC de la Evidencia 12; el de la Evidencia 14 no se auditó porque el disparador estaba desactivado). Ahora hay 6, es decir, **cinco filas nuevas**: el disparador es `FOR EACH ROW` y generó un evento por cada fila modificada. El contraste es claro: la bitácora registra una línea por sentencia, y la tabla de auditoría un evento por fila.

## 5. Rastro de la lectura de datos sensibles

```sql
SELECT count(*) AS lecturas_soporte FROM dba.bitacora
WHERE linea LIKE '%user=soporte_ana%SELECT nombre, rfc%';
```

**Resultado:**

| lecturas_soporte |
|---|
| 0 |

**Interpretación:**

La lectura del RFC no dejó rastro. No existe un disparador para `SELECT` (los disparadores de fila solo se activan con `INSERT`, `UPDATE` y `DELETE`), y la configuración `log_statement` del servidor, que sí registró el `UPDATE` en la Evidencia 13, no registra consultas de lectura, lo que corresponde a `mod`. Ni la tabla de auditoría ni la bitácora pueden responder quién consultó el RFC de María García.

Alternativas para registrar lecturas:

| Alternativa | Ventaja | Desventaja |
|---|---|---|
| `log_statement = 'all'` | No requiere instalar nada | Registra todas las consultas de todas las tablas |
| Entregar el dato solo mediante una función que registre su uso | Control preciso | Requiere cambiar la aplicación |
| `pgaudit` con auditoría de objeto (Parte C) | Registra lecturas por tabla y por columna | Requiere instalar una extensión |

## 6. Preguntas

**Pregunta 1. Si `clientes` tuviera un millón de registros, ¿qué ocurriría con la auditoría tras un `UPDATE` sin `WHERE`?**

El disparador `FOR EACH ROW` se ejecutaría un millón de veces y escribiría un millón de eventos en `auditoria.cambios_clientes`, cada uno con dos documentos `jsonb` completos (`valores_antes` y `valores_despues`). Consecuencias:

- La tabla de auditoría crecería de golpe, ocupando mucho espacio en disco (y en el registro de transacciones).
- La sentencia tardaría mucho más, porque cada fila implica además un `INSERT` en la auditoría, y mantendría bloqueos y la transacción abierta por más tiempo.
- Si algo fallara a la mitad (por ejemplo, falta de espacio), la transacción completa se revertiría, porque la auditoría forma parte de ella.
- La bitácora, en cambio, seguiría registrando una sola línea, sin indicar cuántas filas se afectaron.

Esto muestra que la auditoría por filas es muy detallada pero escala mal con los cambios masivos, y hace necesario planificar su volumen y su depuración.

**Pregunta 2. Propón quién podría autorizar la depuración de `auditoria.cambios_clientes`.**

La depuración no debería decidirla el administrador de la base de datos por sí solo. Propongo que la autorice un comité o responsable independiente de la operación: el responsable de los datos (dueño de la información) junto con el área de auditoría o seguridad de la información y el área legal o de cumplimiento, de acuerdo con la política de retención. El administrador ejecuta la depuración técnica una vez autorizada, y la propia depuración debe quedar documentada y registrada en la bitácora. Es coherente con la separación de funciones: quien opera la base no decide qué evidencia se destruye.

**Pregunta 3. ¿Por qué `log_statement = 'all'` puede convertir la bitácora en un nuevo depósito de datos sensibles?**

Porque la bitácora guarda el texto completo de cada sentencia, incluidos los valores literales. Con `all`, cada consulta de lectura y escritura sobre cualquier tabla se registra con sus datos. En este mismo laboratorio, la línea del `UPDATE` de la Evidencia 13 ya muestra el RFC en claro (`SET rfc = 'GAMA780912GHI'`); con `all` también aparecerían los valores usados en los `SELECT`, `INSERT` y filtros de todas las aplicaciones.

El problema es que los archivos de bitácora no tienen los permisos finos de las tablas: quien pueda leerlos (administradores del sistema, soporte, sistemas de recolección de logs) vería datos personales sin pasar por los controles de acceso de la base, y esas copias se replican, respaldan y conservan según otras reglas de retención. La bitácora se convierte así en un segundo almacén de datos sensibles, difícil de controlar, con el mismo conflicto de retención visto en la Evidencia 12.

## 7. Conclusión

La actividad mostró los límites de cada mecanismo. La tabla de auditoría con disparador registra los cambios de datos con gran detalle (un evento por fila: 5 filas nuevas tras el `UPDATE` masivo), pero escala mal con el volumen y no registra lecturas. La bitácora del servidor registra una sola línea por sentencia, sin el detalle de las filas afectadas, y con la configuración actual no registra las consultas de lectura: la consulta de `soporte_ana` sobre el RFC de María García no dejó ningún rastro.

Registrar lecturas exige otro mecanismo (`log_statement = 'all'`, funciones que registren el uso o `pgaudit`), y cada uno tiene un costo: más volumen, cambios en la aplicación o instalar una extensión, además del riesgo de convertir la bitácora en otro depósito de datos sensibles. Por eso la decisión de qué auditar, cuánto conservar y quién autoriza la depuración debe tomarse a nivel organizacional, y no solo técnico.