#!/bin/bash

# Script para configurar Traccar en el servidor por primera vez
# Ejecutar en el servidor después de subir los archivos

set -e

echo "=========================================="
echo "Configuración inicial de Traccar"
echo "=========================================="

# Verificar que estamos como root o con sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Este script debe ejecutarse con sudo"
    exit 1
fi

# 1. Crear usuario y grupo traccar
echo "1. Creando usuario traccar..."
if ! id "traccar" &>/dev/null; then
    useradd -r -s /bin/false -d /opt/traccar traccar
    echo "✓ Usuario traccar creado"
else
    echo "✓ Usuario traccar ya existe"
fi

# 2. Crear directorios
echo "2. Creando directorios..."
mkdir -p /opt/traccar/{conf,lib,logs,data,scripts}
chown -R traccar:traccar /opt/traccar
chmod 755 /opt/traccar
echo "✓ Directorios creados"

# 3. Instalar Java si no está instalado
echo "3. Verificando Java..."
if ! command -v java &> /dev/null; then
    echo "Instalando Java 17..."
    apt-get update
    apt-get install -y openjdk-17-jdk
    echo "✓ Java instalado"
else
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "✓ Java ya instalado: $JAVA_VERSION"
fi

# 4. Configurar servicio systemd
echo "4. Configurando servicio systemd..."
if [ -f /opt/traccar/scripts/traccar.service ]; then
    cp /opt/traccar/scripts/traccar.service /etc/systemd/system/traccar.service
    systemctl daemon-reload
    systemctl enable traccar
    echo "✓ Servicio configurado"
else
    echo "⚠ Archivo traccar.service no encontrado, creando uno básico..."
    cat > /etc/systemd/system/traccar.service << 'EOF'
[Unit]
Description=Traccar GPS Tracking Server
After=network.target

[Service]
Type=simple
User=traccar
Group=traccar
WorkingDirectory=/opt/traccar
ExecStart=/usr/bin/java -jar /opt/traccar/tracker-server.jar /opt/traccar/conf/traccar.xml
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=traccar
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable traccar
    echo "✓ Servicio básico creado"
fi

# 5. Configurar firewall
echo "5. Configurando firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 8082/tcp comment "Traccar Web"
    ufw allow 5000:5500/tcp comment "Traccar GPS Devices"
    echo "✓ Reglas de firewall agregadas"
else
    echo "⚠ ufw no encontrado, configura el firewall manualmente"
fi

# 6. Verificar configuración
echo "6. Verificando configuración..."
if [ ! -f /opt/traccar/tracker-server.jar ]; then
    echo "⚠ ADVERTENCIA: tracker-server.jar no encontrado en /opt/traccar/"
    echo "   Asegúrate de haber subido los archivos primero"
fi

if [ ! -f /opt/traccar/conf/traccar.xml ]; then
    echo "⚠ ADVERTENCIA: traccar.xml no encontrado en /opt/traccar/conf/"
    echo "   Crea el archivo de configuración antes de iniciar el servicio"
fi

echo ""
echo "=========================================="
echo "Configuración completada!"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Asegúrate de que todos los archivos estén en /opt/traccar/"
echo "2. Configura /opt/traccar/conf/traccar.xml con tus datos"
echo "3. Crea usuario admin: /opt/traccar/scripts/create-admin-server.sh"
echo "4. Inicia el servicio: systemctl start traccar"
echo "5. Verifica logs: journalctl -u traccar -f"
echo ""

