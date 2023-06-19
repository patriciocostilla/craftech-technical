# Challenge 3

## Introducción

El objetivo del desafío es generar una imagen de contenedor de NGINX, con el agregado de que se debe modificar el archivo `index.html` que muestra en su configuración por defecto. 

Luego, se pide que se implemente un esquema de CI/CD de forma tal que al enviar al repositorio un cambio en el archivo `index.html` se genere una nueva versión de la imagen y se despliegue la misma. 

## Modificación de la imagen original

Construiremos una nueva imagen basada en NGINX, a la cual le sobreescribiremos el archivo `/usr/share/nginx/html/index.html` con una nueva versión, como se puede observar en el Dockerfile del proyecto. 

El `index.html` original extraído directamente desde la imagen de NGINX:

```html
<!DOCTYPE html>
<html>

<head>
    <title>Welcome to nginx!</title>
    <style>
        html {
            color-scheme: light dark;
        }

        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
</head>

<body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and
        working. Further configuration is required.</p>

    <p>For online documentation and support please refer to
        <a href="http://nginx.org/">nginx.org</a>.<br />
        Commercial support is available at
        <a href="http://nginx.com/">nginx.com</a>.
    </p>

    <p><em>Thank you for using nginx.</em></p>
</body>

</html>
```

## Esquema de CI/CD

> [Ver el diagrama](#diagrama)

Se trabajó con **Github Actions** como herramienta de integración continua, **Dockerhub** como repositorio de imágenes de contenedores, y **Google Cloud Run (GCP)** como entorno de despliegue. Este proceso se ejecuta cada vez que se realiza una modificación en el repositorio (puntualmente en la carpeta del tercer desafío) y consta de los siguientes pasos

1. El usuario envía un cambio al repositorio.
1. Se realiza construcción de la nueva imagen de Docker.
1. Se publica la imagen generada en el paso anterior en Dockerhub.
1. Se genera una nueva revisión del servicio creado en Google Cloud Run, basada en la imagen públicada en el paso anterior.

Se puede revisar la implementación del esquema de CI/CD en el archivo [c3-build-publish.yml](../.github/workflows/c3-build-publish.yml).

### Requerimientos/Configuración

Si revisamos el archivo [c3-build-publish.yml](../.github/workflows/c3-build-publish.yml) podemos ver que el pipeline requiere, para su correcto funcionamiento, de lo siguiente:

1. Una cuenta de Dockerhub con acceso a un repositorio dónde enviar la imagen construida, llamado `challenge-3-app`.
2. Un archivo JSON de credenciales que permitan acceso a una cuenta de GCP
3. La cuenta de GCP debe tener configurado un proyecto de Cloud Run con el nombre `challenge-3-app`.

Para que el ejecutar del proceso de CI/CD se pueda conectar satisfactoriamente, necesitamos generar los siguientes secretos en el repositorio:

| Secreto       | Descripción                                       |
| ------------- | ------------------------------------------------- |
| `DOCKER_USER` | Nombre de usuario de Dockerhub                    |
| `DOCKER_PAT`  | Un Personal Acces Token de Dockerhub              |
| `GCP_SA`      | Archivo JSON con las credenciales de acceso a GCP |

En el caso de las credenciales de acceso a GCP, si revisamos la documentación del action `google-github-actions/deploy-cloudrun@v1` se establece que las credenciales deben corresponder a una cuenta de servicio con el rol `Cloud Run Admin` y que además sea miembro de la cuenta de servicio `Compute Engine default service account` con el rol de `Service Account User`. Esta configuración se debe establecer desde la consola de GCP.

### Consideraciones

* Se decidió trabajar con Github Actions ya que se está utilizando el mismo Github como servidor para el repositorio de código, por lo cual la integración es transparente. 
    * Además, Github Actions cuenta con todas las utilidades necesarias para facilitar la implementación del esquema de CI/CD definido.
* Se utiliza Dockerhub como repositorio de imágenes ya que se pueden crear imagenes públicas sin costo. 
* Se utiliza Google Cloud Run como entorno de ejecución ya que permite la ejecución y publicación de servicios basados en contenedores de forma directa. Como la aplicación a desplegar solamente cuenta con un contenedor, no se requiere de un entorno de orquestación de contenedores. 
    * Además, es posible acceder a una versión de prueba gratuita de la misma. 

### Diagrama 

![Esquema de CICD](imgs/CICD.jpg "Esquema de CI/CD")