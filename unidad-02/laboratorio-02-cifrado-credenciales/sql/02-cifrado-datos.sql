-- Actividad 2: Cifrado de informacion sensible

-- 1. Crear una tabla para guardar el nombre y el RFC cifrado
CREATE TABLE clientes_protegidos (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    rfc_cifrado BYTEA NOT NULL
);

-- 2. Insertar un cliente con su RFC cifrado
INSERT INTO clientes_protegidos (
    nombre,
    rfc_cifrado
)
VALUES (
    'Ana López',
    pgp_sym_encrypt('LOPA900101ABC', 'CLAVE-DE-PRUEBA')
);

-- 3. Consultar la tabla para ver como se guardo la informacion
SELECT *
FROM clientes_protegidos;

-- 4. Recuperar el RFC usando la misma clave que se utilizo para cifrarlo
SELECT
    id,
    nombre,
    pgp_sym_decrypt(
        rfc_cifrado,
        'CLAVE-DE-PRUEBA'
    ) AS rfc
FROM clientes_protegidos;


-- Actividad 3: Ejemplo de mala practica
-- Se utiliza una clave ficticia para demostrar el problema.
SELECT pgp_sym_decrypt(
    rfc_cifrado,
    'CLAVE-DE-PRUEBA'
)
FROM clientes_protegidos;

