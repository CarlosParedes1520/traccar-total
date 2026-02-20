#!/bin/bash

# Script para eliminar TODOS los dispositivos de Traccar

set -e

BASE_URL="${BASE_URL:-http://localhost:8082/api}"
EMAIL="${EMAIL:-admin}"
PASSWORD="${PASSWORD:-admin}"

echo "========================================="
echo "⚠️  ELIMINAR TODOS LOS DISPOSITIVOS"
echo "========================================="
echo ""
echo "⚠️  ADVERTENCIA: Esta operación eliminará TODOS los dispositivos"
echo ""
echo "📌 NOTA: Este script solo elimina dispositivos vía API."
echo "   Para eliminar TAMBIÉN todos los datos relacionados (posiciones,"
echo "   eventos, comandos, etc.), usa el script completo:"
echo "   ./scripts/eliminar-todos-dispositivos-completo.sh"
echo ""

# Confirmar acción
read -p "¿Estás SEGURO de que quieres eliminar TODOS los dispositivos? (escribe 'SI' para confirmar): " -r
echo
if [ "$REPLY" != "SI" ]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "1. Obteniendo lista de dispositivos..."

# Obtener todos los dispositivos
DEVICES_RESPONSE=$(curl -s -u "$EMAIL:$PASSWORD" "$BASE_URL/devices")

# Verificar si hay errores
if echo "$DEVICES_RESPONSE" | grep -q "error\|Error\|401\|403"; then
    echo "❌ Error al obtener dispositivos"
    echo "$DEVICES_RESPONSE"
    exit 1
fi

# Contar dispositivos
DEVICE_COUNT=$(echo "$DEVICES_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null)

if [ "$DEVICE_COUNT" = "0" ]; then
    echo "✅ No hay dispositivos para eliminar"
    exit 0
fi

echo "   Encontrados: $DEVICE_COUNT dispositivo(s)"
echo ""

# Mostrar dispositivos que se van a eliminar
echo "2. Dispositivos que se eliminarán:"
echo "$DEVICES_RESPONSE" | python3 -m json.tool 2>/dev/null | grep -E '"id"|"name"|"uniqueId"' | paste - - - | head -20
if [ "$DEVICE_COUNT" -gt 20 ]; then
    echo "   ... y $((DEVICE_COUNT - 20)) más"
fi
echo ""

# Confirmar nuevamente
read -p "¿Confirmas la eliminación de estos $DEVICE_COUNT dispositivo(s)? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "3. Eliminando dispositivos..."

# Extraer IDs y eliminar
SUCCESS_COUNT=0
FAIL_COUNT=0

DEVICE_IDS=$(echo "$DEVICES_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for device in data:
    print(device['id'])
" 2>/dev/null)

for DEVICE_ID in $DEVICE_IDS; do
    echo -n "   Eliminando dispositivo ID=$DEVICE_ID... "
    
    DELETE_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE -u "$EMAIL:$PASSWORD" "$BASE_URL/devices/$DEVICE_ID")
    HTTP_STATUS=$(echo "$DELETE_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
    
    if [ "$HTTP_STATUS" = "204" ] || [ "$HTTP_STATUS" = "200" ]; then
        echo "✅"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "❌ (HTTP $HTTP_STATUS)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

echo ""
echo "4. Verificando eliminación..."
FINAL_RESPONSE=$(curl -s -u "$EMAIL:$PASSWORD" "$BASE_URL/devices")
FINAL_COUNT=$(echo "$FINAL_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null)

echo ""
echo "========================================="
echo "Resultado:"
echo "  ✅ Eliminados exitosamente: $SUCCESS_COUNT"
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "  ❌ Fallos: $FAIL_COUNT"
fi
echo "  📊 Dispositivos restantes: $FINAL_COUNT"
echo "========================================="

if [ "$FINAL_COUNT" = "0" ]; then
    echo ""
    echo "✅ Todos los dispositivos han sido eliminados"
    echo ""
    echo "💡 RECOMENDACIÓN: Para eliminar también datos relacionados"
    echo "   (posiciones, eventos, comandos en cola), ejecuta:"
    echo "   ./scripts/eliminar-todos-dispositivos-completo.sh"
    echo "   o"
    echo "   ./scripts/limpiar-datos-dispositivos-sql.sh"
else
    echo ""
    echo "⚠️  Aún quedan $FINAL_COUNT dispositivo(s)"
    echo "   Puedes ejecutar este script nuevamente para eliminarlos"
fi

