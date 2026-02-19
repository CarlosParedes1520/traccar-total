# 🚀 Guía: Qué Ejecutar en el Servidor

Esta guía te indica exactamente qué comandos ejecutar en el servidor para:
1. **Solucionar el error de password null del usuario admin** (solución temporal)
2. **Aplicar el fix de la causa raíz** (solución permanente)

---

## 📋 Prerrequisitos

Antes de empezar, verifica que estás en el servidor:

```bash
# Verificar que estás en el servidor correcto
hostname
# Debería mostrar algo como: ubuntu-s-1vcpu-2gb-nyc3-01

# Verificar que el servicio Traccar está corriendo
sudo systemctl status traccar
```

---

## 🔧 Paso 1: Actualizar el Código desde Git

Si el código en el servidor no está actualizado, primero actualízalo:

```bash
# Ir al directorio del proyecto
cd /opt/traccar-total

# Verificar que estás en la rama main
git branch

# Si no estás en main, cambiar:
git checkout main

# Actualizar desde el repositorio remoto
git pull origin main
```

---

## 🔧 Paso 2: Verificar que el Script Existe

```bash
# Verificar que el script existe
ls -la scripts/fix-admin-user.sh

# Si no existe, el git pull debería haberlo descargado
# Si aún no existe, verifica la conexión a git
```

---

## 🔧 Paso 3: Verificar Prerrequisitos del Script

El script necesita:
- Java instalado
- JAR de MySQL connector
- Acceso a la base de datos

### Verificar Java:

```bash
java -version
# Debe mostrar Java 17 o superior
```

### Verificar JAR de MySQL:

```bash
# Buscar el JAR en el proyecto compilado
find /opt/traccar-total/target/lib -name "mysql-connector-j-*.jar" 2>/dev/null

# O buscar en el directorio de Traccar instalado
find /opt/traccar/lib -name "mysql-connector-j-*.jar" 2>/dev/null

# Si no encuentras ninguno, necesitas compilar el proyecto primero (ver Paso 4)
```

---

## 🔧 Paso 4: Compilar el Proyecto (Si es Necesario)

Si el JAR de MySQL no existe, necesitas compilar el proyecto:

```bash
cd /opt/traccar-total

# Verificar que Gradle está instalado
./gradlew --version

# Compilar el proyecto (esto generará target/lib con todos los JARs)
./gradlew build -x test

# Esto puede tardar varios minutos la primera vez
```

---

## ✅ Paso 5: Ejecutar el Script de Corrección

Una vez que todo esté listo, ejecuta el script:

```bash
cd /opt/traccar-total

# Ejecutar el script con permisos de root
sudo bash scripts/fix-admin-user.sh
```

### ¿Qué hace el script?

1. **Busca el usuario admin** en la base de datos
2. **Verifica** si tiene `hashedPassword` o `salt` como `NULL`
3. **Genera un nuevo hash** usando PBKDF2 con el password "admin"
4. **Actualiza el usuario** con el hash y salt correctos
5. **Asegura** que el usuario sea administrador y esté habilitado

### Salida Esperada:

```
==========================================
Verificando y corrigiendo usuario Admin
==========================================
MySQL connector: /opt/traccar-total/target/lib/mysql-connector-j-8.0.33.jar
Compilando script...
Ejecutando corrección...
Usuario encontrado:
  ID: 1
  Nombre: Administrator
  Email: admin
  Login: admin
  Administrador: true
  Deshabilitado: false
  Sin password: true
  Sin salt: true
  Hash actual: NULL
  Salt actual: NULL

Corrigiendo usuario...
✓ Usuario corregido exitosamente!

Credenciales:
  Email/Login: admin
  Password: admin

==========================================
Proceso completado!
==========================================
```

---

## ✅ Paso 6: Verificar que Funciona

Después de ejecutar el script, verifica que el login funciona:

```bash
# Probar el login
curl -X POST http://localhost:8082/api/session \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=admin&password=admin"
```

### Respuesta Exitosa:

Deberías recibir un JSON con los datos del usuario:

```json
{
  "id": 1,
  "name": "Administrator",
  "email": "admin",
  "administrator": true,
  "disabled": false,
  ...
}
```

### Si Aún Hay Error:

Si sigues recibiendo el error `NullPointerException`, verifica:

1. **Que el script se ejecutó correctamente:**
   ```bash
   # Verificar en la base de datos directamente
   mysql -h 137.184.85.144 -P 4406 -u physeter -p traccar
   # Password: Ph15eter$2025$R
   ```

2. **En MySQL, ejecuta:**
   ```sql
   SELECT id, email, 
          hashedPassword IS NULL as sin_password,
          salt IS NULL as sin_salt,
          LENGTH(hashedPassword) as len_hash,
          LENGTH(salt) as len_salt
   FROM tc_users 
   WHERE email = 'admin' OR login = 'admin';
   ```

   Deberías ver:
   - `sin_password: 0` (false)
   - `sin_salt: 0` (false)
   - `len_hash: 48` (24 bytes = 48 caracteres hex)
   - `len_salt: 48` (24 bytes = 48 caracteres hex)

3. **Si los valores siguen siendo NULL, ejecuta el script nuevamente:**
   ```bash
   sudo bash scripts/fix-admin-user.sh
   ```

---

## 🔄 Paso 7: Reiniciar el Servicio (Opcional)

Si después de corregir el usuario aún hay problemas, reinicia el servicio:

```bash
# Reiniciar Traccar
sudo systemctl restart traccar

# Verificar que está corriendo
sudo systemctl status traccar

# Ver logs en tiempo real
sudo journalctl -u traccar -f
```

---

## 🐛 Solución de Problemas

### Error: "No se encontró mysql-connector-j-*.jar"

**Solución:**
```bash
# Compilar el proyecto
cd /opt/traccar-total
./gradlew build -x test
```

### Error: "No se pudo compilar"

**Solución:**
```bash
# Verificar que Java está instalado
java -version

# Si no está instalado, instalar Java 17
sudo apt update
sudo apt install openjdk-17-jdk -y
```

### Error: "Connection refused" o "Access denied"

**Solución:**
```bash
# Verificar que puedes conectarte a la base de datos
mysql -h 137.184.85.144 -P 4406 -u physeter -p traccar

# Si falla, verifica:
# 1. Que la IP y puerto son correctos
# 2. Que el usuario y password son correctos
# 3. Que el firewall permite la conexión
```

### Error: "Usuario no encontrado"

**Solución:**
El script creará el usuario automáticamente si no existe. Si quieres verificar manualmente:

```sql
SELECT * FROM tc_users WHERE email = 'admin' OR login = 'admin';
```

---

## 📝 Resumen de Comandos (Copy-Paste)

Si solo quieres ejecutar los comandos esenciales:

```bash
# 1. Ir al directorio
cd /opt/traccar-total

# 2. Actualizar código (si es necesario)
git pull origin main

# 3. Compilar (si es necesario)
./gradlew build -x test

# 4. Ejecutar script de corrección
sudo bash scripts/fix-admin-user.sh

# 5. Verificar que funciona
curl -X POST http://localhost:8082/api/session \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=admin&password=admin"
```

---

## ✅ Checklist Final

- [ ] Código actualizado desde git
- [ ] Java instalado y funcionando
- [ ] JAR de MySQL encontrado
- [ ] Script ejecutado exitosamente
- [ ] Login funciona correctamente
- [ ] Servicio Traccar corriendo

---

**Última actualización:** 2026-02-18

