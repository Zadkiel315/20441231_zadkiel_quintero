# Evidencia 01 — Configuración inicial del servidor PostgreSQL

**Laboratorio:** LAB-01 — Bitácoras y auditoría del dato en PostgreSQL  
**Motor:** PostgreSQL 18.6  
**Sistema operativo:** Windows 64 bits  
**Base de datos:** comercial

## 1. Identificación del servidor

Se realizaron consultas para identificar la versión del motor y las ubicaciones de sus archivos principales.

| Elemento | Resultado |
|---|---|
| Versión | PostgreSQL 18.6 |
| Arquitectura | x86_64-windows |
| Directorio de datos | `C:/Program Files/PostgreSQL/18/data` |
| Archivo de configuración | `C:/Program Files/PostgreSQL/18/data/postgresql.conf` |
| Archivo de autenticación | `C:/Program Files/PostgreSQL/18/data/pg_hba.conf` |

## 2. Revisión de las reglas de autenticación

Se consultó la vista `pg_hba_file_rules` para identificar los métodos de autenticación configurados.

| Línea | Tipo | Dirección | Método de autenticación |
|---|---|---|---|
| 113 | local | Conexión local | scram-sha-256 |
| 115 | host | 127.0.0.1 | scram-sha-256 |
| 117 | host | ::1 | scram-sha-256 |

**Interpretación:**

Las conexiones locales y las conexiones TCP/IP utilizan el método `scram-sha-256`, que requiere autenticación mediante contraseña.

No fue necesario modificar el archivo `pg_hba.conf`, debido a que la configuración ya cumple con el requisito de autenticación del laboratorio.

Esta configuración permitirá realizar pruebas de conexiones exitosas y fallidas.

## 3. Configuración inicial de bitácoras

Se ejecutó una consulta sobre `pg_settings` para identificar los parámetros de registro, sus valores actuales y el origen de cada configuración.

| Parámetro | Valor | Origen |
|---|---|---|
| log_connections | on | configuration file |
| log_destination | stderr | configuration file |
| log_directory | log | default |
| log_disconnections | on | configuration file |
| log_filename | postgresql-%Y-%m-%d_%H%M%S.log | default |
| log_line_prefix | %t | configuration file |
| log_min_error_statement | error | default |
| log_statement | none | default |
| log_timezone | America/Chihuahua | configuration file |
| logging_collector | on | configuration file |

## 4. Preguntas

**Pregunta 1. Con esta configuración, ¿se registra quién se conecta?**

Sí. El parámetro `log_connections` está activado (`on`), por lo que PostgreSQL registra los eventos de conexión. Sin embargo, el prefijo actual no incluye explícitamente el nombre del usuario.

**Pregunta 2. ¿Se registran las sentencias UPDATE?**

No mediante el parámetro `log_statement`, porque está configurado en `none`. Por lo tanto, no se registran las sentencias SQL mediante este mecanismo.

**Pregunta 3. ¿La línea de bitácora incluye el usuario o la dirección IP del cliente?**

No. El parámetro `log_line_prefix` tiene el valor `%t`, que únicamente muestra la hora. No incluye los marcadores `%u` (usuario) ni `%h` (dirección del cliente).

**Pregunta 4. ¿En qué zona horaria se registran los eventos? ¿Por qué importa al reconstruir una cronología?**

La zona horaria configurada es `America/Chihuahua`. Es importante porque permite interpretar correctamente las fechas y horas de los eventos y reconstruir una cronología de lo ocurrido sin confundir los horarios.

**Pregunta 5. Con logging_collector = off, ¿quién decide dónde termina la bitácora: PostgreSQL o el mecanismo con que se desplegó el servidor?**

Cuando `logging_collector` está desactivado (`off`), PostgreSQL no recopila directamente los mensajes en archivos mediante su colector. El destino de la salida `stderr` depende del mecanismo utilizado para iniciar y administrar el servidor.

En esta instalación, el colector está activado (`on`), por lo que PostgreSQL administra la escritura de las bitácoras en archivos.

## 5. Conclusión

La revisión permitió identificar la configuración inicial del servidor PostgreSQL 18.6 y comprobar que la autenticación mediante contraseña ya se encuentra habilitada.

También se identificó que el servidor tiene activados los registros de conexiones y desconexiones, así como el colector de bitácoras. Sin embargo, todavía no registra las sentencias SQL mediante `log_statement` y el prefijo de sus líneas no permite identificar directamente al usuario ni la dirección IP del cliente.

Por esta razón, será necesario ajustar los parámetros de registro durante las siguientes actividades para obtener evidencia más completa sobre los accesos, las modificaciones y los eventos de seguridad que ocurran en la base de datos.

