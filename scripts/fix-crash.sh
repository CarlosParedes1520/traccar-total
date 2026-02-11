#!/bin/bash

# Script para diagnosticar y corregir el crash del servidor
# Ejecutar en el servidor

set -e

echo "=========================================="
echo "Diagnóstico de Crash - Traccar"
echo "=========================================="
echo ""

# 1. Ver el error completo
echo "1. Error completo del último crash:"
echo "----------------------------------------"
sudo journalctl -u traccar -n 200 --no-pager | tail -50
echo ""

# 2. Verificar configuración
echo "2. Verificando configuración:"
echo "----------------------------------------"
if [ -f "/opt/traccar/conf/traccar.xml" ]; then
    echo "✓ Archivo de configuración existe"
    echo "Verificando contenido problemático..."
    # Buscar líneas sospechosas
    grep -n "changelog\|schema\|path" /opt/traccar/conf/traccar.xml | head -5
else
    echo "✗ Archivo de configuración NO existe"
fi
echo ""

# 3. Verificar que schema existe
echo "3. Verificando directorio schema:"
echo "----------------------------------------"
if [ -d "/opt/traccar/schema" ]; then
    echo "✓ Directorio schema existe"
    if [ -f "/opt/traccar/schema/changelog-master.xml" ]; then
        echo "✓ changelog-master.xml existe"
    else
        echo "✗ changelog-master.xml NO existe"
        echo "Copiando schema..."
        sudo mkdir -p /opt/traccar/schema
        sudo cp -r /opt/traccar-total/schema/* /opt/traccar/schema/
        sudo chown -R traccar:traccar /opt/traccar/schema
    fi
else
    echo "✗ Directorio schema NO existe"
    echo "Copiando schema..."
    sudo mkdir -p /opt/traccar/schema
    sudo cp -r /opt/traccar-total/schema/* /opt/traccar/schema/
    sudo chown -R traccar:traccar /opt/traccar/schema
fi
echo ""

# 4. Verificar permisos
echo "4. Verificando permisos:"
echo "----------------------------------------"
ls -la /opt/traccar/ | head -10
echo ""

# 5. Intentar iniciar y ver error en tiempo real
echo "5. Intentando iniciar servicio:"
echo "----------------------------------------"
sudo systemctl start traccar
sleep 5
sudo systemctl status traccar --no-pager -l | head -20
echo ""

# 6. Si falla, ver el error específico
if ! sudo systemctl is-active traccar > /dev/null 2>&1; then
    echo "6. Error al iniciar, viendo logs detallados:"
    echo "----------------------------------------"
    sudo journalctl -u traccar -n 100 --no-pager | grep -A 10 -B 10 "Exception\|Error\|Failed" | tail -30
fi

echo ""
echo "=========================================="
echo "Diagnóstico completado"
echo "=========================================="

