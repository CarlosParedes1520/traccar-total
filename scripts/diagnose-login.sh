#!/bin/bash

# Script para diagnosticar problemas de login
# Ejecutar en el servidor

echo "=========================================="
echo "Diagnóstico de Login - Traccar"
echo "=========================================="
echo ""

# 1. Verificar logs del servidor
echo "1. Últimos errores en los logs:"
echo "----------------------------------------"
sudo journalctl -u traccar -n 50 --no-pager | grep -i "error\|exception\|failed\|400" | tail -20
echo ""

# 2. Verificar si el servicio está corriendo
echo "2. Estado del servicio:"
echo "----------------------------------------"
sudo systemctl status traccar --no-pager -l | head -15
echo ""

# 3. Verificar usuario admin en BD
echo "3. Verificando usuario admin en base de datos:"
echo "----------------------------------------"

# Configuración de BD
DB_HOST="${DB_HOST:-137.184.85.144}"
DB_PORT="${DB_PORT:-4406}"
DB_NAME="${DB_NAME:-traccar}"
DB_USER="${DB_USER:-physeter}"
DB_PASS="${DB_PASS:-Ph15eter\$2025\$R}"

# Buscar mysql client
if command -v mysql &> /dev/null; then
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" << EOF 2>/dev/null || echo "Error conectando a BD"
SELECT id, name, email, login, administrator, disabled, 
       CASE WHEN hashedPassword IS NULL OR hashedPassword = '' THEN 'SIN PASSWORD' ELSE 'CON PASSWORD' END as password_status
FROM tc_users 
WHERE email = 'admin' OR login = 'admin';
EOF
else
    echo "MySQL client no instalado. Instalando..."
    sudo apt-get update && sudo apt-get install -y mysql-client
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" << EOF 2>/dev/null || echo "Error conectando a BD"
SELECT id, name, email, login, administrator, disabled, 
       CASE WHEN hashedPassword IS NULL OR hashedPassword = '' THEN 'SIN PASSWORD' ELSE 'CON PASSWORD' END as password_status
FROM tc_users 
WHERE email = 'admin' OR login = 'admin';
EOF
fi
echo ""

# 4. Verificar configuración
echo "4. Verificando configuración:"
echo "----------------------------------------"
if [ -f "/opt/traccar/conf/traccar.xml" ]; then
    echo "✓ Archivo de configuración existe"
    echo "Contenido relevante:"
    grep -E "database|web.port" /opt/traccar/conf/traccar.xml | head -5
else
    echo "✗ Archivo de configuración NO existe"
fi
echo ""

# 5. Probar conexión a la API
echo "5. Probando conexión a la API:"
echo "----------------------------------------"
API_URL="http://localhost:8082/api/session"
echo "Probando: $API_URL"

# Probar con curl
if command -v curl &> /dev/null; then
    echo ""
    echo "Respuesta del servidor:"
    curl -X POST "$API_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "email=admin&password=admin" \
        -v 2>&1 | grep -E "< HTTP|error|Error" | head -5
else
    echo "curl no instalado. Instalando..."
    sudo apt-get install -y curl
    curl -X POST "$API_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "email=admin&password=admin" \
        -v 2>&1 | grep -E "< HTTP|error|Error" | head -5
fi
echo ""

# 6. Verificar puerto
echo "6. Verificando puerto 8082:"
echo "----------------------------------------"
if command -v netstat &> /dev/null; then
    netstat -tulpn | grep 8082 || echo "Puerto 8082 no está en uso"
elif command -v ss &> /dev/null; then
    ss -tulpn | grep 8082 || echo "Puerto 8082 no está en uso"
fi
echo ""

echo "=========================================="
echo "Diagnóstico completado"
echo "=========================================="
echo ""
echo "Si el usuario admin no existe o no tiene password, ejecuta:"
echo "  /opt/traccar/scripts/create-admin-server.sh"
echo "  o"
echo "  /opt/traccar-total/scripts/create-admin-direct.sh"

