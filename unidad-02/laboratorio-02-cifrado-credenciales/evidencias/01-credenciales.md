#  01 — Protección de credenciales

## Objetivo

Demostrar por qué no se deben guardar contraseñas en texto claro y cómo protegerlas con hash y sal usando la extensión `pgcrypto` de PostgreSQL 16.

## Comando o procedimiento

Los comandos completos están en `sql/01-credenciales.sql`. Se ejecutaron uno por uno en pgAdmin (Query Tool) en este orden:

1. Crear la tabla insegura `usuarios_insegura`, insertar a `juan` con `Password123` y consultarla.
2. Ejecutar dos veces `SELECT crypt('Password123', gen_salt('bf'));` y comparar.
3. Crear la tabla segura `usuarios_segura` con la columna `password_hash`.
4. Insertar a `juan` usando `crypt('Password123', gen_salt('bf'))`.
5. Consultar `usuarios_segura`.
6. Verificar la contraseña correcta (`Password123`) y una incorrecta (`OtraPassword`).

## Resultado obtenido

### 1. Tabla insegura (`usuarios_insegura`)

```sql
SELECT * FROM usuarios_insegura;
```

| id | usuario | password    |
|----|---------|-------------|
| 1  | juan    | Password123 |

La contraseña se ve completa, tal cual.

### 2. Dos ejecuciones de `crypt()` con `gen_salt('bf')`

```sql
SELECT crypt('Password123', gen_salt('bf'));
```

Primera ejecución: $2a$06$eNIaBmSlm//dlc/xTRDr1OC.O0aNbkqh7Vz7fGog6Kg9jm432LSBS

Segunda ejecución: $2a$06$TDP/hiFV8dgxF7yShpHRkuhjtihwUgPKNredk9r4TfV9ziKN9dkIm

Los dos resultados son diferentes.

### 3. Tabla segura (`usuarios_segura`)

```sql
SELECT * FROM usuarios_segura;
```

| id | usuario | password_hash          |
|----|---------|------------------------|
| 1  | juan    | $2a$06$TDP/hiFV8dgxF7yShpHRkuhjtihwUgPKNredk9r4TfV9ziKN9dkIm|

Ya no aparece la contraseña original.

### 4. Verificación de contraseña

Contraseña correcta (`Password123`):

| usuario | contraseña_correcta |
|---------|---------------------|
| juan    | true                |

Contraseña incorrecta (`OtraPassword`):

| usuario | contraseña_correcta |
|---------|---------------------|
| juan    | false               |

## Análisis

### ¿Qué ocurriría si una persona obtiene acceso de lectura a `usuarios_insegura`?

Ve la contraseña tal cual (`Password123`) con un simple `SELECT`. No tiene que romper nada ni adivinar nada. Y si se filtra la base, se filtran también las contraseñas de todos los usuarios, que además mucha gente reutiliza en otros sitios.

### Preguntas de la sección 7.3

**1. ¿Son iguales?**
No, los dos resultados salen distintos aunque la contraseña es la misma.

**2. Si no son iguales, ¿por qué?**
Porque cada vez que se ejecuta `gen_salt('bf')` se crea una sal aleatoria diferente, y esa sal se mezcla con la contraseña. Sal distinta, hash distinto.

**3. ¿Qué función cumple `gen_salt()`?**
Genera la sal, que es un valor aleatorio que se mezcla con la contraseña antes de hacerle el hash. También le indica a `crypt()` qué algoritmo usar (`'bf'` es bcrypt).

**4. ¿Qué función cumple `crypt()`?**
Toma la contraseña y la sal y las combina con el algoritmo para generar el hash. También sirve para verificar contraseñas: si se le pasa el hash guardado como sal, recalcula el hash con la misma sal.

**5. ¿Esto es cifrado reversible?**
No. Es de un solo sentido: del hash no se puede volver a la contraseña original, no existe forma de "descifrarlo".

### Preguntas de la sección 7.5

**1. ¿Qué resultado obtuviste con la contraseña correcta?**
`true`, porque al recalcular el hash con la misma sal da exactamente el que está guardado.

**2. ¿Qué resultado obtuviste con la contraseña incorrecta?**
`false`, porque al ser otra contraseña el hash resultante no coincide con el guardado.

**3. ¿Por qué no es necesario recuperar la contraseña original?**
Porque nunca hace falta saber cuál es la contraseña, solo comprobar si la que escribe el usuario es la correcta. Se calcula el hash de lo que escribió, se compara con el guardado y, si coinciden, se permite el acceso.

**4. ¿Por qué un hash no debe confundirse con cifrado?**
Porque el cifrado se hace para poder recuperar el dato original usando una clave, y el hash está diseñado justo para que no se pueda recuperar. Son para cosas distintas: cifrado para datos que se necesitan volver a leer (como un RFC) y hash para contraseñas.

### Consideración para aplicaciones reales

`crypt()` con bcrypt se usó aquí para demostrar el concepto. En una aplicación real se debe usar el algoritmo recomendado actualmente (como Argon2id, scrypt o bcrypt) con las herramientas del framework, sin inventar un algoritmo propio, sin guardar contraseñas en texto claro y sin cifrarlas con una clave fija como si fueran datos recuperables.

## Conclusión

Las contraseñas nunca deben guardarse en texto claro, porque quien lea la tabla las obtiene de inmediato. Lo correcto es guardar un hash con sal: es irreversible, y como la sal es aleatoria, la misma contraseña genera hashes distintos. Para validar un acceso no se recupera la contraseña, se recalcula el hash y se compara. Esto es diferente al cifrado, que sí es reversible y se usa para datos que necesitan recuperarse.