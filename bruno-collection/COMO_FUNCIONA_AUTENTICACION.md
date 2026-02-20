# 🔐 Cómo Funciona la Autenticación en Traccar

## 📋 Resumen Rápido

Traccar usa **DOS formas** de autenticación:
1. **Cookies de Sesión HTTP** (automático en navegador)
2. **Tokens** (para APIs y aplicaciones)

---

## 🔄 Flujo Completo de Autenticación

### **Opción 1: Login con Cookies (Navegador Web)**

```
1. POST /api/session
   Body: email=admin&password=admin
   
   → Respuesta: Usuario JSON
   → Cookie: JSESSIONID=xxxxx (automático)
   
2. GET /api/session
   → Envía automáticamente la cookie JSESSIONID
   → Respuesta: Usuario JSON (si la sesión es válida)
   
3. Todas las demás peticiones
   → Usan automáticamente la cookie JSESSIONID
   → No necesitas hacer nada más
```

**En el navegador:**
- Haces `POST /api/session` con email/password
- El servidor te devuelve una **cookie JSESSIONID**
- El navegador guarda la cookie automáticamente
- Todas las peticiones siguientes incluyen la cookie automáticamente
- **No necesitas hacer nada más**

---

### **Opción 2: Login con Token (APIs, Bruno, etc.)**

```
1. POST /api/session
   Body: email=admin&password=admin
   
   → Respuesta: Usuario JSON
   → Cookie: JSESSIONID=xxxxx (pero Bruno no la guarda)
   
2. POST /api/session/token
   → Debes estar autenticado (con cookie o basic auth)
   → Respuesta: "token_string_aqui"
   
3. GET /api/session?token=token_string_aqui
   → Usas el token como query parameter
   → Respuesta: Usuario JSON
   
4. O usar Basic Auth en todas las peticiones:
   → Username: admin
   → Password: admin
```

**En Bruno/APIs:**
- Bruno **NO guarda cookies automáticamente**
- Tienes 2 opciones:
  - **Opción A:** Usar Basic Auth en cada request
  - **Opción B:** Generar un token y usarlo

---

## 📝 Endpoints Explicados

### **1. POST /api/session** - Login
**¿Qué hace?**
- Valida email/password
- Crea una sesión HTTP
- Devuelve cookie `JSESSIONID`
- Devuelve datos del usuario

**¿Cuándo usarlo?**
- Al iniciar sesión
- Primera vez que te conectas

**Ejemplo:**
```http
POST /api/session
Content-Type: application/x-www-form-urlencoded

email=admin&password=admin
```

**Respuesta:**
```json
{
  "id": 9,
  "email": "admin",
  "name": "Administrator",
  "administrator": true,
  ...
}
```
**+ Cookie:** `JSESSIONID=xxxxx`

---

### **2. GET /api/session** - Verificar Sesión
**¿Qué hace?**
- Verifica si tienes una sesión activa
- Puede usar:
  - **Cookie JSESSIONID** (automático en navegador)
  - **Token como query param** (`?token=xxxxx`)
  - **Basic Auth** (username/password)

**¿Cuándo usarlo?**
- Para verificar si estás logueado
- Para obtener información del usuario actual
- Al recargar la página

**Ejemplo 1 (con cookie - navegador):**
```http
GET /api/session
Cookie: JSESSIONID=xxxxx
```

**Ejemplo 2 (con token):**
```http
GET /api/session?token=TU_TOKEN_AQUI
```

**Ejemplo 3 (con Basic Auth):**
```http
GET /api/session
Authorization: Basic YWRtaW46YWRtaW4=
```

**Respuesta:**
```json
{
  "id": 9,
  "email": "admin",
  ...
}
```

---

### **3. POST /api/session/token** - Generar Token
**¿Qué hace?**
- Genera un token de autenticación
- **Requiere estar autenticado primero** (cookie o basic auth)
- El token expira según la fecha que le pases

**¿Cuándo usarlo?**
- Cuando quieres usar tokens en lugar de cookies
- Para APIs que no soportan cookies
- Para autenticación de larga duración

**Ejemplo:**
```http
POST /api/session/token
Authorization: Basic YWRtaW46YWRtaW4=
Content-Type: application/x-www-form-urlencoded

expiration=2026-12-31T23:59:59Z
```

