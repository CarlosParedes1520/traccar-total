# 🔐 Posibles Errores de Login en Traccar

## 📋 Errores Comunes y Soluciones

### 1. **Usuario No Encontrado** (401 Unauthorized)

**Síntoma:**
- `POST /api/session` devuelve `401 Unauthorized`
- Logs muestran: `SELECT * FROM tc_users WHERE (email = ? OR login = ?)`
- No hay errores en los logs

**Causa:**
- El usuario no existe en la base de datos
- El email/login no coincide

**Solución:**
```bash
# Verificar si el usuario existe
./scripts/verificar-usuario-admin.sh

# Crear el usuario admin si no existe
./scripts/fix-admin-user.sh
```

---

### 2. **Password Incorrecto** (401 Unauthorized)

**Síntoma:**
- `POST /api/session` devuelve `401 Unauthorized`
- El usuario existe pero el password no coincide
- Logs muestran: `login failed from: [IP]`

**Causa:**
- El hash del password no coincide
- El salt está mal configurado
- El password fue cambiado manualmente en la BD

**Solución:**
```bash
# Recrear el password del usuario admin
./scripts/fix-admin-user.sh
```

---

### 3. **Usuario Deshabilitado** (SecurityException)

**Síntoma:**
- `POST /api/session` devuelve `401 Unauthorized`
- Error: `SecurityException: User account is disabled`
- El usuario existe y el password es correcto

**Causa:**
- El campo `disabled = 1` en la tabla `tc_users`

**Solución:**
```sql
-- Habilitar el usuario
UPDATE tc_users 
SET disabled = 0 
WHERE email = 'admin' OR login = 'admin';
```

O ejecuta:
```bash
mysql -h 137.184.85.144 -P 4406 -u physeter -p'Ph15eter$2025$R' traccar \
  -e "UPDATE tc_users SET disabled = 0 WHERE email = 'admin' OR login = 'admin';"
```

---

### 4. **TOTP Requerido** (401 Unauthorized con header TOTP)

**Síntoma:**
- `POST /api/session` devuelve `401 Unauthorized`
- Header de respuesta: `WWW-Authenticate: TOTP`
- El usuario tiene 2FA habilitado

**Causa:**
- El usuario tiene `totpKey` configurado
- No se está enviando el código TOTP

**Solución:**
```bash
# Deshabilitar TOTP para el usuario admin
mysql -h 137.184.85.144 -P 4406 -u physeter -p'Ph15eter$2025$R' traccar \
  -e "UPDATE tc_users SET totpKey = NULL WHERE email = 'admin' OR login = 'admin';"
```

---

### 5. **OpenID Forzado** (Login bloqueado)

**Síntoma:**
- `POST /api/session` devuelve `401 Unauthorized`
- El login siempre falla
- Configuración: `openid.force = true`

**Causa:**
- La configuración fuerza el uso de OpenID
- No se permite login con email/password

**Solución:**
Revisar `debug.xml` o `/opt/traccar/conf/traccar.xml`:
```xml
<!-- Comentar o eliminar esta línea si existe -->
<!-- <entry key='openid.force'>true</entry> -->
```

---

### 6. **LDAP Forzado** (Login bloqueado)

**Síntoma:**
- `POST /api/session` devuelve `401 Unauthorized`
- El login siempre falla
- Configuración: `ldap.force = true`

**Causa:**
- La configuración fuerza el uso de LDAP
- No se permite login con password local

**Solución:**
Revisar `debug.xml` o `/opt/traccar/conf/traccar.xml`:
```xml
<!-- Comentar o eliminar esta línea si existe -->
<!-- <entry key='ldap.force'>true</entry> -->
```

---

### 7. **Error de Conexión a Base de Datos**

**Síntoma:**
- `POST /api/session` devuelve `500 Internal Server Error`
- Logs muestran errores de conexión a MySQL
- `SQLException` o `ConnectionException`

**Causa:**
- La base de datos no está accesible
- Credenciales incorrectas
- Puerto bloqueado

**Solución:**
```bash
# Verificar conexión a la base de datos
mysql -h 137.184.85.144 -P 4406 -u physeter -p'Ph15eter$2025$R' traccar -e "SELECT 1;"

# Verificar configuración en debug.xml
grep -E "database.url|database.user|database.password" debug.xml
```

---

### 8. **Password Hash Inválido**

**Síntoma:**
- `POST /api/session` devuelve `401 Unauthorized`
- El usuario existe pero el password no funciona
- El hash o salt están corruptos

**Causa:**
- El `hashedPassword` o `salt` están vacíos o corruptos
- El formato del hash no es válido

**Solución:**
```bash
# Recrear el password correctamente
./scripts/fix-admin-user.sh
```

---

## 🔍 Cómo Diagnosticar

### Paso 1: Ejecutar diagnóstico
```bash
./scripts/diagnose-login-error.sh
```

### Paso 2: Verificar usuario en BD
```bash
./scripts/verificar-usuario-admin.sh
```

### Paso 3: Probar login con curl
```bash
curl -v -X POST http://localhost:8082/api/session \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: */*" \
  -H "Origin: http://localhost:8082" \
  -H "Referer: http://localhost:8082/login" \
  -d "email=admin&password=admin"
```

### Paso 4: Ver logs en tiempo real
```bash
journalctl -u traccar -f
```

---

## 📝 Flujo de Autenticación

```
1. POST /api/session (email, password)
   ↓
2. LoginService.login(email, password, code)
   ↓
3. Buscar usuario: SELECT * FROM tc_users WHERE (email = ? OR login = ?)
   ↓
4. Si usuario existe:
   - Verificar password: user.isPasswordValid(password)
   - Verificar TOTP (si está habilitado)
   - Verificar si está deshabilitado: user.checkDisabled()
   ↓
5. Si todo OK:
   - Crear sesión: SessionHelper.userLogin()
   - Devolver usuario: 200 OK
   ↓
6. Si algo falla:
   - actionLogger.failedLogin()
   - Devolver: 401 Unauthorized
```

---

## ✅ Checklist de Verificación

- [ ] El usuario existe en `tc_users`
- [ ] El campo `disabled = 0` (no está deshabilitado)
- [ ] El `hashedPassword` no está vacío
- [ ] El `salt` no está vacío
- [ ] El password coincide con el hash
- [ ] No hay `totpKey` configurado (o se envía el código)
- [ ] `openid.force` no está en `true`
- [ ] `ldap.force` no está en `true`
- [ ] La base de datos es accesible
- [ ] El servidor está corriendo en el puerto correcto (8082)

---

## 🛠️ Scripts Disponibles

1. **`scripts/diagnose-login-error.sh`** - Diagnóstico completo
2. **`scripts/verificar-usuario-admin.sh`** - Verificar usuario admin
3. **`scripts/fix-admin-user.sh`** - Corregir usuario admin
4. **`scripts/test-login.sh`** - Probar login

---

## 📚 Referencias

- **Código de login:** `src/main/java/org/traccar/api/resource/SessionResource.java`
- **Servicio de login:** `src/main/java/org/traccar/api/security/LoginService.java`
- **Modelo de usuario:** `src/main/java/org/traccar/model/User.java`

