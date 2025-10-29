# 🚀 Guía Completa: GitHub Actions Local en Windows

Ejecutar GitHub Actions de manera local en Windows usando **act**, para construir y probar contenedores Docker sin necesidad de hacer push a GitHub.

---

## 📋 Prerrequisitos

### 1. Instalar Docker Desktop para Windows

```bash
# Descarga Docker Desktop desde:
# https://www.docker.com/products/docker-desktop

# Después de instalar, verifica:
docker --version
```

### 2. Instalar Git

```bash
# Descarga desde: https://git-scm.com/download/win
git --version
```

---

## 🚀 Instalación de "act" (GitHub Actions Local)

### Opción A: Con Chocolatey (Recomendado)

```powershell
# Instalar Chocolatey si no lo tienes (como Administrador):
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Instalar act:
choco install act-cli
```

### Opción B: Con Scoop

```powershell
# Instalar Scoop:
iwr -useb get.scoop.sh | iex

# Instalar act:
scoop install act
```

### Opción C: Descarga Manual

1. Descarga desde: https://github.com/nektos/act/releases
2. Extrae el archivo `.zip`
3. Agrega la carpeta al PATH de Windows

**Verificar instalación:**

```bash
act --version
```

---

## 📁 Estructura del Proyecto

Crea esta estructura en tu proyecto:

```
mi-proyecto/
├── Dockerfile
├── .github/
│   └── workflows/
│       └── docker-build.yml
├── src/
│   └── app.py
├── requirements.txt
└── README.md
```

---

## 📝 Paso 1: Crear el Dockerfile

Crea un archivo llamado `Dockerfile` en la raíz de tu proyecto:

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Copiar archivos de dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código fuente
COPY src/ .

# Exponer puerto (opcional)
EXPOSE 5000

# Comando de inicio
CMD ["python", "app.py"]
```

---

## ⚙️ Paso 2: Crear el Workflow de GitHub Actions

Crea el archivo `.github/workflows/docker-build.yml`:

```yaml
name: Build Docker Container

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:  # Permite ejecución manual desde GitHub

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout código
        uses: actions/checkout@v3
      
      - name: Mostrar información del sistema
        run: |
          echo "Sistema: $(uname -a)"
          echo "Docker version: $(docker --version)"
      
      - name: Construir imagen Docker
        run: docker build -t mi-app:latest .
      
      - name: Listar imágenes creadas
        run: docker images
      
      - name: Ejecutar contenedor (test básico)
        run: |
          docker run -d --name test-container mi-app:latest
          sleep 5
          docker ps -a
          docker logs test-container
          docker stop test-container
          docker rm test-container
      
      - name: Test exitoso
        run: echo "✅ Contenedor construido y probado exitosamente"
```

---

## 🎯 Paso 3: Ejecutar con act (Localmente)

Abre **PowerShell** o **CMD** en la carpeta raíz de tu proyecto:

### Comandos Básicos

```bash
# Ver los workflows disponibles
act -l

# Ejecutar el workflow completo
act

# Ejecutar un job específico
act -j build

# Ejecutar con modo verbose (para debugging)
act -v

# Simular un push event
act push

# Ejecutar workflow específico
act -W .github/workflows/docker-build.yml
```

### Primera Ejecución

La primera vez que ejecutes `act`, te preguntará qué imagen Docker usar. Recomendaciones:

- **Micro** (~300MB) - Para workflows simples
- **Medium** (~500MB) - **Recomendado** para la mayoría de casos
- **Large** (~17GB) - Para workflows complejos

```bash
# Ejecutar con imagen medium
act -P ubuntu-latest=catthehacker/ubuntu:act-latest
```

---

## 🔧 Configuración Adicional (Opcional)

### Crear archivo `.actrc`

Crea un archivo `.actrc` en la raíz de tu proyecto para configuración persistente:

```bash
-P ubuntu-latest=catthehacker/ubuntu:act-latest
--container-architecture linux/amd64
-v
```

### Variables de Entorno y Secrets

Crea un archivo `.secrets` (no lo subas a GitHub - agrégalo a `.gitignore`):

```env
GITHUB_TOKEN=tu_token_aqui
DOCKER_USERNAME=tu_usuario
DOCKER_PASSWORD=tu_password
```

Usar las secrets:

```bash
act --secret-file .secrets
```

### Archivo `.gitignore`

```gitignore
# Secrets locales
.secrets
.env

# Act cache
.act/

# Python
__pycache__/
*.pyc
*.pyo
venv/
```

---

## 🧪 Ejemplo Completo de Aplicación Python

### `requirements.txt`

```txt
flask==3.0.0
werkzeug==3.0.0
```

### `src/app.py`

```python
from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return '''
    <h1>¡Hola desde Docker con GitHub Actions Local! 🐳</h1>
    <p>Este contenedor fue construido y probado localmente.</p>
    '''

