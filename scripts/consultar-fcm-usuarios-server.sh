#!/bin/bash

# Script para consultar usuarios con FCM en el servidor
# Ejecutar directamente en el servidor: bash consultar-fcm-usuarios-server.sh

DB_HOST="137.184.85.144"
DB_PORT="4406"
DB_NAME="traccar"
DB_USER="physeter"
DB_PASS="Ph15eter\$2025\$R"

echo "=========================================="
echo "Consulta de usuarios con FCM"
echo "=========================================="
echo ""

# Consulta principal: todos los usuarios con campos FCM
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'SQL_EOF'
SELECT 
    id,
    name,
    email,
    login,
    fcmtoken,
    fcmactivate,
    CASE 
        WHEN fcmtoken IS NULL OR fcmtoken = '' THEN 'Sin token'
        ELSE 'Con token'
    END as estado_token,
    CASE 
        WHEN fcmactivate = 1 THEN 'Activado'
        WHEN fcmactivate = 0 THEN 'Desactivado'
        WHEN fcmactivate IS NULL THEN 'NULL'
        ELSE 'Desconocido'
    END as estado_activate
FROM tc_users
ORDER BY id;
SQL_EOF

echo ""
echo "=========================================="
echo "Resumen"
echo "=========================================="
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'SQL_EOF'
SELECT 
    COUNT(*) as total_usuarios,
    SUM(CASE WHEN fcmtoken IS NOT NULL AND fcmtoken != '' THEN 1 ELSE 0 END) as con_token,
    SUM(CASE WHEN fcmactivate = 1 THEN 1 ELSE 0 END) as activados,
    SUM(CASE WHEN fcmtoken IS NOT NULL AND fcmtoken != '' AND fcmactivate = 1 THEN 1 ELSE 0 END) as listos_para_push
FROM tc_users;
SQL_EOF

