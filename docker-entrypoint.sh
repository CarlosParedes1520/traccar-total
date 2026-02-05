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

# Si DATABASE_URL está configurada, extraer información
if [ -n "$DATABASE_URL" ]; then
    echo "  - Procesando DATABASE_URL: ${DATABASE_URL:0:50}..."
    
    # Detectar tipo de base de datos y extraer credenciales
    if echo "$DATABASE_URL" | grep -q "^postgresql://"; then
        # PostgreSQL: postgresql://user:password@host:port/database
        DB_DRIVER="org.postgresql.Driver"
        
        # Extraer usuario y contraseña de la URL
        # Formato: postgresql://user:password@host:port/database
        URL_PART=$(echo "$DATABASE_URL" | sed 's|^postgresql://||')
        
        # Extraer usuario y contraseña si están presentes
        if echo "$URL_PART" | grep -q "@"; then
            # Hay credenciales en la URL
            CREDENTIALS=$(echo "$URL_PART" | cut -d'@' -f1)
            HOST_PART=$(echo "$URL_PART" | cut -d'@' -f2)
            
            if echo "$CREDENTIALS" | grep -q ":"; then
                DB_USER=$(echo "$CREDENTIALS" | cut -d':' -f1)
                DB_PASSWORD=$(echo "$CREDENTIALS" | cut -d':' -f2-)
            else
                DB_USER="$CREDENTIALS"
            fi
            
            # Construir URL JDBC sin credenciales
            DB_URL="jdbc:postgresql://${HOST_PART}?sslmode=require"
        else
            # No hay credenciales, usar la URL directamente
            DB_URL=$(echo "$DATABASE_URL" | sed 's|^postgresql://|jdbc:postgresql://|')
            # Agregar sslmode si no está presente
            if echo "$DB_URL" | grep -qv "sslmode"; then
                DB_URL="${DB_URL}?sslmode=require"
            fi
        fi
        echo "  - Detectado PostgreSQL, driver configurado"
        
    elif echo "$DATABASE_URL" | grep -q "^mysql://"; then
        # MySQL: mysql://user:password@host:port/database
        DB_DRIVER="com.mysql.cj.jdbc.Driver"
        
        # Extraer usuario y contraseña de la URL
        URL_PART=$(echo "$DATABASE_URL" | sed 's|^mysql://||')
        
        if echo "$URL_PART" | grep -q "@"; then
            CREDENTIALS=$(echo "$URL_PART" | cut -d'@' -f1)
            HOST_PART=$(echo "$URL_PART" | cut -d'@' -f2)
            
            if echo "$CREDENTIALS" | grep -q ":"; then
                DB_USER=$(echo "$CREDENTIALS" | cut -d':' -f1)
                DB_PASSWORD=$(echo "$CREDENTIALS" | cut -d':' -f2-)
            else
                DB_USER="$CREDENTIALS"
            fi
            
            # Construir URL JDBC sin credenciales
            DB_URL="jdbc:mysql://${HOST_PART}?zeroDateTimeBehavior=round&serverTimezone=UTC&allowPublicKeyRetrieval=true&useSSL=true&allowMultiQueries=true&autoReconnect=true&useUnicode=yes&characterEncoding=UTF-8&sessionVariables=sql_mode=''"
        else
            DB_URL=$(echo "$DATABASE_URL" | sed 's|^mysql://|jdbc:mysql://|')
        fi
        echo "  - Detectado MySQL, driver configurado"
        
    elif echo "$DATABASE_URL" | grep -q "^jdbc:"; then
        # Ya está en formato JDBC
        DB_URL="$DATABASE_URL"
        
        # Intentar detectar el driver desde la URL
        if echo "$DATABASE_URL" | grep -q "jdbc:postgresql"; then
            DB_DRIVER="org.postgresql.Driver"
        elif echo "$DATABASE_URL" | grep -q "jdbc:mysql"; then
            DB_DRIVER="com.mysql.cj.jdbc.Driver"
        fi
        echo "  - URL ya en formato JDBC"
    else
        DB_URL="$DATABASE_URL"
        echo "  - URL en formato desconocido, usando tal cual"
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

# Usar variables explícitas si están configuradas (tienen prioridad)
if [ -n "$DATABASE_DRIVER" ]; then
    DB_DRIVER="$DATABASE_DRIVER"
fi
if [ -n "$DATABASE_USER" ]; then
    DB_USER="$DATABASE_USER"
fi
if [ -n "$DATABASE_PASSWORD" ]; then
    DB_PASSWORD="$DATABASE_PASSWORD"
fi

# Si tenemos URL pero no driver, intentar detectarlo desde la URL
if [ -n "$DB_URL" ] && [ -z "$DB_DRIVER" ]; then
    if echo "$DB_URL" | grep -q "jdbc:postgresql"; then
        DB_DRIVER="org.postgresql.Driver"
        echo "  - Driver PostgreSQL detectado desde URL"
    elif echo "$DB_URL" | grep -q "jdbc:mysql"; then
        DB_DRIVER="com.mysql.cj.jdbc.Driver"
        echo "  - Driver MySQL detectado desde URL"
    fi
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

# Verificar conexión a la base de datos si está configurada
if [ -n "$DB_URL" ] && [ -n "$DB_DRIVER" ]; then
    echo ""
    echo "=== Verificando conexión a la base de datos ==="
    echo "URL: ${DB_URL:0:60}..."
    echo "Driver: $DB_DRIVER"
    echo "Usuario: ${DB_USER:-no configurado}"
    echo ""
    
    # Intentar verificar la conexión usando un pequeño script Java
    # (Esto es opcional, Traccar lo hará de todas formas)
    echo "La conexión será verificada por Traccar al iniciar..."
    echo ""
fi

echo "=== Iniciando Traccar ==="
echo "Comando: java $JAVA_OPTS -jar tracker-server.jar $CONFIG_FILE"
echo "Variables Java: $JAVA_OPTS"
echo ""

# Ejecutar Traccar y capturar el código de salida
# Usar exec para que Railway pueda manejar las señales correctamente
set +e  # No salir inmediatamente si hay error
java $JAVA_OPTS -jar tracker-server.jar "$CONFIG_FILE"
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "=========================================="
    echo "ERROR: Traccar terminó con código de salida: $EXIT_CODE"
    echo "=========================================="
    echo ""
    echo "Posibles causas:"
    echo "  - Error de conexión a la base de datos"
    echo "  - Error al inicializar las tablas (Liquibase)"
    echo "  - Problema con el puerto o configuración"
    echo "  - Falta de memoria (actualmente: $JAVA_OPTS)"
    echo "  - Error en la configuración del archivo XML"
    echo ""
    echo "Revisa los logs anteriores para más detalles."
    echo ""
    echo "Configuración actual:"
    echo "  - Driver: ${DB_DRIVER:-no configurado}"
    echo "  - URL: ${DB_URL:0:80}..."
    echo "  - Usuario: ${DB_USER:-no configurado}"
    echo "  - Puerto web: ${PORT:-no configurado}"
    echo ""
fi

# Salir con el mismo código de salida
exit $EXIT_CODE
