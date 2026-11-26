# LAB-03 — Politicas practicas, gobierno de datos y evidencias

## 1. Descripcion

Este laboratorio tiene como finalidad aplicar politicas practicas de auditoria, gobierno y administracion de datos en PostgreSQL y MongoDB.

Se trabaja con la base de datos `comercial`, revisando los mecanismos de registro de operaciones, privilegios de usuarios, auditoria de cambios, catalogos de datos, conservacion de registros y conciliacion de solicitudes de cambio.

Tambien se integran las evidencias obtenidas durante las actividades para elaborar un expediente de auditoria interna.

## 2. Objetivo

Documentar y analizar los mecanismos de auditoria y gobierno de datos utilizados en los sistemas revisados, identificando los controles existentes, sus limitaciones y los riesgos que necesitan atencion.

## 3. Entorno de trabajo

| Componente | Tecnologia |
|---|---|
| Sistema operativo | Windows |
| Base de datos relacional | PostgreSQL 18.6 |
| Base de datos NoSQL | MongoDB Community 7 |
| Herramienta de administracion | pgAdmin |
| Entorno de MongoDB | Docker |

## 4. Estructura del laboratorio

```text
LAB-03/
│
├── README.md
├── EXPEDIENTE.md
│
├── evidencias/
│   ├── 01-calidad.md
│   ├── 02-responsables.md
│   ├── 03-diccionario.md
│   ├── 04-catalogo.md
│   ├── 05-conservacion.md
│   ├── 06-conciliacion.md
│   ├── diccionario-clientes.csv
│   ├── E1-configuracion-registro.txt
│   ├── E2-privilegios.txt
│   ├── E3-disparadores.txt
│   ├── E4-muestra-auditoria.txt
│   ├── E5-bitacora-postgresql.log
│   ├── E5-bitacora-postgresql.sha256
│   └── Archivos de evidencia de MongoDB
│
├── politicas/
│   ├── POL-01
│   ├── POL-02
│   ├── POL-03
│   ├── POL-04
│   ├── POL-05
│   └── POL-06
│
└── sql/
    ├── 01-verificaciones-calidad.sql
    ├── 02-comentarios-diccionario.sql
    ├── 03-inventario-tablas.sql
    └── 04-registro-cambios.sql
```

## 5. Contenido de las carpetas

### evidencias/

Contiene los resultados obtenidos durante las actividades del laboratorio. Incluye documentos de calidad, responsables, diccionario y catalogo de datos, conservacion, conciliacion, privilegios, disparadores, auditoria y registros de PostgreSQL y MongoDB.

Los archivos de hash permiten comprobar la integridad de determinados archivos de evidencia.

### politicas/

Contiene las seis politicas documentadas para establecer criterios de administracion, proteccion, auditoria, conservacion y gobierno de los datos.

### sql/

Contiene los scripts utilizados para realizar verificaciones de calidad, agregar comentarios al diccionario de datos, consultar el inventario de tablas y registrar cambios.

## 6. Actividades realizadas

Durante el laboratorio se trabajaron los siguientes aspectos:

- Verificacion de la calidad de los datos.
- Identificacion de responsables y custodios de la informacion.
- Elaboracion del diccionario y catalogo de datos.
- Definicion de criterios de conservacion de registros.
- Registro y conciliacion de solicitudes de cambio.
- Revision de privilegios de usuarios.
- Verificacion del estado de los disparadores de auditoria.
- Analisis de muestras de auditoria y bitacoras.
- Revision de registros de MongoDB.
- Identificacion de hallazgos, limitaciones y riesgos.

## 7. Expediente de auditoria

El archivo principal del laboratorio es `EXPEDIENTE.md`.

En el se integran el alcance de la revision, la configuracion de auditoria, la interpretacion de bitacoras, los elementos de gobierno, las politicas, la conciliacion de cambios, los hallazgos, las limitaciones y el indice de evidencias.

Este documento funciona como el expediente general de auditoria interna de la base de datos comercial.

## 8. Consideraciones y limitaciones

