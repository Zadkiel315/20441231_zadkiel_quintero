# Evidencia 10 — Diseño y creación del registro de auditoría

**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Actividad:** 10 — Diseñar y crear el registro de auditoría  
**Motor:** PostgreSQL 18.6  
**Sistema operativo:** Windows 64 bits  
**Base de datos:** comercial

## 1. Diseño del registro de auditoría

Antes de escribir código se decidió qué debe contener cada registro. Cada campo responde a una de las preguntas que surgen de un incidente como el de la actividad 3: quién, cuándo, desde dónde, qué se hizo, sobre qué registro y cuál era el valor anterior.

| Campo propuesto | Tipo | ¿Qué pregunta responde? | ¿Puede ser nulo? ¿Por qué? |
|---|---|---|---|
| id_evento | BIGSERIAL | ¿En qué orden ocurrió? Identifica cada evento y permite detectar huecos en la secuencia | No: es la clave primaria |
| momento | TIMESTAMPTZ | ¿Cuándo ocurrió? | No: sin hora no hay cronología |
| usuario_sesion | TEXT | ¿Quién? Es el rol con el que se autenticó la sesión y no cambia con `SET ROLE` | No: toda operación ocurre dentro de una sesión |
| usuario_efectivo | TEXT | ¿Con qué privilegios se ejecutó? Puede diferir del usuario de sesión si se usó `SET ROLE` o una función `SECURITY DEFINER` | No: siempre hay un rol efectivo |
| aplicacion | TEXT | ¿Desde qué aplicación? | Sí: el nombre lo declara el cliente y puede venir vacío o no informarse |
| ip_cliente | INET | ¿Desde dónde se conectó? | Sí: es `NULL` si la conexión se hizo por socket local, sin red |
| operacion | TEXT | ¿Qué se hizo? (INSERT, UPDATE o DELETE) | No: es la esencia del evento |
| id_cliente | BIGINT | ¿Sobre qué registro? | Sí: puede no haber una fila única (por ejemplo, un `TRUNCATE`). No lleva clave foránea, para que el registro sobreviva aunque el cliente se elimine |
| valores_antes | JSONB | ¿Cuál era el valor anterior? | Sí: es `NULL` en un `INSERT`, porque antes no existía |
| valores_despues | JSONB | ¿Qué valor quedó? | Sí: es `NULL` en un `DELETE`, porque ya no existe |

## 2. Creación del esquema y de la tabla

Se creó un esquema separado, sin acceso para el rol `PUBLIC`, y la tabla de auditoría:

```sql
CREATE SCHEMA auditoria;
REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;

CREATE TABLE auditoria.cambios_clientes (
    id_evento        BIGSERIAL PRIMARY KEY,
    momento          TIMESTAMPTZ NOT NULL DEFAULT now(),
    usuario_sesion   TEXT        NOT NULL DEFAULT session_user,
    usuario_efectivo TEXT        NOT NULL DEFAULT current_user,
    aplicacion       TEXT        DEFAULT current_setting('application_name'),
    ip_cliente       INET        DEFAULT inet_client_addr(),
    operacion        TEXT        NOT NULL,
    id_cliente       BIGINT,
    valores_antes    JSONB,
    valores_despues  JSONB
);
```

| Sentencia | Resultado |
|---|---|
| `CREATE SCHEMA auditoria` | `CREATE SCHEMA` |
| `REVOKE ALL ON SCHEMA auditoria FROM PUBLIC` | `REVOKE` |
| `CREATE TABLE auditoria.cambios_clientes (...)` | `CREATE TABLE` |

Los valores por defecto capturan el contexto de la sesión en el momento de insertar cada registro: la hora (`now()`), el usuario de sesión (`session_user`), el usuario efectivo (`current_user`), el nombre de la aplicación (`application_name`) y la dirección del cliente (`inet_client_addr()`).

