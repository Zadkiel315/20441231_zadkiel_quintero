# Laboratorio 01 — Protección de datos

## Actividad 1 — Clasificación de los datos

**Matriz de clasificación de la tabla `clientes`**

| Campo | ¿Identifica directamente? | ¿Puede contribuir a identificar? | ¿Requiere protección? | Justificación |
|---|---|---|---|---|
| `id` | No | Sí | Sí | Por sí solo es solo un número, pero si existe una tabla que lo relacione con los datos personales (como `pii.mapa_cliente`), permite llegar a la persona. |
| `nombre` | Sí | Sí | Sí | Identifica a la persona, sobre todo si es poco común. Su capacidad de identificar depende de qué tan específico sea y de si hay otras personas con el mismo nombre. |
| `correo` | Sí | Sí | Sí | Es único por persona y sirve para contactarla o cruzarla con otros registros y servicios. |
| `telefono` | Sí | Sí | Sí | Es único por persona, permite contactarla directamente y vincularla con otros registros. |
| `rfc` | Sí | Sí | Sí | Es un identificador fiscal único; su filtración puede usarse para suplantación de identidad o fraude. |
| `edad` | No | Sí | Sí | Sola no identifica, pero combinada con ciudad, código postal y fecha de alta reduce el número de personas posibles. |
| `ciudad` | No | Sí | Sí | Ubica geográficamente a la persona; combinada con otros datos facilita la reidentificación. |
| `codigo_postal` | No | Sí | Sí | Es más específico que la ciudad y acota mucho la zona donde vive la persona. |
| `fecha_alta` | No | Sí | Sí (riesgo menor) | Sola no identifica, pero combinada con otros campos ayuda a distinguir un registro de otro. |


**1. ¿Qué campos identifican directamente a una persona?**

Los campos `nombre`, `correo`, `telefono` y `rfc` pueden identificar directamente a una persona. El correo, el teléfono y el RFC suelen ser especialmente útiles para identificarla o vincularla con otros registros. En el caso del nombre, su capacidad de identificación depende de qué tan específico sea y de si existen otras personas con el mismo nombre.

**2. ¿Qué campos no identifican por sí solos pero podrían contribuir a hacerlo?**

Los campos `edad`, `ciudad`, `codigo_postal` y `fecha_alta` generalmente no identifican por sí solos a una persona, pero pueden ayudar a distinguirla cuando se combinan con otros atributos. El campo `id` también puede contribuir a identificarla si existe una tabla o relación que lo vincule con sus datos personales.

**3. ¿Qué combinación de campos podría incrementar el riesgo de reidentificación?**

Una combinación de `edad`, `ciudad`, `codigo_postal` y `fecha_alta` puede reducir el número de personas que coinciden con esas características. Si esta combinación se relaciona con información externa o con otros registros, podría facilitar la reidentificación de una persona, incluso cuando se hayan eliminado su nombre y otros identificadores directos.

**4. ¿Todos los datos que deben protegerse son necesariamente datos personales sensibles desde el punto de vista jurídico?**

No. Existen datos personales que deben protegerse, pero que no necesariamente se consideran datos personales sensibles desde el punto de vista jurídico. Por ejemplo, el nombre, el correo electrónico y el teléfono son datos personales, pero no se clasifican automáticamente como sensibles por sí mismos. La clasificación jurídica depende de la naturaleza del dato y de la legislación aplicable. Por lo tanto, que un dato requiera protección no significa necesariamente que sea un dato personal sensible.

---

### Complemento 19.1 — Por qué requieren protección

Estos datos hay que protegerlos porque, si se filtran, se pueden usar para suplantar identidad, hacer fraude (sobre todo con el RFC), mandar spam o exponer la vida privada de los clientes. Los identificadores directos (`nombre`, `correo`, `telefono`, `rfc`) son los más delicados, y los demás (`edad`, `ciudad`, `codigo_postal`, `fecha_alta`) también se protegen porque, combinados, permiten reidentificar a alguien.

---

## Actividad 2 — Enmascaramiento (masking)

**1. ¿Qué información continúa existiendo en la tabla original?**

Todos los datos completos y sin modificar: correo, teléfono y RFC con sus valores reales, además del resto de columnas. La vista no copia ni altera nada; solo transforma los datos al momento de consultarlos.

