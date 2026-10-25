
-- LAB-04: Hardening y configuración segura de PostgreSQL
-- Actividad 1: Identificación de la superficie de ataque
-- Objetivo de estas consultas: revisar la configuración inicial del servidor.

-- 1. Versión instalada de PostgreSQL
SELECT version();
-- 2. Puerto en el que escucha PostgreSQL
SHOW port;
-- 3. Interfaces de red en las que escucha PostgreSQL
SHOW listen_addresses;
-- 4. Estado de SSL/TLS
SHOW ssl;
-- 5. Método predeterminado para almacenar contraseñas
SHOW password_encryption;
-- 6. Sesiones y conexiones registradas en PostgreSQL
SELECT
    pid,
    usename,
    datname,
    client_addr,
    client_port,
    application_name
FROM pg_stat_activity
ORDER BY pid;
