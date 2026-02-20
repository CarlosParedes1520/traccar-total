#!/bin/bash

# Script para consultar solo el usuario Mateo (admin)
# Ejecutar en el servidor: bash consultar-usuario-mateo.sh

mysql -h 137.184.85.144 -P 4406 -u physeter -p'Ph15eter$2025$R' traccar <<'SQL'
SELECT 
    id,
    name,
    email,
    login,
    fcmtoken,
    fcmactivate,
    attributes,
    administrator,
    disabled
FROM tc_users
WHERE name = 'Mateo' OR email = 'admin' OR login = 'admin';
SQL

