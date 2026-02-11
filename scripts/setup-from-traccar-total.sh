#!/bin/bash

# Script para configurar Traccar cuando está en /opt/traccar-total
# Ejecutar desde /opt/traccar-total

set -e

echo "=========================================="
echo "Configuración de Traccar desde traccar-total"
echo "=========================================="

# Verificar que estamos en el directorio correcto
if [ ! -f "target/tracker-server.jar" ]; then
    echo "ERROR: No se encontró target/tracker-server.jar"
    echo "Asegúrate de estar en /opt/traccar-total y haber compilado el proyecto"
    exit 1
fi

# Verificar que estamos como root o con sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Este script debe ejecutarse con sudo"
    exit 1
fi

# 1. Crear estructura en /opt/traccar
echo "1. Creando estructura en /opt/traccar..."
mkdir -p /opt/traccar/{conf,lib,logs,data,scripts}

# 2. Copiar archivos
echo "2. Copiando archivos..."
if [ -f "target/tracker-server.jar" ]; then
    cp target/tracker-server.jar /opt/traccar/
    echo "✓ tracker-server.jar copiado"
fi

if [ -d "target/lib" ]; then
    cp -r target/lib/* /opt/traccar/lib/
    echo "✓ Librerías copiadas"
fi

if [ -f "debug.xml" ]; then
    cp debug.xml /opt/traccar/conf/traccar.xml
    echo "✓ Configuración copiada"
fi

if [ -d "traccar-web" ]; then
    cp -r traccar-web /opt/traccar/
    echo "✓ Frontend copiado"
fi

# 3. Copiar scripts
echo "3. Copiando scripts..."
if [ -d "scripts" ]; then
    cp scripts/*.sh /opt/traccar/scripts/ 2>/dev/null || true
    cp scripts/*.service /opt/traccar/scripts/ 2>/dev/null || true
    chmod +x /opt/traccar/scripts/*.sh 2>/dev/null || true
    echo "✓ Scripts copiados"
fi

# 4. Crear usuario traccar
echo "4. Creando usuario traccar..."
if ! id "traccar" &>/dev/null; then
    useradd -r -s /bin/false -d /opt/traccar traccar
    echo "✓ Usuario traccar creado"
else
    echo "✓ Usuario traccar ya existe"
fi

# 5. Ajustar permisos
echo "5. Ajustando permisos..."
chown -R traccar:traccar /opt/traccar
chmod 755 /opt/traccar
echo "✓ Permisos ajustados"

# 6. Instalar Java si no está instalado
echo "6. Verificando Java..."
if ! command -v java &> /dev/null; then
    echo "Instalando Java 17..."
    apt-get update
    apt-get install -y openjdk-17-jdk
    echo "✓ Java instalado"
else
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "✓ Java ya instalado: $JAVA_VERSION"
fi

# 7. Configurar servicio systemd
echo "7. Configurando servicio systemd..."
if [ -f "/opt/traccar/scripts/traccar.service" ]; then
    cp /opt/traccar/scripts/traccar.service /etc/systemd/system/traccar.service
else
    # Crear servicio básico
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
fi

systemctl daemon-reload
systemctl enable traccar
echo "✓ Servicio configurado"

# 8. Configurar firewall
echo "8. Configurando firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 8082/tcp comment "Traccar Web" 2>/dev/null || true
    ufw allow 5000:5500/tcp comment "Traccar GPS Devices" 2>/dev/null || true
    echo "✓ Reglas de firewall agregadas"
else
    echo "⚠ ufw no encontrado, configura el firewall manualmente"
fi

echo ""
echo "=========================================="
echo "Configuración completada!"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Crear usuario admin: /opt/traccar/scripts/create-admin-server.sh"
echo "2. Iniciar servicio: systemctl start traccar"
echo "3. Verificar logs: journalctl -u traccar -f"
echo ""

