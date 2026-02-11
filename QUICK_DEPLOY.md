# 🚀 Guía Rápida de Deploy - Digital Ocean

## Opción 1: Deploy Automático (Recomendado)

### Desde tu máquina local:

```bash
# 1. Editar el script deploy.sh y cambiar el servidor
nano scripts/deploy.sh
# Cambiar: SERVER="${1:-usuario@tu-servidor-ip}"

# 2. Ejecutar deploy
./scripts/deploy.sh usuario@tu-servidor-ip
```

### En el servidor:

```bash
# 1. Configurar el servidor (solo primera vez)
sudo /opt/traccar/scripts/setup-server.sh

# 2. Crear usuario admin
/opt/traccar/scripts/create-admin-server.sh

# 3. Iniciar servicio
sudo systemctl start traccar

# 4. Verificar
sudo systemctl status traccar
```

---

## Opción 2: Deploy Manual

### Paso 1: Compilar localmente

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
./gradlew build -x test
```

### Paso 2: Subir archivos

```bash
# Subir JAR y dependencias
scp target/tracker-server.jar usuario@servidor:/opt/traccar/
scp -r target/lib usuario@servidor:/opt/traccar/
scp debug.xml usuario@servidor:/opt/traccar/conf/traccar.xml
scp -r traccar-web usuario@servidor:/opt/traccar/
```

### Paso 3: En el servidor

```bash
# Instalar Java
sudo apt update
sudo apt install -y openjdk-17-jdk

# Configurar servicio
sudo /opt/traccar/scripts/setup-server.sh

# Crear admin
/opt/traccar/scripts/create-admin-server.sh

# Iniciar
sudo systemctl start traccar
```

---

## 📝 Comandos Útiles

```bash
# Ver estado del servicio
sudo systemctl status traccar

# Ver logs en tiempo real
sudo journalctl -u traccar -f

# Reiniciar servicio
sudo systemctl restart traccar

# Detener servicio
sudo systemctl stop traccar

# Ver últimos 100 logs
sudo journalctl -u traccar -n 100
```

---

## 🔐 Crear Usuario Admin

```bash
# Ejecutar script
/opt/traccar/scripts/create-admin-server.sh

# Credenciales por defecto:
# Email: admin
# Password: admin
```

---

## 🌐 Acceder a la Web

Una vez iniciado, accede a:
```
http://tu-servidor-ip:8082
```

---

## ⚙️ Configuración

Editar configuración:
```bash
sudo nano /opt/traccar/conf/traccar.xml
```

Después de cambiar, reiniciar:
```bash
sudo systemctl restart traccar
```

---

## 🔥 Firewall

```bash
# Abrir puertos necesarios
sudo ufw allow 8082/tcp
sudo ufw allow 5000:5500/tcp
sudo ufw reload
```

---

## 🐛 Problemas Comunes

### Servicio no inicia
```bash
sudo journalctl -u traccar -n 50
```

### Puerto en uso
```bash
sudo lsof -i :8082
sudo kill -9 <PID>
```

### Error de permisos
```bash
sudo chown -R traccar:traccar /opt/traccar
```

