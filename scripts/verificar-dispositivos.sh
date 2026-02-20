#!/bin/bash

# Script para verificar dispositivos en la base de datos

echo "========================================="
echo "Verificando Dispositivos en Base de Datos"
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

echo "1. Total de dispositivos en la base de datos:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF 2>/dev/null
SELECT COUNT(*) as total_dispositivos FROM tc_devices;
EOF

echo ""
echo "2. Lista de todos los dispositivos:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF 2>/dev/null
SELECT 
    id,
    name,
    uniqueId,
    status,
    lastUpdate,
    CASE 
        WHEN lastUpdate IS NULL THEN 'Nunca conectado'
        WHEN lastUpdate < DATE_SUB(NOW(), INTERVAL 1 DAY) THEN 'Desconectado (>1 día)'
        ELSE 'Activo'
    END as estado_coneccion
FROM tc_devices 
ORDER BY id;
EOF

echo ""
echo "3. Buscando dispositivo con uniqueId '24959195':"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF 2>/dev/null
SELECT 
    id,
    name,
    uniqueId,
    status,
    lastUpdate,
    disabled
FROM tc_devices 
WHERE uniqueId = '24959195';
EOF

echo ""
echo "4. Verificando si hay dispositivos duplicados por uniqueId:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF 2>/dev/null
SELECT 
    uniqueId,
    COUNT(*) as cantidad,
    GROUP_CONCAT(id ORDER BY id) as ids
FROM tc_devices 
GROUP BY uniqueId 
HAVING COUNT(*) > 1;
EOF

echo ""
echo "========================================="
echo "Si hay dispositivos duplicados, puedes eliminarlos con:"
echo "mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p'$DB_PASS' $DB_NAME -e \"DELETE FROM tc_devices WHERE uniqueId = '24959195' AND id NOT IN (SELECT MIN(id) FROM (SELECT id FROM tc_devices WHERE uniqueId = '24959195') AS temp);\""
echo ""
echo "O eliminar todos los dispositivos (¡CUIDADO!):"
echo "mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p'$DB_PASS' $DB_NAME -e \"DELETE FROM tc_devices;\""
echo "========================================="