**Respuesta:**
```
"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Luego usas el token:**
```http
GET /api/session?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

### **4. DELETE /api/session** - Logout
**¿Qué hace?**
- Cierra la sesión
- Elimina la cookie
- Invalida el token (si usas uno)

**Ejemplo:**
```http
DELETE /api/session
Cookie: JSESSIONID=xxxxx
```

---

## 🎯 Cómo Usar en Bruno

### **Método 1: Basic Auth (MÁS FÁCIL) ⭐**

**Configuración:**
1. En cada request, usa Basic Auth
2. Username: `{{email}}` (admin)
3. Password: `{{password}}` (admin)

**Ventajas:**
- ✅ Simple
- ✅ No necesitas tokens
- ✅ Funciona en todos los endpoints

**Desventajas:**
- ❌ Tienes que poner credenciales en cada request

---

### **Método 2: Token (MÁS SEGURO)**

**Paso 1: Login**
```http
POST /api/session
Body: email=admin&password=admin
```

**Paso 2: Generar Token**
```http
POST /api/session/token
Authorization: Basic admin:admin
Body: expiration=2026-12-31T23:59:59Z
```

**Paso 3: Usar Token**
```http
GET /api/session?token=TU_TOKEN
```

**O usar Bearer Token:**
```http
GET /api/devices
Authorization: Bearer TU_TOKEN
```

**Ventajas:**
- ✅ Más seguro
- ✅ No expones credenciales en cada request
- ✅ Puedes revocar tokens

**Desventajas:**
- ❌ Más pasos
- ❌ Los tokens expiran

---

## 🔍 Diferencia entre Cookie y Token

| Característica | Cookie (JSESSIONID) | Token |
|---------------|---------------------|-------|
| **Dónde se guarda** | Navegador automáticamente | Tú lo guardas |
| **Cómo se envía** | Automático en cada request | Manual (query param o header) |
| **Duración** | Sesión del navegador | Hasta que expire |
| **Uso en navegador** | ✅ Perfecto | ⚠️ Posible pero manual |
| **Uso en API/Bruno** | ❌ No funciona bien | ✅ Perfecto |
| **Seguridad** | Media (CSRF) | Alta (Bearer) |

---

## 💡 Recomendación para Bruno

**Usa Basic Auth en todos los requests:**
- Es lo más simple
- Funciona inmediatamente
- No necesitas manejar tokens
- Bruno lo soporta nativamente

**Solo usa tokens si:**
- Necesitas compartir acceso sin dar credenciales
- Quieres tokens de larga duración
- Estás construyendo una API pública

---

## 📚 Ejemplos Prácticos

### Ejemplo 1: Login y usar Basic Auth
```bru
# 1. Login (opcional, solo para verificar)
POST /api/session
Body: email=admin&password=admin

# 2. Todos los demás requests con Basic Auth
GET /api/devices
Auth: Basic (admin:admin)

GET /api/users
Auth: Basic (admin:admin)
```

### Ejemplo 2: Login, generar token, usar token
```bru
# 1. Login
POST /api/session
Body: email=admin&password=admin

# 2. Generar token
POST /api/session/token
Auth: Basic (admin:admin)
Body: expiration=2026-12-31T23:59:59Z
# Guarda el token en una variable: {{token}}

# 3. Usar token
GET /api/session?token={{token}}
GET /api/devices?token={{token}}
```

---

## ❓ Preguntas Frecuentes

**P: ¿Por qué GET /session no funciona en Bruno?**
R: Porque Bruno no guarda cookies automáticamente. Usa Basic Auth o un token.

**P: ¿Necesito hacer login antes de cada request?**
R: No. Si usas Basic Auth, no necesitas hacer login. Si usas tokens, solo necesitas generar el token una vez.

**P: ¿El token expira?**
R: Sí, según la fecha que le pases al generarlo. Por defecto puede no expirar o expirar según configuración del servidor.

**P: ¿Puedo usar Basic Auth y Token al mismo tiempo?**
R: Sí, pero no es necesario. Elige uno.

---

## 🎯 Resumen Ultra Rápido

1. **POST /session** = Login (crea sesión)
2. **GET /session** = Verificar si estás logueado
3. **POST /session/token** = Generar token (después de login)
4. **DELETE /session** = Logout

**En Bruno:** Usa Basic Auth en todos los requests. Es lo más fácil.