**2. ¿Qué información puede visualizar el usuario `soporte`?**

Solo lo que muestra la vista `v_clientes_soporte`: `id` y `nombre` completos, los dos primeros caracteres del correo junto con su dominio, los últimos 4 dígitos del teléfono y los últimos 4 caracteres del RFC. No puede ver los valores completos ni consultar la tabla `clientes`.

**3. ¿Por qué no es suficiente ocultar los datos únicamente en la aplicación?**

Porque los datos reales siguen almacenados en la base de datos. Un usuario con credenciales puede conectarse directamente (con `psql`, DBeaver, scripts, etc.) y saltarse la aplicación para consultar la tabla. Además, errores o cambios en la aplicación pueden exponer información sensible. El control debe aplicarse en la base de datos para que sea obligatorio sin importar el medio de acceso.

**4. ¿Qué ocurriría si `soporte` tuviera acceso directo a `clientes`?**

Podría ejecutar `SELECT * FROM clientes;` y ver correo, teléfono y RFC completos, por lo que el enmascaramiento no serviría de nada. Se expondrían datos personales, aumentaría el riesgo de filtración o uso indebido y se incumpliría el principio de mínimo privilegio.


### Complemento 19.2 — Resumen del enmascaramiento

- **Qué se ocultó:** parte del correo (solo se ven los 2 primeros caracteres y el dominio), parte del teléfono (solo los últimos 4 dígitos) y parte del RFC (solo los últimos 4 caracteres).
- **Para quién:** para el usuario `soporte`.
- **Por qué:** soporte necesita saber con quién habla para atender al cliente, pero no necesita ver los datos completos (mínimo privilegio).
- **Mecanismo:** una vista (`v_clientes_soporte`) que transforma los datos al consultarlos, y permisos: `soporte` tiene `SELECT` sobre la vista y ningún acceso a la tabla `clientes`.
- **Limitación:** el nombre se ve completo, así que soporte todavía puede identificar a la persona. Reduce el riesgo, pero no anonimiza.

---

## Actividad 4 — Separación de funciones

## Preguntas

**1. ¿Qué ocurriría si `analista` pudiera consultar también `pii.mapa_cliente`?**

Podría unir `analitica.clientes` con `pii.mapa_cliente` mediante el token y obtener el `cliente_id` de cada registro. Con ese identificador podría reconstruir la identidad completa de cada persona. La seudonimización perdería su utilidad, porque el analista tendría tanto los datos como la llave para revertirla.

**2. ¿Qué principio de seguridad se está aplicando al separar ambos accesos?**

Se aplica el principio de **separación de funciones** (o de deberes), junto con el de **mínimo privilegio**. Cada rol solo accede a lo estrictamente necesario para su trabajo, y ningún usuario concentra el acceso a los datos seudonimizados y al mapa que permite revertirlos.

**3. ¿Por qué la seudonimización no equivale a anonimización?**

Porque en la seudonimización la relación con la persona puede recuperarse si se dispone de información adicional, en este caso la tabla `pii.mapa_cliente`. En la anonimización la reidentificación no es posible por ningún medio razonable. Además, los datos seudonimizados siguen siendo datos personales, ya que campos como `edad`, `ciudad`, `codigo_postal` y `fecha_alta` pueden combinarse para reidentificar a una persona.

**4. ¿Qué información permite volver a relacionar el token con una persona?**

La tabla `pii.mapa_cliente`, que vincula cada `token` con el `cliente_id`. Ese identificador, a su vez, se relaciona con los datos completos de la persona en `public.clientes` (nombre, correo, teléfono y RFC).


### Complemento 19.3 — Tokens, mapa y accesos

