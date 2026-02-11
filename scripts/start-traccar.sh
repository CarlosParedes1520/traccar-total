#!/bin/bash

# Script para iniciar Traccar y verificar que funciona
# Ejecutar en el servidor

set -e

echo "=========================================="
echo "Iniciando Traccar"
echo "=========================================="
echo ""

# 1. Verificar estado actual
echo "1. Estado actual del servicio:"
echo "----------------------------------------"
sudo systemctl status traccar --no-pager | head -15 || echo "Servicio no configurado"
echo ""

# 2. Iniciar servicio
echo "2. Iniciando servicio..."
echo "----------------------------------------"
sudo systemctl start traccar
sleep 5
echo "✓ Comando de inicio ejecutado"
echo ""

# 3. Verificar que está corriendo
echo "3. Verificando estado después de iniciar:"
echo "----------------------------------------"
if sudo systemctl is-active traccar > /dev/null 2>&1; then
    echo "✓ Servicio activo"
else
    echo "✗ Servicio no está activo"
    echo "Ver logs para más información:"
    sudo journalctl -u traccar -n 30 --no-pager | tail -20
    exit 1
fi
echo ""

# 4. Esperar a que termine de iniciar
echo "4. Esperando a que el servidor termine de iniciar (15 segundos)..."
echo "----------------------------------------"
sleep 15
echo "✓ Espera completada"
echo ""

# 5. Verificar puerto
echo "5. Verificando puerto 8082:"
echo "----------------------------------------"
if command -v ss &> /dev/null; then
    ss -tulpn | grep :8082 && echo "✓ Puerto 8082 escuchando" || echo "✗ Puerto 8082 no está escuchando"
elif command -v netstat &> /dev/null; then
    netstat -tulpn | grep :8082 && echo "✓ Puerto 8082 escuchando" || echo "✗ Puerto 8082 no está escuchando"
fi
echo ""

# 6. Probar conexión
echo "6. Probando conexión HTTP:"
echo "----------------------------------------"
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/api/server 2>&1)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
        echo "✓ Servidor responde (HTTP $HTTP_CODE)"
    else
        echo "✗ Servidor no responde correctamente (HTTP $HTTP_CODE)"
        echo "Ver logs: sudo journalctl -u traccar -n 50"
    fi
else
    echo "curl no instalado"
fi
echo ""

# 7. Ver logs recientes
echo "7. Logs recientes (últimas 5 líneas):"
echo "----------------------------------------"
sudo journalctl -u traccar -n 5 --no-pager
echo ""

echo "=========================================="
echo "Proceso completado"
echo "=========================================="
echo ""
echo "Si el servicio está activo, puedes acceder a:"
echo "  http://traccar.viajeromorlaco.com"
echo "  o"
echo "  http://tu-servidor-ip:8082"
echo ""
echo "Para ver logs en tiempo real:"
echo "  sudo journalctl -u traccar -f"
echo ""

