# Guía de Despliegue en Digital Ocean (Linux)

## 📋 Índice
1. [Preparar el proyecto localmente](#1-preparar-el-proyecto-localmente)
2. [Subir archivos al servidor](#2-subir-archivos-al-servidor)
3. [Instalar dependencias en el servidor](#3-instalar-dependencias-en-el-servidor)
4. [Configurar Traccar](#4-configurar-traccar)
5. [Crear usuario Admin](#5-crear-usuario-admin)
6. [Configurar como servicio systemd](#6-configurar-como-servicio-systemd)

---

## 1. Preparar el proyecto localmente

### Compilar el proyecto

```bash
# En tu máquina local
cd traccar-total
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
./gradlew build -x test
```

Esto generará:
- `target/tracker-server.jar` - El JAR ejecutable
- `target/lib/` - Todas las dependencias

### Crear un paquete para subir

```bash
# Crear directorio temporal para el deploy
mkdir -p deploy/traccar
cp target/tracker-server.jar deploy/traccar/
cp -r target/lib deploy/traccar/
cp debug.xml deploy/traccar/traccar.xml
cp -r traccar-web deploy/traccar/  # Si tienes el frontend
cp -r templates deploy/traccar/  # Si tienes templates
cp -r schema deploy/traccar/  # Para las migraciones

# Crear un archivo comprimido
cd deploy
tar -czf traccar-deploy.tar.gz traccar/
```

---

## 2. Subir archivos al servidor

### Opción A: Usando SCP

```bash
# Desde tu máquina local
scp traccar-deploy.tar.gz usuario@tu-servidor-ip:/tmp/

# O si prefieres subir archivos individuales
scp target/tracker-server.jar usuario@tu-servidor-ip:/opt/traccar/
scp -r target/lib usuario@tu-servidor-ip:/opt/traccar/
scp debug.xml usuario@tu-servidor-ip:/opt/traccar/conf/traccar.xml
```

### Opción B: Usando Git (recomendado)

```bash
# 1. Subir código al repositorio
git add .
git commit -m "Preparado para deploy"
git push origin main

# 2. En el servidor, clonar/actualizar
ssh usuario@tu-servidor-ip
cd /opt
git clone tu-repositorio traccar
cd traccar/traccar-total
./gradlew build -x test
```

---

## 3. Instalar dependencias en el servidor

Conéctate al servidor:

```bash
ssh usuario@tu-servidor-ip
```

### Instalar Java 17

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y openjdk-17-jdk

# Verificar instalación
java -version
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

### Crear estructura de directorios

```bash
sudo mkdir -p /opt/traccar/{conf,data,logs,lib}
sudo chown -R $USER:$USER /opt/traccar
```

### Extraer archivos (si usaste tar)

```bash
cd /tmp
tar -xzf traccar-deploy.tar.gz
sudo cp -r traccar/* /opt/traccar/
```

---

## 4. Configurar Traccar

### Crear archivo de configuración

```bash
sudo nano /opt/traccar/conf/traccar.xml
```

Usa tu configuración de `debug.xml` pero adaptada para producción:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM 'http://java.sun.com/dtd/properties.dtd'>
<properties>

    <entry key='web.path'>/opt/traccar/traccar-web</entry>
    <entry key='web.port'>8082</entry>
    <entry key='web.debug'>false</entry>
    <entry key='web.console'>false</entry>

    <entry key='database.driver'>com.mysql.cj.jdbc.Driver</entry>
    <entry key='database.url'>jdbc:mysql://137.184.85.144:4406/traccar?serverTimezone=UTC&amp;useSSL=false&amp;allowPublicKeyRetrieval=true</entry>
    <entry key='database.user'>physeter</entry>
    <entry key='database.password'>Ph15eter$2025$R</entry>

    <entry key='logger.console'>false</entry>
    <entry key='logger.file'>/opt/traccar/logs/tracker-server.log</entry>

    <!-- Otras configuraciones... -->

</properties>
```

---

## 5. Crear usuario Admin

### Crear script para crear admin

```bash
sudo nano /opt/traccar/scripts/create-admin.sh
```

Pega este contenido:

```bash
#!/bin/bash

# Script para crear usuario admin en Traccar
# Uso: ./create-admin.sh

DB_HOST="137.184.85.144"
DB_PORT="4406"
DB_NAME="traccar"
DB_USER="physeter"
DB_PASS="Ph15eter\$2025\$R"

# Verificar si mysql está instalado
if ! command -v mysql &> /dev/null; then
    echo "MySQL client no está instalado. Instalando..."
    sudo apt install -y mysql-client
fi

# Crear script SQL temporal
cat > /tmp/create_admin.sql << 'EOF'
-- Verificar si existe usuario admin
SELECT id FROM tc_users WHERE email = 'admin' OR login = 'admin' INTO @user_id;

-- Si existe, actualizar contraseña
-- Si no existe, crear nuevo usuario
-- Nota: Este script requiere que ejecutes el script Java para generar el hash correcto
EOF

echo "Para crear el usuario admin, necesitas ejecutar el script Java."
echo "Ver sección 'Crear Admin con Script Java' más abajo."
```

### Crear script Java para crear admin

```bash
sudo nano /opt/traccar/scripts/CreateAdminUser.java
```

(Copia el código del script que creamos antes, adaptado para el servidor)

### Compilar y ejecutar

```bash
cd /opt/traccar/scripts
javac -cp "/opt/traccar/lib/mysql-connector-j-*.jar" CreateAdminUser.java
java -cp ".:/opt/traccar/lib/mysql-connector-j-*.jar" CreateAdminUser
```

---

## 6. Configurar como servicio systemd

### Crear archivo de servicio

```bash
sudo nano /etc/systemd/system/traccar.service
```

Contenido:

```ini
[Unit]
Description=Traccar GPS Tracking Server
After=network.target mysql.service

[Service]
Type=simple
User=tu-usuario
Group=tu-grupo
WorkingDirectory=/opt/traccar
ExecStart=/usr/bin/java -jar /opt/traccar/tracker-server.jar /opt/traccar/conf/traccar.xml
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=traccar

# Límites de recursos
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

**Importante:** Reemplaza `tu-usuario` y `tu-grupo` con tu usuario real.

### Habilitar y iniciar el servicio

```bash
# Recargar systemd
sudo systemctl daemon-reload

# Habilitar para que inicie al arrancar
sudo systemctl enable traccar

# Iniciar el servicio
sudo systemctl start traccar

# Verificar estado
sudo systemctl status traccar

# Ver logs
sudo journalctl -u traccar -f
```

### Comandos útiles del servicio

```bash
# Iniciar
sudo systemctl start traccar

# Detener
sudo systemctl stop traccar

# Reiniciar
sudo systemctl restart traccar

# Ver estado
sudo systemctl status traccar

# Ver logs en tiempo real
sudo journalctl -u traccar -f

# Ver últimos 100 logs
sudo journalctl -u traccar -n 100
```

---

## 🔧 Scripts de Automatización

### Script completo de deploy

Crea `deploy.sh` en tu máquina local:

```bash
#!/bin/bash

SERVER="usuario@tu-servidor-ip"
REMOTE_DIR="/opt/traccar"

echo "Compilando proyecto..."
./gradlew build -x test

echo "Subiendo archivos..."
scp target/tracker-server.jar $SERVER:$REMOTE_DIR/
scp -r target/lib $SERVER:$REMOTE_DIR/
scp debug.xml $SERVER:$REMOTE_DIR/conf/traccar.xml

echo "Reiniciando servicio..."
ssh $SERVER "sudo systemctl restart traccar"

echo "Deploy completado!"
```

Hazlo ejecutable:

```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 📝 Checklist de Deploy

- [ ] Java 17 instalado en el servidor
- [ ] Proyecto compilado (`tracker-server.jar` generado)
- [ ] Archivos subidos al servidor
- [ ] Configuración `traccar.xml` creada en `/opt/traccar/conf/`
- [ ] Directorios creados (`/opt/traccar/{lib,logs,data}`)
- [ ] Permisos correctos en `/opt/traccar`
- [ ] Servicio systemd configurado
- [ ] Servicio iniciado y funcionando
- [ ] Usuario admin creado
- [ ] Firewall configurado (puerto 8082 abierto)
- [ ] Logs verificados

---

## 🔥 Configurar Firewall

```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 8082/tcp
sudo ufw allow 5000:5500/tcp  # Para dispositivos GPS
sudo ufw reload

# O si usas iptables directamente
sudo iptables -A INPUT -p tcp --dport 8082 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5000:5500 -j ACCEPT
```

---

## 🐛 Troubleshooting

### El servicio no inicia

```bash
# Ver logs detallados
sudo journalctl -u traccar -n 50

# Verificar permisos
ls -la /opt/traccar/

# Verificar que Java está en el PATH
which java
java -version
```

### Error de conexión a base de datos

```bash
# Probar conexión manualmente
mysql -h 137.184.85.144 -P 4406 -u physeter -p traccar
```

### Puerto ya en uso

```bash
# Ver qué proceso usa el puerto 8082
sudo lsof -i :8082
# O
sudo netstat -tulpn | grep 8082
```

---

## 📚 Recursos Adicionales

- Logs del sistema: `/opt/traccar/logs/`
- Configuración: `/opt/traccar/conf/traccar.xml`
- Base de datos: MySQL en `137.184.85.144:4406`
- Web interface: `http://tu-servidor-ip:8082`

