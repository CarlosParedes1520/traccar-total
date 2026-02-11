#!/bin/bash

# Script para verificar que el servidor está funcionando correctamente
# Ejecutar en el servidor

echo "=========================================="
echo "Verificación del Servidor Traccar"
echo "=========================================="
echo ""

# 1. Estado del servicio
echo "1. Estado del servicio:"
echo "----------------------------------------"
sudo systemctl status traccar --no-pager -l | head -15
echo ""

# 2. Verificar que el proceso está corriendo
echo "2. Procesos Traccar:"
echo "----------------------------------------"
pgrep -f tracker-server && echo "✓ Proceso tracker-server corriendo" || echo "✗ No hay proceso tracker-server"
echo ""

# 3. Verificar puerto 8082
echo "3. Puerto 8082 (Web):"
echo "----------------------------------------"
if command -v lsof &> /dev/null; then
    lsof -i :8082 && echo "✓ Puerto 8082 en uso" || echo "✗ Puerto 8082 no está en uso"
elif command -v ss &> /dev/null; then
    ss -tulpn | grep :8082 && echo "✓ Puerto 8082 en uso" || echo "✗ Puerto 8082 no está en uso"
else
    netstat -tulpn | grep :8082 && echo "✓ Puerto 8082 en uso" || echo "✗ Puerto 8082 no está en uso"
fi
echo ""

# 4. Probar conexión HTTP
echo "4. Probando conexión HTTP:"
echo "----------------------------------------"
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/api/server || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
        echo "✓ Servidor responde (HTTP $HTTP_CODE)"
    else
        echo "✗ Servidor no responde correctamente (HTTP $HTTP_CODE)"
    fi
else
    echo "curl no instalado, no se puede probar HTTP"
fi
echo ""

# 5. Verificar errores recientes
echo "5. Errores recientes (últimas 20 líneas):"
echo "----------------------------------------"
sudo journalctl -u traccar -n 20 --no-pager | grep -i "error\|exception\|failed" | tail -5 || echo "✓ No hay errores recientes"
echo ""

# 6. Verificar usuario admin
echo "6. Verificando usuario admin:"
echo "----------------------------------------"
echo "Ejecuta: scripts/fix-admin-user.sh para verificar/corregir"
echo ""

echo "=========================================="
echo "Resumen:"
echo "=========================================="
echo ""
echo "Si todo está bien, deberías poder acceder a:"
echo "  http://tu-servidor-ip:8082"
echo ""
echo "Credenciales:"
echo "  Email/Login: admin"
echo "  Password: admin"
echo ""
echo "Para ver logs en tiempo real:"
echo "  sudo journalctl -u traccar -f"
echo ""

