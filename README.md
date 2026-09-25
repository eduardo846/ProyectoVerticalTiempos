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
- Comentarios asociados a cada actividad finalizada.
- Persistencia local mediante `localStorage`.
- Persistencia compartida mediante `server.py` y `registros.txt`.
- Edición y exportación de información desde el dashboard administrador.
- Interfaz adaptable para escritorio y dispositivos móviles.
- Diseño responsive para teléfonos, tablets y pantallas de escritorio.
- Recarga segura de la sesión y del listado de actividades.

## Acceso y roles

### Inicio de sesión

La aplicación solicita credenciales antes de mostrar el dashboard:

| Usuario | Contraseña | Rol |
|---|---|---|
| `admin` | `admin` | Administrador |
| `user` | `user` | Usuario |

El rol se conserva únicamente durante la sesión de la pestaña del navegador.
Para salir, utiliza **Cerrar sesión**. Si no hay una sesión válida, el
dashboard permanece bloqueado.

### Administrador

Inicia sesión con `admin` / `admin`. Permite:

- Iniciar y finalizar tiempos.
- Corregir o borrar tiempos.
- Agregar, editar y eliminar actividades.
- Ajustar horas planificadas.
- Reiniciar todos los tiempos.
- Agregar, consultar y actualizar comentarios de tareas finalizadas.
- Exportar los registros a CSV.

### Usuario

Inicia sesión con `user` / `user`. Permite consultar las actividades e iniciar
o finalizar sus tiempos. No puede modificar la planificación, editar
registros, agregar actividades, eliminar información, reiniciar tiempos ni
exportar datos. Sí puede agregar, consultar y actualizar comentarios de tareas
finalizadas.

> Las credenciales actuales se validan en el navegador y son de demostración.
> Para un entorno productivo se requiere autenticación y autorización en el
> servidor. No se deben reutilizar estas credenciales en un entorno real.

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

En PowerShell:

```powershell
$env:PORT = "8081"
python server.py
```

La interfaz se adapta automáticamente al tamaño de la pantalla. En teléfonos
los filtros se muestran en columna, las tarjetas de área se organizan en dos
columnas y cada actividad distribuye sus tiempos y acciones en bloques
independientes. En escritorio se conserva la vista compacta de varias
columnas.

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
un servicio `systemd` en `/opt/cronometro`. Está preparado para Red Hat
Enterprise Linux (RHEL) 8 y 9, y debe ejecutarse con permisos de administrador.

### Requisitos del servidor

- Red Hat/RHEL 8 o 9.
- Acceso SSH con un usuario que pueda utilizar `sudo`.
- Python 3; el instalador lo instala con `dnf` si no está disponible.
- `systemd` activo.
- `firewalld` habilitado si se desea abrir automáticamente el puerto `8080`.

Instala los paquetes base en el servidor:

```bash
sudo dnf install -y python3 openssh-server curl firewalld
sudo systemctl enable --now sshd
sudo systemctl enable --now firewalld
```

Desde la raíz del proyecto en el servidor:

```bash
sudo bash deploy/instalar.sh
```

El instalador:
1. Instala Python 3 con `dnf` si no está disponible.
2. Crea el usuario de sistema no privilegiado `cronometro`.
3. Copia `server.py` y la página HTML a `/opt/cronometro`.
4. Crea `registros.txt` si todavía no existe.
5. Conserva los registros existentes durante las actualizaciones.
6. Instala el servicio `cronometro.service`.
7. Habilita el servicio para iniciar con el sistema y lo reinicia.
8. Abre el puerto TCP `8080` si `firewalld` está activo.

El servicio se ejecuta como el usuario `cronometro`, utiliza
`/opt/cronometro/registros.txt` y escucha en el puerto `8080`.

Si el servidor está detrás de un firewall externo, también debes permitir el
puerto TCP `8080` en la red, máquina virtual o proveedor de infraestructura.

Comandos útiles para verificar el servicio:

```bash
sudo systemctl status cronometro
sudo journalctl -u cronometro -n 50 --no-pager
curl http://127.0.0.1:8080/api/registros
```

Después de una actualización manual, vuelve a ejecutar el instalador:

```bash
sudo bash deploy/instalar.sh
```

El instalador reinicia el servicio sin eliminar los registros guardados.

Los comentarios se guardan en la misma línea de cada actividad dentro de
`registros.txt`. También se incluyen en la exportación CSV. Los comentarios
existentes se conservan al actualizar la aplicación o reiniciar el servicio.
Al recargar la página, la sesión válida y el listado se restauran sin dejar la
vista vacía.

## GitHub Actions hacia Red Hat

El workflow [deploy.yml](.github/workflows/deploy.yml) se ejecuta al hacer
`push` a la rama `deployment` y también puede iniciarse manualmente desde la
pestaña **Actions**. El runner temporal de GitHub usa Ubuntu y se conecta por
SSH al servidor Red Hat/RHEL configurado.

Configura estos secrets en el repositorio:

```text
DEPLOY_HOST
DEPLOY_USER
DEPLOY_SSH_KEY
DEPLOY_KNOWN_HOSTS
```

`DEPLOY_PORT` es opcional y utiliza `22` por defecto.

Después de modificar la aplicación o la documentación, publica los cambios en
`deployment` para activar el despliegue:

```powershell
git add .
git commit -m "Actualizar aplicación"
git push origin deployment
```

El usuario remoto debe poder ejecutar mediante `sudo`:

```bash
sudo bash ~/cronometro-src/deploy/instalar.sh
```

Para configurar el acceso SSH, instala la clave pública del usuario de
despliegue en:

```text
/home/USUARIO/.ssh/authorized_keys
```

Prueba manualmente la conexión antes de ejecutar el workflow:

```bash
ssh -i ~/.ssh/id_ed25519 USUARIO@HOST_RED_HAT
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

El servidor actual no incluye autenticación de servidor ni HTTPS. Las
credenciales `admin/admin` y `user/user` se encuentran en el frontend y no
deben considerarse una medida de seguridad. Antes de exponerlo a Internet o a
una red no confiable, debe protegerse mediante una red privada, proxy inverso
con HTTPS, autenticación real y restricciones de acceso al endpoint
`PUT /api/registros`.
