#!/bin/bash

# Script para probar el login y diagnosticar problemas
# Ejecutar en el servidor

echo "=========================================="
echo "Prueba de Login - Traccar"
echo "=========================================="
echo ""

# 1. Probar login con curl
echo "1. Probando login con curl:"
echo "----------------------------------------"
if command -v curl &> /dev/null; then
    echo "Enviando: email=admin&password=admin"
    echo ""
    RESPONSE=$(curl -X POST http://localhost:8082/api/session \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "email=admin&password=admin" \
        -w "\nHTTP_CODE:%{http_code}" \
        -s 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE")
    
    echo "Código HTTP: $HTTP_CODE"
    echo "Respuesta:"
    echo "$BODY" | head -20
    echo ""
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Login exitoso!"
    elif [ "$HTTP_CODE" = "401" ]; then
        echo "✗ Error 401: Credenciales incorrectas"
    elif [ "$HTTP_CODE" = "400" ]; then
        echo "✗ Error 400: Petición mal formada"
    else
        echo "✗ Error: Código HTTP $HTTP_CODE"
    fi
else
    echo "curl no instalado. Instalando..."
    sudo apt-get update && sudo apt-get install -y curl
    curl -X POST http://localhost:8082/api/session \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "email=admin&password=admin" \
        -v
fi
echo ""

# 2. Verificar usuario en BD
echo "2. Verificando usuario admin en base de datos:"
echo "----------------------------------------"
echo "Ejecutando: scripts/fix-admin-user.sh"
echo ""
scripts/fix-admin-user.sh 2>/dev/null || echo "Error ejecutando script"
echo ""

# 3. Ver errores recientes en logs
echo "3. Errores recientes en logs:"
echo "----------------------------------------"
sudo journalctl -u traccar -n 50 --no-pager | grep -i "error\|exception\|failed\|400\|401" | tail -10 || echo "No hay errores recientes"
echo ""

# 4. Verificar que el servidor está corriendo
echo "4. Estado del servidor:"
echo "----------------------------------------"
sudo systemctl is-active traccar && echo "✓ Servicio activo" || echo "✗ Servicio inactivo"
echo ""

echo "=========================================="
echo "Diagnóstico completado"
echo "=========================================="

