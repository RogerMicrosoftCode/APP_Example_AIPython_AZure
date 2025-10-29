#!/bin/bash

# Script para probar la API de AI desplegada
# Uso: ./test_api.sh https://tu-webapp.azurewebsites.net

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Obtener URL de la aplicación (argumento o prompt)
if [ -z "$1" ]; then
    read -p "Ingresa la URL de tu aplicación (ej: https://webapp-ai-app-xxx.azurewebsites.net): " API_URL
else
    API_URL=$1
fi

# Limpiar URL (remover trailing slash)
API_URL=${API_URL%/}

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Probando API de AI en: $API_URL${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Test 1: Endpoint raíz
echo -e "${YELLOW}[TEST 1]${NC} Probando endpoint raíz..."
echo "GET $API_URL/"
response=$(curl -s -w "\n%{http_code}" "$API_URL/")
http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Éxito (200)${NC}"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
else
    echo -e "${RED}✗ Error ($http_code)${NC}"
    echo "$body"
fi
echo ""

# Test 2: Health check
echo -e "${YELLOW}[TEST 2]${NC} Probando health check..."
echo "GET $API_URL/health"
response=$(curl -s -w "\n%{http_code}" "$API_URL/health")
http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Éxito (200)${NC}"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
else
    echo -e "${RED}✗ Error ($http_code)${NC}"
    echo "$body"
fi
echo ""

# Test 3: Predicción positiva
echo -e "${YELLOW}[TEST 3]${NC} Probando predicción (sentimiento positivo)..."
echo "POST $API_URL/api/predict"
echo "Body: {\"text\": \"Me encanta este producto, es fantástico\"}"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/predict" \
    -H "Content-Type: application/json" \
    -d '{"text": "Me encanta este producto, es fantástico y de excelente calidad"}')
http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Éxito (200)${NC}"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
else
    echo -e "${RED}✗ Error ($http_code)${NC}"
    echo "$body"
fi
echo ""

# Test 4: Predicción negativa
echo -e "${YELLOW}[TEST 4]${NC} Probando predicción (sentimiento negativo)..."
echo "POST $API_URL/api/predict"
echo "Body: {\"text\": \"Pésima experiencia, muy decepcionante\"}"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/predict" \
    -H "Content-Type: application/json" \
    -d '{"text": "Pésima experiencia, muy decepcionante y de mala calidad"}')
http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Éxito (200)${NC}"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
else
    echo -e "${RED}✗ Error ($http_code)${NC}"
    echo "$body"
fi
echo ""

# Test 5: Predicción neutral
echo -e "${YELLOW}[TEST 5]${NC} Probando predicción (sentimiento neutral)..."
echo "POST $API_URL/api/predict"
echo "Body: {\"text\": \"El producto cumple con lo esperado\"}"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/predict" \
    -H "Content-Type: application/json" \
    -d '{"text": "El producto cumple con lo esperado, nada más"}')
http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Éxito (200)${NC}"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
else
    echo -e "${RED}✗ Error ($http_code)${NC}"
    echo "$body"
fi
echo ""

# Test 6: Error - sin texto
echo -e "${YELLOW}[TEST 6]${NC} Probando validación de errores (sin campo 'text')..."
echo "POST $API_URL/api/predict"
echo "Body: {}"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/predict" \
    -H "Content-Type: application/json" \
    -d '{}')
http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "400" ]; then
    echo -e "${GREEN}✓ Error esperado (400)${NC}"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
else
    echo -e "${RED}✗ Error inesperado ($http_code)${NC}"
    echo "$body"
fi
echo ""

# Test 7: Error - texto vacío
echo -e "${YELLOW}[TEST 7]${NC} Probando validación de errores (texto vacío)..."
echo "POST $API_URL/api/predict"
echo "Body: {\"text\": \"\"}"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/predict" \
    -H "Content-Type: application/json" \
    -d '{"text": ""}')
http_code=$(echo "$response" | tail -n 1)
body=$(echo "$response" | head -n -1)

if [ "$http_code" = "400" ]; then
    echo -e "${GREEN}✓ Error esperado (400)${NC}"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
else
    echo -e "${RED}✗ Error inesperado ($http_code)${NC}"
    echo "$body"
fi
echo ""

echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}  Pruebas completadas${NC}"
echo -e "${BLUE}============================================${NC}"
