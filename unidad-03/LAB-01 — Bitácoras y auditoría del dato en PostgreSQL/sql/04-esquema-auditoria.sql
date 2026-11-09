-- ============================================================
-- Actividad 7 — Modificaciones de datos: ddl frente a mod
-- ============================================================

-- Consulta los ultimos 3 registros relacionados con el usuario app_ventas.
SELECT linea FROM dba.bitacora WHERE linea LIKE '%user=app_ventas%' ORDER BY num DESC LIMIT 3;

-- Cambia el registro de sentencias para incluir modificaciones de datos (INSERT, UPDATE y DELETE).
ALTER SYSTEM SET log_statement = 'mod';

-- Recarga la configuracion de PostgreSQL.
SELECT pg_reload_conf();

-- Busca registros relacionados con el cambio de configuracion y las sentencias de app_ventas.
SELECT linea FROM dba.bitacora
WHERE linea LIKE '%log_statement%' OR linea LIKE '%user=app_ventas%statement:%'
ORDER BY num;


-- ============================================================
-- Actividad 8 — Errores y operaciones rechazadas
-- ============================================================

-- Intenta eliminar el rol soporte_ana.
DROP ROLE soporte_ana;

-- Busca errores y operaciones relacionadas con permisos, roles y sentencias DELETE o DROP.
SELECT linea FROM dba.bitacora
WHERE linea ~ '(ERROR|STATEMENT|DETAIL):  (permission|privileges|role|DELETE|DROP)'
ORDER BY num;


-- ============================================================
-- Actividad 9 — Sesiones activas con pg_stat_activity
-- ============================================================

-- Consulta las sesiones de clientes conectados a PostgreSQL.
-- Muestra su proceso, usuario, aplicacion, direccion IP, inicio y estado.
-- Tambien muestra los primeros 30 caracteres de la ultima consulta.
SELECT pid, usename, application_name, client_addr, backend_start, state, left(query, 30) AS query
FROM pg_stat_activity
WHERE backend_type = 'client backend';

-- Busca en la bitacora los registros relacionados con el proceso 189.
SELECT linea FROM dba.bitacora WHERE linea LIKE '%[189]%' ORDER BY num;


-- ============================================================
-- Actividad 10 — Diseñar y crear el registro de auditoría
-- ============================================================

-- Crea el esquema auditoria para almacenar los registros de cambios.
CREATE SCHEMA auditoria;

-- Quita todos los permisos del esquema auditoria al rol PUBLIC.
REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;

-- Crea la tabla para guardar los cambios realizados en los clientes.
CREATE TABLE auditoria.cambios_clientes (
    id_evento        BIGSERIAL PRIMARY KEY, -- Identificador unico de cada evento.
    momento          TIMESTAMPTZ NOT NULL DEFAULT now(), -- Fecha y hora del cambio.
    usuario_sesion   TEXT        NOT NULL DEFAULT session_user, -- Usuario que inicio la sesion.
    usuario_efectivo TEXT        NOT NULL DEFAULT current_user, -- Usuario que ejecuta la operacion.
    aplicacion       TEXT        DEFAULT current_setting('application_name'), -- Aplicacion que realiza el cambio.
    ip_cliente       INET        DEFAULT inet_client_addr(), -- Direccion IP del cliente.
    operacion        TEXT        NOT NULL, -- Tipo de operacion realizada.
    id_cliente       BIGINT, -- Identificador del cliente afectado.
    valores_antes    JSONB, -- Datos del cliente antes del cambio.
    valores_despues  JSONB -- Datos del cliente despues del cambio.
);