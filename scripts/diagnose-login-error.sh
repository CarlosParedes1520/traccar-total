#!/bin/bash

# Script para diagnosticar errores de login en Traccar

echo "========================================="
echo "Diagnóstico de Error de Login"
echo "========================================="
echo ""

# 1. Verificar si el servicio está corriendo
echo "1. Estado del servicio Traccar:"
systemctl is-active traccar && echo "✅ Servicio activo" || echo "❌ Servicio inactivo"
echo ""

# 2. Ver logs recientes
echo "2. Últimos logs del servidor (últimas 50 líneas):"
journalctl -u traccar -n 50 --no-pager | tail -30
echo ""

# 3. Buscar errores específicos de login
echo "3. Errores relacionados con login:"
journalctl -u traccar -n 200 --no-pager | grep -i "login\|unauthorized\|401\|400\|failed\|error" | tail -20
echo ""

# 4. Verificar usuario admin en la base de datos
echo "4. Verificando usuario admin en la base de datos:"
echo "   (Necesitas tener acceso a MySQL)"
echo ""
echo "Para verificar manualmente, ejecuta:"
echo "mysql -h 137.184.85.144 -P 4406 -u physeter -p traccar -e \"SELECT id, email, login, administrator, disabled FROM tc_users WHERE email='admin' OR login='admin';\""
echo ""

# 5. Probar login con curl
echo "5. Probando login con curl:"
echo ""
curl -v -X POST http://localhost:8082/api/session \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: */*" \
  -H "Origin: http://localhost:8082" \
  -H "Referer: http://localhost:8082/login" \
  -d "email=admin&password=admin" 2>&1 | grep -E "< HTTP|error|Error|401|400|200"
echo ""

# 6. Verificar puerto
echo "6. Verificando si el puerto 8082 está escuchando:"
netstat -tlnp 2>/dev/null | grep 8082 || ss -tlnp 2>/dev/null | grep 8082
echo ""

# 7. Verificar configuración
echo "7. Verificando configuración (debug.xml):"
if [ -f "/opt/traccar/conf/traccar.xml" ]; then
    echo "   Archivo de configuración encontrado: /opt/traccar/conf/traccar.xml"
    grep -E "web.port|database" /opt/traccar/conf/traccar.xml | head -5
elif [ -f "debug.xml" ]; then
    echo "   Archivo de configuración encontrado: debug.xml"
    grep -E "web.port|database" debug.xml | head -5
else
    echo "   ⚠️  No se encontró archivo de configuración"
fi
echo ""

echo "========================================="
echo "Diagnóstico completado"
echo "========================================="

