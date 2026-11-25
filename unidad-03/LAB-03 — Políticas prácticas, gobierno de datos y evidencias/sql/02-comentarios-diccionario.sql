-- ============================================================
-- Actividad 3: Diccionario de datos operativo
-- ============================================================

-- Agrega una descripción general a la tabla clientes.
COMMENT ON TABLE public.clientes IS
'Clientes de Comercializadora Norte. Propietario: Gerencia Comercial. Custodio: DBA. Clasificación: confidencial (contiene datos personales).';


-- Identificador del cliente.
COMMENT ON COLUMN public.clientes.id IS
'Identificador interno del cliente. Generado por el sistema.';

-- Nombre del cliente.
COMMENT ON COLUMN public.clientes.nombre IS
'Nombre completo. Dato personal identificador directo.';

-- Correo del cliente.
COMMENT ON COLUMN public.clientes.correo IS
'Correo de contacto. Dato personal. Uso: notificaciones al cliente.';

-- Teléfono del cliente.
COMMENT ON COLUMN public.clientes.telefono IS
'Numero telefonico de contacto. Dato personal. Uso: comunicacion con el cliente.';

-- RFC del cliente.
COMMENT ON COLUMN public.clientes.rfc IS
'RFC del cliente. Dato personal. Uso: facturación. Cambios auditados en auditoria.cambios_clientes.';

-- Edad del cliente.
COMMENT ON COLUMN public.clientes.edad IS
'Edad en años cumplidos. Dato personal. Uso: analítica agregada.';

-- Ciudad del cliente.
COMMENT ON COLUMN public.clientes.ciudad IS
'Ciudad relacionada con el cliente. Dato de ubicacion. Uso: organizacion y analisis de clientes por zona.';

-- Código postal del cliente.
COMMENT ON COLUMN public.clientes.codigo_postal IS
'Codigo postal relacionado con el cliente. Dato de ubicacion. Uso: identificacion de zona y cobertura.';

-- Fecha de registro del cliente.
COMMENT ON COLUMN public.clientes.fecha_alta IS
'Fecha en que el cliente fue registrado en el sistema. Uso: seguimiento de antiguedad del cliente.';

-- Segmento comercial del cliente.
COMMENT ON COLUMN public.clientes.segmento IS
'Clasificacion comercial del cliente. Uso: organizacion y analisis de clientes por segmento.';


-- Consulta que muestra la información de las columnas de la tabla
-- clientes, incluyendo sus tipos de datos, longitud, si aceptan
-- valores nulos, valores por defecto y sus descripciones.
SELECT c.ordinal_position          AS pos,
       c.column_name               AS columna,
       c.data_type                 AS tipo,
       c.character_maximum_length  AS longitud,
       c.is_nullable                AS acepta_nulos,
       c.column_default             AS valor_por_defecto,
       col_description('public.clientes'::regclass, c.ordinal_position) AS descripcion
FROM information_schema.columns c
WHERE c.table_schema = 'public'
  AND c.table_name = 'clientes'
ORDER BY c.ordinal_position;