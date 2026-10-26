
-- =====================================================
-- ACTIVIDAD 4: REVISAR pg_hba.conf
-- =====================================================

SELECT
    type,
    database,
    user_name,
    address,
    auth_method
FROM pg_hba_file_rules;

-- =====================================================
-- ACTIVIDAD 7: Revisar autenticación
-- =====================================================

-- Método predeterminado para almacenar contraseñas
SHOW password_encryption;


-- =====================================================
-- ACTIVIDAD 10: Consultar las extensiones instaladas
-- =====================================================

SELECT
    extname,    -- Nombre de la extensión
    extversion  -- Versión instalada
FROM pg_extension
ORDER BY extname;
