-- LAB-03 - Actividad 4: Control de acceso
-- Crear un rol y limitar los datos que puede consultar

-- 1. Crear el rol para analisis
CREATE ROLE analista NOLOGIN;

-- 2. Crear una vista con datos agrupados para analisis
CREATE VIEW v_analitica_clientes AS
SELECT
    ciudad,
    CASE
        WHEN edad < 18 THEN 'Menor de edad'
        WHEN edad BETWEEN 18 AND 29 THEN '18 a 29'
        WHEN edad BETWEEN 30 AND 49 THEN '30 a 49'
        WHEN edad >= 50 THEN '50 o mas'
        ELSE 'Sin edad registrada'
    END AS rango_edad,
    COUNT(*) AS total_clientes
FROM clientes
GROUP BY
    ciudad,
    CASE
        WHEN edad < 18 THEN 'Menor de edad'
        WHEN edad BETWEEN 18 AND 29 THEN '18 a 29'
        WHEN edad BETWEEN 30 AND 49 THEN '30 a 49'
        WHEN edad >= 50 THEN '50 o mas'
        ELSE 'Sin edad registrada'
    END;

-- 3. Permitir que el rol use el esquema public
GRANT USAGE ON SCHEMA public TO analista;

-- 4. Permitir consultar solamente la vista
GRANT SELECT ON v_analitica_clientes TO analista;

-- 5. Comprobar los resultados de la vista
SELECT *
FROM v_analitica_clientes;

-- 6. Revisar los permisos del rol
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'analista';
