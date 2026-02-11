#!/bin/bash

# Script para corregir la configuración de nginx
# Cambia el puerto de 8083 a 8082

CONFIG_FILE="/etc/nginx/sites-available/traccar.viajeromorlaco.com"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Archivo de configuración no encontrado: $CONFIG_FILE"
    exit 1
fi

echo "Corrigiendo configuración de nginx..."
echo "Archivo: $CONFIG_FILE"
echo ""

# Crear backup
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo "✓ Backup creado"

# Reemplazar puerto 8083 por 8082
sudo sed -i 's/127\.0\.0\.1:8083/127.0.0.1:8082/g' "$CONFIG_FILE"
sudo sed -i 's/localhost:8083/localhost:8082/g' "$CONFIG_FILE"
sudo sed -i 's/:8083/:8082/g' "$CONFIG_FILE"

echo "✓ Puerto corregido de 8083 a 8082"
echo ""

# Verificar configuración
echo "Verificando configuración de nginx..."
if sudo nginx -t; then
    echo "✓ Configuración válida"
    echo ""
    echo "Recargando nginx..."
    sudo systemctl reload nginx
    echo "✓ Nginx recargado"
else
    echo "✗ Error en la configuración"
    echo "Restaurando backup..."
    sudo cp "${CONFIG_FILE}.backup."* "$CONFIG_FILE" 2>/dev/null || true
    exit 1
fi

echo ""
echo "=========================================="
echo "Configuración corregida!"
echo "=========================================="
echo ""
echo "Nginx ahora apunta a: http://127.0.0.1:8082"
echo ""
echo "Prueba acceder a: http://traccar.viajeromorlaco.com"

