#!/bin/bash

# Script para verificar y corregir el usuario admin

echo "========================================="
echo "Verificando Usuario Admin"
echo "========================================="
echo ""

# Configuración de base de datos
DB_HOST="137.184.85.144"
DB_PORT="4406"
DB_USER="physeter"
DB_NAME="traccar"
DB_PASS="Ph15eter\$2025\$R"

# Verificar si mysql está instalado
if ! command -v mysql &> /dev/null; then
    echo "⚠️  MySQL client no está instalado"
    echo "   Instalando dependencias..."
    apt-get update -qq && apt-get install -y -qq mysql-client > /dev/null 2>&1
fi

echo "1. Verificando usuarios en la base de datos:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF 2>/dev/null
SELECT 
    id, 
    email, 
    login, 
    administrator, 
    disabled,
    CASE 
        WHEN hashedPassword IS NULL OR hashedPassword = '' THEN 'SIN PASSWORD'
        WHEN salt IS NULL OR salt = '' THEN 'SIN SALT'
        ELSE 'OK'
    END as password_status
FROM tc_users 
WHERE email = 'admin' OR login = 'admin';
EOF

echo ""
echo "2. Verificando si el usuario está deshabilitado:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF 2>/dev/null
SELECT 
    id,
    email,
    disabled,
    CASE 
        WHEN disabled = 1 THEN '❌ USUARIO DESHABILITADO'
        ELSE '✅ Usuario habilitado'
    END as status
FROM tc_users 
WHERE (email = 'admin' OR login = 'admin') AND disabled = 1;
EOF

echo ""
echo "3. Verificando si hay problemas con el password:"
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF 2>/dev/null
SELECT 
    id,
    email,
    LENGTH(hashedPassword) as hash_length,
    LENGTH(salt) as salt_length,
    CASE 
        WHEN hashedPassword IS NULL OR hashedPassword = '' THEN '❌ PASSWORD VACÍO'
        WHEN salt IS NULL OR salt = '' THEN '❌ SALT VACÍO'
        WHEN LENGTH(hashedPassword) < 20 THEN '❌ HASH MUY CORTO'
        WHEN LENGTH(salt) < 10 THEN '❌ SALT MUY CORTO'
        ELSE '✅ Password OK'
    END as password_status
FROM tc_users 
WHERE email = 'admin' OR login = 'admin';
EOF

echo ""
echo "========================================="
echo "Si el usuario está deshabilitado, ejecuta:"
echo "mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p'$DB_PASS' $DB_NAME -e \"UPDATE tc_users SET disabled = 0 WHERE email = 'admin' OR login = 'admin';\""
echo ""
echo "Si el password está mal, ejecuta:"
echo "./scripts/fix-admin-user.sh"
echo "========================================="

