Guía Completa: GitHub Actions Local en Windows
📋 Prerrequisitos
1. Instalar Docker Desktop para Windows
bash# Descarga Docker Desktop desde:
# https://www.docker.com/products/docker-desktop

# Después de instalar, verifica:
docker --version
2. Instalar Git
bash# Descarga desde: https://git-scm.com/download/win
git --version
🚀 Instalación de "act" (GitHub Actions Local)
Opción A: Con Chocolatey (Recomendado)
powershell# Instalar Chocolatey si no lo tienes (como Administrador):
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Instalar act:
choco install act-cli
Opción B: Con Scoop
powershell# Instalar Scoop:
iwr -useb get.scoop.sh | iex

# Instalar act:
scoop install act
Opción C: Descarga Manual
powershell# Descarga desde: https://github.com/nektos/act/releases
# Extrae el .zip y agrega la carpeta al PATH
Verifica la instalación:
bashact --version
```

## 📁 Estructura del Proyecto

Crea esta estructura en tu proyecto:
```
mi-proyecto/
├── Dockerfile
├── .github/
│   └── workflows/
│       └── docker-build.yml
├── src/
│   └── app.py (o tu código)
└── requirements.txt (si usas Python)
📝 Paso 1: Crear el Dockerfile
dockerfile# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Copiar archivos
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .

# Comando de inicio
CMD ["python", "app.py"]
⚙️ Paso 2: Crear el Workflow de GitHub Actions
yaml# .github/workflows/docker-build.yml
name: Build Docker Container

on:
  push:
    branches: [ main, dev ]
  workflow_dispatch:  # Permite ejecución manual

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout código
        uses: actions/checkout@v3
      
      - name: Construir imagen Docker
        run: docker build -t mi-app:latest .
      
      - name: Listar imágenes
        run: docker images
      
      - name: Ejecutar contenedor (test)
        run: |
          docker run -d --name test-container mi-app:latest
          docker ps -a
          docker logs test-container
          docker stop test-container
🎯 Paso 3: Ejecutar con act (Localmente)
Abre PowerShell o CMD en la carpeta de tu proyecto:
bash# Ver los workflows disponibles
act -l

# Ejecutar el workflow completo
act

# Ejecutar un job específico
act -j build

# Ejecutar con modo verbose (para debugging)
act -v

# Simular un push event
act push

# Simular con una rama específica
act push -e <(echo '{"ref":"refs/heads/main"}')
🔧 Configuración Adicional (Opcional)
Crear archivo .actrc en tu proyecto
bash# .actrc
-P ubuntu-latest=catthehacker/ubuntu:act-latest
--container-architecture linux/amd64
Variables de entorno
bash# Crear archivo .secrets
GITHUB_TOKEN=tu_token_aqui
DOCKER_USERNAME=tu_usuario
Usar las secrets:
bashact --secret-file .secrets
🧪 Ejemplo Completo de Aplicación Python
requirements.txt:
txtflask==3.0.0
src/app.py:
pythonfrom flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return '¡Hola desde Docker con GitHub Actions local!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
🎬 Ejecución Completa
powershell# 1. Navega a tu proyecto
cd C:\ruta\a\tu\proyecto

# 2. Asegúrate que Docker Desktop está corriendo
docker ps

# 3. Ejecuta act
act

# 4. Para ver los logs detallados
act -v
⚠️ Problemas Comunes
Error: Docker daemon no está corriendo
bash# Solución: Abre Docker Desktop y espera a que inicie
Error: permisos en Windows
powershell# Ejecuta PowerShell como Administrador
Imagen muy pesada
bash# Usa una imagen más ligera en .actrc:
-P ubuntu-latest=node:16-bullseye-slim
Error con rutas de Windows
bash# act puede tener problemas con rutas de Windows
# Solución: Usa WSL2 o Git Bash
🎯 Comandos Útiles
bash# Ver todas las acciones disponibles
act -l

# Dry run (simular sin ejecutar)
act -n

# Usar un workflow específico
act -W .github/workflows/docker-build.yml

# Ejecutar solo un step
act -j build --step "Construir imagen Docker"

# Limpiar contenedores de act
docker ps -a | grep act- | awk '{print $1}' | xargs docker rm -f
