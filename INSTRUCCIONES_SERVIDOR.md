# 🖥️ Instrucciones para Ejecutar en el Servidor

## Situación Actual
Estás en `/opt/traccar-total` pero los scripts buscan `/opt/traccar`

## Solución Rápida

### Opción 1: Ejecutar desde donde estás (RECOMENDADO)

```bash
# 1. Verificar que estás en el directorio correcto
cd /opt/traccar-total
ls -la

# 2. Si los scripts están aquí, ejecutar directamente:
chmod +x scripts/*.sh

# 3. Configurar desde traccar-total
sudo scripts/setup-from-traccar-total.sh

# 4. Crear admin (desde traccar-total)
scripts/create-admin-direct.sh

# 5. Iniciar servicio
sudo systemctl start traccar
```

### Opción 2: Crear estructura en /opt/traccar

```bash
# 1. Crear directorios
sudo mkdir -p /opt/traccar/{conf,lib,logs,data,scripts}

# 2. Copiar archivos desde traccar-total
cd /opt/traccar-total
sudo cp target/tracker-server.jar /opt/traccar/
sudo cp -r target/lib/* /opt/traccar/lib/
sudo cp debug.xml /opt/traccar/conf/traccar.xml
sudo cp -r scripts/* /opt/traccar/scripts/
sudo chmod +x /opt/traccar/scripts/*.sh

# 3. Ahora ejecutar los scripts originales
sudo /opt/traccar/scripts/setup-server.sh
/opt/traccar/scripts/create-admin-server.sh
sudo systemctl start traccar
```

### Opción 3: Crear admin manualmente (MÁS RÁPIDO)

Si solo necesitas crear el admin y ya tienes Traccar funcionando:

```bash
cd /opt/traccar-total

# Buscar el JAR de MySQL
MYSQL_JAR=$(find . -name "mysql-connector-j-*.jar" | head -1)
echo "MySQL JAR: $MYSQL_JAR"

# Si no está aquí, buscar en /opt/traccar
if [ -z "$MYSQL_JAR" ]; then
    MYSQL_JAR=$(find /opt/traccar -name "mysql-connector-j-*.jar" 2>/dev/null | head -1)
fi

# Ejecutar script directo
chmod +x scripts/create-admin-direct.sh
scripts/create-admin-direct.sh
```

## Verificar Estado Actual

```bash
# Ver qué archivos tienes
ls -la /opt/traccar-total/

# Ver si existe /opt/traccar
ls -la /opt/traccar/ 2>/dev/null || echo "No existe /opt/traccar"

# Buscar tracker-server.jar
find /opt -name "tracker-server.jar" 2>/dev/null

# Ver si hay un servicio configurado
systemctl status traccar 2>/dev/null || echo "Servicio no configurado"
```

## Comandos Paso a Paso (Desde /opt/traccar-total)

```bash
# 1. Verificar que tienes todo
cd /opt/traccar-total
ls -la target/tracker-server.jar
ls -la target/lib/
ls -la debug.xml

# 2. Configurar todo (esto creará /opt/traccar y copiará archivos)
sudo scripts/setup-from-traccar-total.sh

# 3. Crear usuario admin
scripts/create-admin-direct.sh

# 4. Iniciar servicio
sudo systemctl start traccar

# 5. Verificar
sudo systemctl status traccar
sudo journalctl -u traccar -f
```

## Si el Servicio Ya Está Corriendo

Si Traccar ya está funcionando pero solo necesitas crear el admin:

```bash
cd /opt/traccar-total
chmod +x scripts/create-admin-direct.sh
scripts/create-admin-direct.sh
```

Esto creará el usuario admin sin afectar el servicio.

