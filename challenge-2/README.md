# Challenge 2

> tl;dr: [Ir a la guía de despliegue](#instrucciones-de-despliegue)

## Introducción/Consideraciones

La aplicación consta de dos componentes principales:

### Frontend

Realizado en React, que utiliza Webpack como sistema de construcción para generar los archivos HTML, CSS y JS que se sirven a los clientes. 

Al tratarse de un proyecto de React en la versión 16.13.1, se decidió trabajar con la versión 8.17.0 de NodeJS como entorno de ejecución para el desarrollo y construcción de la aplicación, ya que esta versión de Node es una LTS liberada en un momento del tiempo similar a la versión correspondiente de React. 

### Backend

Realizado en Django 2.1.4, para el cual utilizaremos la versión 3.7 de Python. 

Además de algunas vistas generadas el motor de Django, también ofrece una api REST para permitir la comunicación con el frontend realizado en React

Para la persistencia de información, se requiere de una base de datos relacional. Con esto en mente, y teniendo en cuenta que en los requerimientos de la aplicación (`requirements.txt`) se define como dependencia el paquete `psycopg2`, se decidió trabajar con PostgreSQL. 

## Despliegue

En un entorno de despliegue, el frontend se sirve directamente desde el backend, es decir, la aplicación de React se sirve desde el proyecto de Django. Esto se logra a través del paquete `django-webpack-loader` que permite la inclusión y renderización de proyectos de React dentro del contexto de Django. 

Para esto, el proyecto de Django requiere que los assets obtenidos de la construcción del frontend se ubiquen en una carpeta en la raíz del proyecto, de manera tal que dichos assets se puedan recolectar como los demás archivos estáticos del proyecto. Esto se puede controlar revisando el archivo `settings.py`:

```py
# backend/backend/settings.py
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, "backend/static"),
    os.path.join(BASE_DIR, "assets"),
]
```

A su vez, también se puede controlar que dentro de la carpeta `assets` en la raíz del proyecto, los mismos se deben ubicar dentro de una subcarpeta llamada bundles: 

```py
# backend/backend/settings.py
WEBPACK_LOADER = {
    'DEFAULT': {
        'BUNDLE_DIR_NAME': 'bundles/',
        'STATS_FILE': os.path.join(BASE_DIR, 'webpack-stats.dev.json') if env('ENVIRONMENT', 'local') == 'local'
        else os.path.join(BASE_DIR, 'webpack-stats.prod.json'),
    },
}
```

Si revisamos el proceso de construcción del frontend, vemos que el resultado del mismo se ubica en una carpeta `assets/bundles` que se encuentra por fuera de la carpeta del proyecto del frontend. Entonces, simplemente restaría copiar dicha carpeta a la raíz del proyecto del backend. 

Además, en el bloque de código anterior se puede ver que se requiere un archivo `webpack-stats.{dev,prod}.json`, el cual también es generado durante la construcción del frontend, ubicado junto a la carpeta `assets`. 

De esta forma, el proceso de despliegue de la aplicación se puede resumir de la siguiente manera:

1. Posicionarse en el proyecto del frontend.
1. Instalar las dependencias del proyecto con `npm install` (al tratarse de la versión 8 de Node, no contamos con el comando `npm ci`).
1. Realizar la construcción del frontend con el comando `npm run build`.
1. Copiar los archivos generados en el paso anterior dentro del proyecto del backend.
1. Posicionarse en el proyecto del backend
1. Instalar las dependencias del proyecto con el comando `pip install -r requirements.txt`
1. Configurar las variables de entorno del backend (ver tabla abajo)
1. Ejecutar las migraciones de base de datos (requiere que la BD se encuentre disponible) con el comando `python manage.py migrate`
1. Realizar la recolección de archivos estáticos con el comando `python manage.py collectstatic --noinput`
1. Ejecutar el proyecto del backend con el comando `gunicorn backend.wsgi -b 0.0.0.0:8000 -w 2` dónde:
    1. `-b 0.0.0.0:8000` indica que el servidor WSGI escucha peticiones desde todas las interfaces de red en el puerto 8000.
    1. `-w 2` indica que se utilizaran dos workers (este valor se debería modificar según la carga prevista de la aplicación).

**Nota:** Para la ejecución del proyecto de Django y la conexión con la BD, se debe contar con los siguientes paquetes instalados en el sistema: 

* `libgraphviz-dev` 
* `libpq-dev` 
* `gcc` 
* `python3-dev` 
* `musl-dev`

## Variables de entorno

| Variable     | Descripción                   | Ejemplo                         |
| ------------ | ----------------------------- | ------------------------------- |
| SECRET_KEY   | Valor secreto de Django       | `6p4kr_5jyhnui67s*_...`         |
| DJANGO_DEBUG | Ejecutar Django en modo DEBUG | `True` o `False`                |
| ENVIRONMENT  | Entorno de ejecución          | `prod` o `local`                |
| DB_ENGINE    | Motor de BD a utilizar (*)    | `django.db.backends.postgresql` |
| DB_NAME      | Nombre de la BD a utilizar    | `my_database`                   |
| DB_USER      | Nombre de usuario de la BD    | `my_user`                       |
| DB_PASS      | Contraseña de la BD           | `p455w0rd`                      |
| DB_HOST      | Nombre del host de la BD      | `localhost`                     |
| DB_PORT      | Puerto de conexión de la BD   | `5432`                          |

(*) Revisar los motores de basos de datos disponibles en: https://docs.djangoproject.com/en/2.1/ref/settings/#std-setting-DATABASES

## Ajustes realizados al código

Durante la revisión del código de ambos proyectos, se detectó que eran necesarios dos ajustes para garantizar el correcto funcionamiento del mismo:

1. **Modificar la configuración de producción de Webpack para el proyecto de React**. En la línea 20 del archivo `webpack.config.prod.js` se establecía que la URL pública de los archivos generados sería `/static/public_bundles/`. Este valor debe coincidir con la configuración establecida en el proyecto de Django (mostrada en los bloques de código anteriores) para garantizar que los archivos estáticos se puedan servir de forma correcta. Por lo tanto, se decidió actualizar el valor correspondiente a `/static/bundles/`
1. **Establecer un valor de `Site` por defecto para el proyecto de Django**. Este proyecto cuenta con el módulo de sitios habilitado (se puede ver ya que tiene instalada la app `django.contrib.sites`). Este módulo permite la gestión de diferentes sitios dentro de un solo proyecto de Django, que compartan un mismo depósito de datos. Sin embargo, el proyecto tiene solamente el sitio por defecto habilitado (originalmente example.com), y es necesario indicar que se quiere utilizar el mismo para poder visualizar correctamente el proyecto en modo de desarrollo. Para esto, se agregó en el archivo `settings.py` la constante correspondiente: `SITE_ID = 1`.

## Despliegue con Docker

Una vez que se describió el proceso de construcción del proyecto completo, se puede pasar a realizar la dockerización del mismo. 

En este caso, y considerando que el frontend se debe servir a través de Django, se va a elaborar un solo contenedor para ambos subproyectos. 

Para la construcción de esta imagen, realizaremos un proceso de varios pasos (*multi-stage build*) con las siguientes etapas:

1. A partir de una imagen de Node: 
    1. Instale las dependencias necesarias
    1. Realice la construcción del frontend
1. A partir de una imagen de Python:
    1. Instale las dependencias necesarias
    1. Copie los resultados de la compilación del frontend a la ubicación correspondiente
    1. Configure el arranque del proyecto para realizar la recolección de archivos estáticos y aplicación de migraciones pendientes al iniciar. 
        1. Para esto último, simplemente generamos un `entrypoint` para el proyecto.

## Ejecución en entorno de desarrollo

Para ejecutar el proyecto en modo desarrollo, se puede utilizar `docker-compose`. Trabajaremos con la versión 3.8 de compose, y definiremos los siguientes elementos:

* Servicios:
    * `db`: La instancia de PostgreSQL para almacenar información. 
        * El nombre de la base de datos, el usuario y la contraseña se pasan a través de las mismas variables de entorno utilizadas en el backend. 
        * Se establece un healtcheck periódico para saber cuando la BD se encuentra lista para aceptar conexiones. 
    * `app`: Correspondiente al contendor generado en el apartado anterior. Como es necesario que la BD se encuentre operativa antes de comenzar, se define el servicio `db` como dependencia. 

* Volumenes:
    * `db_data`: Utilizado para persistir la información de la BD a lo largo de diferentes ejecuciones.

## Ejecución en entornos de orquestación de contenedores

Para un despliegue en un entorno productivo, es necesario utilizar una herramienta de orquestación de contenedores. En este caso utilizaremos Kubernetes y Helm. De esta forma, se va a generar un *chart* de Helm para el despliegue de la aplicación. 

El chart realiza un despliegue de los siguientes componentes en un clúster de Kubernetes:

* `Deployment` del contenedor de la aplicación
* `Service` para exponer el Deployment dentro del cluster
* `ConfigMap` con los valores de las variables de entorno de la aplicación
* `Secret` con los valores secretos de las variables de entorno de la aplicación
* `Ingress` para exponer el Service hacia fuera del cluster
* `HorizontalPodAutoscaler` para controlar el escalamiento bajo demanda de la aplicación
* `ServiceAccount`

El Deployment del contenedor de la aplicación incluye la definición de un initContainer, que se utiliza para controlar que la base de datos esté lista para recibir peticiones. De esta forma, se garantiza que la aplicación, y la ejecución de migraciones, se ejecuten una vez la BD se encuentra lista. 

En el archivo values.yaml se pueden modificar varios parámetros del despliegue, entre ellos resaltamos

1. Cantidad de réplicas del Deployment
2. Repositorio/Nombre de imagen a utilizar en el Deployment, así como el tag correspondiente y la política de actualización de la misma.
3. Valores secretos para la descarga de la imagen, si los hubiera
4. Configuración del Service
5. Configuración del Ingress
6. Asignación de recursos de CPU y Memoria
7. Configuración del HorizontalPodAutoscaler
8.  Valores del Secret
9.  Configuración inicial de la instancia de PostgreSQL

Respecto a los valores del Secret y la configuración de PostgreSQL, Helm admite que se sobreescriban los valores por defecto del chart. Con esto, se puede asegurar que los valores secretos se provean al momento de desplegar en cada entorno sin necesidad de incluirlos en el código base del chart. 

## Instrucciones de despliegue

### Despliegue con docker-compose

**Requerimientos previos:** Contar con una instalación local (o acceso a una instalación remota) de Docker, y tener instalados la CLI de `docker` el binario de `docker-compose`.

1. Clonar este repositorio
2. Posicionarse en la carpeta `challenge-2`
3. Generar el archivo `.env` a partir del archivo de ejemplo `.env.example`
   1. Revisar la definición de las variables de entorno en [la sección Variables de entorno](#variables-de-entorno)
4. (opcional) Generar el archivo `docker-compose.override.yml` con los ajustes necesarios para este despliegue (se deja un ejemplo para un entorno de desarrollo).
5. Descargar imágenes y realizar una build local del proyecto: `docker-compose pull && docker-compose build`.
6. Inicializar el proyecto `docker compose up`
   1. En caso de un despliegue de producción, se puede iniciar el proyecto en segundo plano agregando el flag `-d` al comando anterior.

Para eliminar el proyecto, simplemente detenerlo utilizando el comando `docker-compose down`, que detiene y elimina los contenedores del proyecto. Adicionalmente, se puede pasar el flag `--volumes` al comando anterior para eliminar el volumen de persistencia de datos de la BD. 

### Despliegue con Kubernetes + Helm

**Requerimientos previos:** Contar con una instalación local (o acceso a una instalación remota) de Kubernetes, y tener instalados los binarios de `kubectl` y `helm`. También, contar con acceso al repositorio de la imagen del contenedor de la aplicación (revisar el paso 3 para modificar el repositorio). El cluster debe contar con un Ingress habilitado para permitir el acceso desde el exterior a la aplicación (por defecto el ingress es `nginx`)

1. Clonar este repositorio
2. Posicionarse en la carpeta `challenge-2/charts`
3. Realizar un despliegue del helmchart correspondiente: `helm install <release_name> challenge-2/`.
   1. (opcional) Realizar un override de los valores por defecto del chart según el entorno de despliegue, [ya sea proporcionando un nuevo archivo `values.yaml` o indicando valores puntuales con el flag `--set`](https://helm.sh/docs/chart_template_guide/values_files/).

Para desinstalar el chart, simplemente ejecutar el comando `helm uninstall <release_name>`. Adicionalmente, es necesario eliminar el objeto PVC de Kubernetes asociado a la instalación de PostgreSQL, si es que se desea eliminar los datos persistidos.

### Despliegue en entorno cloud

**Requerimientos previos:** Contar con acceso a una instancia de EKS (AWS) o GKE (GCP), además de los requerimientos previos indicados en la [sección anterior](#despliegue-con-kubernetes--helm). 

1. Realizar los pasos indicados en la [sección anterior](#despliegue-con-kubernetes--helm).
