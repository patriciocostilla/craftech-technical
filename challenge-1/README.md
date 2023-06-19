# Challenge 1

## Consideraciones

* Se trabajará con **AWS** como proveedor de *Cloud Computing* para desplegar la aplicación
* Se asume que la aplicación cuenta con dos componentes fundamentales: un **frontend** y un **backend**. 
  * El **frontend** (`myapp.com`) consiste de una aplicación web desarrollada con un framework de JS (como por ejemplo Angular, React o Vue) que se puede “compilar” en un conjunto de archivos HTML, CSS y JS.
  * El **backend** (`api.myapp.com`) consiste de un servidor de aplicación (desarrollado con una tecnología a definir) que se expone a internet a través de un servidor web (por ejemplo NGINX).
* El modelo implementado se basa en un whitepaper ofrecido por AWS, dónde se detalla una alternativa de implementación para una aplicación web, comparando la misma con su contraparte en un entorno on-premise “tradicional”.

## Arquitectura implementada

Cuando un cliente envía una petición a la aplicación, se utiliza **Route 53** como servidor de nombres de DNS para resolver a dónde dirigirla. En cualquiera de los dos casos, se analiza la petición con un **Web Application Firewall**, para tratar de detectar y mitigar posibles ataques antes de gestionar las peticiones correspondientes.

Si la petición es para el `myapp.com`, entonces se sirve la misma a través de **CloudFront**, que funciona como **CDN** para el frontend, utilizando por debajo un **Bucket S3** para almacenar los assets originales del sitio. 

Si la petición es para `api.myapp.com`, entonces se deriva la misma a la flota de servidores web (escalados horizontalmente utilizando **Auto Scaling Groups** y balanceados con **Elastic Load Balancer**). En este punto, los servidores web analizan las peticiones (pudiendo, por ejemplo, realizar *SSL Termination*) y derivan las mismas (según corresponda) a la flota de servidores de aplicación (también replicada con **Auto Scaling Groups** y balanceadas con **ELB**). 

Ambas flotas se encuentran implementadas en instancias de **EC2** y distribuidas a lo largo de dos zonas de disponibilidad de AWS para garantizar la continuidad de las operaciones si alguna de ellas falla. 

Los servidores de aplicación se conectan a las dos bases de datos (SQL y No-SQL), que consisten de instancias de **RDS** y **DynamoDB**, ambas replicadas a lo largo de las diferentes zonas de disponibilidad. 

Las flotas de servidores (web y de aplicación) y las bases de datos se organizan en diferentes *subnets* privadas dentro de la **VPC** de AWS. Esto quiere decir que no cuentan con acceso directo a internet. Por esto, para garantizar que los servidores de aplicación puedan consumir los microservicios externos, se debe generar *subnets* públicas con **NAT Gateways** que permitan la comunicación con el exterior. 

Adicionalmente, y aunque no se encuentra aclarado en el gráfico, los nodos correspondientes del servicio de **Elastic Load Balancing** se encuentran dentro de una *subnet* pública, de forma tal que se pueden acceder desde el exterior. 

## Referencias

* https://docs.aws.amazon.com/pdfs/whitepapers/latest/web-application-hosting-best-practices/web-application-hosting-best-practices.pdf#welcome
* https://docs.aws.amazon.com/vpc/latest/userguide/vpc-example-private-subnets-nat.html
