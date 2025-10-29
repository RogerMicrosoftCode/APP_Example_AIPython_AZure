# APP_Example_AIPython_AZure
Ejemplo de aplicación de AI en Python, con servicios de contenedores de azure 


# Despliegue de Aplicación de AI en Azure Container Registry y App Services

## 📋 Índice
- [Descripción del Proyecto](#descripción-del-proyecto)
- [Arquitectura](#arquitectura)
- [Requisitos Previos](#requisitos-previos)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Código de la Aplicación](#código-de-la-aplicación)
- [Contenerización](#contenerización)
- [Despliegue en Azure](#despliegue-en-azure)
- [Pruebas](#pruebas)
- [Troubleshooting](#troubleshooting)

---

## 📖 Descripción del Proyecto

Este proyecto demuestra cómo desplegar una aplicación monolítica de Machine Learning (AI) desarrollada en Python utilizando:
- **Azure Container Registry (ACR)** para almacenar la imagen Docker
- **Azure App Services** para hospedar la aplicación contenerizada

La aplicación de ejemplo es una API REST que utiliza un modelo de clasificación de texto con scikit-learn.

---

## 🏗️ Arquitectura

```
┌─────────────────┐
│  Código Python  │
│   + Modelo AI   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Dockerfile    │
│  (Contenerizar) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Azure Container│
│    Registry     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Azure App      │
│   Services      │
└─────────────────┘
```

---

## ✅ Requisitos Previos

1. **Azure CLI** instalado ([Descargar aquí](https://docs.microsoft.com/cli/azure/install-azure-cli))
2. **Docker** instalado ([Descargar aquí](https://www.docker.com/products/docker-desktop))
3. **Python 3.9+** instalado
4. **Suscripción activa de Azure**

Verificar instalaciones:
```bash
az --version
docker --version
python --version
```

---

## 📁 Estructura del Proyecto

```
mi-app-ai/
├── app.py                 # Aplicación Flask principal
├── requirements.txt       # Dependencias Python
├── Dockerfile            # Instrucciones para contenerizar
├── .dockerignore         # Archivos a ignorar en Docker
├── model.py              # Lógica del modelo de AI
└── README.md             # Este archivo
```

---

## 💻 Código de la Aplicación

### 1. `requirements.txt`

```txt
Flask==3.0.0
scikit-learn==1.3.2
numpy==1.26.2
pandas==2.1.3
joblib==1.3.2
gunicorn==21.2.0
```

### 2. `model.py`

```python
"""
Módulo para el modelo de Machine Learning
"""
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
import joblib
import os

class SentimentModel:
    def __init__(self):
        self.model = None
        self.load_or_train_model()
    
    def load_or_train_model(self):
        """Carga o entrena el modelo de sentimiento"""
        model_path = 'sentiment_model.pkl'
        
        if os.path.exists(model_path):
            self.model = joblib.load(model_path)
            print("✓ Modelo cargado desde archivo")
        else:
            print("⚙ Entrenando nuevo modelo...")
            self.train_model()
            joblib.dump(self.model, model_path)
            print("✓ Modelo entrenado y guardado")
    
    def train_model(self):
        """Entrena un modelo simple de clasificación de sentimientos"""
        # Datos de ejemplo para entrenamiento
        texts = [
            "Me encanta este producto, es excelente",
            "Muy buena calidad, lo recomiendo",
            "Fantástico servicio al cliente",
            "Terrible experiencia, no lo recomiendo",
            "Muy mala calidad, decepcionante",
            "Pésimo servicio, nunca más",
            "Es aceptable, nada especial",
            "Cumple su función básica"
        ]
        
        labels = [
            "positivo", "positivo", "positivo",
            "negativo", "negativo", "negativo",
            "neutral", "neutral"
        ]
        
        # Crear pipeline con TF-IDF y Naive Bayes
        self.model = Pipeline([
            ('tfidf', TfidfVectorizer(max_features=100)),
            ('classifier', MultinomialNB())
        ])
        
        self.model.fit(texts, labels)
    
    def predict(self, text):
        """Predice el sentimiento de un texto"""
        if self.model is None:
            raise ValueError("Modelo no inicializado")
        
        prediction = self.model.predict([text])[0]
        probabilities = self.model.predict_proba([text])[0]
        
        # Obtener las clases y sus probabilidades
        classes = self.model.classes_
        prob_dict = {cls: float(prob) for cls, prob in zip(classes, probabilities)}
        
        return {
            'prediction': prediction,
            'confidence': float(max(probabilities)),
            'probabilities': prob_dict
        }
```

### 3. `app.py`

```python
"""
Aplicación Flask para servir el modelo de AI
"""
from flask import Flask, request, jsonify
from model import SentimentModel
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Inicializar Flask
app = Flask(__name__)

# Inicializar modelo
logger.info("Inicializando modelo de AI...")
sentiment_model = SentimentModel()
logger.info("✓ Modelo inicializado correctamente")

@app.route('/')
def home():
    """Endpoint raíz"""
    return jsonify({
        'status': 'online',
        'service': 'AI Sentiment Analysis API',
        'version': '1.0.0',
        'endpoints': {
            'health': '/health',
            'predict': '/api/predict (POST)'
        }
    })

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': sentiment_model.model is not None
    }), 200

@app.route('/api/predict', methods=['POST'])
def predict():
    """Endpoint para realizar predicciones"""
    try:
        # Validar request
        if not request.is_json:
            return jsonify({'error': 'Content-Type debe ser application/json'}), 400
        
        data = request.get_json()
        
        if 'text' not in data:
            return jsonify({'error': 'Campo "text" es requerido'}), 400
        
        text = data['text']
        
        if not isinstance(text, str) or len(text.strip()) == 0:
            return jsonify({'error': 'El texto debe ser una cadena no vacía'}), 400
        
        # Realizar predicción
        logger.info(f"Procesando texto: {text[:50]}...")
        result = sentiment_model.predict(text)
        
        return jsonify({
            'success': True,
            'input': text,
            'result': result
        }), 200
        
    except Exception as e:
        logger.error(f"Error en predicción: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    # En producción, usar gunicorn en lugar de Flask development server
    app.run(host='0.0.0.0', port=8000, debug=False)
```

### 4. `.dockerignore`

```
__pycache__
*.pyc
*.pyo
*.pyd
.Python
*.so
.env
.venv
venv/
ENV/
.git
.gitignore
*.md
.vscode
.idea
*.log
.DS_Store
```

### 5. `Dockerfile`

```dockerfile
# Usar imagen base oficial de Python
FROM python:3.9-slim

# Establecer el directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema necesarias
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copiar archivos de dependencias
COPY requirements.txt .

# Instalar dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código de la aplicación
COPY . .

# Crear usuario no-root para seguridad
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Exponer el puerto
EXPOSE 8000

# Comando para ejecutar la aplicación con Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "120", "app:app"]
```

---

## 🐳 Contenerización

### Construir la imagen localmente

```bash
# Construir la imagen
docker build -t mi-app-ai:latest .

# Ejecutar el contenedor localmente para probar
docker run -p 8000:8000 mi-app-ai:latest

# Probar la aplicación
curl http://localhost:8000/health
```

---

## ☁️ Despliegue en Azure

### Paso 1: Login en Azure

```bash
# Iniciar sesión en Azure
az login

# Establecer la suscripción (si tienes múltiples)
az account set --subscription "TU_SUBSCRIPTION_ID"

# Verificar la suscripción activa
az account show
```

### Paso 2: Crear un Resource Group

```bash
# Variables
RESOURCE_GROUP="rg-ai-app"
LOCATION="eastus"

# Crear resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

### Paso 3: Crear Azure Container Registry (ACR)

```bash
# Variables
ACR_NAME="acrmyaiapp$(date +%s)"  # Nombre único
ACR_SKU="Basic"  # Opciones: Basic, Standard, Premium

# Crear ACR
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku $ACR_SKU \
  --admin-enabled true

# Obtener el login server
ACR_LOGIN_SERVER=$(az acr show \
  --name $ACR_NAME \
  --resource-group $RESOURCE_GROUP \
  --query loginServer \
  --output tsv)

echo "ACR Login Server: $ACR_LOGIN_SERVER"
```

### Paso 4: Subir la imagen al ACR

```bash
# Login en ACR
az acr login --name $ACR_NAME

# Etiquetar la imagen local
docker tag mi-app-ai:latest $ACR_LOGIN_SERVER/mi-app-ai:v1

# Subir la imagen al ACR
docker push $ACR_LOGIN_SERVER/mi-app-ai:v1

# Verificar que la imagen fue subida
az acr repository list --name $ACR_NAME --output table
az acr repository show-tags --name $ACR_NAME --repository mi-app-ai --output table
```

### Paso 5: Crear Azure App Service

```bash
# Variables
APP_SERVICE_PLAN="asp-ai-app"
WEB_APP_NAME="webapp-ai-app-$(date +%s)"  # Nombre único global
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

# Crear App Service Plan (Linux)
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --is-linux \
  --sku B1  # Opciones: B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2

# Crear Web App con contenedor del ACR
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --name $WEB_APP_NAME \
  --deployment-container-image-name $ACR_LOGIN_SERVER/mi-app-ai:v1

# Configurar credenciales del ACR
az webapp config container set \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_LOGIN_SERVER/mi-app-ai:v1 \
  --docker-registry-server-url https://$ACR_LOGIN_SERVER \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD

# Configurar el puerto de la aplicación
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --settings WEBSITES_PORT=8000

# Habilitar logs
az webapp log config \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-container-logging filesystem

# Obtener la URL de la aplicación
echo "URL de la aplicación: https://$WEB_APP_NAME.azurewebsites.net"
```

### Paso 6: Verificar el despliegue

```bash
# Ver logs en tiempo real
az webapp log tail \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP

# Verificar el estado de la aplicación
az webapp show \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query state
```

---

## 🧪 Pruebas

### Probar la API desplegada

```bash
# Variable con la URL de tu Web App
WEB_APP_URL="https://$WEB_APP_NAME.azurewebsites.net"

# 1. Health Check
curl $WEB_APP_URL/health

# 2. Endpoint raíz
curl $WEB_APP_URL/

# 3. Predicción de sentimiento (positivo)
curl -X POST $WEB_APP_URL/api/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Me encanta este producto, es fantástico"}'

# 4. Predicción de sentimiento (negativo)
curl -X POST $WEB_APP_URL/api/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Pésima experiencia, muy decepcionante"}'

# 5. Predicción de sentimiento (neutral)
curl -X POST $WEB_APP_URL/api/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "El producto cumple con lo esperado"}'
```

### Respuestas esperadas

```json
// Health Check
{
  "status": "healthy",
  "model_loaded": true
}

// Predicción
{
  "success": true,
  "input": "Me encanta este producto, es fantástico",
  "result": {
    "prediction": "positivo",
    "confidence": 0.85,
    "probabilities": {
      "positivo": 0.85,
      "negativo": 0.10,
      "neutral": 0.05
    }
  }
}
```

---

## 🔄 Actualizar la aplicación

Cuando necesites desplegar una nueva versión:

```bash
# 1. Hacer cambios en el código

# 2. Construir nueva imagen
docker build -t mi-app-ai:latest .

# 3. Etiquetar con nueva versión
docker tag mi-app-ai:latest $ACR_LOGIN_SERVER/mi-app-ai:v2

# 4. Subir al ACR
docker push $ACR_LOGIN_SERVER/mi-app-ai:v2

# 5. Actualizar Web App
az webapp config container set \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-custom-image-name $ACR_LOGIN_SERVER/mi-app-ai:v2

# 6. Reiniciar la aplicación
az webapp restart \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP
```

---

## 🐛 Troubleshooting

### Ver logs detallados

```bash
# Logs en tiempo real
az webapp log tail --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP

# Descargar logs
az webapp log download \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --log-file logs.zip
```

### Problemas comunes

#### 1. La aplicación no inicia

```bash
# Verificar que el puerto está configurado correctamente
az webapp config appsettings list \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[?name=='WEBSITES_PORT']"

# Verificar que la imagen se descargó correctamente
az webapp log tail --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
```

#### 2. Error de autenticación con ACR

```bash
# Regenerar credenciales
az acr credential renew \
  --name $ACR_NAME \
  --password-name password

# Actualizar configuración
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

az webapp config container set \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --docker-registry-server-password $ACR_PASSWORD
```

#### 3. Aplicación responde lento

```bash
# Escalar el App Service Plan
az appservice plan update \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --sku B2  # o superior

# Aumentar workers en Gunicorn (modificar Dockerfile)
# CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--timeout", "120", "app:app"]
```

---

## 💰 Costos estimados (USD/mes)

- **Azure Container Registry (Basic)**: ~$5/mes
- **App Service Plan (B1)**: ~$13/mes
- **Total aproximado**: ~$18/mes

Para reducir costos en desarrollo:
- Usar el plan gratuito F1 de App Service (limitaciones aplican)
- Eliminar recursos cuando no se usen

---

## 🗑️ Limpieza de recursos

Para eliminar todos los recursos creados:

```bash
# Eliminar todo el resource group (ACR + App Service + Plan)
az group delete \
  --name $RESOURCE_GROUP \
  --yes \
  --no-wait

# Verificar que se eliminó
az group exists --name $RESOURCE_GROUP
```

---

## 📚 Referencias

- [Azure Container Registry Documentation](https://docs.microsoft.com/azure/container-registry/)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Docker Documentation](https://docs.docker.com/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Scikit-learn Documentation](https://scikit-learn.org/)

---

## 📝 Notas adicionales

### Variables de entorno

Para configuraciones sensibles, usa variables de entorno:

```bash
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --settings \
    MODEL_PATH="/app/models" \
    LOG_LEVEL="INFO" \
    API_KEY="tu_api_key_secreta"
```

### Continuous Deployment

Para CI/CD con GitHub Actions o Azure DevOps, consulta:
- [GitHub Actions con Azure](https://docs.microsoft.com/azure/app-service/deploy-github-actions)
- [Azure DevOps Pipelines](https://docs.microsoft.com/azure/devops/pipelines)

### Seguridad

Recomendaciones:
- Usar Azure Key Vault para secretos
- Habilitar HTTPS only
- Configurar autenticación en el App Service
- Usar Managed Identity en lugar de credenciales

```bash
# Forzar HTTPS
az webapp update \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --https-only true
```

---

## 👨‍💻 Autor

Documento creado para despliegue de aplicaciones de AI en Azure.

## 📄 Licencia

Este proyecto es un ejemplo educativo y puede ser usado libremente.
