#!/bin/bash

# Script SQL para limpiar TODOS los datos relacionados con dispositivos
# Usa este script si quieres limpiar datos huérfanos después de eliminar dispositivos

set -e

# Configuración de base de datos
DB_HOST="${DB_HOST:-137.184.85.144}"
DB_PORT="${DB_PORT:-4406}"
DB_NAME="${DB_NAME:-traccar}"
DB_USER="${DB_USER:-physeter}"
DB_PASS="${DB_PASS:-Ph15eter\$2025\$R}"

echo "========================================="
echo "🧹 Limpiar Datos Huérfanos de Dispositivos"
echo "========================================="
echo ""
echo "Este script elimina:"
echo "  - Posiciones sin dispositivo"
echo "  - Eventos sin dispositivo"
echo "  - Comandos en cola sin dispositivo"
echo "  - Relaciones huérfanas"
echo ""

# Verificar si mysql está instalado
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL client no está instalado"
    echo "   Instalando..."
    sudo apt-get update -qq && sudo apt-get install -y -qq mysql-client > /dev/null 2>&1
fi

# Confirmar
read -p "¿Continuar con la limpieza? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "Limpiando datos..."

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'SQL_EOF' 2>/dev/null

SET FOREIGN_KEY_CHECKS = 0;

-- Mostrar estadísticas antes
SELECT '=== ANTES DE LIMPIAR ===' as info;
SELECT 
    (SELECT COUNT(*) FROM tc_devices) as dispositivos,
    (SELECT COUNT(*) FROM tc_positions) as posiciones,
    (SELECT COUNT(*) FROM tc_events) as eventos,
    (SELECT COUNT(*) FROM tc_commands_queue) as comandos_cola,
    (SELECT COUNT(*) FROM tc_device_attribute) as relaciones_atributos,
    (SELECT COUNT(*) FROM tc_device_command) as relaciones_comandos,
    (SELECT COUNT(*) FROM tc_device_driver) as relaciones_conductores,
    (SELECT COUNT(*) FROM tc_device_geofence) as relaciones_geocercas,
    (SELECT COUNT(*) FROM tc_device_maintenance) as relaciones_mantenimientos,
    (SELECT COUNT(*) FROM tc_device_notification) as relaciones_notificaciones,
    (SELECT COUNT(*) FROM tc_user_device) as relaciones_usuarios;

-- Eliminar posiciones (puede ser millones de registros)
SELECT 'Eliminando posiciones...' as status;
DELETE FROM tc_positions;

-- Eliminar eventos
SELECT 'Eliminando eventos...' as status;
DELETE FROM tc_events;

-- Eliminar comandos en cola
SELECT 'Eliminando comandos en cola...' as status;
DELETE FROM tc_commands_queue;

-- Eliminar relaciones de dispositivos
SELECT 'Eliminando relaciones de dispositivos...' as status;
DELETE FROM tc_device_attribute;
DELETE FROM tc_device_command;
DELETE FROM tc_device_driver;
DELETE FROM tc_device_geofence;
DELETE FROM tc_device_maintenance;
DELETE FROM tc_device_notification;
DELETE FROM tc_device_order;
DELETE FROM tc_device_report;
DELETE FROM tc_user_device;

-- Eliminar dispositivos
SELECT 'Eliminando dispositivos...' as status;
DELETE FROM tc_devices;

SET FOREIGN_KEY_CHECKS = 1;

-- Mostrar estadísticas después
SELECT '=== DESPUÉS DE LIMPIAR ===' as info;
SELECT 
    (SELECT COUNT(*) FROM tc_devices) as dispositivos,
    (SELECT COUNT(*) FROM tc_positions) as posiciones,
    (SELECT COUNT(*) FROM tc_events) as eventos,
    (SELECT COUNT(*) FROM tc_commands_queue) as comandos_cola,
    (SELECT COUNT(*) FROM tc_device_attribute) as relaciones_atributos,
    (SELECT COUNT(*) FROM tc_device_command) as relaciones_comandos,
    (SELECT COUNT(*) FROM tc_device_driver) as relaciones_conductores,
    (SELECT COUNT(*) FROM tc_device_geofence) as relaciones_geocercas,
    (SELECT COUNT(*) FROM tc_device_maintenance) as relaciones_mantenimientos,
    (SELECT COUNT(*) FROM tc_device_notification) as relaciones_notificaciones,
    (SELECT COUNT(*) FROM tc_user_device) as relaciones_usuarios;

SQL_EOF

echo ""
echo "========================================="
echo "✅ Limpieza completada"
echo "========================================="

