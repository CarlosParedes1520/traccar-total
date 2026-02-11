#!/bin/bash

# Script para verificar y corregir rutas en el servidor
# Ejecutar en el servidor

echo "Verificando estructura del servidor..."

# Verificar directorio actual
CURRENT_DIR=$(pwd)
echo "Directorio actual: $CURRENT_DIR"

# Buscar archivos importantes
echo ""
echo "Buscando tracker-server.jar..."
find /opt -name "tracker-server.jar" 2>/dev/null || echo "No encontrado"

echo ""
echo "Buscando scripts..."
find /opt -name "create-admin-server.sh" 2>/dev/null || echo "No encontrado"
find /opt -name "setup-server.sh" 2>/dev/null || echo "No encontrado"

echo ""
echo "Estructura de /opt/traccar-total:"
ls -la /opt/traccar-total/ 2>/dev/null || echo "No existe"

echo ""
echo "Estructura de /opt/traccar:"
ls -la /opt/traccar/ 2>/dev/null || echo "No existe"

echo ""
echo "Buscando archivos .jar en /opt:"
find /opt -name "*.jar" -type f 2>/dev/null | head -5

