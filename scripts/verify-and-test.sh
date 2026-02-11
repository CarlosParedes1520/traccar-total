#!/bin/bash

# Script para verificar que el servidor está completamente iniciado y probar login
# Ejecutar en el servidor

echo "=========================================="
echo "Verificación Completa del Servidor"
echo "=========================================="
echo ""

# 1. Esperar a que el servidor termine de iniciar
echo "1. Esperando a que el servidor termine de iniciar..."
echo "----------------------------------------"
sleep 10
echo "✓ Espera completada"
echo ""

# 2. Verificar estado
echo "2. Estado del servicio:"
echo "----------------------------------------"
sudo systemctl is-active traccar && echo "✓ Servicio activo" || echo "✗ Servicio inactivo"
echo ""

# 3. Verificar que el puerto está escuchando
echo "3. Verificando puerto 8082:"
echo "----------------------------------------"
if command -v ss &> /dev/null; then
    ss -tulpn | grep :8082 && echo "✓ Puerto 8082 escuchando" || echo "✗ Puerto 8082 no está escuchando"
elif command -v netstat &> /dev/null; then
    netstat -tulpn | grep :8082 && echo "✓ Puerto 8082 escuchando" || echo "✗ Puerto 8082 no está escuchando"
fi
echo ""

# 4. Probar conexión HTTP
echo "4. Probando conexión HTTP:"
echo "----------------------------------------"
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8082/api/server 2>&1)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
        echo "✓ Servidor responde (HTTP $HTTP_CODE)"
    else
        echo "✗ Servidor no responde correctamente (HTTP $HTTP_CODE)"
        echo "Intentando con más detalle..."
        curl -v http://localhost:8082/api/server 2>&1 | head -20
    fi
else
    echo "curl no instalado"
fi
echo ""

# 5. Probar login
echo "5. Probando login:"
echo "----------------------------------------"
if command -v curl &> /dev/null; then
    echo "Enviando: email=admin&password=admin"
    RESPONSE=$(curl -X POST http://localhost:8082/api/session \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "email=admin&password=admin" \
        -w "\nHTTP_CODE:%{http_code}" \
        -s 2>&1)
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE")
    
    echo "Código HTTP: $HTTP_CODE"
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Login exitoso!"
        echo "Respuesta:"
        echo "$BODY" | head -5
    elif [ "$HTTP_CODE" = "401" ]; then
        echo "✗ Error 401: Credenciales incorrectas"
        echo "Respuesta: $BODY"
    elif [ "$HTTP_CODE" = "400" ]; then
        echo "✗ Error 400: Petición mal formada"
        echo "Respuesta: $BODY"
    elif [ "$HTTP_CODE" = "000" ]; then
        echo "✗ Error: No se pudo conectar al servidor"
        echo "Verifica que el servidor esté completamente iniciado"
    else
        echo "✗ Error: Código HTTP $HTTP_CODE"
        echo "Respuesta: $BODY"
    fi
else
    echo "curl no instalado"
fi
echo ""

# 6. Ver logs recientes
echo "6. Logs recientes (últimas 10 líneas):"
echo "----------------------------------------"
sudo journalctl -u traccar -n 10 --no-pager
echo ""

echo "=========================================="
echo "Verificación completada"
echo "=========================================="
echo ""
echo "Si el login falla, verifica:"
echo "1. Que el servidor esté completamente iniciado (espera 10-15 segundos)"
echo "2. Que el usuario admin existe: scripts/fix-admin-user.sh"
echo "3. Los logs en tiempo real: sudo journalctl -u traccar -f"
echo ""

