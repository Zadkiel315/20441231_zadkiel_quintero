-- Actividad 5: Verificar el estado de TLS en PostgreSQL

-- 1. Ver si SSL esta activado en PostgreSQL
SHOW ssl;

-- 2. Ver la version minima de TLS permitida
SHOW ssl_min_protocol_version;

-- 3. Consultar el puerto que utiliza PostgreSQL
SHOW port;

-- 4. Ver en que direcciones escucha PostgreSQL
SHOW listen_addresses;

-- 5. Consultar la direccion y el puerto del cliente actual
SELECT
    inet_client_addr(),
    inet_client_port();

-- 6. Verificar si la conexion actual utiliza TLS
SELECT
    ssl,
    version,
    cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();