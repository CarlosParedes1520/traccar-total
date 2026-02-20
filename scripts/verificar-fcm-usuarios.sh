#!/bin/bash

# Script para verificar campos FCM en usuarios
# Verifica si los usuarios tienen fcmtoken y fcmactivate

set -e

echo "=========================================="
echo "Verificando campos FCM en usuarios"
echo "=========================================="

# Configuración
DB_HOST="${DB_HOST:-137.184.85.144}"
DB_PORT="${DB_PORT:-4406}"
DB_NAME="${DB_NAME:-traccar}"
DB_USER="${DB_USER:-physeter}"
DB_PASS="${DB_PASS:-Ph15eter\$2025\$R}"

echo ""
echo "Conectando a: $DB_HOST:$DB_PORT/$DB_NAME"
echo ""

# Verificar estructura de la tabla primero
echo "1. Verificando estructura de la tabla tc_users..."
echo "---------------------------------------------------"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'SQL_EOF' 2>/dev/null
SHOW COLUMNS FROM tc_users LIKE '%fcm%';
SQL_EOF

echo ""
echo "2. Consultando todos los usuarios con campos FCM..."
echo "---------------------------------------------------"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'SQL_EOF' 2>/dev/null
SELECT 
    id,
    name,
    email,
    login,
    fcmtoken,
    fcmactivate,
    CASE 
        WHEN fcmtoken IS NULL OR fcmtoken = '' THEN '❌ Sin token'
        ELSE '✅ Con token'
    END as estado_token,
    CASE 
        WHEN fcmactivate = 1 THEN '✅ Activado'
        WHEN fcmactivate = 0 THEN '❌ Desactivado'
        WHEN fcmactivate IS NULL THEN '⚠️ NULL'
        ELSE '❓ Desconocido'
    END as estado_activate,
    attributes
FROM tc_users
ORDER BY id;
SQL_EOF

echo ""
echo "3. Resumen de usuarios con FCM configurado..."
echo "---------------------------------------------------"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'SQL_EOF' 2>/dev/null
SELECT 
    COUNT(*) as total_usuarios,
    SUM(CASE WHEN fcmtoken IS NOT NULL AND fcmtoken != '' THEN 1 ELSE 0 END) as usuarios_con_token,
    SUM(CASE WHEN fcmactivate = 1 THEN 1 ELSE 0 END) as usuarios_activados,
    SUM(CASE WHEN fcmtoken IS NOT NULL AND fcmtoken != '' AND fcmactivate = 1 THEN 1 ELSE 0 END) as usuarios_listos_para_push
FROM tc_users;
SQL_EOF

echo ""
echo "4. Usuarios listos para recibir push notifications..."
echo "---------------------------------------------------"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'SQL_EOF' 2>/dev/null
SELECT 
    id,
    name,
    email,
    fcmtoken,
    fcmactivate
FROM tc_users
WHERE fcmtoken IS NOT NULL 
  AND fcmtoken != ''
  AND fcmactivate = 1
ORDER BY id;
SQL_EOF

echo ""
echo "5. Verificando notificationTokens en attributes..."
echo "---------------------------------------------------"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<'SQL_EOF' 2>/dev/null
SELECT 
    id,
    name,
    email,
    attributes,
    CASE 
        WHEN attributes LIKE '%notificationTokens%' THEN '✅ Tiene notificationTokens'
        ELSE '❌ Sin notificationTokens'
    END as tiene_notification_tokens
FROM tc_users
WHERE attributes IS NOT NULL
ORDER BY id;
SQL_EOF

echo ""
echo "=========================================="
echo "Verificación completada!"
echo "=========================================="