- Las politicas documentadas establecen criterios de trabajo y no significan que todos los controles se encuentren implementados tecnicamente.
- Los registros de auditoria permiten identificar determinadas operaciones, pero no necesariamente todas las acciones realizadas.
- La configuracion de auditoria tiene limitaciones dependiendo de las herramientas y ediciones utilizadas.
- Las politicas de respaldo y recuperacion se documentaron, pero no se realizaron pruebas completas de restauracion.
- Los hallazgos y riesgos identificados se conservan en el expediente para su seguimiento.

## 9. Preguntas de reflexion

### 1. ¿Por que el gobierno de datos no es "burocracia" en el contexto del problema inicial de la unidad?

Porque permite tener un mejor control sobre la informacion y saber quien es responsable de ella, quien puede modificarla y como deben registrarse los cambios. En el laboratorio se observo que no basta con tener una base de datos funcionando, tambien es necesario contar con reglas y controles para evitar modificaciones sin autorizacion y poder investigar cuando ocurre algun problema.

### 2. ¿Que diferencia hay entre el propietario tecnico de una tabla en PostgreSQL y el propietario del dato?

El propietario tecnico es el usuario o rol de PostgreSQL que tiene el control administrativo sobre una tabla y puede realizar acciones como modificar su estructura o administrar sus permisos. En cambio, el propietario del dato es el area o persona de la organizacion que tiene la responsabilidad sobre la informacion, su uso y su calidad. Por ejemplo, una tabla puede estar administrada tecnicamente por el DBA, pero la informacion de los clientes puede ser responsabilidad de la Gerencia Comercial.

### 3. ¿Por que una politica sin evidencia no supera una auditoria?

Porque una politica solamente demuestra que existen reglas escritas, pero no comprueba que realmente se cumplan. Para demostrar su aplicacion se necesitan evidencias como registros, consultas, archivos de configuracion, bitacoras y resultados de verificaciones. En este laboratorio se utilizaron diferentes archivos de evidencia para respaldar lo documentado en las politicas y en el expediente.

### 4. ¿Que parte del expediente seria la mas dificil de mantener actualizada? ¿Como lo resolverias?

Considero que la parte mas dificil seria el registro de cambios, hallazgos y evidencias, porque cada modificacion en la base de datos puede generar nuevos eventos que deben revisarse y relacionarse con sus respectivas solicitudes. Lo resolveria estableciendo revisiones periodicas, responsables definidos y un procedimiento para registrar cada cambio con su fecha, usuario, motivo y evidencia correspondiente.

### 5. ¿Que hallazgo de tu expediente tiene mayor impacto y por que?

Considero que uno de los hallazgos de mayor impacto es la posibilidad de que un administrador desactive un disparador de auditoria y realice modificaciones sin que estas queden registradas en la tabla de auditoria. Esto se observo en LAB-01, Actividad 14, cuando se desactivo temporalmente el disparador para modificar un dato y despues se volvio a habilitar. Es importante porque demuestra que los controles pueden ser modificados por usuarios con privilegios elevados y que no siempre se conserva un registro completo de los cambios.

### 6. ¿Por que documentar una limitacion es preferible a ocultarla ante una auditoria?

Porque permite conocer el alcance real de los controles y reconocer que aspectos necesitan mejorarse. Si se oculta una limitacion, se puede dar una idea incorrecta sobre la seguridad del sistema y dificultar futuras investigaciones. En cambio, al documentarla se demuestra transparencia y se pueden proponer soluciones. En este laboratorio se identificaron limitaciones en los mecanismos de auditoria de PostgreSQL y MongoDB, asi como en las pruebas de respaldo y recuperacion.

## 10. Conclusion

El laboratorio permitio integrar evidencias de PostgreSQL y MongoDB para revisar como se administran, protegen y auditan los datos de una organizacion.

Ademas, se documentaron politicas, responsabilidades, catalogos y procedimientos que ayudan a mejorar el control de la informacion y facilitan futuras revisiones de auditoria.