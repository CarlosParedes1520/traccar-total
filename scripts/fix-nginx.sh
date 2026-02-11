#!/bin/bash

# Script para verificar y corregir configuración de nginx
# Ejecutar en el servidor

echo "=========================================="
echo "Diagnóstico y Corrección de Nginx"
echo "=========================================="
echo ""

# 1. Verificar que nginx está corriendo
echo "1. Estado de nginx:"
echo "----------------------------------------"
sudo systemctl status nginx --no-pager | head -10 || echo "nginx no está instalado"
echo ""

# 2. Buscar configuración de traccar
echo "2. Buscando configuración de nginx para traccar:"
echo "----------------------------------------"
if [ -d "/etc/nginx/sites-available" ]; then
    echo "Archivos en sites-available:"
    ls -la /etc/nginx/sites-available/ | grep -i traccar || echo "No se encontró configuración de traccar"
    echo ""
    
    if [ -f "/etc/nginx/sites-available/traccar" ] || [ -f "/etc/nginx/sites-available/traccar.viajeromorlaco.com" ]; then
        CONFIG_FILE=$(ls /etc/nginx/sites-available/*traccar* | head -1)
        echo "Archivo de configuración encontrado: $CONFIG_FILE"
        echo "Contenido:"
        cat "$CONFIG_FILE"
    fi
fi

if [ -d "/etc/nginx/conf.d" ]; then
    echo ""
    echo "Archivos en conf.d:"
    ls -la /etc/nginx/conf.d/ | grep -i traccar || echo "No se encontró configuración de traccar"
fi
echo ""

# 3. Verificar configuración activa
echo "3. Configuración activa en sites-enabled:"
echo "----------------------------------------"
if [ -d "/etc/nginx/sites-enabled" ]; then
    ls -la /etc/nginx/sites-enabled/ | grep -i traccar || echo "No hay configuración activa"
fi
echo ""

# 4. Probar conexión desde nginx a Traccar
echo "4. Probando conexión a Traccar desde el servidor:"
echo "----------------------------------------"
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/api/server 2>&1)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
        echo "✓ Traccar responde correctamente en localhost:8082 (HTTP $HTTP_CODE)"
    else
        echo "✗ Traccar no responde (HTTP $HTTP_CODE)"
    fi
else
    echo "curl no instalado"
fi
echo ""

# 5. Verificar logs de nginx
echo "5. Errores recientes de nginx:"
echo "----------------------------------------"
if [ -f "/var/log/nginx/error.log" ]; then
    sudo tail -20 /var/log/nginx/error.log | grep -i "502\|bad gateway\|upstream" || echo "No hay errores recientes de 502"
else
    echo "Log de errores no encontrado"
fi
echo ""

echo "=========================================="
echo "Solución:"
echo "=========================================="
echo ""
echo "Si nginx no está configurado, crea la configuración:"
echo ""
echo "sudo nano /etc/nginx/sites-available/traccar.viajeromorlaco.com"
echo ""
echo "Con este contenido:"
echo ""
cat << 'EOF'
server {
    listen 80;
    server_name traccar.viajeromorlaco.com;

    location / {
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF
echo ""
echo "Luego:"
echo "  sudo ln -s /etc/nginx/sites-available/traccar.viajeromorlaco.com /etc/nginx/sites-enabled/"
echo "  sudo nginx -t"
echo "  sudo systemctl reload nginx"
echo ""

