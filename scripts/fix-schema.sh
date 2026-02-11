#!/bin/bash

# Script para copiar el directorio schema a /opt/traccar
# Ejecutar en el servidor

set -e

echo "=========================================="
echo "Copiando directorio schema"
echo "=========================================="

# Verificar si existe schema en traccar-total
if [ -d "/opt/traccar-total/schema" ]; then
    echo "Copiando schema desde /opt/traccar-total/schema..."
    sudo mkdir -p /opt/traccar/schema
    sudo cp -r /opt/traccar-total/schema/* /opt/traccar/schema/
    sudo chown -R traccar:traccar /opt/traccar/schema
    echo "✓ Schema copiado exitosamente"
elif [ -d "./schema" ]; then
    echo "Copiando schema desde directorio actual..."
    sudo mkdir -p /opt/traccar/schema
    sudo cp -r ./schema/* /opt/traccar/schema/
    sudo chown -R traccar:traccar /opt/traccar/schema
    echo "✓ Schema copiado exitosamente"
else
    echo "ERROR: No se encontró el directorio schema"
    echo "Busca en:"
    echo "  - /opt/traccar-total/schema"
    echo "  - ./schema"
    exit 1
fi

# Verificar que el archivo existe
if [ -f "/opt/traccar/schema/changelog-master.xml" ]; then
    echo "✓ changelog-master.xml encontrado"
else
    echo "⚠ ADVERTENCIA: changelog-master.xml no encontrado después de copiar"
fi

echo ""
echo "=========================================="
echo "Proceso completado!"
echo "=========================================="
echo ""
echo "Ahora reinicia el servicio:"
echo "  sudo systemctl restart traccar"

