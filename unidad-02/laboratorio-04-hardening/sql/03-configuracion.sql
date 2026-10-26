
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

-- ========================================================================
-- ACTIVIDAD 11: Revisar la configuración de conexiones y timeouts
-- ========================================================================

-- 1. Muestra el número máximo de conexiones simultáneas que permite el servidor.
SHOW max_connections;
-- 2. Muestra cuántas de esas conexiones están reservadas solo para administradores.
SHOW superuser_reserved_connections;
-- 3. Muestra el tiempo máximo que puede durar una consulta antes de ser cancelada.
SHOW statement_timeout;
-- 4. Muestra cuánto tiempo puede estar una conexión inactiva con una transacción abierta.
SHOW idle_in_transaction_session_timeout;

