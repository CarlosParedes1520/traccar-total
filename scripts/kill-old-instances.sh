#!/bin/bash

# Script para detener todas las instancias antiguas de Traccar
# Ejecutar en el servidor

set -e

echo "=========================================="
echo "Deteniendo instancias antiguas de Traccar"
echo "=========================================="
echo ""

# 1. Detener servicio systemd
echo "1. Deteniendo servicio systemd..."
sudo systemctl stop traccar 2>/dev/null || echo "Servicio no estaba corriendo"
echo "✓ Servicio detenido"
echo ""

# 2. Matar procesos manuales
echo "2. Buscando procesos tracker-server..."
PIDS=$(pgrep -f "tracker-server" || true)
if [ ! -z "$PIDS" ]; then
    echo "Encontrados procesos: $PIDS"
    echo "Deteniendo procesos..."
    pkill -f "tracker-server" || true
    sleep 2
    # Forzar si aún están corriendo
    pkill -9 -f "tracker-server" 2>/dev/null || true
    echo "✓ Procesos detenidos"
else
    echo "✓ No hay procesos tracker-server corriendo"
fi
echo ""

# 3. Verificar puertos
echo "3. Verificando puertos..."
if command -v lsof &> /dev/null; then
    PORT_8082=$(lsof -ti :8082 2>/dev/null || true)
    if [ ! -z "$PORT_8082" ]; then
        echo "Puerto 8082 aún en uso por PID: $PORT_8082"
        echo "Deteniendo proceso..."
        kill -9 $PORT_8082 2>/dev/null || true
    fi
fi
echo ""

# 4. Esperar un momento
echo "4. Esperando 3 segundos..."
sleep 3
echo ""

# 5. Verificar que todo está limpio
echo "5. Verificación final:"
echo "----------------------------------------"
REMAINING=$(pgrep -f "tracker-server" || true)
if [ -z "$REMAINING" ]; then
    echo "✓ No hay procesos tracker-server corriendo"
else
    echo "⚠ Aún hay procesos: $REMAINING"
    echo "Forzando detención..."
    kill -9 $REMAINING 2>/dev/null || true
fi
echo ""

echo "=========================================="
echo "Limpieza completada!"
echo "=========================================="
echo ""
echo "Ahora puedes iniciar el servicio:"
echo "  sudo systemctl start traccar"
echo ""

