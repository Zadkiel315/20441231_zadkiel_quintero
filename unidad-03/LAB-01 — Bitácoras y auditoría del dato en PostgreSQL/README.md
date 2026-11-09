# LAB-01 — Bitácoras y auditoría del dato en PostgreSQL

## Despliegue

| Elemento | Valor |
|---|---|
| Motor | PostgreSQL **18.6** (la guía indica 16; no se usó esa versión) |
| Forma de despliegue | Instalación nativa en Windows 64 bits (x86_64-windows) |
| Base de datos | `comercial` |
| Directorio de datos | `C:/Program Files/PostgreSQL/18/data` |
| Archivo de configuración | `C:/Program Files/PostgreSQL/18/data/postgresql.conf` |
| Archivo de autenticación | `C:/Program Files/PostgreSQL/18/data/pg_hba.conf` |
| Sesión de administrador | `psql -U postgres -d comercial` (llega por TCP a `::1`, no por socket) |
| Sesiones por red | `psql "postgresql://<usuario>:<contraseña>@127.0.0.1/comercial?application_name=<aplicacion>"` desde PowerShell |
| Zona horaria de la bitácora | `America/Chihuahua` (CST, UTC-6) |

### Diferencias con la guía

- **Valores iniciales.** El servidor ya tenía `logging_collector`, `log_connections` y `log_disconnections` en `on`, y `log_line_prefix = %t`. Por eso `logging_collector` no requirió reinicio (`pending_restart = f`).
- **`pg_hba.conf`.** Ya exigía `scram-sha-256` en las reglas `local`, `127.0.0.1` y `::1`; no se editó.
- **Idioma.** Los mensajes están en español (`sentencia:`, `SENTENCIA:`, `DETALLE:`), y los filtros de las consultas aceptan español e inglés.
- **Codificación.** La bitácora está en Windows-1252 y la vista `dba.bitacora` la convierte con `pg_read_binary_file` y `convert_from(..., 'LATIN1')`.
- **`ip_cliente`.** Aparece como `::1` para el administrador (en Linux habría quedado vacía).
- **`statement_timeout`.** El servidor lo fija en 60 s y canceló el reporte de la Actividad 9.
- **Avisos `parameter ... changed to ...`.** No aparecieron en la bitácora consultada.

## Contenido

```
LAB-01/
├── README.md
├── informe.md
├── sql/
│   ├── 01-colector-y-vista.sql
│   ├── 02-configuracion-bitacora.sql
│   ├── 03-privilegios-estructura.sql
│   ├── 04-esquema-auditoria.sql
│   ├── 05-funcion-disparador.sql
│   └── 06-campos-modificados.sql
└── evidencias/
    ├── 01-configuracion-inicial.md
    ├── 02-colector.md
    ├── 03-incidente-sin-bitacora.md
    ├── 04-configuracion-bitacora.md
    ├── 05-accesos.md
    ├── 06-privilegios-estructura.md
    ├── 07-modificaciones.md
    ├── 08-errores.md
    ├── 09-pg-stat-activity.md
    ├── 10-diseno-auditoria.md
    ├── 11-incidente-auditado.md
    ├── 12-altas-bajas.md
    ├── 13-manipulacion.md
    ├── 14-limites.md
    ├── 15-cronologia.md
    ├── bitacora-lab01.log
    └── bitacora-lab01.sha256
```

## Actividades

| Archivo | Actividad | Resumen |
|---|---|---|
| `01-configuracion-inicial.md` | 1 | Identificación del servidor, reglas de autenticación y parámetros de registro iniciales |
| `02-colector.md` | 2 | Colector, lectura de la bitácora con SQL y vista `dba.bitacora` |
| `03-incidente-sin-bitacora.md` | 3 | `UPDATE` del RFC sin evidencia de la sentencia |
| `04-configuracion-bitacora.md` | 4 | `log_connections`, `log_disconnections`, `log_line_prefix` y `log_statement = ddl` |
| `05-accesos.md` | 5 | Accesos exitosos y fallidos; consulta de intentos fallidos por usuario |
| `06-privilegios-estructura.md` | 6 | `GRANT`, `REVOKE`, `ALTER TABLE` y secretos en la bitácora |
| `07-modificaciones.md` | 7 | `ddl` frente a `mod` |
| `08-errores.md` | 8 | Errores de autorización y de dependencias |
| `09-pg-stat-activity.md` | 9 | Sesión activa en `pg_stat_activity` y su PID en la bitácora |
| `10-diseno-auditoria.md` | 10 | Diseño de `auditoria.cambios_clientes` |
| `11-incidente-auditado.md` | 11 y 12 | Función, disparador `SECURITY DEFINER` e incidente auditado |
| `12-altas-bajas.md` | 13 | `INSERT` y `DELETE` auditados; conflicto con la retención |
| `13-manipulacion.md` | 14 | Intentos de manipular la auditoría; disparador desactivado por el administrador |
| `14-limites.md` | 15 | Lecturas sin rastro y volumen del `UPDATE` masivo |
| `15-cronologia.md` | 16 y 17 | Exportación, hash, cronología de 27 eventos y respuestas a Dirección |

La **Parte C (pgaudit)** es opcional y **no se realizó**; por eso no existe `16-pgaudit.md`.

## Integridad de la bitácora exportada

`evidencias/bitacora-lab01.log` es la bitácora vigente exportada (439 líneas, 71 504 bytes, 2026-11-08 18:49:16 a 22:19:03, UTF-16 LE). El SHA-256 está en `evidencias/bitacora-lab01.sha256`:

```
8A7D8EFB558CE1F668690ED48E60DCF36BD463CA5698E0BA7FE9AB0FCB138578
```

Para verificarlo:

```powershell
Get-FileHash evidencias/bitacora-lab01.log -Algorithm SHA256
```

```bash
sha256sum evidencias/bitacora-lab01.log
```

El resultado (sin distinguir mayúsculas) debe coincidir con el valor guardado.

## Secretos y datos sensibles

- **Contraseñas.** Ninguna contraseña aparece en el repositorio. En los comandos de las evidencias figura `<contraseña>` o `<contraseña de práctica>`.
- **Bitácora exportada.** Los secretos (la contraseña de `rol_temporal`, el verificador SCRAM de `soporte_ana` y la contraseña de `postgres`) se sustituyeron por `<REDACTED>`. La primera exportación contenía los dos últimos, se descartó y se rehízo; el detalle está en `evidencias/15-cronologia.md` y en el informe.
- **Tabla de auditoría.** Solo se incluyen las filas necesarias para demostrar cada punto, no un volcado completo.
- **Datos.** Los clientes son ficticios (correos `@example.test`).

## Informe

Las conclusiones del laboratorio están en [`informe.md`](informe.md): despliegue, configuración aplicada, eventos observados, auditoría del dato, limitaciones, riesgos de la bitácora, cronología y reflexión.

