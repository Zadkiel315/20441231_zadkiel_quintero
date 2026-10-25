
-- LAB-04: Hardening y configuración segura de PostgreSQL
-- Actividad 2: Identificar los archivos de configuración

-- Ruta del archivo principal de configuración
SHOW config_file;
-- Ruta del archivo de reglas de autenticación
SHOW hba_file;
-- Ruta del archivo de identificación de usuarios
SHOW ident_file;
-- Directorio donde se almacenan los datos
SHOW data_directory;
-- Directorio configurado para los registros
SHOW log_directory;
-- Configuración del registro de conexiones
SHOW log_connections;
-- Configuración del registro de desconexiones
SHOW log_disconnections;
