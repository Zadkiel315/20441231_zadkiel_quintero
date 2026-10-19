# 05 — Verificar el estado de TLS en PostgreSQL

## Objetivo

Revisar si PostgreSQL tiene SSL activado y comprobar si la conexión actual utiliza TLS. También conocer la versión y el cifrado que se están usando.

## Comando o procedimiento

Ejecuté las siguientes consultas en pgAdmin, usando el Query Tool.

### 1. Revisar la configuración de PostgreSQL

```sql
SHOW ssl;
SHOW ssl_min_protocol_version;
SHOW port;
SHOW listen_addresses;
```

Estas consultas sirven para revisar si SSL está activado, cuál es la versión mínima de TLS permitida, qué puerto utiliza PostgreSQL y en qué direcciones escucha.

### 2. Revisar la conexión actual

```sql
SELECT
    inet_client_addr(),
    inet_client_port();
```

Con esta consulta revisé la dirección y el puerto del cliente conectado.

### 3. Comprobar si la conexión utiliza TLS

```sql
SELECT
    ssl,
    version,
    cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
```

Esta consulta permite ver si la conexión actual está protegida y, si utiliza TLS, muestra su versión y el cifrado empleado.

### 1. Resultados obtenidos

- **SSL:** `off`
- **Versión mínima de TLS:** `TLSv1.2`
- **Puerto:** `5432`
- **Direcciones:** `*`
- **Conexión actual:** dirección `::1` y puerto `53578`
- **Estado de TLS de la conexión actual:** `off`

### 2. Análisis

**¿La conexión actual utiliza TLS?**

No. El resultado de `pg_stat_ssl` mostró `off`, por lo que la conexión actual no está utilizando TLS.

**¿Qué versión de TLS se está utilizando?**

Actualmente no se está utilizando ninguna versión de TLS en esta conexión, porque el estado de SSL apareció como `off`. Aunque la versión mínima configurada es `TLSv1.2`, eso no significa que la conexión actual esté cifrada.

**¿Qué algoritmo de cifrado aparece?**

No aparece un algoritmo de cifrado porque la conexión no está utilizando TLS.

**¿Qué diferencia existe entre una conexión protegida con TLS y una sin TLS?**

Una conexión protegida con TLS cifra la información que se envía entre el cliente y PostgreSQL. Sin TLS, la información no cuenta con ese cifrado durante la comunicación y podría quedar expuesta si alguien logra interceptar el tráfico de red.

### 3. Conclusión

Con esta actividad comprobé que PostgreSQL utiliza el puerto `5432` y está configurado para escuchar en todas las interfaces de red disponibles, porque `listen_addresses` mostró `*`. También observé que la conexión actual utiliza la dirección `::1`, que corresponde a la dirección local IPv6. Sin embargo, la conexión no utiliza TLS, por lo que sería necesario configurar y habilitar esta protección para cifrar la comunicación.
---

# 06 — Conexión mediante psql

## Objetivo

Aprender cómo conectarse a PostgreSQL desde la terminal usando `psql` y solicitar una conexión protegida mediante TLS.

## Comando o procedimiento

Para realizar esta actividad se necesitaba acceder a la terminal de FIC Labs y ejecutar un comando como el siguiente, sustituyendo los datos de ejemplo por los correspondientes a la conexión.

```bash
psql "host=SERVIDOR port=5432 dbname=TU_BASE user=TU_USUARIO sslmode=require"
```

Una vez conectado, se debía ejecutar la siguiente consulta para comprobar el estado de TLS:

```sql
SELECT
    ssl,
    version,
    cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();
```

Sin embargo, no fue posible realizar el procedimiento porque la página `terminal.ficlabs.com.mx` se encontraba caída y no permitía acceder a la terminal.

## Resultado obtenido

La actividad quedó pendiente de ejecución, ya que no fue posible acceder a la terminal para realizar la conexión mediante `psql`.

## Análisis

El parámetro `sslmode=require` solicita una conexión protegida mediante TLS. La consulta a `pg_stat_ssl` permite comprobar si la conexión actual utiliza TLS y muestra la versión y el cifrado cuando están disponibles.

No fue posible comprobar estos datos desde la terminal debido a la indisponibilidad de la página.

## Conclusión

Aprendí cómo se realiza una conexión a PostgreSQL desde la terminal usando `psql` y cómo solicitar el uso de TLS. Aunque no pude ejecutar la prueba, porque la página de la terminal estaba caída, comprendí el procedimiento necesario para realizarla cuando el servicio esté disponible.
---

# 13 — Comprender sslmode

## Objetivo

Conocer los diferentes modos de conexión de PostgreSQL y entender las diferencias entre ellos al proteger la comunicación.

## Comando o procedimiento

En esta parte revisé los principales valores de `sslmode` y lo que hace cada uno.

| Modo | Descripción |
|---|---|
| `disable` | Se conecta sin utilizar TLS. |
| `prefer` | Intenta utilizar TLS, pero puede conectarse sin él si no está disponible. |
| `require` | Exige una conexión TLS, pero no valida completamente la identidad del servidor. |
| `verify-ca` | Utiliza TLS y verifica el certificado con una autoridad certificadora de confianza. |
| `verify-full` | Verifica el certificado y comprueba que el nombre del servidor coincida con el certificado. |

## Resultado obtenido

Identifiqué que existen diferentes modos de conexión y que no todos ofrecen el mismo nivel de protección. Algunos solo solicitan cifrado, mientras que otros también comprueban la identidad del servidor.

## Análisis

Entendí que no basta con cifrar la conexión, porque también es importante comprobar que el servidor sea confiable.

Por ejemplo, `require` solicita TLS, mientras que `verify-full` también comprueba que el certificado corresponda al nombre del servidor.

## Conclusión

Con esta actividad aprendí que `sslmode` permite elegir cómo se realiza la conexión con PostgreSQL. También comprendí que `verify-full` ofrece una comprobación más completa de la identidad del servidor cuando se configura correctamente el certificado y su nombre.