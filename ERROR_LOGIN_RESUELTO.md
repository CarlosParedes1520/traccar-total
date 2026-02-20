# ✅ Error de Login Resuelto

## 🔍 Problema Encontrado

**Error:** `NullPointerException` al intentar hacer login

```
java.lang.NullPointerException: Cannot invoke "String.toCharArray()" because "data" is null
	at org.apache.commons.codec.binary.Hex.decodeHex(Hex.java:122)
	at org.traccar.helper.DataConverter.parseHex(DataConverter.java:29)
	at org.traccar.helper.Hashing.validatePassword(Hashing.java:82)
	at org.traccar.model.User.isPasswordValid(User.java:304)
```

## 🎯 Causa Raíz

El usuario `admin` en la base de datos tenía:
- ❌ `hashedPassword = NULL` o vacío
- ❌ `salt = NULL` o vacío

Cuando el sistema intentaba validar el password, llamaba a:
```java
Hashing.validatePassword(password, hashedPassword, salt)
```

Pero como `hashedPassword` o `salt` eran `null`, el método `DataConverter.parseHex()` fallaba al intentar decodificar un valor `null`.

## ✅ Solución Aplicada

Se ejecutó el script `fix-admin-user.sh` que:

1. **Verificó** el usuario admin en la base de datos
2. **Detectó** que faltaba el password (`sin_password: true`)
3. **Generó** un nuevo hash y salt usando el algoritmo PBKDF2
4. **Actualizó** la base de datos con:
   - `hashedPassword`: Hash del password "admin"
   - `salt`: Salt aleatorio para el hash

## 📝 Resultado

```
Usuario encontrado:
  ID: 9
  Nombre: Mateo
  Email: admin
  Login: admin
  Administrador: true
  Deshabilitado: false
  Sin password: true  ← Problema detectado

Corrigiendo usuario...
✓ Usuario corregido exitosamente!

Credenciales:
  Email/Login: admin
  Password: admin
```

## 🔐 Cómo Funciona el Hash

El sistema usa **PBKDF2WithHmacSHA1**:
- **Iteraciones:** 1000
- **Salt size:** 24 bytes
- **Hash size:** 24 bytes
- **Algoritmo:** PBKDF2 con HMAC-SHA1

El password "admin" se convierte en:
- `hashedPassword`: String hexadecimal (48 caracteres)
- `salt`: String hexadecimal (48 caracteres)

## 🧪 Verificar que Funciona

```bash
# Probar login
curl -X POST http://localhost:8082/api/session \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=admin&password=admin"
```

**Respuesta esperada:** `200 OK` con datos del usuario en JSON

## 🛠️ Si Vuelve a Pasar

Si el error vuelve a ocurrir:

1. **Verificar el usuario:**
   ```bash
   ./scripts/verificar-usuario-admin.sh
   ```

2. **Corregir el usuario:**
   ```bash
   ./scripts/fix-admin-user.sh
   ```

3. **O manualmente en MySQL:**
   ```sql
   -- Verificar
   SELECT id, email, 
          CASE WHEN hashedPassword IS NULL OR hashedPassword = '' 
               THEN 'SIN PASSWORD' 
               ELSE 'OK' 
          END as status
   FROM tc_users 
   WHERE email = 'admin';
   
   -- Si está vacío, ejecutar el script fix-admin-user.sh
   ```

## 📚 Referencias

- **Código de hash:** `src/main/java/org/traccar/helper/Hashing.java`
- **Validación:** `src/main/java/org/traccar/model/User.java:303-305`
- **Script de corrección:** `scripts/fix-admin-user.sh`

