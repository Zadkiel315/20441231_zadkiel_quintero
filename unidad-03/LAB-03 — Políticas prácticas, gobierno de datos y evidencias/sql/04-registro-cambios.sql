-- ============================================================
-- Actividad 7: Registro de cambios y conciliacion
-- ============================================================

-- Crear esquema de gobierno
CREATE SCHEMA gobierno;

-- Evitar que cualquier usuario tenga acceso al esquema
REVOKE ALL ON SCHEMA gobierno FROM PUBLIC;

-- Crear tabla de solicitudes de cambio
CREATE TABLE gobierno.solicitudes_cambio (
    folio            TEXT PRIMARY KEY,
    descripcion      TEXT NOT NULL,
    solicitado_por   TEXT NOT NULL,
    aprobado_por     TEXT,
    ambiente         TEXT NOT NULL CHECK (
        ambiente IN ('desarrollo', 'pruebas', 'produccion')
    ),
    fecha_aprobacion TIMESTAMPTZ,
    ventana_inicio   TIMESTAMPTZ,
    ventana_fin      TIMESTAMPTZ
);

-- Documentar la tabla
COMMENT ON TABLE gobierno.solicitudes_cambio IS
'Registro de solicitudes de cambio en la base comercial. Propietario: Comite de cambios. Custodio: DBA. Evidencia de POL-06.';

-- Registrar una solicitud aprobada
INSERT INTO gobierno.solicitudes_cambio VALUES
(
    'CAM-2026-014',
    'Agregar columna canal_alta a clientes',
    'Gerencia Comercial',
    'Comite de cambios',
    'produccion',
    now() - interval '1 day',
    now() - interval '5 minutes',
    now() + interval '1 hour'
);

-- Ejecutar el cambio autorizado
ALTER TABLE public.clientes
ADD COLUMN canal_alta VARCHAR(20);

-- Documentar la nueva columna
COMMENT ON COLUMN public.clientes.canal_alta IS
'Canal por el que se registro el cliente. Cambio CAM-2026-014.';

-- Verificar si el cambio se realizo dentro de la ventana
SELECT folio,
       aprobado_por,
       ventana_inicio <= now() AND now() <= ventana_fin AS dentro_de_ventana
FROM gobierno.solicitudes_cambio;

-- Extrae de la bitácora todos los cambios de estructura y privilegios con la vista del LAB-01:

SELECT num,
       substr(linea, 1, 23)                    AS momento,
       substring(linea from 'user=([^ ]*)')     AS usuario,
       substring(linea from 'statement: (.*)$') AS sentencia
FROM dba.bitacora
WHERE linea ~ 'statement: (CREATE|ALTER|DROP|GRANT|REVOKE)'
ORDER BY num;