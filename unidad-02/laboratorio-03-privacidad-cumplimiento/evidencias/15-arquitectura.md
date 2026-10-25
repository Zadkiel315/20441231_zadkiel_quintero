# LAB-03 - Arquitectura de datos protegidos

## 1. Objetivo

Proponer una forma de organizar los datos de los clientes para que cada area tenga acceso solamente a la informacion que necesita y se mantengan protegidos los datos personales.

## 2. Procedimiento

### Actividad 15 - Propuesta de arquitectura de datos protegidos

```text
                    BASE DE DATOS
                          |
          +---------------+---------------+
          |               |               |
          v               v               v
      Operacion        Analitica       Auditoria
          |               |               |
          v               v               v
    Datos necesarios   Datos agrupados  Registro de
    para el servicio   y estadisticas   accesos y cambios
          |               |
          v               v
    Acceso limitado   Sin datos personales
    por usuario       innecesarios
```

**Controles propuestos**

- **Acceso:** crear roles y permisos para que cada area consulte solo lo que necesita.
- **Minimizacion:** evitar guardar datos que no tengan una finalidad clara.
- **Proteccion de informacion sensible:** limitar el acceso a datos como el RFC y los datos de contacto.
- **Retencion:** definir cuanto tiempo se conservaran los datos y revisar si todavia son necesarios.
- **Trazabilidad:** registrar los accesos y cambios importantes para saber quien los realizo.
- **Eliminacion:** revisar donde existen copias de los datos antes de eliminarlos, siguiendo el procedimiento autorizado.
- **Atencion de solicitudes:** contar con un procedimiento para atender solicitudes de acceso, rectificacion, cancelacion y oposicion, con apoyo del area responsable.

Esta propuesta es conceptual. No es necesario crear todas estas areas o tablas en PostgreSQL para esta actividad.

## 3. Resultado

Se propuso una arquitectura que separa los datos de operacion, las estadisticas y los registros de auditoria. Tambien se identificaron controles para limitar accesos y proteger la informacion.

## 4. Analisis

Considero que esta organizacion seria mas segura porque cada area tendria acceso a la informacion que realmente necesita. Por ejemplo, analitica podria trabajar con cantidades agrupadas sin consultar directamente los nombres, correos o RFC de los clientes.

Tambien es importante tener un control de los cambios y definir que se hara con los datos cuando ya no sean necesarios.

## 5. Conclusion

Separar los datos por finalidad ayuda a tener un mejor control de la informacion. Si se combinan permisos limitados, minimizacion, retencion y registros de auditoria, se pueden reducir los riesgos y proteger mejor los datos personales.

---

# Verificacion final del laboratorio

### 1. Privacidad

**Que diferencia existe entre seguridad de la informacion y privacidad?**

La seguridad se encarga de proteger la informacion contra accesos o cambios no autorizados. La privacidad se enfoca en que los datos personales se utilicen de manera adecuada y para una finalidad definida.

### 2. Finalidad

**Por que una organizacion no deberia utilizar automaticamente todos los datos que posee para cualquier proposito?**

Porque los datos se recopilaron para una finalidad y no significa que se puedan usar para cualquier otra. Antes de darles un nuevo uso, se debe revisar si corresponde y que condiciones se deben cumplir.

### 3. Minimizacion

**Por que almacenar mas informacion no necesariamente es mejor?**

Porque guardar datos innecesarios aumenta los riesgos y hace mas dificil protegerlos. Es mejor conservar solo los que se necesitan.

### 4. ARCO

**Que implicaciones tecnicas tienen los derechos de acceso, rectificacion, cancelacion y oposicion?**

Pueden requerir consultar los datos de una persona, corregir informacion, revisar donde existen copias o limitar el uso de los datos para una finalidad. Estas acciones deben realizarse con los permisos y procedimientos adecuados.

### 5. Retencion

**Por que la conservacion indefinida puede representar un riesgo?**

Porque los datos podrian seguir guardados aunque ya no sean necesarios y podrian quedar expuestos si ocurre un acceso no autorizado.

### 6. Gobierno

**Quien deberia decidir que datos pueden utilizarse y para que finalidad?**

La decision debe involucrar a las areas responsables del servicio, privacidad y cumplimiento. Cada area debe explicar que necesita, mientras que el DBA ayuda a aplicar los controles tecnicos.

### 7. DBA

**Cual es la responsabilidad del DBA y cuales decisiones deben involucrar a otras areas?**

El DBA se encarga de administrar la base de datos, configurar permisos, proteger la informacion y apoyar con consultas y cambios. Las decisiones sobre las finalidades, los periodos de conservacion y la atencion de solicitudes deben involucrar a las areas responsables.