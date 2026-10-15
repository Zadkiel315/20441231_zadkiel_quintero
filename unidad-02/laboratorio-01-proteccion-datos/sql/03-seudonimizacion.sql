-- ============================================================
-- Actividad 3 — Seudonimización
-- Actividad 4 — Separación de funciones
-- ============================================================

-- 9.1 Crear los esquemas
-- pii: guarda el mapa que permite recuperar la identidad
-- analitica: guarda los datos seudonimizados para análisis
CREATE SCHEMA pii;
CREATE SCHEMA analitica;

-- 9.2 Crear la tabla de correspondencia token <-> cliente
CREATE TABLE pii.mapa_cliente (
    token UUID PRIMARY KEY,
    cliente_id BIGINT UNIQUE
        REFERENCES public.clientes(id)
);

-- 9.3 Generar los tokens
-- Habilitar la extensión necesaria para generar UUID
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Generar un token para cada cliente
INSERT INTO pii.mapa_cliente
(token, cliente_id)
SELECT
    gen_random_uuid(),
    id
FROM clientes;

-- Verificar el mapa
SELECT *
FROM pii.mapa_cliente;

-- 10. Crear el conjunto de datos para analítica
-- No incluye nombre, correo, telefono ni rfc
CREATE TABLE analitica.clientes AS
SELECT
    m.token AS cliente_token,
    c.edad,
    c.ciudad,
    c.codigo_postal,
    c.fecha_alta
FROM pii.mapa_cliente m
JOIN clientes c
    ON c.id = m.cliente_id;

-- Verificar el conjunto analítico
SELECT *
FROM analitica.clientes;

-- 11. Actividad 4 — Separación de funciones
-- Crear el rol del área de analítica (sin inicio de sesión)
CREATE ROLE analista1 NOLOGIN;

-- Permitir que tu usuario pueda usar el rol con SET ROLE
GRANT analista1 TO u_20441231_zadkiel_quintero;

-- Conceder acceso únicamente al conjunto analítico
GRANT USAGE
ON SCHEMA analitica
TO analista1;

GRANT SELECT
ON analitica.clientes
TO analista1;

-- NO se concede acceso a pii.mapa_cliente ni a public.clientes

-- 11.1 Verificar los permisos
SET ROLE analista1;

-- Confirmar el rol activo (debe mostrar: analista1)
SELECT current_user;

-- CAPTURA 1: consulta permitida
SELECT *
FROM analitica.clientes;

-- CAPTURA 2: debe marcar ERROR: permission denied for schema pii
SELECT *
FROM pii.mapa_cliente;

-- CAPTURA 3: debe marcar ERROR: permission denied for table clientes
SELECT *
FROM public.clientes;

-- Regresar al usuario original
RESET ROLE;