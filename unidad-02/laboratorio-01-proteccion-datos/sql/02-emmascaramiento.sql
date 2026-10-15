-- ============================================================
-- Actividad 2 — Enmascaramiento (masking)
-- ============================================================

-- 8.1 Crear el rol (sin permiso de inicio de sesión)
CREATE ROLE soporte NOLOGIN;

-- Permitir que tu usuario pueda usar el rol con SET ROLE

GRANT soporte TO u_20441231_zadkiel_quintero;


-- 8.2 Crear la vista con los datos enmascarados
CREATE VIEW v_clientes_soporte AS
SELECT
    id,
    nombre,
    -- Correo: primeras 2 letras + ***** + dominio
    CONCAT(
        LEFT(correo, 2),
        '*****',
        SUBSTRING(correo FROM POSITION('@' IN correo))
    ) AS correo,
    -- Teléfono: solo los últimos 4 dígitos
    CONCAT(
        '******',
        RIGHT(telefono, 4)
    ) AS telefono,
    -- RFC: solo los últimos 4 caracteres
    CONCAT(
        '*********',
        RIGHT(rfc, 4)
    ) AS rfc
FROM clientes;

-- Consultar la vista (como superusuario, solo para comprobar)
SELECT *
FROM v_clientes_soporte;

-- 8.3 Conceder acceso a la vista
-- Permitir al rol entrar al esquema public
GRANT USAGE
ON SCHEMA public
TO soporte;

-- Permitir al rol consultar únicamente la vista
GRANT SELECT
ON v_clientes_soporte
TO soporte;

-- Quitar todo acceso directo a la tabla original
REVOKE ALL
ON clientes
FROM soporte;

-- 8.4 Verificar el resultado

-- Cambiar al rol soporte
SET ROLE soporte;

-- Confirmar el rol activo (debe mostrar: soporte)
SELECT current_user;

-- CAPTURA 1: la vista debe mostrar los datos enmascarados
SELECT *
FROM v_clientes_soporte;

-- CAPTURA 2: debe marcar ERROR: permission denied for table clientes
SELECT *
FROM clientes;

-- Regresar al usuario original
RESET ROLE;

-- CAPTURA 3: permisos aplicados (solo debe aparecer v_clientes_soporte con SELECT)
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'soporte';