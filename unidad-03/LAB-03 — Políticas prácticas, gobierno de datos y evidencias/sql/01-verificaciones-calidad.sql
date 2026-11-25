-- ============================================================
-- Actividad 1 — Calidad de datos desde la operación
-- ============================================================

-- Simula dos registros capturados con errores:
INSERT INTO clientes (nombre, correo, telefono, rfc, edad, ciudad, codigo_postal) VALUES
('Ana Lopez', 'ANA.LOPEZ@example.test', '6671234567', 'LOAA850315AB', 41, 'Culiacan', '80000'),
('Jorge Díaz', 'sin-correo', '667', NULL, -3, 'Culiacán', '8000');

-- Posibles clientes duplicados por correo.
SELECT lower(correo) AS correo_normalizado,
       count(*) AS registros,
       string_agg(id::text, ', ') AS ids
FROM clientes
GROUP BY lower(correo)
HAVING count(*) > 1;

-- RFC con formato no valido o ausente.
SELECT id, nombre, rfc
FROM clientes
WHERE rfc IS NULL
   OR rfc !~ '^[A-ZÑ&]{3,4}[0-9]{6}[A-Z0-9]{3}$';

-- Correos con formato no valido.
SELECT id, nombre, correo
FROM clientes
WHERE correo !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$';

-- Edades fuera del rango permitido.
SELECT id, nombre, edad
FROM clientes
WHERE edad IS NOT NULL
  AND (edad < 18 OR edad > 120);

-- Verificacion de completitud.
SELECT count(*) AS total,
       count(*) FILTER (WHERE telefono IS NULL) AS sin_telefono,
       count(*) FILTER (WHERE rfc IS NULL) AS sin_rfc
FROM clientes;
