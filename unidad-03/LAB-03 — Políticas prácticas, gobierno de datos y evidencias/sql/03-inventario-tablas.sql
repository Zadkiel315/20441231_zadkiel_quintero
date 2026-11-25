-- ============================================================
-- Actividad 4: Catalogo minimo de datos
-- ============================================================

-- Actividad 4: Catalogo minimo de datos

-- Actualizar estadisticas de las tablas
ANALYZE;

-- Consultar informacion tecnica de las tablas
SELECT n.nspname AS esquema,
       c.relname AS tabla,
       pg_get_userbyid(c.relowner) AS propietario_tecnico,
       c.reltuples::bigint AS filas_estimadas,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS tamano,
       obj_description(c.oid, 'pg_class') AS descripcion
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;

