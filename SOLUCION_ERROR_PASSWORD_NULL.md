# Solución: Error "Cannot invoke String.toCharArray() because data is null"

## 🔴 Problema

Al intentar hacer login con `admin` / `admin`, obtienes este error:

```
java.lang.NullPointerException: Cannot invoke "String.toCharArray()" because "data" is null
	at org.apache.commons.codec.binary.Hex.decodeHex(Hex.java:122)
	at org.traccar.helper.DataConverter.parseHex(DataConverter.java:29)
	at org.traccar.helper.Hashing.validatePassword(Hashing.java:82)
```

## 🔍 Causa

El usuario `admin` existe en la base de datos, pero su campo `hashedPassword` o `salt` es `NULL`. Cuando Traccar intenta validar el password, intenta parsear el `salt` como hexadecimal, pero como es `null`, falla.

## ✅ Solución

Ejecuta el script `fix-admin-user.sh` que corregirá el usuario admin:

### Opción 1: Ejecutar desde el servidor (Recomendado)

```bash
cd /opt/traccar-total
sudo bash scripts/fix-admin-user.sh
```

### Opción 2: Si no tienes el script, ejecuta directamente SQL

Conéctate a MySQL y ejecuta:

```sql
-- Verificar estado actual
SELECT id, email, login, administrator, disabled, 
       hashedPassword IS NULL as sin_password,
       salt IS NULL as sin_salt
FROM tc_users 
WHERE email = 'admin' OR login = 'admin';

-- Si el usuario existe pero tiene password NULL, necesitas usar el script Java
-- porque necesitas generar el hash correctamente con PBKDF2
```

**⚠️ IMPORTANTE:** No puedes simplemente insertar un hash manualmente. Debes usar el script Java que genera el hash correctamente con PBKDF2.

### Opción 3: Usar el script Java directamente

Si el script bash no funciona, puedes ejecutar el Java directamente:

```bash
# 1. Encontrar el JAR de MySQL
MYSQL_JAR=$(find /opt/traccar-total/target/lib -name "mysql-connector-j-*.jar" | head -n 1)
echo "MySQL JAR: $MYSQL_JAR"

# 2. Crear el script Java (copia el contenido de fix-admin-user.sh)
# 3. Compilar
javac -cp "$MYSQL_JAR" FixAdminUser.java

# 4. Ejecutar
java -cp ".:$MYSQL_JAR" FixAdminUser \
    "137.184.85.144" "4406" "traccar" "physeter" "Ph15eter\$2025\$R"
```

## 📋 Verificación

Después de ejecutar el script, verifica que funciona:

```bash
curl -X POST http://localhost:8082/api/session \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=admin&password=admin"
```

Deberías recibir un JSON con los datos del usuario, no un error.

## 🔧 Si el script no funciona

### Verificar que el usuario existe:

```sql
SELECT * FROM tc_users WHERE email = 'admin' OR login = 'admin';
```

### Verificar conexión a la base de datos:

```bash
mysql -h 137.184.85.144 -P 4406 -u physeter -p traccar
# Password: Ph15eter$2025$R
```

### Verificar que Java está instalado:

```bash
java -version
# Debe ser Java 17 o superior
```

### Verificar que el JAR de MySQL existe:

```bash
find /opt/traccar-total/target/lib -name "mysql-connector-j-*.jar"
find /opt/traccar/lib -name "mysql-connector-j-*.jar"
```

## 🎯 Solución Rápida (Si todo falla)

Si nada funciona, puedes eliminar y recrear el usuario admin:

```sql
-- ⚠️ CUIDADO: Esto eliminará el usuario admin
DELETE FROM tc_users WHERE email = 'admin' OR login = 'admin';
```

Luego ejecuta el script `fix-admin-user.sh` que creará un nuevo usuario admin con password correcto.

## 📝 Notas

- El password se hashea usando **PBKDF2** con 1000 iteraciones
- El salt es aleatorio y único para cada usuario
- No puedes simplemente copiar un hash de otro usuario
- El script genera un hash nuevo cada vez que se ejecuta (esto es normal y seguro)

---

**Última actualización:** 2026-02-18

