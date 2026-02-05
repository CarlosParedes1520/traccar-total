#!/bin/sh
set -e

echo "=== Iniciando docker-entrypoint.sh ==="
echo "Directorio de trabajo: $(pwd)"
echo "Variables de entorno relevantes:"
echo "  CONFIG_USE_ENVIRONMENT_VARIABLES=${CONFIG_USE_ENVIRONMENT_VARIABLES:-no configurada}"
echo "  DATABASE_DRIVER=${DATABASE_DRIVER:-no configurada}"
echo "  PORT=${PORT:-no configurada}"

# Crear directorios si no existen
mkdir -p /opt/traccar/conf /opt/traccar/data /opt/traccar/logs
echo "Directorios creados: conf, data, logs"

# Generar archivo de configuración
CONFIG_FILE="/opt/traccar/conf/traccar.xml"

# Iniciar el archivo XML
cat > "$CONFIG_FILE" <<'XMLHEAD'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM 'http://java.sun.com/dtd/properties.dtd'>
<properties>
XMLHEAD

# Agregar configuración de base de datos si está disponible
if [ -n "$DATABASE_DRIVER" ]; then
    echo "    <entry key='database.driver'>$DATABASE_DRIVER</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado DATABASE_DRIVER"
fi

if [ -n "$DATABASE_URL" ]; then
    echo "    <entry key='database.url'>$DATABASE_URL</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado DATABASE_URL"
fi

if [ -n "$DATABASE_USER" ]; then
    echo "    <entry key='database.user'>$DATABASE_USER</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado DATABASE_USER"
fi

if [ -n "$DATABASE_PASSWORD" ]; then
    echo "    <entry key='database.password'>$DATABASE_PASSWORD</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado DATABASE_PASSWORD"
fi

# Si no hay configuración de base de datos, usar valores por defecto (H2)
if [ -z "$DATABASE_DRIVER" ] && [ -z "$DATABASE_URL" ]; then
    echo "  - Usando base de datos H2 por defecto (en memoria)"
    cat >> "$CONFIG_FILE" <<'DEFAULTH2'
    <entry key='database.driver'>org.h2.Driver</entry>
    <entry key='database.url'>jdbc:h2:./data/database</entry>
    <entry key='database.user'>sa</entry>
    <entry key='database.password'></entry>
DEFAULTH2
fi

# Configuración de puerto web (Railway usa PORT)
if [ -n "$PORT" ]; then
    echo "    <entry key='web.port'>$PORT</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado puerto web: $PORT"
elif [ -n "$WEB_PORT" ]; then
    echo "    <entry key='web.port'>$WEB_PORT</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado puerto web: $WEB_PORT"
fi

# Otras configuraciones opcionales
if [ -n "$LOG_LEVEL" ]; then
    echo "    <entry key='logger.level'>$LOG_LEVEL</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado LOG_LEVEL: $LOG_LEVEL"
fi

# Cerrar el archivo XML
echo "</properties>" >> "$CONFIG_FILE"

# Verificar que el archivo existe y tiene contenido
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: No se pudo crear el archivo de configuración: $CONFIG_FILE"
    exit 1
fi

if [ ! -s "$CONFIG_FILE" ]; then
    echo "ERROR: El archivo de configuración está vacío: $CONFIG_FILE"
    exit 1
fi

echo "=== Archivo de configuración creado exitosamente ==="
echo "Contenido de $CONFIG_FILE:"
cat "$CONFIG_FILE"
echo "=========================================="

# Verificar que el JAR existe
if [ ! -f "tracker-server.jar" ]; then
    echo "ERROR: tracker-server.jar no encontrado en $(pwd)"
    ls -la
    exit 1
fi

echo "=== Iniciando Traccar ==="
echo "Comando: java $JAVA_OPTS -jar tracker-server.jar $CONFIG_FILE"

# Ejecutar Traccar
exec java $JAVA_OPTS -jar tracker-server.jar "$CONFIG_FILE"
