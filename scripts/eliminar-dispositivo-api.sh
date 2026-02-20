#!/bin/bash

# Script para eliminar un dispositivo usando la API

set -e

UNIQUE_ID="${1}"
DEVICE_ID="${2}"

if [ -z "$UNIQUE_ID" ] && [ -z "$DEVICE_ID" ]; then
    echo "Uso: $0 <uniqueId> [deviceId]"
    echo "Ejemplo: $0 24959195"
    echo "O: $0 24959195 22"
    exit 1
fi

BASE_URL="${BASE_URL:-http://localhost:8082/api}"
EMAIL="${EMAIL:-admin}"
PASSWORD="${PASSWORD:-admin}"

echo "========================================="
echo "Eliminando Dispositivo vía API"
echo "========================================="
echo ""

# 1. Obtener token de sesión
echo "1. Iniciando sesión..."
SESSION_RESPONSE=$(curl -s -X POST "$BASE_URL/session" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: */*" \
  -H "Origin: http://localhost:8082" \
  -H "Referer: http://localhost:8082/login" \
  -d "email=$EMAIL&password=$PASSWORD")

if echo "$SESSION_RESPONSE" | grep -q "error\|Error\|401"; then
    echo "❌ Error al iniciar sesión"
    echo "$SESSION_RESPONSE"
    exit 1
fi

echo "✅ Sesión iniciada"
echo ""

# 2. Buscar dispositivo
if [ -z "$DEVICE_ID" ]; then
    echo "2. Buscando dispositivo con uniqueId '$UNIQUE_ID'..."
    DEVICE_RESPONSE=$(curl -s -u "$EMAIL:$PASSWORD" "$BASE_URL/devices?uniqueId=$UNIQUE_ID")
    
    DEVICE_ID=$(echo "$DEVICE_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data[0]['id'] if data and len(data) > 0 else '')" 2>/dev/null)
    
    if [ -z "$DEVICE_ID" ]; then
        echo "❌ No se encontró dispositivo con uniqueId '$UNIQUE_ID'"
        echo "Respuesta: $DEVICE_RESPONSE"
        exit 1
    fi
    
    echo "✅ Dispositivo encontrado: ID=$DEVICE_ID"
else
    echo "2. Usando deviceId proporcionado: $DEVICE_ID"
fi

echo ""
echo "3. Información del dispositivo:"
curl -s -u "$EMAIL:$PASSWORD" "$BASE_URL/devices/$DEVICE_ID" | python3 -m json.tool 2>/dev/null | grep -E "id|name|uniqueId|status" | head -5
echo ""

# 3. Confirmar eliminación
read -p "¿Deseas eliminar este dispositivo? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

# 4. Eliminar dispositivo
echo ""
echo "4. Eliminando dispositivo ID=$DEVICE_ID..."
DELETE_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE -u "$EMAIL:$PASSWORD" "$BASE_URL/devices/$DEVICE_ID")

HTTP_STATUS=$(echo "$DELETE_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$DELETE_RESPONSE" | grep -v "HTTP_STATUS")

if [ "$HTTP_STATUS" = "204" ] || [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Dispositivo eliminado exitosamente"
else
    echo "❌ Error al eliminar dispositivo"
    echo "HTTP Status: $HTTP_STATUS"
    echo "Respuesta: $BODY"
    exit 1
fi

echo ""
echo "5. Verificando eliminación..."
VERIFY_RESPONSE=$(curl -s -u "$EMAIL:$PASSWORD" "$BASE_URL/devices?uniqueId=$UNIQUE_ID")
DEVICE_COUNT=$(echo "$VERIFY_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null)

if [ "$DEVICE_COUNT" = "0" ]; then
    echo "✅ Confirmado: El dispositivo ya no existe"
else
    echo "⚠️  El dispositivo aún existe (puede ser un problema de caché)"
fi

echo ""
echo "========================================="
echo "Proceso completado!"
echo "========================================="

