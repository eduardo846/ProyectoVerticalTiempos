# ProyectoVerticalTiempos

Dashboard web para controlar los tiempos de una migración de Storage Pure
Cirion en Venezuela.

## Funcionalidades

- Cronómetro individual por actividad.
- Inicio y finalización de tiempos.
- Resumen global de la ventana de migración.
- Agrupación por fases y áreas.
- Búsqueda y filtros por estado, área, actividad y nodo.
- Indicador de actividades que superan 60 minutos.
- Persistencia local mediante `localStorage`.
- Persistencia compartida mediante `server.py` y `registros.txt`.
- Edición y exportación de información desde el dashboard administrador.
- Interfaz adaptable para escritorio y dispositivos móviles.

## Modos de acceso

### Administrador

Es el modo predeterminado. Permite:

- Iniciar y finalizar tiempos.
- Corregir o borrar tiempos.
- Agregar, editar y eliminar actividades.
- Ajustar horas planificadas.
- Reiniciar todos los tiempos.
- Exportar los registros a CSV.

### Usuario

El dashboard restringido se abre agregando `?role=user` a la URL:

```text
http://SERVIDOR:8080/?role=user
```

El usuario puede consultar las actividades e iniciar o finalizar sus tiempos.
No puede modificar la planificación, editar registros, agregar actividades,
eliminar información ni exportar datos.

Para volver al dashboard administrador:

```text
http://SERVIDOR:8080/?role=admin
```

> El parámetro de URL es una restricción de interfaz. Para un entorno
> productivo se recomienda agregar autenticación y autorización en el servidor.

## Ejecución local

### Opción 1: Windows

Ejecuta:

```text
iniciar.bat
```

Después abre:

```text
http://127.0.0.1:8080/
```

El archivo de datos se guarda en:

```text
registros.txt
```

### Opción 2: Python

Requiere Python 3.6 o superior:

```bash
python server.py
```

El puerto predeterminado es `8080`. Se puede cambiar con la variable
`PORT`:

```bash
PORT=8081 python server.py
```

También se puede indicar una ruta alternativa para los registros con `DATA`:

```bash
DATA=/ruta/registros.txt python server.py
```

## Estructura principal

```text
.
├── Cronómetro · Migración Storage Pure Cirion VE.html
├── server.py
├── registros.txt
├── iniciar.bat
├── deploy/
│   ├── cronometro.service
│   └── instalar.sh
└── .github/
    └── workflows/
        └── deploy.yml
```

## Despliegue en Red Hat/RHEL

El script [deploy/instalar.sh](deploy/instalar.sh) instala la aplicación como
un servicio systemd en `/opt/cronometro`.

En el servidor:

```bash
sudo bash deploy/instalar.sh
```

El servicio se ejecuta como el usuario no privilegiado `cronometro` y escucha
en el puerto `8080`.

## GitHub Actions

El workflow de despliegue se ejecuta al hacer `push` a la rama `deployment` y
también puede iniciarse manualmente desde la pestaña **Actions**.

Configura estos secrets en el repositorio:

```text
DEPLOY_HOST
DEPLOY_USER
DEPLOY_SSH_KEY
DEPLOY_KNOWN_HOSTS
```

`DEPLOY_PORT` es opcional y utiliza `22` por defecto.

El usuario remoto debe poder ejecutar mediante `sudo`:

```bash
sudo bash ~/cronometro-src/deploy/instalar.sh
```

## Persistencia y registros

`registros.txt` funciona como una base de datos de texto sencilla. El servidor
admite:

```text
GET  /api/registros
HEAD /api/registros
PUT  /api/registros
```

El archivo se actualiza de forma atómica y la interfaz detecta cambios
externos periódicamente.

El archivo `registros.txt` está excluido del repositorio porque contiene datos
operativos de la migración.

## Consideraciones de seguridad

El servidor actual no incluye autenticación ni HTTPS. Antes de exponerlo a
Internet o a una red no confiable, debe protegerse mediante una red privada,
proxy inverso con HTTPS, autenticación y restricciones de acceso al endpoint
`PUT /api/registros`.