- **Cómo se generaron los tokens:** con la función `gen_random_uuid()`, habilitando antes la extensión `pgcrypto`. Se hizo un `INSERT ... SELECT` sobre `clientes` para que cada cliente recibiera su propio UUID aleatorio en `pii.mapa_cliente`. Lo bueno de usar un UUID aleatorio es que el token no se calcula a partir de ningún dato del cliente, entonces no se puede adivinar ni sacar con un hash. Cada cliente recibió un token que reemplaza a sus identificadores directos en `analitica.clientes`.
- **Dónde está el mapa de correspondencia:** en la tabla `pii.mapa_cliente`, dentro del esquema `pii`, que relaciona cada `token` con su `cliente_id`.
- **Quién debería poder acceder al mapa:** solo un rol administrativo o de seguridad (por ejemplo, el responsable de los datos) y solo cuando haya una razón justificada. El rol `analista` no debe tener acceso.
- **Por qué se separaron los permisos:** para que nadie junte los datos seudonimizados con el mapa que permite revertirlos (separación de funciones y mínimo privilegio).

---

## Actividad 6 — Análisis del riesgo de reidentificación

**1. ¿Qué identificadores directos fueron eliminados?**

Se eliminaron `id`, `nombre`, `correo`, `telefono` y `rfc`. El resultado solo contiene el rango de edad, la región y el total de registros por grupo, sin ninguna fila individual.

**2. ¿Qué cuasi-identificadores permanecen?**

Permanecen el rango de edad y la región (los dos primeros dígitos del código postal). Aunque están generalizados, siguen siendo datos que pueden combinarse con información externa para identificar a una persona.

**3. ¿Qué combinaciones de atributos podrían reducir el anonimato?**

La combinación de rango de edad y región, sobre todo si se agregan otros campos como `ciudad`, `codigo_postal` completo o `fecha_alta`. Cuantos más atributos se combinan, más pequeños son los grupos y más fácil es distinguir a una persona. También puede ayudar a reidentificar el cruce con fuentes externas (redes sociales, padrones, otras bases).

**4. ¿Qué sucede cuando un grupo contiene pocos registros?**

Las personas de ese grupo son más fáciles de distinguir. Un grupo de una sola persona permite identificarla directamente, y en un grupo muy pequeño es más probable inferir sus características. Por eso se suprimen los grupos menores al umbral `k`.

**5. ¿Qué atributos deberían generalizarse?**

La edad (en rangos amplios), el código postal (a menos dígitos o a una región mayor), la `ciudad` y la `fecha_alta` (por ejemplo, solo el año o el trimestre).

**6. ¿Qué información debería suprimirse?**

Los identificadores directos (`nombre`, `correo`, `telefono`, `rfc`, `id`) y los grupos con menos registros que el umbral `k`. También conviene suprimir los valores atípicos o poco comunes que hagan único a un registro.

**7. ¿Es correcto afirmar que el conjunto de datos es “100 % anónimo”? ¿Por qué?**

No. Cumplir `k = 5` solo garantiza que cada combinación de edad y región tiene al menos 5 registros, pero no demuestra anonimato total. Pueden existir otros atributos, combinaciones o información externa que permitan reidentificar. Además, `k-anonimato` no protege contra la inferencia de atributos cuando todos los registros de un grupo comparten el mismo valor. La anonimización siempre es una reducción del riesgo, no una garantía absoluta.

### Complemento 19.4 — Resumen de la anonimización

- **Identificadores eliminados:** `id`, `nombre`, `correo`, `telefono` y `rfc`.
- **Atributos generalizados:** la edad se cambió por un rango de edad y el código postal por una región (los dos primeros dígitos).
- **Grupos suprimidos:** los 3 grupos que salían (31-45 en región 80 con 3 registros, 46+ en región 82 con 1 registro y 31-45 en región 81 con 1 registro) quedaron fuera porque ninguno llegaba a 5. Con los 5 clientes de prueba la consulta con `HAVING COUNT(*) >= 5` devolvió 0 filas, o sea que se suprimieron todos. Con tan pocos datos es normal, y en una base real con más registros sí saldrían grupos.
- **Riesgo que permanece:** aunque se cumpla `k = 5`, el rango de edad y la región siguen siendo cuasi-identificadores que se pueden cruzar con información externa, y no se puede decir que el conjunto sea 100 % anónimo.

---

## Actividad 7 — Retención de datos

**¿Qué registros serían afectados?**

Los clientes cuya `fecha_alta` sea anterior a la fecha actual menos 5 años. Por ahora la consulta devolvió 0 registros, o sea que no hay clientes que pasen el periodo de conservación. La consulta queda lista para cuando existan. No se ejecutó ningún `DELETE`.

