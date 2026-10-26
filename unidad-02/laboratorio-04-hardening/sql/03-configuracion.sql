
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

-- Muestra el número máximo de conexiones simultáneas que permite el servidor.
SHOW max_connections;
-- Muestra cuántas de esas conexiones están reservadas solo para administradores.
SHOW superuser_reserved_connections;
-- Muestra el tiempo máximo que puede durar una consulta antes de ser cancelada.
SHOW statement_timeout;
-- Muestra cuánto tiempo puede estar una conexión inactiva con una transacción abierta.
SHOW idle_in_transaction_session_timeout;

-- ========================================================================
-- ACTIVIDAD 12: Revisar rutas de archivos para verificar permisos del sistema operativo
-- ========================================================================


-- Consultar la ruta del directorio de datos
SHOW data_directory;
-- Consultar la ruta del archivo de configuración principal
SHOW config_file;
-- Consultar la ruta del archivo de autenticación
SHOW hba_file;

-- ========================================================================
-- ACTIVIDAD 13: Revisar exposición de red
-- ========================================================================


-- Dirección de escucha configurada
SHOW listen_addresses;
-- Puerto de escucha
SHOW port;