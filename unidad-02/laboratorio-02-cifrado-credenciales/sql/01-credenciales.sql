-- =====================================================
-- LAB-02 | Actividad 1: Protección de credenciales
-- =====================================================


-- Activamos pgcrypto, que trae crypt() y gen_salt()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Checamos que sí quedó instalada
SELECT extname
FROM pg_extension
WHERE extname = 'pgcrypto';

-- Borramos las tablas si ya existían, para poder repetir el script
DROP TABLE IF EXISTS usuarios_insegura;
DROP TABLE IF EXISTS usuarios_segura;


-- Tabla donde la contraseña se guarda tal cual (mala práctica)
CREATE TABLE usuarios_insegura (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL
);

-- Metemos un usuario de prueba
INSERT INTO usuarios_insegura (usuario, password)
VALUES ('juan', 'Password123');

-- Aquí se ve el problema: la contraseña aparece completa
SELECT *
FROM usuarios_insegura;


-- Ejecute este SELECT dos veces y compare:
-- la contraseña es la misma, pero el resultado cambia
-- porque gen_salt('bf') crea una sal aleatoria cada vez
SELECT crypt('Password123', gen_salt('bf'));

SELECT crypt('Password123', gen_salt('bf'));


-- Tabla donde guardamos el hash, no la contraseña
CREATE TABLE usuarios_segura (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL
);

-- Insertamos al usuario con su contraseña ya convertida en hash
INSERT INTO usuarios_segura (usuario, password_hash)
VALUES (
    'juan',
    crypt('Password123', gen_salt('bf'))
);

-- Ahora ya no se ve la contraseña original, solo el hash
SELECT *
FROM usuarios_segura;


-- Contraseña CORRECTA: debe dar true
SELECT
    usuario,
    password_hash = crypt('Password123', password_hash)
        AS contraseña_correcta
FROM usuarios_segura
WHERE usuario = 'juan';

-- Contraseña INCORRECTA: debe dar false
SELECT
    usuario,
    password_hash = crypt('OtraPassword', password_hash)
        AS contraseña_correcta
FROM usuarios_segura
WHERE usuario = 'juan';














