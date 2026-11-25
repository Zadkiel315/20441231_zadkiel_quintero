# Actividad 1 — Calidad de datos desde la operación

## Objetivo

Identificar problemas de calidad en los datos de los clientes mediante consultas SQL, registrando los hallazgos y definiendo quién debe decidir las correcciones.

## Resultados obtenidos

Se insertaron dos registros de prueba en la tabla `clientes`: Ana Lopez y Jorge Díaz.

Al realizar las verificaciones se encontraron los siguientes problemas:

- Posible cliente duplicado por correo.
- RFC con formato incorrecto o ausente.
- Correo con formato incorrecto.
- Edad fuera del rango permitido.

## Registro de hallazgos

| ID | Hallazgo | Registros | Regla de calidad | ¿Quién decide la corrección? | Acción propuesta |
|---|---|---|---|---|---|
| C1 | Posible cliente duplicado | 1 y 7 | Unicidad del correo | Gerencia Comercial | Revisar si ambos registros pertenecen al mismo cliente y decidir si se deben unificar. |
| C2 | RFC con formato incorrecto o incompleto | 7 y 8 | Formato del RFC | Gerencia Comercial, con apoyo del área de facturación | Verificar el RFC con el cliente y corregirlo solamente cuando exista confirmación. |
| C3 | Correo con formato incorrecto | 8 | Formato del correo | Gerencia Comercial | Solicitar un correo válido al cliente antes de actualizar el registro. |
| C4 | Edad fuera del rango permitido | 8 | Edad entre 18 y 120 años | Gerencia Comercial | Verificar la edad correcta con el cliente y actualizar el dato con autorización. |

## Preguntas

### 1. ¿Por qué el DBA no debe corregir por su cuenta el RFC del registro 7?

Porque el DBA es el encargado de administrar y proteger la base de datos, pero no es quien decide cuál es el RFC correcto de un cliente.

El RFC es un dato personal que se utiliza para facturación. Si el DBA lo modifica sin autorización, podría registrar información incorrecta y afectar otros procesos de la empresa.

Por eso, la corrección debe ser aprobada por el propietario del dato, que en este caso es la Gerencia Comercial, con apoyo del área de facturación.

### 2. ¿Qué restricción (CHECK, UNIQUE) habría evitado cada hallazgo? ¿Quién debería aprobar agregarla?

- C1: Se podría utilizar una restricción UNIQUE sobre el correo normalizado para evitar correos duplicados, sin importar si se escriben con mayúsculas o minúsculas. Antes de agregarla, Gerencia Comercial debe revisar los registros duplicados y aprobar la regla.
- C2: Se podría utilizar una restricción CHECK para validar el formato del RFC. La Gerencia Comercial y el área de facturación deben aprobar la regla.
- C3: Se podría utilizar una restricción CHECK para validar el formato del correo electrónico. La Gerencia Comercial debe aprobarla.
- C4: Se podría utilizar una restricción CHECK para permitir únicamente edades entre 18 y 120 años. La Gerencia Comercial debe aprobar el rango permitido.

Estas restricciones deben revisarse antes de aplicarse, ya que los registros existentes contienen errores y podrían impedir su creación.

### 3. Si el DBA corrige un dato, ¿qué mecanismo del LAB-01 (Parte B) dejará evidencia del cambio?

El mecanismo que dejará evidencia es el disparador (trigger) de auditoría creado en el LAB-01.

Este mecanismo registra los cambios realizados en la tabla `clientes` dentro de `auditoria.cambios_clientes`, incluyendo información como el usuario, la operación realizada y los valores anteriores y posteriores del registro.

De esta manera, se puede identificar qué dato se modificó y quién realizó la corrección.

## Conclusión

La actividad permitió identificar diferentes problemas de calidad en los datos de los clientes.

Se comprobó que un dato puede estar presente en la base de datos, pero tener un formato incorrecto o un valor que no cumple con las reglas establecidas.

También se identificó que el DBA no debe decidir por su cuenta las correcciones de los datos, sino que debe reportar los hallazgos al propietario correspondiente.

Finalmente, las restricciones de integridad y los mecanismos de auditoría permiten prevenir errores y mantener evidencia de los cambios realizados.
