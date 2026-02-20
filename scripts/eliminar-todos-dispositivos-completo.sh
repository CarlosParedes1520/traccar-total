#!/bin/bash

# Script para eliminar TODOS los dispositivos y TODOS sus datos relacionados
# Esto incluye: posiciones, eventos, relaciones, comandos en cola, etc.

set -e

BASE_URL="${BASE_URL:-http://localhost:8082/api}"
EMAIL="${EMAIL:-admin}"
PASSWORD="${PASSWORD:-admin}"

# Configuración de base de datos
DB_HOST="${DB_HOST:-137.184.85.144}"
DB_PORT="${DB_PORT:-4406}"
DB_NAME="${DB_NAME:-traccar}"
DB_USER="${DB_USER:-physeter}"
DB_PASS="${DB_PASS:-Ph15eter\$2025\$R}"

echo "========================================="
echo "⚠️  ELIMINAR TODOS LOS DISPOSITIVOS Y DATOS"
echo "========================================="
echo ""
echo "⚠️  ADVERTENCIA: Esta operación eliminará:"
echo "    - Todos los dispositivos"
echo "    - Todas las posiciones GPS"
echo "    - Todos los eventos"
echo "    - Todas las relaciones (geocercas, comandos, notificaciones, etc.)"
echo "    - Todos los comandos en cola"
echo "    - Todos los reportes asociados"
echo ""
echo "    Esta operación NO se puede deshacer!"
echo ""

# Confirmar acción
read -p "¿Estás SEGURO de que quieres eliminar TODO? (escribe 'SI' para confirmar): " -r
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

# Verificar si mysql está disponible
USE_SQL=false
if command -v mysql &> /dev/null; then
    USE_SQL=true
    echo "2. Usando MySQL para eliminación completa de datos relacionados..."
else
    echo "2. MySQL no disponible, usando solo API (puede dejar datos huérfanos)..."
    echo "   ⚠️  Se recomienda usar MySQL para eliminación completa"
fi

if [ "$USE_SQL" = true ]; then
    echo ""
    echo "3. Eliminando datos relacionados en la base de datos..."
    
    # Eliminar en orden para evitar problemas de foreign keys
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'SQL_EOF' 2>/dev/null
SET FOREIGN_KEY_CHECKS = 0;

-- Eliminar posiciones (puede ser millones de registros)
SELECT 'Eliminando posiciones...' as status;
DELETE FROM tc_positions;

-- Eliminar eventos
SELECT 'Eliminando eventos...' as status;
DELETE FROM tc_events;

-- Eliminar comandos en cola
SELECT 'Eliminando comandos en cola...' as status;
DELETE FROM tc_commands_queue;

-- Eliminar relaciones de dispositivos
SELECT 'Eliminando relaciones de dispositivos...' as status;
DELETE FROM tc_device_attribute;
DELETE FROM tc_device_command;
DELETE FROM tc_device_driver;
DELETE FROM tc_device_geofence;
DELETE FROM tc_device_maintenance;
DELETE FROM tc_device_notification;
DELETE FROM tc_device_order;
DELETE FROM tc_device_report;
DELETE FROM tc_user_device;

-- Finalmente, eliminar los dispositivos
SELECT 'Eliminando dispositivos...' as status;
DELETE FROM tc_devices;

SET FOREIGN_KEY_CHECKS = 1;

-- Verificar que todo se eliminó
SELECT 
    (SELECT COUNT(*) FROM tc_devices) as dispositivos,
    (SELECT COUNT(*) FROM tc_positions) as posiciones,
    (SELECT COUNT(*) FROM tc_events) as eventos,
    (SELECT COUNT(*) FROM tc_commands_queue) as comandos_cola;
SQL_EOF

    echo ""
    echo "✅ Datos eliminados de la base de datos"
    
else
    # Usar API (menos completo, pero funciona)
    echo ""
    echo "3. Eliminando dispositivos vía API..."
    echo "   (Nota: Esto puede dejar datos huérfanos en posiciones y eventos)"
    
    DEVICE_IDS=$(echo "$DEVICES_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for device in data:
    print(device['id'])
" 2>/dev/null)

    SUCCESS_COUNT=0
    FAIL_COUNT=0

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
    echo "   ✅ Eliminados: $SUCCESS_COUNT"
    if [ "$FAIL_COUNT" -gt 0 ]; then
        echo "   ❌ Fallos: $FAIL_COUNT"
    fi
fi

echo ""
echo "4. Verificando eliminación..."

# Verificar dispositivos
FINAL_RESPONSE=$(curl -s -u "$EMAIL:$PASSWORD" "$BASE_URL/devices")
FINAL_COUNT=$(echo "$FINAL_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null)

echo ""
echo "========================================="
echo "Resultado Final:"
echo "  📊 Dispositivos restantes: $FINAL_COUNT"
if [ "$USE_SQL" = true ]; then
    echo "  ✅ Datos relacionados eliminados de la BD"
else
    echo "  ⚠️  Puede haber datos huérfanos (posiciones, eventos)"
    echo "     Ejecuta el script con MySQL para eliminación completa"
fi
echo "========================================="

if [ "$FINAL_COUNT" = "0" ]; then
    echo ""
    echo "✅ Todos los dispositivos han sido eliminados"
    if [ "$USE_SQL" = false ]; then
        echo ""
        echo "⚠️  RECOMENDACIÓN: Ejecuta este script con MySQL instalado"
        echo "   para eliminar también posiciones y eventos huérfanos:"
        echo "   sudo apt-get install mysql-client"
        echo "   ./scripts/eliminar-todos-dispositivos-completo.sh"
    fi
else
    echo ""
    echo "⚠️  Aún quedan $FINAL_COUNT dispositivo(s)"
fi

