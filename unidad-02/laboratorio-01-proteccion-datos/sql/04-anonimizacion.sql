-- ============================================================
-- Actividad 5 — Anonimización (agregación y generalización)
-- Actividad 6 — Reto: reducir el riesgo de reidentificación
-- ============================================================

-- 12.1 Generalizar la edad (rangos en lugar de edad exacta)
-- CAPTURA 1
SELECT
    CASE
        WHEN edad BETWEEN 18 AND 30 THEN '18-30'
        WHEN edad BETWEEN 31 AND 45 THEN '31-45'
        ELSE '46+'
    END AS rango_edad,
    COUNT(*) AS total
FROM clientes
GROUP BY 1;

-- 12.2 Generalizar la región (solo los 2 primeros dígitos del código postal)
-- CAPTURA 2
SELECT
    LEFT(codigo_postal, 2) AS region,
    COUNT(*) AS total
FROM clientes
GROUP BY 1;

-- 12.3 Combinar atributos (rango de edad + región)
-- CAPTURA 3
SELECT
    CASE
        WHEN edad BETWEEN 18 AND 30 THEN '18-30'
        WHEN edad BETWEEN 31 AND 45 THEN '31-45'
        ELSE '46+'
    END AS rango_edad,
    LEFT(codigo_postal, 2) AS region,
    COUNT(*) AS total
FROM clientes
GROUP BY 1, 2;

-- 12.4 Suprimir grupos pequeños (umbral didáctico k = 5)
--  CAPTURA 4
SELECT
    CASE
        WHEN edad BETWEEN 18 AND 30 THEN '18-30'
        WHEN edad BETWEEN 31 AND 45 THEN '31-45'
        ELSE '46+'
    END AS rango_edad,
    LEFT(codigo_postal, 2) AS region,
    COUNT(*) AS total
FROM clientes
GROUP BY 1, 2
HAVING COUNT(*) >= 5;

