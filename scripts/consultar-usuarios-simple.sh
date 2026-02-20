#!/bin/bash

# Script simple para consultar usuarios - Copiar y pegar en el servidor

mysql -h 137.184.85.144 -P 4406 -u physeter -p'Ph15eter$2025$R' traccar <<'SQL'
SELECT 
    id,
    name,
    email,
    fcmtoken,
    fcmactivate,
    attributes
FROM tc_users
ORDER BY id;
SQL

