-- =========================================
-- ACTIVIDAD 7: RETENCIÓN DE DATOS
-- =========================================

-- 1. Registros que superan los 5 años
SELECT *
FROM clientes
WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years';

-- Debe funcionar: soporte consulta la vista con datos limitados
SELECT *
FROM v_clientes_soporte;

-- Debe fallar con "permission denied": soporte no accede a la tabla base
SELECT *
FROM clientes;


-- Debe funcionar: analítica consulta su propia tabla del esquema analitica
SELECT *
FROM analitica.clientes;

-- Debe fallar con "permission denied": no accede a la tabla que relaciona
-- identificadores
SELECT *
FROM pii.mapa_cliente;

-- Debe fallar con "permission denied": no accede a la tabla original
SELECT *
FROM public.clientes;


