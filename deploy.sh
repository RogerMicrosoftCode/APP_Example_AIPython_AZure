#!/bin/bash

# Script de despliegue automatizado para Azure
# Este script automatiza todo el proceso de despliegue

set -e  # Salir si hay algún error

echo "============================================"
echo "  Despliegue de Aplicación AI en Azure"
echo "============================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Función para imprimir mensajes
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar que Azure CLI está instalado
if ! command -v az &> /dev/null; then
    print_error "Azure CLI no está instalado. Por favor instálalo desde: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Verificar que Docker está instalado
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado. Por favor instálalo desde: https://www.docker.com/products/docker-desktop"
    exit 1
fi

print_info "Verificaciones completadas ✓"
echo ""

# ============================================
# CONFIGURACIÓN - MODIFICA ESTAS VARIABLES
# ============================================

RESOURCE_GROUP="rg-ai-app"
LOCATION="eastus"
ACR_NAME="acrmyaiapp$(date +%s)"
APP_SERVICE_PLAN="asp-ai-app"
WEB_APP_NAME="webapp-ai-app-$(date +%s)"
IMAGE_NAME="mi-app-ai"
IMAGE_TAG="v1"

echo "Configuración:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  ACR Name: $ACR_NAME"
echo "  App Service Plan: $APP_SERVICE_PLAN"
echo "  Web App Name: $WEB_APP_NAME"
echo ""

read -p "¿Deseas continuar con esta configuración? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Despliegue cancelado por el usuario"
    exit 0
fi

# ============================================
# PASO 1: Login en Azure
# ============================================
print_info "PASO 1: Verificando sesión de Azure..."
if ! az account show &> /dev/null; then
    print_info "Iniciando sesión en Azure..."
    az login
else
    print_info "Ya estás autenticado en Azure ✓"
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
print_info "Suscripción activa: $SUBSCRIPTION"
echo ""

# ============================================
# PASO 2: Crear Resource Group
# ============================================
print_info "PASO 2: Creando Resource Group..."
if az group exists --name $RESOURCE_GROUP | grep -q "true"; then
    print_warning "El Resource Group '$RESOURCE_GROUP' ya existe, se usará el existente"
else
    az group create \
        --name $RESOURCE_GROUP \
        --location $LOCATION \
        --output none
    print_info "Resource Group creado ✓"
fi
echo ""

# ============================================
# PASO 3: Crear Azure Container Registry
# ============================================
print_info "PASO 3: Creando Azure Container Registry..."
ACR_EXISTS=$(az acr list --resource-group $RESOURCE_GROUP --query "[?name=='$ACR_NAME'].name" -o tsv)
if [ -z "$ACR_EXISTS" ]; then
    az acr create \
        --resource-group $RESOURCE_GROUP \
        --name $ACR_NAME \
        --sku Basic \
        --admin-enabled true \
        --output none
    print_info "ACR creado: $ACR_NAME ✓"
else
    print_warning "El ACR ya existe, se usará el existente"
fi

ACR_LOGIN_SERVER=$(az acr show \
    --name $ACR_NAME \
    --resource-group $RESOURCE_GROUP \
    --query loginServer \
    --output tsv)

print_info "ACR Login Server: $ACR_LOGIN_SERVER"
echo ""

# ============================================
# PASO 4: Construir y subir imagen Docker
# ============================================
print_info "PASO 4: Construyendo imagen Docker..."
docker build -t $IMAGE_NAME:$IMAGE_TAG .

if [ $? -eq 0 ]; then
    print_info "Imagen construida exitosamente ✓"
else
    print_error "Error al construir la imagen Docker"
    exit 1
fi

print_info "Iniciando sesión en ACR..."
az acr login --name $ACR_NAME

print_info "Etiquetando imagen..."
docker tag $IMAGE_NAME:$IMAGE_TAG $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG

print_info "Subiendo imagen al ACR..."
docker push $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG

if [ $? -eq 0 ]; then
    print_info "Imagen subida exitosamente ✓"
else
    print_error "Error al subir la imagen al ACR"
    exit 1
fi
echo ""

# ============================================
# PASO 5: Crear App Service Plan
# ============================================
print_info "PASO 5: Creando App Service Plan..."
PLAN_EXISTS=$(az appservice plan list --resource-group $RESOURCE_GROUP --query "[?name=='$APP_SERVICE_PLAN'].name" -o tsv)
if [ -z "$PLAN_EXISTS" ]; then
    az appservice plan create \
        --name $APP_SERVICE_PLAN \
        --resource-group $RESOURCE_GROUP \
        --is-linux \
        --sku B1 \
        --output none
    print_info "App Service Plan creado ✓"
else
    print_warning "El App Service Plan ya existe, se usará el existente"
fi
echo ""

# ============================================
# PASO 6: Crear Web App
# ============================================
print_info "PASO 6: Creando Web App..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN \
    --name $WEB_APP_NAME \
    --deployment-container-image-name $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG \
    --output none

print_info "Configurando credenciales del ACR..."
az webapp config container set \
    --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --docker-custom-image-name $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG \
    --docker-registry-server-url https://$ACR_LOGIN_SERVER \
    --docker-registry-server-user $ACR_USERNAME \
    --docker-registry-server-password $ACR_PASSWORD \
    --output none

print_info "Configurando puerto de aplicación..."
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --settings WEBSITES_PORT=8000 \
    --output none

print_info "Habilitando logs..."
az webapp log config \
    --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --docker-container-logging filesystem \
    --output none

print_info "Web App creada y configurada ✓"
echo ""

# ============================================
# RESUMEN
# ============================================
echo "============================================"
echo "  DESPLIEGUE COMPLETADO EXITOSAMENTE"
echo "============================================"
echo ""
print_info "URL de la aplicación: https://$WEB_APP_NAME.azurewebsites.net"
echo ""
echo "Información de recursos creados:"
echo "  • Resource Group: $RESOURCE_GROUP"
echo "  • Azure Container Registry: $ACR_NAME"
echo "  • App Service Plan: $APP_SERVICE_PLAN"
echo "  • Web App: $WEB_APP_NAME"
echo ""
echo "Comandos útiles:"
echo "  • Ver logs: az webapp log tail --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP"
echo "  • Reiniciar app: az webapp restart --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP"
echo "  • Ver estado: az webapp show --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --query state"
echo ""
print_info "Esperando a que la aplicación esté disponible (esto puede tardar 2-3 minutos)..."
sleep 30

# Probar health endpoint
print_info "Probando endpoint de salud..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$WEB_APP_NAME.azurewebsites.net/health)
if [ "$HTTP_CODE" = "200" ]; then
    print_info "¡Aplicación respondiendo correctamente! ✓"
else
    print_warning "La aplicación aún no responde (código: $HTTP_CODE). Puede tardar unos minutos más."
    print_info "Verifica el estado con: az webapp log tail --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP"
fi

echo ""
print_info "¡Despliegue completado! 🚀"
