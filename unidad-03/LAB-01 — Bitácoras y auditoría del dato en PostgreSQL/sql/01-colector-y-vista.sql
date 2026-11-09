
-- ============================================================
-- Actividad 1 — Revisar la configuración de registro por defecto
-- ============================================================

-- Muestra el valor actual y el origen (default, configuration file, etc.)
-- de los parámetros que controlan qué se registra, dónde y con qué formato.
SELECT name, setting, source
FROM pg_settings
WHERE name IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename',
               'log_connections', 'log_disconnections', 'log_line_prefix',
               'log_statement', 'log_min_error_statement', 'log_timezone')
ORDER BY name;


-- ============================================================
-- Actividad 2 — Que el servidor administre su propia bitácora
-- ============================================================

-- Activa el colector de bitácoras: PostgreSQL escribe sus mensajes en
-- archivos dentro del directorio log/. Es un parámetro de contexto
-- "postmaster", por lo que un cambio real requiere reiniciar el servicio.
ALTER SYSTEM SET logging_collector = on;

-- Verifica el valor y si el cambio queda pendiente de reinicio
-- (pending_restart = t significa que falta reiniciar).
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';

-- Después del reinicio, confirma el valor y su origen.
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';

-- Devuelve la ruta del archivo de bitácora vigente, relativa al
-- directorio de datos.
SELECT pg_current_logfile();

-- Lee el archivo vigente desde el propio motor y lo divide en una fila
-- por línea. Se lee como bytes (pg_read_binary_file) y se convierte con
-- convert_from porque la bitácora en Windows está en Windows-1252 y no
-- en UTF8; con pg_read_file la consulta falla por bytes no válidos.
SELECT linea
FROM regexp_split_to_table(
       convert_from(pg_read_binary_file(pg_current_logfile()), 'LATIN1'),
       E'\n') AS linea;

-- Crea un esquema exclusivo del administrador para objetos de auditoría.
CREATE SCHEMA dba;

-- Quita todos los permisos sobre el esquema al rol PUBLIC, de modo que
-- solo quien reciba permisos explícitos pueda usarlo.
REVOKE ALL ON SCHEMA dba FROM PUBLIC;

-- Crea la vista que expone la bitácora como tabla:
--   num   = número de línea (WITH ORDINALITY), útil para ordenar y citar
--   linea = texto de la línea
-- Se omiten las líneas vacías. DROP VIEW IF EXISTS permite ejecutar el
-- script varias veces sin error.
DROP VIEW IF EXISTS dba.bitacora;

CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(
       convert_from(pg_read_binary_file(pg_current_logfile()), 'LATIN1'),
       E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';

-- Últimas 10 líneas de la bitácora (las más recientes primero).
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;

-- Líneas que contienen un texto, sin distinguir mayúsculas
-- (ILIKE). Aquí busca la palabra "update".
SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';

-- Líneas que cumplen una expresión regular (operador ~).
-- Aquí muestra los eventos FATAL y ERROR.
SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';