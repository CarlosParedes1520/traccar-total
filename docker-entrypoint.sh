#!/bin/sh
set -e

echo "=== Iniciando docker-entrypoint.sh ==="
echo "Directorio de trabajo: $(pwd)"
echo "Variables de entorno relevantes:"
echo "  CONFIG_USE_ENVIRONMENT_VARIABLES=${CONFIG_USE_ENVIRONMENT_VARIABLES:-no configurada}"
echo "  DATABASE_DRIVER=${DATABASE_DRIVER:-no configurada}"
echo "  DATABASE_URL=${DATABASE_URL:-no configurada}"
echo "  PGHOST=${PGHOST:-no configurada}"
echo "  PGPORT=${PGPORT:-no configurada}"
echo "  PGDATABASE=${PGDATABASE:-no configurada}"
echo "  PGUSER=${PGUSER:-no configurada}"
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

# Determinar configuración de base de datos
DB_DRIVER=""
DB_URL=""
DB_USER=""
DB_PASSWORD=""

# Si DATABASE_URL está configurada, verificar si necesita conversión
if [ -n "$DATABASE_URL" ]; then
    # Si la URL no comienza con jdbc:, convertirla
    if echo "$DATABASE_URL" | grep -q "^jdbc:"; then
        DB_URL="$DATABASE_URL"
    elif echo "$DATABASE_URL" | grep -q "^postgresql://"; then
        # Convertir postgresql:// a jdbc:postgresql://
        DB_URL=$(echo "$DATABASE_URL" | sed 's|^postgresql://|jdbc:postgresql://|')
        echo "  - Convertida URL de postgresql:// a formato JDBC"
    elif echo "$DATABASE_URL" | grep -q "^mysql://"; then
        # Convertir mysql:// a jdbc:mysql://
        DB_URL=$(echo "$DATABASE_URL" | sed 's|^mysql://|jdbc:mysql://|')
        echo "  - Convertida URL de mysql:// a formato JDBC"
    else
        DB_URL="$DATABASE_URL"
    fi
fi

# Si tenemos variables PostgreSQL de Railway, construir la URL JDBC
if [ -z "$DB_URL" ] && [ -n "$PGHOST" ] && [ -n "$PGDATABASE" ]; then
    echo "  - Detectadas variables PostgreSQL de Railway, construyendo URL JDBC"
    DB_DRIVER="org.postgresql.Driver"
    DB_USER="${PGUSER:-postgres}"
    DB_PASSWORD="${PGPASSWORD:-}"
    PGPORT="${PGPORT:-5432}"
    
    # Construir URL JDBC
    DB_URL="jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}?sslmode=require"
    echo "  - URL JDBC construida desde variables Railway"
fi

# Si tenemos variables MySQL de Railway, construir la URL JDBC
if [ -z "$DB_URL" ] && [ -n "$MYSQLHOST" ] && [ -n "$MYSQLDATABASE" ]; then
    echo "  - Detectadas variables MySQL de Railway, construyendo URL JDBC"
    DB_DRIVER="com.mysql.cj.jdbc.Driver"
    DB_USER="${MYSQLUSER:-root}"
    DB_PASSWORD="${MYSQLPASSWORD:-}"
    MYSQLPORT="${MYSQLPORT:-3306}"
    
    # Construir URL JDBC
    DB_URL="jdbc:mysql://${MYSQLHOST}:${MYSQLPORT}/${MYSQLDATABASE}?zeroDateTimeBehavior=round&serverTimezone=UTC&allowPublicKeyRetrieval=true&useSSL=true&allowMultiQueries=true&autoReconnect=true&useUnicode=yes&characterEncoding=UTF-8&sessionVariables=sql_mode=''"
    echo "  - URL JDBC construida desde variables Railway"
fi

# Usar variables explícitas si están configuradas
if [ -n "$DATABASE_DRIVER" ]; then
    DB_DRIVER="$DATABASE_DRIVER"
fi
if [ -n "$DATABASE_USER" ]; then
    DB_USER="$DATABASE_USER"
fi
if [ -n "$DATABASE_PASSWORD" ]; then
    DB_PASSWORD="$DATABASE_PASSWORD"
fi

# Agregar configuración de base de datos al archivo XML
if [ -n "$DB_DRIVER" ]; then
    echo "    <entry key='database.driver'>$DB_DRIVER</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado DATABASE_DRIVER: $DB_DRIVER"
fi

if [ -n "$DB_URL" ]; then
    echo "    <entry key='database.url'>$DB_URL</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado DATABASE_URL"
fi

if [ -n "$DB_USER" ]; then
    echo "    <entry key='database.user'>$DB_USER</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado DATABASE_USER"
fi

if [ -n "$DB_PASSWORD" ]; then
    echo "    <entry key='database.password'>$DB_PASSWORD</entry>" >> "$CONFIG_FILE"
    echo "  - Configurado DATABASE_PASSWORD"
fi

# Si no hay configuración de base de datos, usar valores por defecto (H2)
if [ -z "$DB_DRIVER" ] && [ -z "$DB_URL" ]; then
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
