# 02 — Cifrado de información sensible

## Objetivo

Aprender cómo proteger información sensible, como el RFC de un cliente, usando cifrado en PostgreSQL y comprobar que se puede recuperar cuando se tiene la clave correcta.

## Comando o procedimiento

Los comandos se ejecutaron en pgAdmin (Query Tool) en este orden:

1. Crear la tabla `clientes_protegidos` con los campos `id`, `nombre` y `rfc_cifrado`.
2. Insertar un registro de prueba usando `pgp_sym_encrypt()` para cifrar el RFC.
3. Consultar la tabla con `SELECT * FROM clientes_protegidos;`.
4. Recuperar el RFC usando `pgp_sym_decrypt()` y la clave de prueba.

## Resultado obtenido

### 1. Consultar la información cifrada

```sql
SELECT * FROM clientes_protegidos;
```

El RFC aparece cifrado en la columna `rfc_cifrado`, por lo que no se muestra directamente como texto normal.

### 2. Recuperar el RFC

```sql
SELECT
    id,
    nombre,
    pgp_sym_decrypt(
        rfc_cifrado,
        'CLAVE-DE-PRUEBA'
    ) AS rfc
FROM clientes_protegidos;
```

Al usar la clave correcta, se puede ver nuevamente el RFC original: `LOPA900101ABC`.

## Análisis

**1. ¿Qué diferencia existe entre `crypt()` y `pgp_sym_encrypt()`?**

`crypt()` se usa para proteger contraseñas mediante un hash, mientras que `pgp_sym_encrypt()` cifra información que después se puede recuperar con una clave.

**2. ¿Cuál de los dos mecanismos permite recuperar el dato original?**

`pgp_sym_encrypt()`, porque permite recuperar el dato usando la clave correcta. Con `crypt()` no se recupera la contraseña original directamente.

**3. ¿Qué ocurre si se utiliza una clave incorrecta?**

No se puede recuperar el dato correctamente y PostgreSQL puede mostrar un error al intentar descifrarlo.

**4. ¿Qué problema de seguridad representa colocar la clave directamente en una consulta?**

Que otras personas podrían encontrar la clave si tienen acceso al código, a los archivos o a los registros donde aparece. Por eso no es buena idea poner claves reales directamente en las consultas.

## Conclusión

Con esta actividad aprendí que el cifrado sirve para proteger información como el RFC y que se puede recuperar cuando se tiene la clave correcta. También entendí que la clave debe cuidarse, porque si alguien la obtiene podría acceder a la información protegida.