@app.route('/health')
def health():
    return {'status': 'healthy', 'version': '1.0.0'}

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
```

---

## 🎬 Proceso Completo de Ejecución

### 1. Preparar el proyecto

```powershell
# Crear la estructura de carpetas
mkdir mi-proyecto
cd mi-proyecto
mkdir src, .github\workflows -Force

# Inicializar git (opcional)
git init
```

### 2. Crear los archivos

- Crea el `Dockerfile`
- Crea el workflow en `.github/workflows/docker-build.yml`
- Crea tu aplicación en `src/`
- Crea `requirements.txt`

### 3. Verificar que Docker está corriendo

```powershell
docker ps
# Si hay error, abre Docker Desktop y espera a que inicie
```

### 4. Ejecutar act

```powershell
# Primera ejecución (descargará imágenes)
act

# Ver logs detallados
act -v

# Ejecutar solo el job de build
act -j build
```

---

## ⚠️ Problemas Comunes y Soluciones

### ❌ Error: "Cannot connect to the Docker daemon"

**Solución:**
```bash
# Asegúrate que Docker Desktop está corriendo
# Abre Docker Desktop y espera a que el ícono deje de parpadear
```

### ❌ Error: "act: command not found"

**Solución:**
```powershell
# Cierra y vuelve a abrir PowerShell después de instalar
# O verifica que act está en el PATH:
where.exe act
```

### ❌ Error: Permisos en Windows

**Solución:**
```powershell
# Ejecuta PowerShell como Administrador
# Click derecho en PowerShell → "Ejecutar como administrador"
```

### ❌ Error: "no space left on device"

**Solución:**
```bash
# Limpiar imágenes y contenedores de Docker
docker system prune -a --volumes

# Limpiar contenedores específicos de act
docker ps -a | findstr "act-" | ForEach-Object { docker rm -f $_.Split()[0] }
```

### ❌ Error: Rutas de Windows en workflows

**Solución:**
```yaml
# Usa barras diagonales (/) en lugar de backslashes (\)
# Ejemplo:
- name: Copy files
  run: cp src/app.py build/app.py  # ✅
  # NO: copy src\app.py build\app.py  # ❌
```

### ❌ Error: "refused to connect to registry"

**Solución:**
```bash
# Si intentas hacer push a un registry, necesitas estar autenticado
# Para testing local, evita los steps de push o usa --skip push
```

---

## 🎯 Comandos Útiles de act

### Información y Debugging

```bash
# Ver todas las acciones disponibles
act -l

# Ver los jobs de un workflow específico
act -l -W .github/workflows/docker-build.yml

# Dry run (simular sin ejecutar)
act -n

# Ver las variables de entorno disponibles
act --env
```

### Ejecución Selectiva

```bash
# Ejecutar solo ciertos steps
act -j build --step "Construir imagen Docker"

# Ejecutar con una matriz específica
act -j test --matrix os:ubuntu-latest

# Ejecutar con un evento específico
act pull_request
act workflow_dispatch
```

### Limpieza

```bash
# Limpiar contenedores de act (PowerShell)
docker ps -a | Select-String "act-" | ForEach-Object { docker rm -f $_.ToString().Split()[0] }

# Limpiar imágenes no usadas
docker image prune -a
```

---

## 🚀 Siguiente Paso: CI/CD Completo

### Workflow Avanzado con Push a Registry

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ghcr.io/${{ github.repository }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

### Probar localmente (sin push)

```bash
# Ejecutar solo hasta el build, saltando el push
act -j build-and-push --skip "Log in to GitHub Container Registry,Build and push"
```

---

## 📚 Recursos Adicionales

- [Documentación oficial de act](https://github.com/nektos/act)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Awesome Act - Recursos comunitarios](https://github.com/nektos/act#awesome-act)

---

## 💡 Tips y Mejores Prácticas

### 1. **Usa caché para acelerar builds**

```yaml
- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
```

### 2. **Multi-stage builds en Dockerfile**

```dockerfile
# Build stage
FROM python:3.11 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY src/ .
ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

### 3. **Mantén los workflows simples**

- Un job = Una responsabilidad
- Usa nombres descriptivos
- Comenta pasos complejos

### 4. **Testing local antes de push**

```bash
# Siempre prueba localmente primero
act -n  # Dry run
act -j build  # Ejecutar build
# Si todo funciona, entonces haz push a GitHub
```

---

## ✅ Checklist de Verificación

Antes de ejecutar tu workflow:

- [ ] Docker Desktop está corriendo
- [ ] act está instalado (`act --version`)
- [ ] Estructura de carpetas correcta
- [ ] Dockerfile existe y es válido
- [ ] Workflow YAML tiene sintaxis correcta
- [ ] Archivos de código existen en las rutas correctas
- [ ] `.gitignore` incluye archivos sensibles

---
