#!/bin/bash

# Script para encontrar y resolver conflictos de puertos
# Ejecutar en el servidor

echo "=========================================="
echo "Diagnóstico de Conflictos de Puertos"
echo "=========================================="
echo ""

# Buscar procesos Java de Traccar
echo "1. Procesos Java de Traccar:"
echo "----------------------------------------"
ps aux | grep -i "traccar\|tracker-server" | grep -v grep
echo ""

# Buscar qué está usando el puerto 8082
echo "2. Proceso usando puerto 8082 (Web):"
echo "----------------------------------------"
if command -v lsof &> /dev/null; then
    lsof -i :8082 || echo "Puerto 8082 libre"
elif command -v netstat &> /dev/null; then
    netstat -tulpn | grep :8082 || echo "Puerto 8082 libre"
elif command -v ss &> /dev/null; then
    ss -tulpn | grep :8082 || echo "Puerto 8082 libre"
else
    echo "No se encontró herramienta para verificar puertos"
fi
echo ""

# Buscar puertos comunes de Traccar (5000-5500)
echo "3. Puertos de dispositivos GPS (5000-5500):"
echo "----------------------------------------"
for port in 5000 5013 5023 5033 5043 5053; do
    if command -v lsof &> /dev/null; then
        result=$(lsof -i :$port 2>/dev/null)
        if [ ! -z "$result" ]; then
            echo "Puerto $port:"
            echo "$result"
        fi
    elif command -v ss &> /dev/null; then
        result=$(ss -tulpn | grep :$port)
        if [ ! -z "$result" ]; then
            echo "Puerto $port: $result"
        fi
    fi
done
echo ""

# Verificar servicios systemd
echo "4. Servicios Traccar:"
echo "----------------------------------------"
systemctl list-units | grep traccar || echo "No hay servicios traccar"
echo ""

# Verificar si hay instancias corriendo manualmente
echo "5. Instancias manuales de Traccar:"
echo "----------------------------------------"
pgrep -f "tracker-server" && echo "Hay procesos tracker-server corriendo" || echo "No hay procesos tracker-server"
echo ""

echo "=========================================="
echo "Solución:"
echo "=========================================="
echo ""
echo "Si hay múltiples instancias, ejecuta:"
echo "  sudo systemctl stop traccar"
echo "  pkill -f tracker-server"
echo "  sudo systemctl start traccar"
echo ""