## 3. Verificación de la estructura

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'auditoria' AND table_name = 'cambios_clientes'
ORDER BY ordinal_position;
```

**Resultado:** 10 filas.

| Columna | Tipo | ¿Admite nulos? | Valor por defecto |
|---|---|---|---|
| id_evento | bigint | NO | `nextval('auditoria.cambios_clientes_id_evento_seq')` |
| momento | timestamp with time zone | NO | `now()` |
| usuario_sesion | text | NO | `SESSION_USER` |
| usuario_efectivo | text | NO | `CURRENT_USER` |
| aplicacion | text | SÍ | `current_setting('application_name')` |
| ip_cliente | inet | SÍ | `inet_client_addr()` |
| operacion | text | NO | (sin valor por defecto) |
| id_cliente | bigint | SÍ | (sin valor por defecto) |
| valores_antes | jsonb | SÍ | (sin valor por defecto) |
| valores_despues | jsonb | SÍ | (sin valor por defecto) |

**Interpretación:**

La estructura creada coincide con el diseño de la sección 1: los campos obligatorios (`id_evento`, `momento`, `usuario_sesion`, `usuario_efectivo`, `operacion`) no admiten nulos, y los campos que pueden faltar según el caso (`aplicacion`, `ip_cliente`, `id_cliente`, `valores_antes`, `valores_despues`) sí los admiten. `id_evento` se genera con una secuencia propia del esquema `auditoria`. La columna `operacion` no tiene valor por defecto, porque quien escriba el registro debe indicar el tipo de operación.

## 4. Verificación de los permisos de los esquemas

```sql
SELECT nspname, nspacl FROM pg_namespace WHERE nspname IN ('dba', 'auditoria');
```

| Esquema | Permisos (nspacl) |
|---|---|
| dba | `{postgres=UC/postgres}` |
| auditoria | `{postgres=UC/postgres}` |

**Interpretación:**

En ambos esquemas la única entrada es `postgres=UC/postgres`: el administrador tiene `USAGE` (U) y `CREATE` (C) concedidos por sí mismo. No hay ninguna entrada para `PUBLIC` ni para los roles `app_ventas` y `soporte_ana`, por lo que ningún otro rol puede acceder a los objetos del esquema `auditoria`.

## 5. Preguntas

**Pregunta 1. ¿Por qué `momento` usa `TIMESTAMPTZ` y no `TIMESTAMP`?**

`TIMESTAMPTZ` guarda un instante absoluto (internamente en UTC) y lo presenta en la zona horaria de la sesión. `TIMESTAMP` guarda solo la fecha y hora "de reloj", sin zona, por lo que resulta ambiguo: el mismo valor puede significar horas distintas si el servidor, los clientes o el horario de verano cambian.

En una auditoría, cada instante debe significar una sola cosa. Con `TIMESTAMPTZ` se puede reconstruir una cronología sin confundir horarios, y comparar los eventos con la bitácora del servidor, que registra la hora con su zona (`CST` en este laboratorio).

**Pregunta 2. ¿Por qué se guarda el registro completo en `JSONB` y no solo la columna que cambió?**

- **Contexto y reversión:** con el registro completo se conoce el estado exacto de la fila antes y después, lo que permite revertir un cambio con certeza (lo que faltaba en la actividad 7).
- **Detección de cambios:** comparando `valores_antes` y `valores_despues` se deduce qué columnas cambiaron, incluso si cambió más de una.
- **Resistencia a cambios de estructura:** si la tabla `clientes` cambia (en la actividad 6 se agregó la columna `segmento`), la auditoría sigue funcionando sin modificar su estructura, porque el documento JSON incluye las columnas que existan en ese momento.

El costo es un mayor uso de espacio, porque cada cambio guarda la fila completa.

**Pregunta 3. La tabla de auditoría también contendrá RFC. ¿Qué implica eso para su clasificación y su control de acceso?**

El RFC identifica a una persona, por lo que es un dato personal. La tabla de auditoría debe clasificarse al menos con el mismo nivel de sensibilidad que la tabla `clientes`, y en la práctica es más delicada porque conserva además valores anteriores y datos de clientes que ya pudieron haberse eliminado de la tabla original.

Para el control de acceso implica:

- Mantener el esquema sin acceso para `PUBLIC`, como ya se aplicó.
- Permitir la lectura solo al administrador o a un rol de auditoría con permisos explícitos.
- Impedir que los roles de aplicación y de soporte puedan leerla, modificarla o borrarla, para que el historial no pueda alterarse.
- Definir cuánto tiempo se conserva y proteger sus respaldos con el mismo nivel de control.

## 6. Conclusión

Se diseñó un registro de auditoría en el que cada campo responde a una pregunta concreta sobre un cambio: quién, cuándo, desde dónde, qué operación, sobre qué registro y con qué valores antes y después. El esquema `auditoria` y la tabla `cambios_clientes` se crearon correctamente, y la verificación confirmó que los tipos, las restricciones de nulos y los valores por defecto corresponden al diseño.

El esquema quedó sin acceso para `PUBLIC` ni para los roles de aplicación, lo que es adecuado para una tabla que contendrá datos personales. En la siguiente actividad deberá resolverse cómo se escribirán los registros, ya que los roles de aplicación no tienen acceso a este esquema.