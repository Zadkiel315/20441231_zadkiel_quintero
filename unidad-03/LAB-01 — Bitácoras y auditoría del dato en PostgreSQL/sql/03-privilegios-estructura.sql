-- ============================================================
-- Actividad 5 — Accesos exitosos y fallidos
-- ============================================================

-- Busca los registros de conexiones realizadas desde la direccion local 127.0.0.1.
-- Ordena los resultados por numero de registro.
SELECT linea FROM dba.bitacora WHERE linea LIKE '%client=127.0.0.1%' ORDER BY num;


-- ============================================================
-- Actividad 6 — Cambios de privilegios y de estructura
-- ============================================================

-- Quita el permiso UPDATE al usuario soporte_ana sobre la tabla clientes.
REVOKE UPDATE ON clientes FROM soporte_ana;

-- Otorga el permiso UPDATE al usuario app_ventas sobre la tabla clientes.
GRANT UPDATE ON clientes TO app_ventas;

-- Agrega la columna segmento de tipo VARCHAR(20) a la tabla clientes.
ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20);


-- Crea un rol temporal con permiso de inicio de sesion y contrasena.
CREATE ROLE rol_temporal LOGIN PASSWORD 'Temporal_Practica_2026';

-- Elimina el rol temporal creado anteriormente.
DROP ROLE rol_temporal;


-- Consulta los registros de la bitacora que contienen sentencias SQL.
-- Los ordena por numero para mostrar primero los registros mas antiguos.
SELECT linea FROM dba.bitacora WHERE linea LIKE '%statement:%' ORDER BY num;