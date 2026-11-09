-- ============================================================
-- Actividad 11 — Consultar los registros de auditoria
-- ============================================================

-- Activa la visualizacion expandida para mostrar los resultados verticalmente.
\x

-- Consulta los registros de auditoria con informacion del usuario,
-- aplicacion, direccion IP, operacion realizada y cliente afectado.
SELECT id_evento, momento, usuario_sesion, usuario_efectivo, aplicacion, ip_cliente, operacion, id_cliente
FROM auditoria.cambios_clientes ORDER BY id_evento;

-- Desactiva la visualizacion expandida.
\x


-- Consulta los cambios realizados en los registros de clientes.
-- Compara los valores anteriores con los nuevos para identificar
-- que campos fueron modificados.
SELECT a.id_evento, a.momento, a.usuario_sesion, a.ip_cliente,
       d.key                     AS campo,
       a.valores_antes ->> d.key AS antes,
       d.value #>> '{}'          AS despues
FROM auditoria.cambios_clientes a
CROSS JOIN LATERAL jsonb_each(a.valores_despues) d
WHERE a.operacion = 'UPDATE'
  AND a.valores_antes -> d.key IS DISTINCT FROM d.value
ORDER BY a.id_evento;