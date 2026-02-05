#!/bin/sh
set -e

# Crear directorios si no existen
mkdir -p /opt/traccar/conf /opt/traccar/data /opt/traccar/logs

# Generar archivo de configuración desde variables de entorno si CONFIG_USE_ENVIRONMENT_VARIABLES está activado
if [ "$CONFIG_USE_ENVIRONMENT_VARIABLES" = "true" ]; then
    echo "Generando configuración desde variables de entorno..."
    
    # Crear archivo traccar.xml desde plantilla o desde cero
    cat > /opt/traccar/conf/traccar.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM 'http://java.sun.com/dtd/properties.dtd'>
<properties>
EOF

    # Configuración de base de datos
    if [ -n "$DATABASE_DRIVER" ]; then
        echo "    <entry key='database.driver'>$DATABASE_DRIVER</entry>" >> /opt/traccar/conf/traccar.xml
    fi
    
    if [ -n "$DATABASE_URL" ]; then
        echo "    <entry key='database.url'>$DATABASE_URL</entry>" >> /opt/traccar/conf/traccar.xml
    fi
    
    if [ -n "$DATABASE_USER" ]; then
        echo "    <entry key='database.user'>$DATABASE_USER</entry>" >> /opt/traccar/conf/traccar.xml
    fi
    
    if [ -n "$DATABASE_PASSWORD" ]; then
        echo "    <entry key='database.password'>$DATABASE_PASSWORD</entry>" >> /opt/traccar/conf/traccar.xml
    fi
    
    # Configuración de puerto web (Railway usa PORT)
    if [ -n "$PORT" ]; then
        echo "    <entry key='web.port'>$PORT</entry>" >> /opt/traccar/conf/traccar.xml
    elif [ -n "$WEB_PORT" ]; then
        echo "    <entry key='web.port'>$WEB_PORT</entry>" >> /opt/traccar/conf/traccar.xml
    fi
    
    # Otras configuraciones opcionales
    if [ -n "$LOG_LEVEL" ]; then
        echo "    <entry key='logger.level'>$LOG_LEVEL</entry>" >> /opt/traccar/conf/traccar.xml
    fi
    
    echo "</properties>" >> /opt/traccar/conf/traccar.xml
    
    echo "Configuración generada en /opt/traccar/conf/traccar.xml"
else
    # Si no se usan variables de entorno, copiar plantilla si existe
    if [ -f /opt/traccar/conf/traccar.xml.template ]; then
        cp /opt/traccar/conf/traccar.xml.template /opt/traccar/conf/traccar.xml
    fi
fi

# Ejecutar Traccar
exec java $JAVA_OPTS -jar tracker-server.jar conf/traccar.xml