**¿Cuál sería la justificación del periodo?**

Cinco años es un tiempo razonable para guardar los datos por temas fiscales, contratos o atención al cliente. Después de eso ya no hay motivo para conservarlos y solo aumenta el riesgo de que se filtren. El periodo real habría que confirmarlo con el área jurídica.

**¿Qué aprobación debería existir antes de eliminar información?**

La autorización del responsable de los datos, con visto bueno del área jurídica o de seguridad, para asegurarse de que los registros no se necesiten por alguna auditoría o trámite legal.

**¿Qué respaldo debería existir?**

Un respaldo completo de `clientes` y de las tablas relacionadas (`pii.mapa_cliente` y `analitica.clientes`) hecho justo antes de borrar, guardado en un lugar seguro y probado para confirmar que se puede restaurar.

**¿Qué evidencia debería conservarse?**

- La consulta usada y el conteo de registros identificados.
- La aprobación de la eliminación.
- La fecha y quién lo hizo.
- La confirmación del respaldo.
- El resultado después de borrar (cuántos registros se eliminaron).

**¿Qué procedimiento permitiría recuperar información eliminada accidentalmente?**

Restaurar el respaldo hecho antes de la eliminación en un entorno de pruebas, sacar solo los registros borrados y volver a insertarlos en la tabla original. Si hay archivado WAL, también se puede recuperar a un punto en el tiempo anterior al borrado.

---

### Complemento 19.5 — Qué conservar, qué eliminar y controles

- **Criterio utilizado:** 5 años contados desde `fecha_alta` (valor de ejercicio, a confirmar con jurídico).
- **Información que debería conservarse:** los clientes dentro de los 5 años, los datos que se necesiten por obligaciones fiscales, contratos vigentes o atención activa, y cualquier registro que esté en una auditoría o trámite legal.
- **Información que podría eliminarse:** los clientes con `fecha_alta` de hace más de 5 años que ya no tengan ningún motivo para conservarse, junto con sus datos relacionados en `pii.mapa_cliente` y `analitica.clientes`, para no dejar tokens sueltos.
- **Controles antes de eliminar:** aprobación del responsable de los datos con visto bueno de jurídico o seguridad, respaldo completo probado, revisión del conteo de registros a borrar (de preferencia dentro de una transacción), y conservar la evidencia (consulta, aprobación, fecha, quién lo hizo y resultado).

---

## 19.6 Conclusiones

**¿Qué técnica utilizarías para un área de soporte?**

Enmascaramiento, con una vista como la de `v_clientes_soporte`. Soporte necesita saber con quién está hablando para atender al cliente, pero no necesita ver el correo, teléfono o RFC completos. Con la vista ven lo justo y los datos reales quedan guardados en la tabla, a la que no tienen acceso.

**¿Qué técnica utilizarías para un área de analítica?**

Seudonimización. A los analistas les sirve ver el comportamiento de los datos (edad, ciudad, fecha de alta, etc.), pero no les importa quién es cada persona. Entonces se cambian los identificadores directos por un token, y el mapa que une el token con la persona se queda aparte, en el esquema `pii`, donde el analista no puede entrar.

**¿Qué técnica utilizarías para publicar estadísticas?**

Anonimización, usando generalización y agregación. Si los datos van a salir de la organización o se van a publicar, no deben llevar filas individuales: se agrupan en rangos de edad y regiones, y se suprimen los grupos con menos de `k` registros. Así el riesgo de reidentificación baja bastante, aunque nunca llega a cero.

**¿Por qué ninguna de estas técnicas sustituye al control de acceso?**

Porque todas dependen de que los permisos estén bien puestos. El enmascaramiento no sirve si `soporte` puede hacer un `SELECT` directo a `clientes`, y la seudonimización no sirve si el analista puede consultar `pii.mapa_cliente`. Además, los datos originales siguen existiendo en la base de datos y las técnicas solo cambian lo que se ve en cada caso. Estas técnicas reducen el riesgo, pero quien decide quién puede entrar a qué es el control de acceso, así que se necesitan las dos cosas juntas.

---

## 20. Preguntas de reflexión

**1. ¿Cuál es la diferencia entre enmascaramiento y seudonimización?**

