#!/bin/bash

# Script de deploy para Traccar en servidor Digital Ocean
# Uso: ./deploy.sh [usuario@servidor]

set -e

# Configuración
SERVER="${1:-usuario@tu-servidor-ip}"
REMOTE_DIR="/opt/traccar"
LOCAL_PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=========================================="
echo "Deploy de Traccar a servidor"
echo "=========================================="
echo "Servidor: $SERVER"
echo "Directorio remoto: $REMOTE_DIR"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "build.gradle" ]; then
    echo "ERROR: No se encontró build.gradle"
    echo "Ejecuta este script desde el directorio raíz del proyecto"
    exit 1
fi

# Compilar proyecto
echo "1. Compilando proyecto..."
export JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}
./gradlew build -x test

if [ ! -f "target/tracker-server.jar" ]; then
    echo "ERROR: No se generó tracker-server.jar"
    exit 1
fi

echo "✓ Compilación exitosa"
echo ""

# Crear directorio temporal
TEMP_DIR=$(mktemp -d)
echo "2. Preparando archivos en $TEMP_DIR..."

mkdir -p "$TEMP_DIR/traccar"
cp target/tracker-server.jar "$TEMP_DIR/traccar/"
cp -r target/lib "$TEMP_DIR/traccar/"
cp debug.xml "$TEMP_DIR/traccar/traccar.xml"

# Copiar frontend si existe
if [ -d "traccar-web" ]; then
    cp -r traccar-web "$TEMP_DIR/traccar/"
fi

# Copiar templates si existen
if [ -d "templates" ]; then
    cp -r templates "$TEMP_DIR/traccar/"
fi

# Copiar schema para migraciones
if [ -d "schema" ]; then
    cp -r schema "$TEMP_DIR/traccar/"
fi

# Copiar script de creación de admin
if [ -f "scripts/create-admin-server.sh" ]; then
    mkdir -p "$TEMP_DIR/traccar/scripts"
    cp scripts/create-admin-server.sh "$TEMP_DIR/traccar/scripts/"
    chmod +x "$TEMP_DIR/traccar/scripts/create-admin-server.sh"
fi

echo "✓ Archivos preparados"
echo ""

# Crear archivo comprimido
echo "3. Creando archivo comprimido..."
cd "$TEMP_DIR"
tar -czf traccar-deploy.tar.gz traccar/
echo "✓ Archivo creado: traccar-deploy.tar.gz"
echo ""

# Subir al servidor
echo "4. Subiendo archivos al servidor..."
scp traccar-deploy.tar.gz "$SERVER:/tmp/"

echo "5. Extrayendo archivos en el servidor..."
ssh "$SERVER" << 'ENDSSH'
    # Crear directorios si no existen
    sudo mkdir -p /opt/traccar/{conf,lib,logs,data,scripts}
    
    # Extraer archivos
    cd /tmp
    tar -xzf traccar-deploy.tar.gz
    
    # Copiar archivos
    sudo cp traccar/tracker-server.jar /opt/traccar/
    sudo cp -r traccar/lib/* /opt/traccar/lib/
    sudo cp traccar/traccar.xml /opt/traccar/conf/
    
    # Copiar frontend si existe
    if [ -d traccar/traccar-web ]; then
        sudo cp -r traccar/traccar-web /opt/traccar/
    fi
    
    # Copiar templates si existen
    if [ -d traccar/templates ]; then
        sudo cp -r traccar/templates /opt/traccar/
    fi
    
    # Copiar scripts
    if [ -d traccar/scripts ]; then
        sudo cp -r traccar/scripts/* /opt/traccar/scripts/
        sudo chmod +x /opt/traccar/scripts/*.sh
    fi
    
    # Ajustar permisos
    sudo chown -R $USER:$USER /opt/traccar
    
    # Limpiar
    rm -rf traccar traccar-deploy.tar.gz
    
    echo "✓ Archivos extraídos y configurados"
ENDSSH

echo ""
echo "6. Verificando servicio..."
ssh "$SERVER" "sudo systemctl status traccar || echo 'Servicio no configurado aún'"

echo ""
echo "=========================================="
echo "Deploy completado!"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "1. Conecta al servidor: ssh $SERVER"
echo "2. Configura traccar.xml si es necesario: nano /opt/traccar/conf/traccar.xml"
echo "3. Crea usuario admin: /opt/traccar/scripts/create-admin-server.sh"
echo "4. Inicia el servicio: sudo systemctl start traccar"
echo ""

# Limpiar
rm -rf "$TEMP_DIR"

