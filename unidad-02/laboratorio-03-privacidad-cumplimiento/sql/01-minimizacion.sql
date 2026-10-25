-- LAB-03 - Actividad 2: Principio de minimizacion
-- Crear una tabla con los datos necesarios para soporte

-- 1. Crear la tabla con los campos que necesita soporte
CREATE TABLE clientes_soporte (
    id INT,
    nombre VARCHAR(100),
    correo VARCHAR(150),
    telefono VARCHAR(20)
);

-- 2. Copiar solamente los datos necesarios desde clientes
INSERT INTO clientes_soporte (id, nombre, correo, telefono)
SELECT id, nombre, correo, telefono
FROM clientes;

-- 3. Consultar los datos de la tabla
SELECT *
FROM clientes_soporte;
