# 01 — Protección de credenciales

## Objetivo

Demostrar por qué no se deben guardar contraseñas directamente en la base de datos y cómo protegerlas usando hash y sal con `pgcrypto` de PostgreSQL 16.

## Comando o procedimiento

Los comandos completos están en `sql/01-credenciales.sql`. Los ejecuté uno por uno en pgAdmin (Query Tool) en este orden:

1. Crear la tabla insegura `usuarios_insegura`, insertar al usuario `juan` con la contraseña `Password123` y consultar la tabla.
2. Ejecutar dos veces `SELECT crypt('Password123', gen_salt('bf'));` para comparar los resultados.
3. Crear la tabla segura `usuarios_segura` con la columna `password_hash`.
4. Insertar al usuario `juan` usando `crypt('Password123', gen_salt('bf'))`.
5. Consultar la tabla `usuarios_segura`.
6. Probar la contraseña correcta (`Password123`) y una incorrecta (`OtraPassword`) para ver qué resultado aparece.

## Resultado obtenido

### 1. Tabla insegura (`usuarios_insegura`)

```sql
SELECT * FROM usuarios_insegura;
```

| id | usuario | password |
|----|---------|----------|
| 1  | juan    | Password123 |

La contraseña aparece completa, tal como se guardó.

### 2. Dos ejecuciones de `crypt()` con `gen_salt('bf')`

```sql
SELECT crypt('Password123', gen_salt('bf'));
```

Primera ejecución: `$2a$06$eNIaBmSlm//dlc/xTRDr1OC.O0aNbkqh7Vz7fGog6Kg9jm432LSBS`

Segunda ejecución: `$2a$06$TDP/hiFV8dgxF7yShpHRkuhjtihwUgPKNredk9r4TfV9ziKN9dkIm`

Los dos resultados son diferentes.

### 3. Tabla segura (`usuarios_segura`)

```sql
SELECT * FROM usuarios_segura;
```

| id | usuario | password_hash |
|----|---------|---------------|
| 1  | juan    | $2a$06$TDP/hiFV8dgxF7yShpHRkuhjtihwUgPKNredk9r4TfV9ziKN9dkIm |

Ya no aparece la contraseña original, sino el hash que se guardó.

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

Podría ver las contraseñas de los usuarios directamente, sin tener que hacer nada más. Esto es un problema porque, si alguien obtiene la información de la base de datos, también tendría las contraseñas.

### Preguntas de la sección 7.3

**1. ¿Son iguales?**

No, los dos resultados son diferentes aunque se usó la misma contraseña.

**2. Si no son iguales, ¿por qué?**

Porque cada vez que se ejecuta `gen_salt()` se genera una sal diferente. Por eso, aunque la contraseña sea la misma, el resultado cambia.

**3. ¿Qué función cumple `gen_salt()`?**

Sirve para generar una sal aleatoria que se usa al crear el hash de la contraseña.

**4. ¿Qué función cumple `crypt()`?**

Sirve para generar el hash de una contraseña y también para comprobar si una contraseña es correcta.

**5. ¿Esto es cifrado reversible?**

No, porque no se puede recuperar directamente la contraseña original a partir del hash. Se usa para guardar la contraseña de una forma más segura.

### Preguntas de la sección 7.5

**1. ¿Qué resultado obtuviste con la contraseña correcta?**

Me dio `true`, porque la contraseña que escribí coincide con la que se guardó.

**2. ¿Qué resultado obtuviste con la contraseña incorrecta?**

Me dio `false`, porque la contraseña que escribí era diferente a la original.

**3. ¿Por qué no es necesario recuperar la contraseña original?**

Porque solo necesitamos comprobar si la contraseña que escribe el usuario es correcta. No hace falta saber cuál era la contraseña original.

**4. ¿Por qué un hash no debe confundirse con cifrado?**

Porque el cifrado permite recuperar la información con una clave, mientras que el hash se utiliza para comprobar datos sin tener que recuperar la contraseña original.

### Consideración para aplicaciones reales

En esta actividad usamos `crypt()` para aprender cómo proteger las contraseñas. En una aplicación real se deben usar métodos seguros y los que recomiende el framework que se esté utilizando. También es importante no guardar contraseñas directamente en la base de datos ni inventar métodos propios para protegerlas.

## Conclusión

Con esta actividad aprendí que no es seguro guardar las contraseñas tal cual en una tabla, porque cualquiera que tenga acceso podría verlas. Al usar un hash, la contraseña queda protegida y se puede comprobar si es correcta sin tener que recuperarla. También entendí que la sal hace que una misma contraseña pueda generar resultados diferentes.