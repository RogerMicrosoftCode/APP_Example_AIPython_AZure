# 🚀 Inicio Rápido

## Despliegue Automático (Recomendado)

### Paso 1: Preparar archivos
Descarga todos los archivos de este proyecto en una carpeta.

### Paso 2: Hacer ejecutables los scripts
```bash
chmod +x deploy.sh
chmod +x test_api.sh
```

### Paso 3: Ejecutar despliegue
```bash
./deploy.sh
```

El script automáticamente:
- ✓ Verificará que tengas Azure CLI y Docker instalados
- ✓ Creará todos los recursos en Azure
- ✓ Construirá la imagen Docker
- ✓ Desplegará la aplicación
- ✓ Te dará la URL de tu aplicación

### Paso 4: Probar la aplicación
```bash
./test_api.sh https://TU-WEBAPP.azurewebsites.net
```

---

## Despliegue Manual

Si prefieres hacerlo paso a paso, sigue las instrucciones en `DESPLIEGUE-AI-AZURE.md`

---

## Probar localmente antes de desplegar

```bash
# 1. Instalar dependencias
pip install -r requirements.txt

# 2. Ejecutar aplicación
python app.py

# 3. En otra terminal, probar
curl http://localhost:8000/health

curl -X POST http://localhost:8000/api/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Me encanta este producto"}'
```

---

## Estructura de archivos

```
├── DESPLIEGUE-AI-AZURE.md    # Documentación completa
├── INICIO-RAPIDO.md           # Este archivo
├── app.py                     # Aplicación Flask
├── model.py                   # Modelo de AI
├── requirements.txt           # Dependencias Python
├── Dockerfile                 # Contenerización
├── .dockerignore             # Exclusiones Docker
├── deploy.sh                  # Script de despliegue automático
└── test_api.sh               # Script de pruebas
```

---

## ¿Problemas?

Consulta la sección de **Troubleshooting** en `DESPLIEGUE-AI-AZURE.md`

---

## Costos estimados

- **Azure Container Registry (Basic)**: ~$5/mes
- **App Service Plan (B1)**: ~$13/mes
- **Total**: ~$18/mes

Para detener los costos, elimina todos los recursos:
```bash
az group delete --name rg-ai-app --yes
```
