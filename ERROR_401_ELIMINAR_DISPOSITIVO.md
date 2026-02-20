# 🔒 Error 401 Unauthorized al Eliminar Dispositivo

## 📋 Problema

Al intentar eliminar un dispositivo, obtienes el error:
```
jakarta.ws.rs.WebApplicationException: HTTP 401 Unauthorized
at org.traccar.api.security.SecurityRequestFilter.filter(SecurityRequestFilter.java:122)
```

Esto significa que **la autenticación falló** al intentar eliminar el dispositivo.

---

## 🔍 Causas Posibles

### 1. **Sesión Expirada (Interfaz Web)**

Si estás usando la **interfaz web de Traccar** (navegador):

- La sesión puede haber expirado
- La cookie `JSESSIONID` puede haberse perdido
- El navegador puede no estar enviando la cookie correctamente

**Solución:**
1. Cierra sesión y vuelve a iniciar sesión
2. Verifica que las cookies estén habilitadas en tu navegador
3. Intenta en una ventana de incógnito para descartar problemas de caché

---

### 2. **Basic Auth Mal Formateado (API/Bruno)**

Si estás usando la **API directamente** o **Bruno**:

El header `Authorization` debe tener el formato correcto:
```
Authorization: Basic base64(email:password)
```

**Ejemplo correcto:**
- Email: `admin`
- Password: `admin`
- Header: `Authorization: Basic YWRtaW46YWRtaW4=`

**Verificación en Bruno:**
1. Asegúrate de que el request tenga `auth: basic` configurado
2. Verifica que `username: {{email}}` y `password: {{password}}` estén definidos
3. Verifica que las variables `{{email}}` y `{{password}}` tengan valores correctos

---

### 3. **Credenciales Incorrectas**

Verifica que las credenciales sean correctas:

```bash
# Probar login
curl -X POST http://localhost:8082/api/session \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=admin&password=admin"
```

Si esto falla, las credenciales son incorrectas.

---

## ✅ Soluciones

### Solución 1: Usar Basic Auth Correctamente (Recomendado para APIs)

**En Bruno:**
```bru
meta {
  name: Delete Device
  type: http
}

delete {
  url: {{baseUrl}}/devices/{{deviceId}}
  auth: basic
}

auth:basic {
  username: {{email}}
  password: {{password}}
}
```

**Con curl:**
```bash
curl -X DELETE http://localhost:8082/api/devices/1 \
  -u "admin:admin"
```

**Con JavaScript/Fetch:**
```javascript
const email = 'admin';
const password = 'admin';
const credentials = btoa(`${email}:${password}`);

fetch('http://localhost:8082/api/devices/1', {
  method: 'DELETE',
  headers: {
    'Authorization': `Basic ${credentials}`
  }
});
```

---

### Solución 2: Usar Sesión HTTP (Interfaz Web)

Si estás en la interfaz web:

1. **Asegúrate de estar logueado:**
   - Ve a `http://localhost:8082/login`
   - Inicia sesión con `admin` / `admin`

2. **Verifica que la cookie se esté enviando:**
   - Abre las DevTools (F12)
   - Ve a la pestaña "Network"
   - Intenta eliminar el dispositivo
   - Verifica que la petición incluya la cookie `JSESSIONID`

3. **Si la sesión expiró:**
   - Cierra sesión y vuelve a iniciar sesión
   - Intenta eliminar nuevamente

---

### Solución 3: Usar Token de Sesión

Si Basic Auth no funciona, puedes usar un token:

**Paso 1: Generar token**
```bash
curl -X POST http://localhost:8082/api/session/token \
  -u "admin:admin" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "expiration=2026-12-31T23:59:59Z"
```

**Paso 2: Usar el token**
```bash
TOKEN="tu_token_aqui"
curl -X DELETE "http://localhost:8082/api/devices/1?token=$TOKEN"
```

O con Bearer:
```bash
curl -X DELETE http://localhost:8082/api/devices/1 \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🔧 Verificación de Permisos

Aunque seas admin, verifica que tengas permisos:

**Verificar usuario actual:**
```bash
curl -u "admin:admin" http://localhost:8082/api/session
```

**Respuesta esperada:**
```json
{
  "id": 1,
  "name": "Admin",
  "email": "admin",
  "administrator": true,
  ...
}
```

Si `administrator: false`, no podrás eliminar dispositivos de otros usuarios.

---

## 🐛 Debugging

### Verificar qué está pasando:

1. **Ver logs de Traccar:**
```bash
tail -f logs/tracker-server.log | grep -i "unauthorized\|401\|authentication"
```

2. **Probar el endpoint de eliminación directamente:**
```bash
# Con Basic Auth
curl -v -X DELETE http://localhost:8082/api/devices/1 \
  -u "admin:admin"

# Verás en la respuesta si hay algún problema
```

3. **Verificar que el dispositivo existe:**
```bash
curl -u "admin:admin" http://localhost:8082/api/devices/1
```

---

## 📝 Notas Importantes

1. **El código fue corregido** en `SecurityRequestFilter.java` para manejar mejor el Basic Auth
2. **Recompila el proyecto** después del cambio:
   ```bash
   ./gradlew build
   java -jar target/tracker-server.jar debug.xml
   ```

3. **Si usas la interfaz web**, asegúrate de que:
   - Las cookies estén habilitadas
   - No estés en modo incógnito (a menos que hayas iniciado sesión ahí)
   - La sesión no haya expirado

4. **Si usas la API**, siempre usa Basic Auth o tokens, nunca dependas de cookies

---

## 🎯 Resumen

| Método | Formato | Cuándo Usar |
|--------|---------|-------------|
| **Basic Auth** | `Authorization: Basic base64(email:password)` | APIs, Bruno, scripts |
| **Session Cookie** | Cookie `JSESSIONID` | Interfaz web (navegador) |
| **Bearer Token** | `Authorization: Bearer token` | APIs de larga duración |

**Recomendación:** Para eliminar dispositivos desde scripts o APIs, usa **Basic Auth**. Es más simple y confiable.

---

**Última actualización:** 2025-01-15

