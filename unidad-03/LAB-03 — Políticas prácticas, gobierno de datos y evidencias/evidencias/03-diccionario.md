# Actividad 3 — Diccionario de datos operativo

## Objetivo

Documentar la tabla `clientes` directamente en PostgreSQL mediante comentarios `COMMENT` y complementar la informacion con su clasificacion, finalidad y controles de calidad.

## Resultado

Se agregaron comentarios a la tabla y sus 10 columnas. Despues se consulto el diccionario utilizando `information_schema.columns` y `col_description`.

Tambien se exporto el resultado a `evidencias/diccionario-clientes.csv`.

## Diccionario complementario

| Columna | Clasificacion | Finalidad | Control aplicado | ¿Cambios auditados? | Regla de calidad |
|---|---|---|---|---|---|
| id | Identificador interno | Identificar a cada cliente | Clave primaria y generacion automatica | No aplica | No debe repetirse |
| nombre | Dato personal | Identificar al cliente | Campo obligatorio | Si, mediante trigger de LAB-01 cuando se modifica | No debe estar vacio |
| correo | Dato personal | Contacto y notificaciones | Campo obligatorio y revision de formato | Si, mediante trigger de LAB-01 cuando se modifica | Formato de correo valido y sin duplicados |
| telefono | Dato personal | Comunicacion con el cliente | Revision de longitud y formato | Si, mediante trigger de LAB-01 cuando se modifica | Numero telefonico valido |
| rfc | Dato personal | Facturacion | Vista enmascarada para soporte (U2) | Si, LAB-01 Parte B | Formato RFC |
| edad | Dato personal | Analitica agregada | Revision de valores permitidos | Si, mediante trigger de LAB-01 cuando se modifica | Edad entre 0 y 120 |
| ciudad | Dato de ubicacion | Organizar clientes por zona | Revision de datos registrados | Si, mediante trigger de LAB-01 cuando se modifica | No debe contener valores vacios cuando se capture |
| codigo_postal | Dato de ubicacion | Identificar zona y cobertura | Revision de longitud y formato | Si, mediante trigger de LAB-01 cuando se modifica | Codigo postal de 5 digitos |
| fecha_alta | Dato operativo | Conocer la fecha de registro | Valor por defecto CURRENT_DATE | Si, mediante trigger de LAB-01 cuando se modifica | No debe ser una fecha futura |
| segmento | Dato comercial | Clasificar clientes | Catalogo de segmentos autorizados | Si, mediante trigger de LAB-01 cuando se modifica | Debe pertenecer a un segmento valido |

## Preguntas

### 1. ¿Que ventaja tiene guardar el significado en COMMENT en lugar de solo en un documento aparte?

La ventaja es que la informacion queda guardada directamente en la base de datos y se puede consultar junto con las columnas. Asi, cuando otra persona revise la tabla, puede conocer para que sirve cada campo sin tener que buscar otro documento.

### 2. ¿Quedaron registrados los COMMENT en la bitacora? ¿Con que nivel de log_statement?

Los comentarios se guardaron en PostgreSQL. Para comprobar si tambien aparecen en la bitacora se debe revisar la configuracion y los registros. En LAB-01 se utilizo `log_statement = 'mod'`, que registra sentencias de modificacion, por lo que los comandos `COMMENT` pueden quedar registrados como operaciones de modificacion. 

### 3. ¿Que informacion del diccionario debe mantenerse fuera del motor? ¿Por que?

La informacion mas detallada sobre responsables, autorizaciones, procedimientos internos y reglas de negocio debe mantenerse tambien en documentos externos. Esto ayuda a tener un respaldo de la informacion y permite explicar las politicas que no se pueden representar solamente con comentarios en PostgreSQL.

## Conclusion

Con esta actividad se documento la tabla `clientes` desde el propio motor de base de datos. Tambien se genero un archivo CSV y se complemento el diccionario con la clasificacion de los datos, su finalidad y sus reglas de calidad.