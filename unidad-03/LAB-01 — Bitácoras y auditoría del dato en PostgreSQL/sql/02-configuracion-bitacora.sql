-- ============================================================
-- Actividad 3 — El incidente sin bitácora
-- ============================================================

-- Busca registros relacionados con UPDATE o la aplicacion app_ventas.
SELECT linea FROM dba.bitacora
WHERE linea ILIKE '%update%' OR linea LIKE '%app_ventas%';


-- ============================================================
-- Actividad 4 — Configurar la bitácora
-- ============================================================

-- Activa el registro de conexiones y desconexiones.
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;

-- Define el formato de informacion que se guardara en cada registro.
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';

-- Configura el registro de sentencias DDL.
ALTER SYSTEM SET log_statement = 'ddl';

-- Recarga la configuracion sin reiniciar PostgreSQL.
SELECT pg_reload_conf();

-- Consulta la configuracion actual de los parametros de bitacora.
SELECT name, setting, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections', 'log_line_prefix', 'log_statement');

-- Muestra los ultimos 6 registros de la bitacora.
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 6;