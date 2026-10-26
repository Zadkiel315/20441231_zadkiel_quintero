
-- =====================================================
-- ACTIVIDAD 8: Consultar los roles y sus privilegios
-- =====================================================

SELECT
    rolname,       -- Nombre del rol
    rolsuper,      -- Si es superusuario
    rolinherit,    -- Si hereda privilegios
    rolcreaterole, -- Si puede crear roles
    rolcreatedb,   -- Si puede crear bases de datos
    rolcanlogin    -- Si puede iniciar sesión
FROM pg_roles
ORDER BY rolname;  -- Ordenar los roles por nombre
