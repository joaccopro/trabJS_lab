**Guía de Despliegue: Entorno de Desarrollo (DEV)**

Este proyecto utiliza Terraform Workspaces para gestionar múltiples entornos (DEV, QA, PROD) de forma aislada dentro de la misma infraestructura. Siga estos pasos para desplegar el entorno de desarrollo.

**📋 Requisitos Previos**

-Terraform (v1.5+) instalado.

-AWS CLI configurado con credenciales de Administrador.

-Node.js 20.x (para el empaquetado de las funciones Lambda).

**🛠️ Paso 1: Configuración de Credenciales**

Antes de comenzar, asegúrese de que su terminal esté conectada a la cuenta de AWS:

aws configure <-- ingrese su Access Key, Secret Key y región (us-east-1)

**🌐 Paso 2: Selección del Entorno (Workspace)
Para evitar conflictos entre entornos, utilizaremos el workspace dev. Esto añadirá el sufijo -dev a todos los recursos creados (Buckets, Roles, APIs).**

#Inicializar el directorio de Terraform

terraform init

#Crear y seleccionar el entorno de desarrollo
terraform 

workspace new dev || terraform workspace select dev

**🏗️ Paso 3: Ejecución y Despliegue
Una vez seleccionado el entorno, ejecutamos el flujo estándar de Infraestructura como Código (IaC):**

1-Validación: Comprobar que la sintaxis es correcta.

terraform validate

2-Planificación: Visualizar los recursos que se crearán (30 recursos aproximadamente).

terraform plan

3-Aplicación: Desplegar la infraestructura en la nube.

terraform apply -auto-approve

**🔗 Paso 4: Verificación**

Al finalizar el despliegue, la terminal mostrará la URL de salida:

url_final_del_api: Utilice esta dirección en Postman con el recurso /upload para realizar pruebas de carga de imágenes.

**🧹 Paso 5: Limpieza de Recursos**

Para evitar costos innecesarios en la cuenta de AWS una vez terminada la evaluación:

terraform destroy -auto-approve