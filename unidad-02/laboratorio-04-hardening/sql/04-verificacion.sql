-- ACTIVIDAD 16: Verificación final de la configuración

-- Dirección de escucha y puerto
SHOW listen_addresses;
SHOW port;

-- Método configurado para nuevas contraseñas
SHOW password_encryption;

-- Configuración TLS
SHOW ssl;
SHOW ssl_min_protocol_version;

-- Reglas de autenticación configuradas
SELECT
    type,
    database,
    user_name,
    address,
    auth_method
FROM pg_hba_file_rules;

-- Roles y privilegios
SELECT
    rolname,
    rolsuper,
    rolcreaterole,
    rolcreatedb,
    rolcanlogin
FROM pg_roles
ORDER BY rolname;

-- Extensiones instaladas
SELECT extname, extversion
FROM pg_extension
ORDER BY extname;

-- Parámetros de conexiones
SHOW max_connections;
SHOW superuser_reserved_connections;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;

-- Estado TLS de la conexión actual
SELECT
    a.pid,
    a.usename,
    a.client_addr,
    s.ssl,
    s.version,
    s.cipher
FROM pg_stat_activity AS a
JOIN pg_stat_ssl AS s
    ON a.pid = s.pid
WHERE a.pid = pg_backend_pid();