El enmascaramiento oculta una parte del dato al mostrarlo (por ejemplo, solo los últimos 4 dígitos del teléfono), pero la persona sigue siendo reconocible y el dato real sigue ahí. La seudonimización reemplaza los identificadores por un token y guarda la relación en otra tabla, así que los datos que se trabajan ya no dicen directamente quién es la persona, aunque con el mapa sí se puede volver a saber.

**2. ¿Por qué la seudonimización no significa anonimización?**

Porque se puede revertir. Mientras exista el mapa (`pii.mapa_cliente`), alguien puede volver a unir el token con la persona. Además, campos como `edad`, `ciudad`, `codigo_postal` y `fecha_alta` siguen ahí y combinados pueden reidentificar a alguien. Por eso los datos seudonimizados siguen siendo datos personales; en la anonimización de verdad ya no se puede regresar a la persona.

**3. ¿Por qué eliminar `nombre` y `RFC` no garantiza que un conjunto de datos sea anónimo?**

Porque los demás campos todavía pueden identificar a alguien si se combinan entre ellos o con información de afuera. Por ejemplo, una persona de cierta edad, en cierto código postal y que se dio de alta en una fecha específica puede ser la única que cumple eso. Quitar los identificadores directos ayuda, pero no es suficiente.

**4. ¿Qué función tienen los cuasi-identificadores?**

Son datos que por sí solos no identifican a nadie, pero que juntos sirven para distinguir a una persona de las demás. Son justo los que se usan para reidentificar, sobre todo cuando se cruzan con otras fuentes (redes sociales, padrones, otras bases). Por eso se generalizan o se controlan.

**5. ¿Por qué es importante separar el mapa de seudonimización?**

Porque el mapa es la llave para revertir los tokens. Si está junto a los datos seudonimizados, o lo puede consultar la misma persona que los usa, la seudonimización no sirve para nada. Al guardarlo aparte (en el esquema `pii`) y con acceso muy limitado, se necesita un acceso extra para reidentificar a alguien, lo que hace mucho más difícil que se haga por error o con mala intención.

**6. ¿Qué principio de seguridad se aplica al impedir que el analista acceda al mapa?**

Principalmente el de separación de funciones, porque ninguna persona junta los datos seudonimizados y la llave para revertirlos. También se aplica el de mínimo privilegio: el analista solo tiene el acceso que necesita para su trabajo y para eso no necesita el mapa.

**7. ¿Por qué una vista puede ser preferible a entregar acceso directo a la tabla?**

Porque con la vista controlas exactamente qué columnas y qué versión de los datos ve el usuario. Así puedes darle acceso a la vista y ninguno a la tabla original, y el usuario solo ve los datos enmascarados o limitados, sin poder consultar lo demás. Si le das la tabla completa, ya no hay forma de limitar lo que ve.

**8. ¿Qué diferencia existe entre proteger un dato para visualización y protegerlo contra acceso no autorizado?**

Proteger para visualización es cambiar cómo se muestra el dato (enmascararlo, acortarlo, generalizarlo) para que quien lo ve no obtenga más de lo necesario. Protegerlo contra acceso no autorizado es evitar que personas sin permiso lleguen al dato real, con permisos, roles, autenticación, etc. Lo primero no sirve si falla lo segundo: si alguien se salta la vista y llega a la tabla, el enmascaramiento no lo detiene.

**9. ¿Por qué la retención forma parte de la protección de datos?**

Porque proteger los datos también implica no guardarlos más tiempo del necesario. Cuando ya no hay motivo para conservar un dato (fiscal, contrato, atención al cliente), mantenerlo solo sirve para que haya más información expuesta si algo sale mal. Definir cuánto tiempo se guarda y qué se borra después es parte de proteger a las personas.

**10. ¿Qué riesgo existe si una organización conserva información indefinidamente?**

Que aumenta el riesgo de filtraciones, de usos indebidos y de incumplimiento legal, porque se acumulan datos de personas que ya ni son clientes y que nadie revisa. Si hay una brecha de seguridad, el daño es mayor porque hay más datos que se pueden perder. Además, es más difícil controlar y mantener actualizada tanta información que ya no se necesita.