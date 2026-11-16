# LAB-02 — Trazabilidad en MongoDB Community

Materia: Gestión de Seguridad y Desempeño de Bases de Datos, Unidad III.
Alumno: Zadkiel Uriel Quintero Parra.

## Cómo desplegué el servidor

| Dato | Valor |
|---|---|
| Despliegue | Contenedor Docker (Anexo A.2) dentro de GitHub Codespaces |
| Imagen | `mongo:7` (oficial) |
| Versión del servidor | MongoDB **7.0.48 Community** (`modules: []`) |
| Cliente | mongosh 2.14.2, ejecutado dentro del contenedor con `docker exec` |
| Autorización | Habilitada con `--auth` |
| Nombre del contenedor | `dba-u3-mongo` |

```bash
docker run --name dba-u3-mongo -p 27017:27017 -d mongo:7 --auth
```

### Por qué Codespaces

Mi computadora tiene un Intel Pentium Silver N5000, que no tiene instrucciones AVX. MongoDB 5.0 y posteriores las requieren, y el contenedor local fallaba con `exec format error`. La causa era el procesador, no Docker ni la imagen. Por eso monté el servidor en un Codespaces, que es un Linux en la nube.

### Diferencias respecto a la guía

- La versión es 7.0.48 y no 7.0.43. Solo cambia el parche.
- Todos los comandos corren con `docker exec dba-u3-mongo mongosh ...`, porque mongosh está dentro del contenedor.
- La bitácora de `mongod` sale por la salida estándar (no hay `systemLog.path`) y se lee con `docker logs`.
- El Codespace se apagó por inactividad durante el laboratorio. Eso reinició el servidor y vació la memoria de `getLog`, y lo documenté donde afectó.

## Estructura

```
LAB-02/
├── README.md
├── informe.md
├── evidencias/
│   ├── 01-edicion-y-limitacion.md ... 10-respuesta-direccion.md
│   ├── system-profile.json
│   ├── bitacora-mongod.log
│   ├── docker-logs-completo.log   (extra: bitácora completa del contenedor)
│   └── hashes.sha256
└── scripts/
    └── comandos-mongosh.js
```

## Credenciales

Las contraseñas de práctica son exclusivas de este laboratorio y aparecen como `<REDACTED>` en las evidencias.