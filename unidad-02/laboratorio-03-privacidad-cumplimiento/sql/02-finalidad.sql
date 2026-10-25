-- LAB-03 - Actividad 3: Separacion por finalidad
-- Consultar datos para analisis sin mostrar informacion personal

-- 1. Contar cuantos clientes hay por ciudad
SELECT ciudad, COUNT(*) AS total_clientes
FROM clientes
GROUP BY ciudad
ORDER BY total_clientes DESC;

-- 2. Agrupar clientes por rango de edad
SELECT
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
    CASE
        WHEN edad < 18 THEN 'Menor de edad'
        WHEN edad BETWEEN 18 AND 29 THEN '18 a 29'
        WHEN edad BETWEEN 30 AND 49 THEN '30 a 49'
        WHEN edad >= 50 THEN '50 o mas'
        ELSE 'Sin edad registrada'
    END
ORDER BY rango_edad;
