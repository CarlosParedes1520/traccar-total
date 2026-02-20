#!/bin/bash

# Script para eliminar un dispositivo duplicado por uniqueId

set -e

UNIQUE_ID="${1:-24959195}"

if [ -z "$1" ]; then
    echo "Uso: $0 <uniqueId>"
    echo "Ejemplo: $0 24959195"
    exit 1
fi

echo "========================================="
echo "Eliminando Dispositivo Duplicado"
echo "========================================="
echo ""

# Configuración de base de datos
DB_HOST="${DB_HOST:-137.184.85.144}"
DB_PORT="${DB_PORT:-4406}"
DB_NAME="${DB_NAME:-traccar}"
DB_USER="${DB_USER:-physeter}"
DB_PASS="${DB_PASS:-Ph15eter\$2025\$R}"

# Verificar si mysql está instalado
if ! command -v mysql &> /dev/null; then
    echo "⚠️  MySQL client no está instalado"
    echo "   Instalando dependencias..."
    apt-get update -qq && apt-get install -y -qq mysql-client > /dev/null 2>&1
fi

echo "1. Buscando dispositivos con uniqueId '$UNIQUE_ID':"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF 2>/dev/null
SELECT 
    id,
    name,
    uniqueId,
    status,
    lastUpdate,
    disabled
FROM tc_devices 
WHERE uniqueId = '$UNIQUE_ID'
ORDER BY id;
EOF

echo ""
echo "2. Verificando si hay duplicados:"
COUNT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN <<EOF 2>/dev/null
SELECT COUNT(*) FROM tc_devices WHERE uniqueId = '$UNIQUE_ID';
EOF
)

if [ "$COUNT" -eq "0" ]; then
    echo "   ✅ No hay dispositivos con uniqueId '$UNIQUE_ID'"
    exit 0
elif [ "$COUNT" -eq "1" ]; then
    echo "   ✅ Solo hay 1 dispositivo con uniqueId '$UNIQUE_ID' (no hay duplicados)"
    echo ""
    read -p "¿Deseas eliminarlo de todas formas? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "Operación cancelada"
        exit 0
    fi
    DELETE_QUERY="DELETE FROM tc_devices WHERE uniqueId = '$UNIQUE_ID';"
else
    echo "   ⚠️  Hay $COUNT dispositivos con uniqueId '$UNIQUE_ID'"
    echo ""
    echo "   Se eliminarán todos excepto el más antiguo (menor ID)"
    DELETE_QUERY="DELETE FROM tc_devices WHERE uniqueId = '$UNIQUE_ID' AND id NOT IN (SELECT MIN(id) FROM (SELECT id FROM tc_devices WHERE uniqueId = '$UNIQUE_ID') AS temp);"
fi

echo ""
echo "3. Eliminando dispositivo(s)..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF 2>/dev/null
$DELETE_QUERY
SELECT ROW_COUNT() as dispositivos_eliminados;
EOF

echo ""
echo "4. Verificando resultado:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF 2>/dev/null
SELECT 
    id,
    name,
    uniqueId,
    status,
    lastUpdate
FROM tc_devices 
WHERE uniqueId = '$UNIQUE_ID';
EOF

echo ""
echo "========================================="
echo "Proceso completado!"
echo "========================================="

