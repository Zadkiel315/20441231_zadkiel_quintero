# 03 — El problema de la gestión de claves

## Objetivo

Identificar por qué es una mala práctica guardar claves dentro del código o en archivos que se suben a un repositorio.

## Comando o procedimiento

1. Crear temporalmente el archivo `sql/ejemplo-mala-practica.sql`.
2. Escribir la consulta de demostración que utiliza `pgp_sym_decrypt()` con la clave ficticia `CLAVE-DE-PRUEBA`.
3. Revisar el archivo para identificar dónde aparece la clave.
4. Eliminar el archivo temporal antes de la entrega final, como indica la actividad.

Consulta utilizada:

```sql
SELECT pgp_sym_decrypt(
    rfc_cifrado,
    'CLAVE-DE-PRUEBA'
)
FROM clientes_protegidos;
```

## Resultado obtenido

En el archivo se puede ver que la clave está escrita directamente dentro de la consulta. Aunque en esta práctica es una clave ficticia, se puede observar el riesgo que existiría si se usara una clave real.

## Análisis

**¿Qué ocurriría si esta clave fuera una clave utilizada realmente por una organización y el archivo se publicara en un repositorio Git?**

Si alguien encuentra el archivo, también podría conocer la clave y usarla para intentar acceder a la información cifrada. Aunque después se borre el archivo, la clave podría seguir apareciendo en el historial del repositorio.

Por eso no se deben subir contraseñas, claves ni otros datos secretos a Git.

## Conclusión

Aprendí que no basta con cifrar la información, también hay que cuidar las claves. Si una clave real se publica en un repositorio, otras personas podrían encontrarla y poner en riesgo los datos. Por eso en esta actividad solo usamos una clave de prueba y el archivo temporal no debe quedarse en la entrega final.