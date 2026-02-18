# 🔐 Guía Completa: Autenticación con Tokens en Traccar API

Esta guía explica cómo implementar todas las APIs de Traccar usando **tokens** en lugar de cookies, ideal para aplicaciones móviles, APIs REST, y aplicaciones que no soportan cookies.

---

## 📋 Tabla de Contenidos

1. [Conceptos Básicos](#conceptos-básicos)
2. [Flujo de Autenticación con Tokens](#flujo-de-autenticación-con-tokens)
3. [Generar y Usar Tokens](#generar-y-usar-tokens)
4. [Implementación en JavaScript/TypeScript](#implementación-en-javascripttypescript)
5. [Implementación en Python](#implementación-en-python)
6. [Todas las APIs con Tokens](#todas-las-apis-con-tokens)
7. [Gestión de Tokens](#gestión-de-tokens)
8. [Mejores Prácticas](#mejores-prácticas)
9. [Solución de Problemas](#solución-de-problemas)

---

## 🔑 Conceptos Básicos

### **¿Qué es un Token?**

Un token es una cadena de texto (JWT) que representa una sesión de usuario autenticado. A diferencia de las cookies:

- ✅ **Funciona en cualquier cliente** (móvil, API, etc.)
- ✅ **No depende del navegador**
- ✅ **Puede tener expiración personalizada**
- ✅ **Se puede revocar**
- ✅ **Más seguro para APIs**

### **Formas de Usar Tokens**

Traccar soporta tokens de **3 formas**:

1. **Bearer Token en Header** (Recomendado)
   ```http
   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

2. **Token en Query Parameter**
   ```http
   GET /api/session?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

3. **Token como Basic Auth** (No recomendado, pero funciona)
   ```http
   Authorization: Basic <token_base64>
   ```

---

## 🔄 Flujo de Autenticación con Tokens

### **Paso 1: Generar Token**

Para generar un token, primero necesitas autenticarte con credenciales:

```http
POST /api/session/token
Authorization: Basic base64(email:password)
Content-Type: application/x-www-form-urlencoded

expiration=2026-12-31T23:59:59Z
```

**Respuesta:**
```
"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjksImV4cGlyYXRpb24iOjE3MzU2ODc5OTl9..."
```

### **Paso 2: Usar Token en Peticiones**

Una vez que tienes el token, lo usas en todas las peticiones:

```http
GET /api/devices
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🚀 Generar y Usar Tokens

### **1. Generar Token (JavaScript/TypeScript)**

```typescript
const API_BASE_URL = 'http://localhost:8082/api';

interface TokenResponse {
  token: string;
  expiration: Date;
}

/**
 * Genera un token de autenticación
 * @param email Email del usuario
 * @param password Contraseña del usuario
 * @param expirationDate Fecha de expiración (opcional, por defecto 1 año)
 * @returns Token JWT
 */
async function generateToken(
  email: string,
  password: string,
  expirationDate?: Date
): Promise<string> {
  // Si no se especifica expiración, usar 1 año desde ahora
  const expiration = expirationDate || new Date();
  expiration.setFullYear(expiration.getFullYear() + 1);

  // Formatear fecha en formato ISO
  const expirationISO = expiration.toISOString();

  // Autenticarse con Basic Auth y generar token
  const response = await fetch(`${API_BASE_URL}/session/token`, {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + btoa(`${email}:${password}`),
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: `expiration=${encodeURIComponent(expirationISO)}`
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error al generar token: ${errorText}`);
  }

  // El token viene como texto plano
  const token = await response.text();
  return token.trim(); // Limpiar espacios en blanco
}

// Uso
const token = await generateToken('admin', 'admin');
console.log('Token generado:', token);
```

### **2. Usar Token en Peticiones**

```typescript
/**
 * Realiza una petición autenticada con token
 */
async function authenticatedRequest<T>(
  endpoint: string,
  token: string,
  options: RequestInit = {}
): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...options.headers
    }
  });

  if (!response.ok) {
    if (response.status === 401) {
      throw new Error('Token inválido o expirado');
    }
    const errorText = await response.text();
    throw new Error(`Error en petición: ${errorText}`);
  }

  // Si la respuesta está vacía (204 No Content)
  if (response.status === 204) {
    return null as T;
  }

  return await response.json();
}

// Ejemplo: Obtener dispositivos
async function getDevices(token: string) {
  return authenticatedRequest<Device[]>('/devices', token, {
    method: 'GET'
  });
}

// Ejemplo: Crear dispositivo
async function createDevice(token: string, deviceData: Partial<Device>) {
  return authenticatedRequest<Device>('/devices', token, {
    method: 'POST',
    body: JSON.stringify(deviceData)
  });
}
```

---

## 💻 Implementación en JavaScript/TypeScript

### **Clase Completa para Gestión de Tokens**

```typescript
class TraccarTokenClient {
  private baseUrl: string;
  private token: string | null = null;
  private tokenExpiration: Date | null = null;

  constructor(baseUrl: string = 'http://localhost:8082/api') {
    this.baseUrl = baseUrl;
  }

  /**
   * Genera un token de autenticación
   */
  async login(email: string, password: string, expirationDays: number = 365): Promise<string> {
    const expiration = new Date();
    expiration.setDate(expiration.getDate() + expirationDays);

    const response = await fetch(`${this.baseUrl}/session/token`, {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + btoa(`${email}:${password}`),
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: `expiration=${encodeURIComponent(expiration.toISOString())}`
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Error al generar token: ${errorText}`);
    }

    this.token = (await response.text()).trim();
    this.tokenExpiration = expiration;

    // Guardar token en localStorage (opcional)
    if (typeof window !== 'undefined') {
      localStorage.setItem('traccar_token', this.token);
      localStorage.setItem('traccar_token_expiration', expiration.toISOString());
    }

    return this.token;
  }

  /**
   * Carga token desde localStorage
   */
  loadTokenFromStorage(): boolean {
    if (typeof window === 'undefined') return false;

    const storedToken = localStorage.getItem('traccar_token');
    const storedExpiration = localStorage.getItem('traccar_token_expiration');

    if (storedToken && storedExpiration) {
      const expiration = new Date(storedExpiration);
      if (expiration > new Date()) {
        this.token = storedToken;
        this.tokenExpiration = expiration;
        return true;
      } else {
        // Token expirado, limpiar
        this.logout();
      }
    }

    return false;
  }

  /**
   * Verifica si el token es válido
   */
  async verifyToken(): Promise<boolean> {
    if (!this.token) return false;

    try {
      const user = await this.request<User>('/session?token=' + encodeURIComponent(this.token));
      return user !== null;
    } catch {
      return false;
    }
  }

  /**
   * Realiza una petición autenticada
   */
  async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    if (!this.token) {
      throw new Error('No hay token. Llama a login() primero.');
    }

    // Verificar si el token está expirado
    if (this.tokenExpiration && this.tokenExpiration <= new Date()) {
      throw new Error('Token expirado. Genera uno nuevo con login().');
    }

    const url = endpoint.startsWith('http') ? endpoint : `${this.baseUrl}${endpoint}`;
    
    const response = await fetch(url, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    });

    if (!response.ok) {
      if (response.status === 401) {
        // Token inválido, limpiar
        this.logout();
        throw new Error('Token inválido o expirado. Por favor, inicia sesión nuevamente.');
      }
      const errorText = await response.text();
      throw new Error(`Error en petición: ${errorText}`);
    }

    if (response.status === 204) {
      return null as T;
    }

    return await response.json();
  }

  /**
   * Cierra sesión y elimina el token
   */
  logout(): void {
    this.token = null;
    this.tokenExpiration = null;

    if (typeof window !== 'undefined') {
      localStorage.removeItem('traccar_token');
      localStorage.removeItem('traccar_token_expiration');
    }
  }

  /**
   * Obtiene el token actual
   */
  getToken(): string | null {
    return this.token;
  }

  // ========== MÉTODOS CONVENIENCIA PARA APIS ==========

  // Usuarios
  async getUsers(): Promise<User[]> {
    return this.request<User[]>('/users');
  }

  async getUser(userId: number): Promise<User> {
    return this.request<User>(`/users/${userId}`);
  }

  async createUser(userData: Partial<User>): Promise<User> {
    return this.request<User>('/users', {
      method: 'POST',
      body: JSON.stringify(userData)
    });
  }

  async updateUser(userId: number, userData: Partial<User>): Promise<User> {
    const current = await this.getUser(userId);
    return this.request<User>(`/users/${userId}`, {
      method: 'PUT',
      body: JSON.stringify({ ...current, ...userData, id: userId })
    });
  }

  async deleteUser(userId: number): Promise<void> {
    await this.request<void>(`/users/${userId}`, {
      method: 'DELETE'
    });
  }

  // Dispositivos
  async getDevices(): Promise<Device[]> {
    return this.request<Device[]>('/devices');
  }

  async getDevice(deviceId: number): Promise<Device> {
    return this.request<Device>(`/devices/${deviceId}`);
  }

  async createDevice(deviceData: Partial<Device>): Promise<Device> {
    return this.request<Device>('/devices', {
      method: 'POST',
      body: JSON.stringify(deviceData)
    });
  }

  async updateDevice(deviceId: number, deviceData: Partial<Device>): Promise<Device> {
    const current = await this.getDevice(deviceId);
    return this.request<Device>(`/devices/${deviceId}`, {
      method: 'PUT',
      body: JSON.stringify({ ...current, ...deviceData, id: deviceId })
    });
  }

  async deleteDevice(deviceId: number): Promise<void> {
    await this.request<void>(`/devices/${deviceId}`, {
      method: 'DELETE'
    });
  }

  // Posiciones
  async getPositions(deviceId?: number): Promise<Position[]> {
    const endpoint = deviceId ? `/positions?deviceId=${deviceId}` : '/positions';
    return this.request<Position[]>(endpoint);
  }

  // Permisos
  async assignDeviceToUser(userId: number, deviceId: number): Promise<void> {
    await this.request<void>('/permissions', {
      method: 'POST',
      body: JSON.stringify({ userId, deviceId })
    });
  }

  async removeDeviceFromUser(userId: number, deviceId: number): Promise<void> {
    await this.request<void>('/permissions', {
      method: 'DELETE',
      body: JSON.stringify({ userId, deviceId })
    });
  }

  // Subir imagen de dispositivo
  async uploadDeviceImage(deviceId: number, imageFile: File): Promise<string> {
    const formData = new FormData();
    formData.append('file', imageFile);

    const response = await fetch(`${this.baseUrl}/devices/${deviceId}/image`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`
        // No incluir Content-Type, el navegador lo hará automáticamente con FormData
      },
      body: formData
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Error al subir imagen: ${errorText}`);
    }

    return await response.text(); // Retorna el nombre del archivo
  }
}

// ========== USO ==========

// Crear instancia
const client = new TraccarTokenClient('http://localhost:8082/api');

// Opción 1: Login y usar
async function example1() {
  // Generar token
  await client.login('admin', 'admin');
  
  // Usar APIs
  const devices = await client.getDevices();
  console.log('Dispositivos:', devices);
  
  const users = await client.getUsers();
  console.log('Usuarios:', users);
}

// Opción 2: Cargar token guardado
async function example2() {
  // Intentar cargar token guardado
  if (client.loadTokenFromStorage()) {
    console.log('Token cargado desde localStorage');
  } else {
    // Si no hay token, generar uno nuevo
    await client.login('admin', 'admin');
  }
  
  // Verificar que el token es válido
  const isValid = await client.verifyToken();
  if (!isValid) {
    await client.login('admin', 'admin');
  }
  
  // Usar APIs
  const devices = await client.getDevices();
}

// Ejemplo completo: Crear usuario y asignar dispositivos
async function createUserWithDevices() {
  await client.login('admin', 'admin');
  
  // Crear usuario
  const user = await client.createUser({
    name: 'Nuevo Usuario',
    email: 'nuevo@example.com',
    password: 'password123',
    deviceLimit: 10
  });
  
  // Asignar dispositivos
  await client.assignDeviceToUser(user.id, 34);
  await client.assignDeviceToUser(user.id, 35);
  
  console.log(`Usuario ${user.name} creado con dispositivos asignados`);
}
```

---

## 🐍 Implementación en Python

```python
import requests
import json
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List

class TraccarTokenClient:
    def __init__(self, base_url: str = "http://localhost:8082/api"):
        self.base_url = base_url
        self.token: Optional[str] = None
        self.token_expiration: Optional[datetime] = None

    def login(self, email: str, password: str, expiration_days: int = 365) -> str:
        """Genera un token de autenticación"""
        expiration = datetime.now() + timedelta(days=expiration_days)
        
        response = requests.post(
            f"{self.base_url}/session/token",
            headers={
                "Authorization": f"Basic {self._base64_encode(f'{email}:{password}')}",
                "Content-Type": "application/x-www-form-urlencoded"
            },
            data=f"expiration={expiration.isoformat()}Z"
        )
        
        response.raise_for_status()
        self.token = response.text.strip()
        self.token_expiration = expiration
        return self.token

    def _base64_encode(self, text: str) -> str:
        import base64
        return base64.b64encode(text.encode()).decode()

    def _get_headers(self) -> Dict[str, str]:
        """Obtiene headers con autenticación"""
        if not self.token:
            raise ValueError("No hay token. Llama a login() primero.")
        
        if self.token_expiration and self.token_expiration <= datetime.now():
            raise ValueError("Token expirado. Genera uno nuevo con login().")
        
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

    def request(self, method: str, endpoint: str, **kwargs) -> Any:
        """Realiza una petición autenticada"""
        url = endpoint if endpoint.startswith("http") else f"{self.base_url}{endpoint}"
        headers = self._get_headers()
        headers.update(kwargs.pop("headers", {}))
        
        response = requests.request(method, url, headers=headers, **kwargs)
        
        if response.status_code == 401:
            self.token = None
            raise ValueError("Token inválido o expirado. Por favor, inicia sesión nuevamente.")
        
        response.raise_for_status()
        
        if response.status_code == 204:
            return None
        
        return response.json()

    def get(self, endpoint: str, **kwargs) -> Any:
        return self.request("GET", endpoint, **kwargs)

    def post(self, endpoint: str, data: Any = None, **kwargs) -> Any:
        if data:
            kwargs["json"] = data
        return self.request("POST", endpoint, **kwargs)

    def put(self, endpoint: str, data: Any = None, **kwargs) -> Any:
        if data:
            kwargs["json"] = data
        return self.request("PUT", endpoint, **kwargs)

    def delete(self, endpoint: str, **kwargs) -> Any:
        return self.request("DELETE", endpoint, **kwargs)

    # Métodos de conveniencia
    def get_users(self) -> List[Dict]:
        return self.get("/users")

    def get_user(self, user_id: int) -> Dict:
        return self.get(f"/users/{user_id}")

    def create_user(self, user_data: Dict) -> Dict:
        return self.post("/users", user_data)

    def update_user(self, user_id: int, user_data: Dict) -> Dict:
        current = self.get_user(user_id)
        current.update(user_data)
        current["id"] = user_id
        return self.put(f"/users/{user_id}", current)

    def delete_user(self, user_id: int) -> None:
        self.delete(f"/users/{user_id}")

    def get_devices(self) -> List[Dict]:
        return self.get("/devices")

    def get_device(self, device_id: int) -> Dict:
        return self.get(f"/devices/{device_id}")

    def create_device(self, device_data: Dict) -> Dict:
        return self.post("/devices", device_data)

    def update_device(self, device_id: int, device_data: Dict) -> Dict:
        current = self.get_device(device_id)
        current.update(device_data)
        current["id"] = device_id
        return self.put(f"/devices/{device_id}", current)

    def delete_device(self, device_id: int) -> None:
        self.delete(f"/devices/{device_id}")

    def get_positions(self, device_id: Optional[int] = None) -> List[Dict]:
        endpoint = f"/positions?deviceId={device_id}" if device_id else "/positions"
        return self.get(endpoint)

    def assign_device_to_user(self, user_id: int, device_id: int) -> None:
        self.post("/permissions", {"userId": user_id, "deviceId": device_id})

    def remove_device_from_user(self, user_id: int, device_id: int) -> None:
        self.delete("/permissions", {"userId": user_id, "deviceId": device_id})

# Uso
client = TraccarTokenClient("http://localhost:8082/api")

# Login
client.login("admin", "admin")

# Usar APIs
devices = client.get_devices()
users = client.get_users()

print(f"Dispositivos: {len(devices)}")
print(f"Usuarios: {len(users)}")
```

---

## 📡 Todas las APIs con Tokens

### **Endpoints que Requieren Autenticación**

Todos los endpoints de Traccar (excepto `POST /api/session` y `GET /api/session?token=...`) requieren autenticación. Aquí están organizados por categoría:

#### **1. Usuarios**

```typescript
// Listar usuarios
GET /api/users
Authorization: Bearer <token>

// Obtener usuario específico
GET /api/users/{id}
Authorization: Bearer <token>

// Crear usuario
POST /api/users
Authorization: Bearer <token>
Content-Type: application/json
Body: { "name": "...", "email": "...", ... }

// Actualizar usuario
PUT /api/users/{id}
Authorization: Bearer <token>
Content-Type: application/json
Body: { "id": id, ... }

// Eliminar usuario
DELETE /api/users/{id}
Authorization: Bearer <token>
```

#### **2. Dispositivos**

```typescript
// Listar dispositivos
GET /api/devices
Authorization: Bearer <token>

// Obtener dispositivo específico
GET /api/devices/{id}
Authorization: Bearer <token>

// Crear dispositivo
POST /api/devices
Authorization: Bearer <token>
Content-Type: application/json
Body: { "name": "...", "uniqueId": "...", ... }

// Actualizar dispositivo
PUT /api/devices/{id}
Authorization: Bearer <token>
Content-Type: application/json
Body: { "id": id, ... }

// Eliminar dispositivo
DELETE /api/devices/{id}
Authorization: Bearer <token>

// Subir imagen del dispositivo
POST /api/devices/{id}/image
Authorization: Bearer <token>
Content-Type: image/jpeg
Body: <binary image data>
```

#### **3. Posiciones**

```typescript
// Obtener posiciones
GET /api/positions?deviceId={id}
Authorization: Bearer <token>
```

#### **4. Permisos**

```typescript
// Asignar dispositivo a usuario
POST /api/permissions
Authorization: Bearer <token>
Content-Type: application/json
Body: { "userId": 5, "deviceId": 34 }

// Asignar múltiples permisos
POST /api/permissions/bulk
Authorization: Bearer <token>
Content-Type: application/json
Body: [{ "userId": 5, "deviceId": 34 }, ...]

// Remover permiso
DELETE /api/permissions
Authorization: Bearer <token>
Content-Type: application/json
Body: { "userId": 5, "deviceId": 34 }

// Remover múltiples permisos
DELETE /api/permissions/bulk
Authorization: Bearer <token>
Content-Type: application/json
Body: [{ "userId": 5, "deviceId": 34 }, ...]
```

#### **5. Sesión (con tokens)**

```typescript
// Verificar sesión con token (query param)
GET /api/session?token=<token>
// No requiere Authorization header

// Verificar sesión con token (Bearer)
GET /api/session
Authorization: Bearer <token>

// Generar token (requiere Basic Auth primero)
POST /api/session/token
Authorization: Basic base64(email:password)
Content-Type: application/x-www-form-urlencoded
Body: expiration=2026-12-31T23:59:59Z

// Revocar token
POST /api/session/token/revoke
Authorization: Bearer <token>
Content-Type: application/x-www-form-urlencoded
Body: token=<token_to_revoke>

// Logout (opcional, no afecta tokens)
DELETE /api/session
Authorization: Bearer <token>
```

---

## 🔧 Gestión de Tokens

### **1. Verificar si Token es Válido**

```typescript
async function isTokenValid(token: string): Promise<boolean> {
  try {
    const response = await fetch(`${API_BASE_URL}/session?token=${encodeURIComponent(token)}`);
    return response.ok;
  } catch {
    return false;
  }
}
```

### **2. Refrescar Token**

```typescript
async function refreshToken(
  email: string,
  password: string,
  currentToken: string
): Promise<string> {
  // Primero verificar si el token actual es válido
  const isValid = await isTokenValid(currentToken);
  
  if (isValid) {
    return currentToken; // No es necesario refrescar
  }
  
  // Si no es válido, generar uno nuevo
  return await generateToken(email, password);
}
```

### **3. Revocar Token**

```typescript
async function revokeToken(token: string): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/session/token/revoke`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: `token=${encodeURIComponent(token)}`
  });

  if (!response.ok) {
    throw new Error('Error al revocar token');
  }
}
```

### **4. Guardar y Cargar Token**

```typescript
// Guardar token
function saveToken(token: string, expiration: Date): void {
  localStorage.setItem('traccar_token', token);
  localStorage.setItem('traccar_token_expiration', expiration.toISOString());
}

// Cargar token
function loadToken(): string | null {
  const token = localStorage.getItem('traccar_token');
  const expirationStr = localStorage.getItem('traccar_token_expiration');
  
  if (token && expirationStr) {
    const expiration = new Date(expirationStr);
    if (expiration > new Date()) {
      return token;
    } else {
      // Token expirado, limpiar
      localStorage.removeItem('traccar_token');
      localStorage.removeItem('traccar_token_expiration');
    }
  }
  
  return null;
}
```

---

## ✅ Mejores Prácticas

### **1. Manejo de Errores 401**

```typescript
async function requestWithTokenRefresh<T>(
  endpoint: string,
  token: string,
  email: string,
  password: string,
  options: RequestInit = {}
): Promise<T> {
  try {
    return await authenticatedRequest<T>(endpoint, token, options);
  } catch (error: any) {
    if (error.message.includes('401') || error.message.includes('Token inválido')) {
      // Token expirado, generar uno nuevo
      const newToken = await generateToken(email, password);
      // Reintentar con nuevo token
      return await authenticatedRequest<T>(endpoint, newToken, options);
    }
    throw error;
  }
}
```

### **2. Interceptor para Axios**

```typescript
import axios from 'axios';

// Crear instancia de axios
const apiClient = axios.create({
  baseURL: 'http://localhost:8082/api'
});

// Interceptor para agregar token
apiClient.interceptors.request.use((config) => {
  const token = loadToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Interceptor para manejar errores 401
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expirado, generar uno nuevo
      const newToken = await generateToken('admin', 'admin');
      saveToken(newToken, new Date(Date.now() + 365 * 24 * 60 * 60 * 1000));
      
      // Reintentar petición original
      error.config.headers.Authorization = `Bearer ${newToken}`;
      return apiClient.request(error.config);
    }
    return Promise.reject(error);
  }
);
```

### **3. React Hook para Tokens**

```typescript
import { useState, useEffect, useCallback } from 'react';

function useTraccarToken(email: string, password: string) {
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const login = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const newToken = await generateToken(email, password);
      setToken(newToken);
      saveToken(newToken, new Date(Date.now() + 365 * 24 * 60 * 60 * 1000));
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [email, password]);

  useEffect(() => {
    // Intentar cargar token guardado
    const savedToken = loadToken();
    if (savedToken) {
      setToken(savedToken);
    } else {
      // Si no hay token, generar uno
      login();
    }
  }, [login]);

  return { token, loading, error, login, logout: () => setToken(null) };
}

// Uso en componente
function MyComponent() {
  const { token, loading, error } = useTraccarToken('admin', 'admin');

  if (loading) return <div>Cargando...</div>;
  if (error) return <div>Error: {error}</div>;
  if (!token) return <div>No hay token</div>;

  // Usar token en peticiones
  // ...
}
```

---

## 🔍 Solución de Problemas

### **Error: "Token inválido o expirado"**

**Causa:** El token ha expirado o fue revocado.

**Solución:**
```typescript
// Verificar y regenerar token
const isValid = await isTokenValid(token);
if (!isValid) {
  token = await generateToken(email, password);
}
```

### **Error: "401 Unauthorized"**

**Causa:** El token no se está enviando correctamente.

**Solución:**
```typescript
// Verificar que el header esté correcto
headers: {
  'Authorization': `Bearer ${token}`  // Nota: "Bearer" con espacio
}
```

### **Error: "Token has expired"**

**Causa:** El token llegó a su fecha de expiración.

**Solución:**
```typescript
// Generar token con expiración más larga
const expiration = new Date();
expiration.setFullYear(expiration.getFullYear() + 2); // 2 años
const token = await generateToken(email, password, expiration);
```

### **Error al Generar Token: "401 Unauthorized"**

**Causa:** Las credenciales son incorrectas.

**Solución:**
```typescript
// Verificar credenciales primero
const testResponse = await fetch(`${API_BASE_URL}/session`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: `email=${email}&password=${password}`
});

if (!testResponse.ok) {
  throw new Error('Credenciales incorrectas');
}
```

---

## 📋 Resumen de Endpoints de Autenticación

| Endpoint | Método | Autenticación | Descripción |
|----------|--------|---------------|-------------|
| `/api/session` | `POST` | None | Login con email/password (crea cookie) |
| `/api/session?token=...` | `GET` | Token (query) | Verificar sesión con token |
| `/api/session` | `GET` | Bearer Token | Verificar sesión con token |
| `/api/session/token` | `POST` | Basic Auth | Generar token |
| `/api/session/token/revoke` | `POST` | Bearer Token | Revocar token |
| `/api/session` | `DELETE` | Bearer Token | Logout (opcional) |

---

## 🎯 Checklist de Implementación

- [ ] Generar token con `POST /api/session/token`
- [ ] Guardar token de forma segura (localStorage, secure storage, etc.)
- [ ] Incluir token en header `Authorization: Bearer <token>`
- [ ] Manejar errores 401 (token expirado)
- [ ] Implementar refresh de token cuando sea necesario
- [ ] Verificar expiración del token antes de usarlo
- [ ] Revocar token cuando el usuario cierra sesión

---

## 🔄 Flujo Completo: Crear Usuario y Enlazar a Dispositivos con Tokens

Esta sección explica paso a paso cómo crear un usuario y asignarle dispositivos usando **únicamente tokens** (sin cookies).

---

### **📋 Flujo Paso a Paso**

```
1. Generar Token (Admin)
   ↓
2. Crear Usuario (con token)
   ↓
3. Obtener Dispositivos Disponibles (con token)
   ↓
4. Asignar Dispositivos al Usuario (con token)
   ↓
5. Verificar Asignación (con token)
```

---

### **💻 Implementación Completa en JavaScript/TypeScript**

```typescript
/**
 * Flujo completo: Crear usuario y asignar dispositivos usando tokens
 */
async function createUserAndAssignDevices(
  adminEmail: string,
  adminPassword: string,
  newUserData: {
    name: string;
    email: string;
    password: string;
    deviceLimit?: number;
  },
  deviceIds: number[]
): Promise<{
  user: User;
  assignedDevices: Device[];
}> {
  console.log('🚀 Iniciando flujo de creación de usuario con tokens...\n');

  // ========== PASO 1: Generar Token de Admin ==========
  console.log('📝 Paso 1: Generando token de administrador...');
  
  const adminToken = await generateToken(adminEmail, adminPassword);
  console.log('✅ Token de admin generado:', adminToken.substring(0, 20) + '...\n');

  // ========== PASO 2: Crear Usuario ==========
  console.log('👤 Paso 2: Creando nuevo usuario...');
  
  const newUser = await authenticatedRequest<User>(
    '/users',
    adminToken,
    {
      method: 'POST',
      body: JSON.stringify({
        name: newUserData.name,
        email: newUserData.email,
        password: newUserData.password,
        readonly: false,
        administrator: false,
        disabled: false,
        deviceLimit: newUserData.deviceLimit ?? -1, // -1 = ilimitado
        userLimit: 0,
        deviceReadonly: false,
        limitCommands: false,
        disableReports: false,
        fixedEmail: false,
        attributes: {}
      })
    }
  );
  
  console.log(`✅ Usuario creado: ${newUser.name} (ID: ${newUser.id})\n`);

  // ========== PASO 3: Obtener Dispositivos Disponibles ==========
  console.log('📱 Paso 3: Obteniendo dispositivos disponibles...');
  
  const allDevices = await authenticatedRequest<Device[]>(
    '/devices',
    adminToken,
    { method: 'GET' }
  );
  
  console.log(`✅ Encontrados ${allDevices.length} dispositivos\n`);

  // ========== PASO 4: Asignar Dispositivos al Usuario ==========
  console.log(`🔗 Paso 4: Asignando ${deviceIds.length} dispositivos al usuario...`);
  
  // Verificar que los dispositivos existen
  const devicesToAssign = allDevices.filter(d => deviceIds.includes(d.id));
  
  if (devicesToAssign.length !== deviceIds.length) {
    const missingIds = deviceIds.filter(id => !devicesToAssign.some(d => d.id === id));
    throw new Error(`Algunos dispositivos no existen: ${missingIds.join(', ')}`);
  }

  // Asignar dispositivos en lote (más eficiente)
  const permissions = deviceIds.map(deviceId => ({
    userId: newUser.id,
    deviceId: deviceId
  }));

  await authenticatedRequest<void>(
    '/permissions/bulk',
    adminToken,
    {
      method: 'POST',
      body: JSON.stringify(permissions)
    }
  );
  
  console.log(`✅ ${deviceIds.length} dispositivos asignados correctamente\n`);

  // ========== PASO 5: Verificar Asignación ==========
  console.log('✅ Paso 5: Verificando asignación...');
  
  // Obtener usuarios que tienen acceso a cada dispositivo
  const verificationPromises = deviceIds.map(async (deviceId) => {
    const users = await authenticatedRequest<User[]>(
      `/users?deviceId=${deviceId}`,
      adminToken,
      { method: 'GET' }
    );
    return users.some(u => u.id === newUser.id);
  });

  const verifications = await Promise.all(verificationPromises);
  const allAssigned = verifications.every(v => v === true);
  
  if (allAssigned) {
    console.log('✅ Todos los dispositivos están correctamente asignados\n');
  } else {
    console.warn('⚠️ Algunos dispositivos no se asignaron correctamente\n');
  }

  // Obtener dispositivos asignados
  const assignedDevices = devicesToAssign;

  return {
    user: newUser,
    assignedDevices: assignedDevices
  };
}

// ========== USO ==========

async function ejemplo() {
  try {
    const resultado = await createUserAndAssignDevices(
      'admin',           // Email de admin
      'admin',           // Password de admin
      {
        name: 'Juan Pérez',
        email: 'juan@example.com',
        password: 'password123',
        deviceLimit: 10  // Máximo 10 dispositivos
      },
      [34, 35, 36]      // IDs de dispositivos a asignar
    );

    console.log('🎉 Proceso completado exitosamente:');
    console.log(`   Usuario: ${resultado.user.name} (${resultado.user.email})`);
    console.log(`   Dispositivos asignados: ${resultado.assignedDevices.length}`);
    resultado.assignedDevices.forEach(device => {
      console.log(`   - ${device.name} (${device.uniqueId})`);
    });
  } catch (error: any) {
    console.error('❌ Error:', error.message);
  }
}
```

---

### **🐍 Implementación en Python**

```python
async def create_user_and_assign_devices(
    admin_email: str,
    admin_password: str,
    new_user_data: dict,
    device_ids: list[int]
) -> dict:
    """Flujo completo: Crear usuario y asignar dispositivos usando tokens"""
    
    print('🚀 Iniciando flujo de creación de usuario con tokens...\n')
    
    # Paso 1: Generar token de admin
    print('📝 Paso 1: Generando token de administrador...')
    client = TraccarTokenClient()
    admin_token = await client.login(admin_email, admin_password)
    print(f'✅ Token de admin generado: {admin_token[:20]}...\n')
    
    # Paso 2: Crear usuario
    print('👤 Paso 2: Creando nuevo usuario...')
    new_user = await client.create_user({
        "name": new_user_data["name"],
        "email": new_user_data["email"],
        "password": new_user_data["password"],
        "readonly": False,
        "administrator": False,
        "disabled": False,
        "deviceLimit": new_user_data.get("deviceLimit", -1),
        "userLimit": 0,
        "deviceReadonly": False,
        "limitCommands": False,
        "disableReports": False,
        "fixedEmail": False,
        "attributes": {}
    })
    print(f'✅ Usuario creado: {new_user["name"]} (ID: {new_user["id"]})\n')
    
    # Paso 3: Obtener dispositivos
    print('📱 Paso 3: Obteniendo dispositivos disponibles...')
    all_devices = await client.get_devices()
    print(f'✅ Encontrados {len(all_devices)} dispositivos\n')
    
    # Paso 4: Asignar dispositivos
    print(f'🔗 Paso 4: Asignando {len(device_ids)} dispositivos al usuario...')
    
    # Verificar que los dispositivos existen
    devices_to_assign = [d for d in all_devices if d["id"] in device_ids]
    
    if len(devices_to_assign) != len(device_ids):
        missing_ids = [id for id in device_ids if not any(d["id"] == id for d in devices_to_assign)]
        raise ValueError(f"Algunos dispositivos no existen: {missing_ids}")
    
    # Asignar en lote
    permissions = [{"userId": new_user["id"], "deviceId": device_id} for device_id in device_ids]
    await client.post("/permissions/bulk", permissions)
    print(f'✅ {len(device_ids)} dispositivos asignados correctamente\n')
    
    # Paso 5: Verificar
    print('✅ Paso 5: Verificando asignación...')
    for device_id in device_ids:
        users = await client.get(f"/users?deviceId={device_id}")
        if not any(u["id"] == new_user["id"] for u in users):
            print(f'⚠️ Dispositivo {device_id} no asignado correctamente')
    print('✅ Verificación completada\n')
    
    return {
        "user": new_user,
        "assigned_devices": devices_to_assign
    }

# Uso
resultado = await create_user_and_assign_devices(
    "admin",
    "admin",
    {
        "name": "Juan Pérez",
        "email": "juan@example.com",
        "password": "password123",
        "deviceLimit": 10
    },
    [34, 35, 36]
)
```

---

### **📝 Ejemplo Detallado con Manejo de Errores**

```typescript
/**
 * Versión mejorada con manejo completo de errores y validaciones
 */
class UserDeviceManager {
  private adminToken: string | null = null;
  private baseUrl: string;

  constructor(baseUrl: string = 'http://localhost:8082/api') {
    this.baseUrl = baseUrl;
  }

  /**
   * Paso 1: Autenticar como administrador
   */
  async authenticateAdmin(email: string, password: string): Promise<void> {
    console.log('🔐 Autenticando como administrador...');
    
    try {
      this.adminToken = await generateToken(email, password);
      console.log('✅ Autenticación exitosa\n');
    } catch (error: any) {
      throw new Error(`Error al autenticar: ${error.message}`);
    }
  }

  /**
   * Paso 2: Crear usuario
   */
  async createUser(userData: {
    name: string;
    email: string;
    password: string;
    deviceLimit?: number;
    readonly?: boolean;
  }): Promise<User> {
    if (!this.adminToken) {
      throw new Error('Debes autenticarte primero con authenticateAdmin()');
    }

    console.log(`👤 Creando usuario: ${userData.name}...`);

    // Validar que el email no exista
    const existingUsers = await authenticatedRequest<User[]>(
      '/users',
      this.adminToken,
      { method: 'GET' }
    );

    const emailExists = existingUsers.some(u => u.email === userData.email);
    if (emailExists) {
      throw new Error(`El email ${userData.email} ya está en uso`);
    }

    const newUser = await authenticatedRequest<User>(
      '/users',
      this.adminToken,
      {
        method: 'POST',
        body: JSON.stringify({
          name: userData.name,
          email: userData.email,
          password: userData.password,
          readonly: userData.readonly ?? false,
          administrator: false,
          disabled: false,
          deviceLimit: userData.deviceLimit ?? -1,
          userLimit: 0,
          deviceReadonly: false,
          limitCommands: false,
          disableReports: false,
          fixedEmail: false,
          attributes: {}
        })
      }
    );

    console.log(`✅ Usuario creado: ${newUser.name} (ID: ${newUser.id})\n`);
    return newUser;
  }

  /**
   * Paso 3: Obtener dispositivos disponibles
   */
  async getAvailableDevices(): Promise<Device[]> {
    if (!this.adminToken) {
      throw new Error('Debes autenticarte primero');
    }

    console.log('📱 Obteniendo dispositivos disponibles...');
    
    const devices = await authenticatedRequest<Device[]>(
      '/devices',
      this.adminToken,
      { method: 'GET' }
    );

    console.log(`✅ Encontrados ${devices.length} dispositivos\n`);
    return devices;
  }

  /**
   * Paso 4: Asignar dispositivos a usuario
   */
  async assignDevicesToUser(
    userId: number,
    deviceIds: number[]
  ): Promise<Device[]> {
    if (!this.adminToken) {
      throw new Error('Debes autenticarte primero');
    }

    if (deviceIds.length === 0) {
      console.log('⚠️ No hay dispositivos para asignar\n');
      return [];
    }

    console.log(`🔗 Asignando ${deviceIds.length} dispositivos al usuario ${userId}...`);

    // Verificar que los dispositivos existen
    const allDevices = await this.getAvailableDevices();
    const devicesToAssign = allDevices.filter(d => deviceIds.includes(d.id));

    if (devicesToAssign.length !== deviceIds.length) {
      const missingIds = deviceIds.filter(id => !devicesToAssign.some(d => d.id === id));
      throw new Error(`Dispositivos no encontrados: ${missingIds.join(', ')}`);
    }

    // Verificar límite de dispositivos del usuario
    const user = await authenticatedRequest<User>(
      `/users/${userId}`,
      this.adminToken,
      { method: 'GET' }
    );

    if (user.deviceLimit > 0) {
      // Obtener dispositivos ya asignados
      const usersWithDevices = await Promise.all(
        deviceIds.map(deviceId =>
          authenticatedRequest<User[]>(
            `/users?deviceId=${deviceId}`,
            this.adminToken,
            { method: 'GET' }
          )
        )
      );

      const currentDeviceCount = usersWithDevices.flat()
        .filter(u => u.id === userId).length;

      if (currentDeviceCount + deviceIds.length > user.deviceLimit) {
        throw new Error(
          `El usuario tiene límite de ${user.deviceLimit} dispositivos. ` +
          `Ya tiene ${currentDeviceCount} y se intentan asignar ${deviceIds.length} más.`
        );
      }
    }

    // Asignar dispositivos
    const permissions = deviceIds.map(deviceId => ({
      userId: userId,
      deviceId: deviceId
    }));

    await authenticatedRequest<void>(
      '/permissions/bulk',
      this.adminToken,
      {
        method: 'POST',
        body: JSON.stringify(permissions)
      }
    );

    console.log(`✅ ${deviceIds.length} dispositivos asignados correctamente\n`);
    return devicesToAssign;
  }

  /**
   * Paso 5: Verificar asignación
   */
  async verifyAssignment(userId: number, deviceIds: number[]): Promise<boolean> {
    if (!this.adminToken) {
      throw new Error('Debes autenticarte primero');
    }

    console.log('✅ Verificando asignación...');

    const verifications = await Promise.all(
      deviceIds.map(async (deviceId) => {
        const users = await authenticatedRequest<User[]>(
          `/users?deviceId=${deviceId}`,
          this.adminToken,
          { method: 'GET' }
        );
        return users.some(u => u.id === userId);
      })
    );

    const allAssigned = verifications.every(v => v === true);
    
    if (allAssigned) {
      console.log('✅ Todos los dispositivos están correctamente asignados\n');
    } else {
      const failedDevices = deviceIds.filter((_, i) => !verifications[i]);
      console.warn(`⚠️ Algunos dispositivos no se asignaron: ${failedDevices.join(', ')}\n`);
    }

    return allAssigned;
  }

  /**
   * Flujo completo: Crear usuario y asignar dispositivos
   */
  async createUserAndAssignDevices(
    userData: {
      name: string;
      email: string;
      password: string;
      deviceLimit?: number;
    },
    deviceIds: number[]
  ): Promise<{
    user: User;
    assignedDevices: Device[];
  }> {
    console.log('🚀 Iniciando flujo completo...\n');

    // Paso 1: Ya autenticado (se asume que se llamó authenticateAdmin antes)

    // Paso 2: Crear usuario
    const user = await this.createUser(userData);

    // Paso 3 y 4: Asignar dispositivos
    const assignedDevices = await this.assignDevicesToUser(user.id, deviceIds);

    // Paso 5: Verificar
    await this.verifyAssignment(user.id, deviceIds);

    return {
      user,
      assignedDevices
    };
  }
}

// ========== USO COMPLETO ==========

async function ejemploCompleto() {
  const manager = new UserDeviceManager('http://localhost:8082/api');

  try {
    // Autenticar como admin
    await manager.authenticateAdmin('admin', 'admin');

    // Crear usuario y asignar dispositivos
    const resultado = await manager.createUserAndAssignDevices(
      {
        name: 'María García',
        email: 'maria@example.com',
        password: 'password123',
        deviceLimit: 5
      },
      [34, 35, 36]
    );

    console.log('🎉 Proceso completado:');
    console.log(`   Usuario: ${resultado.user.name}`);
    console.log(`   Email: ${resultado.user.email}`);
    console.log(`   Dispositivos asignados: ${resultado.assignedDevices.length}`);
    resultado.assignedDevices.forEach(device => {
      console.log(`   - ${device.name} (IMEI: ${device.uniqueId})`);
    });
  } catch (error: any) {
    console.error('❌ Error:', error.message);
  }
}
```

---

### **🔄 Flujo Visual con Tokens**

```
┌─────────────────────────────────────────────────────────┐
│ 1. GENERAR TOKEN (Admin)                                 │
│                                                           │
│ POST /api/session/token                                   │
│ Authorization: Basic base64(admin:admin)                │
│ Body: expiration=2026-12-31T23:59:59Z                   │
│                                                           │
│ → Token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."       │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ 2. CREAR USUARIO                                         │
│                                                           │
│ POST /api/users                                           │
│ Authorization: Bearer <token>                            │
│ Body: {                                                  │
│   "name": "Juan Pérez",                                   │
│   "email": "juan@example.com",                           │
│   "password": "password123",                             │
│   "deviceLimit": 10                                       │
│ }                                                         │
│                                                           │
│ → Usuario: { "id": 5, "name": "Juan Pérez", ... }       │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ 3. OBTENER DISPOSITIVOS                                  │
│                                                           │
│ GET /api/devices                                          │
│ Authorization: Bearer <token>                             │
│                                                           │
│ → Dispositivos: [{ "id": 34, ... }, { "id": 35, ... }]  │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ 4. ASIGNAR DISPOSITIVOS                                 │
│                                                           │
│ POST /api/permissions/bulk                                │
│ Authorization: Bearer <token>                            │
│ Body: [                                                  │
│   { "userId": 5, "deviceId": 34 },                       │
│   { "userId": 5, "deviceId": 35 },                       │
│   { "userId": 5, "deviceId": 36 }                        │
│ ]                                                         │
│                                                           │
│ → HTTP 204 No Content (éxito)                            │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ 5. VERIFICAR ASIGNACIÓN                                  │
│                                                           │
│ GET /api/users?deviceId=34                                │
│ Authorization: Bearer <token>                             │
│                                                           │
│ → Usuarios: [{ "id": 5, "name": "Juan Pérez", ... }]     │
│   (Confirma que el usuario tiene acceso)                  │
└─────────────────────────────────────────────────────────┘
```

---

### **✅ Checklist del Flujo**

- [ ] **Paso 1:** Generar token de administrador con `POST /api/session/token`
- [ ] **Paso 2:** Crear usuario con `POST /api/users` usando el token
- [ ] **Paso 3:** Obtener dispositivos disponibles con `GET /api/devices`
- [ ] **Paso 4:** Asignar dispositivos con `POST /api/permissions/bulk`
- [ ] **Paso 5:** Verificar asignación con `GET /api/users?deviceId={id}`
- [ ] **Validaciones:** Verificar que dispositivos existen y respetar límites
- [ ] **Manejo de errores:** Capturar y manejar errores 401 (token expirado)

---

### **🔑 Puntos Clave**

1. **Solo necesitas el token una vez:** Genera el token al inicio y úsalo en todas las peticiones
2. **No necesitas cookies:** Todo funciona con el header `Authorization: Bearer <token>`
3. **El token es reutilizable:** Puedes usar el mismo token para múltiples operaciones
4. **Maneja la expiración:** Si recibes 401, regenera el token
5. **Asignación en lote:** Usa `/permissions/bulk` para asignar múltiples dispositivos de una vez

---

## 📸 Gestión de Imágenes de Dispositivos con Tokens

Esta sección explica cómo subir y obtener imágenes de dispositivos usando **tokens** en lugar de cookies.

---

### **📋 Endpoints de Imágenes**

| Operación | Endpoint | Método | Autenticación |
|-----------|----------|--------|---------------|
| **Subir imagen** | `/api/devices/{id}/image` | `POST` | Bearer Token ✅ |
| **Obtener imagen** | `/api/media/{uniqueId}/device.{ext}` | `GET` | Bearer Token ⚠️ |

**⚠️ Nota importante:** El endpoint `/api/media/*` requiere autenticación por sesión (cookie) o puedes usar el token como query parameter en algunos casos. La forma más confiable es convertir la imagen a base64 o usar un proxy.

---

### **1. Subir Imagen de Dispositivo con Token**

#### **Endpoint:**
```
POST /api/devices/{id}/image
Authorization: Bearer <token>
Content-Type: image/jpeg (o image/png, image/gif, image/webp, image/svg+xml)
Body: <binary image data>
```

#### **Características:**
- ✅ **Funciona perfectamente con tokens**
- ✅ **Formatos soportados:** JPEG, PNG, GIF, WebP, SVG
- ✅ **Límite de tamaño:** 500 KB (500,000 bytes)
- ✅ **Respuesta:** Nombre del archivo guardado (ej: "device.jpg")

---

#### **💻 Implementación en JavaScript/TypeScript**

```typescript
/**
 * Sube una imagen de dispositivo usando token
 */
async function uploadDeviceImage(
  deviceId: number,
  imageFile: File,
  token: string
): Promise<string> {
  // Validar tipo de archivo
  const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'];
  if (!validTypes.includes(imageFile.type)) {
    throw new Error(`Tipo de imagen no soportado: ${imageFile.type}`);
  }

  // Validar tamaño (500 KB)
  const MAX_SIZE = 500 * 1024; // 500 KB
  if (imageFile.size > MAX_SIZE) {
    throw new Error(`La imagen es demasiado grande. Máximo ${MAX_SIZE / 1024} KB`);
  }

  // Crear FormData
  const formData = new FormData();
  formData.append('file', imageFile);

  // Subir imagen
  const response = await fetch(`${API_BASE_URL}/devices/${deviceId}/image`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
      // NO incluir Content-Type - el navegador lo hará automáticamente con FormData
    },
    body: formData
  });

  if (!response.ok) {
    if (response.status === 401) {
      throw new Error('Token inválido o expirado');
    }
    if (response.status === 404) {
      throw new Error('Dispositivo no encontrado');
    }
    const errorText = await response.text();
    throw new Error(`Error al subir imagen: ${errorText}`);
  }

  // La respuesta es el nombre del archivo (ej: "device.jpg")
  const filename = await response.text();
  return filename.trim();
}

// Uso
const token = await generateToken('admin', 'admin');
const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement;
const file = fileInput.files?.[0];

if (file) {
  try {
    const filename = await uploadDeviceImage(34, file, token);
    console.log(`Imagen subida: ${filename}`);
  } catch (error: any) {
    console.error('Error:', error.message);
  }
}
```

---

#### **📱 Ejemplo Completo con React**

```typescript
import React, { useState } from 'react';

interface DeviceImageUploadProps {
  deviceId: number;
  token: string;
  onUploadSuccess?: (filename: string) => void;
}

function DeviceImageUpload({ deviceId, token, onUploadSuccess }: DeviceImageUploadProps) {
  const [uploading, setUploading] = useState(false);
  const [preview, setPreview] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validar tipo
    if (!file.type.startsWith('image/')) {
      setError('Por favor seleccione una imagen válida');
      return;
    }

    // Validar tamaño (500 KB)
    if (file.size > 500 * 1024) {
      setError('La imagen es demasiado grande. Máximo 500 KB');
      return;
    }

    // Crear preview
    const reader = new FileReader();
    reader.onload = (e) => {
      setPreview(e.target?.result as string);
    };
    reader.readAsDataURL(file);

    // Subir imagen
    setUploading(true);
    setError(null);
    setSuccess(null);

    try {
      const filename = await uploadDeviceImage(deviceId, file, token);
      setSuccess(`Imagen subida: ${filename}`);
      if (onUploadSuccess) {
        onUploadSuccess(filename);
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="device-image-upload">
      <input
        type="file"
        accept="image/*"
        onChange={handleFileChange}
        disabled={uploading}
      />
      
      {preview && (
        <div className="preview">
          <img
            src={preview}
            alt="Preview"
            style={{ maxWidth: '300px', marginTop: '10px' }}
          />
        </div>
      )}

      {uploading && <p>Subiendo imagen...</p>}
      {error && <p style={{ color: 'red' }}>Error: {error}</p>}
      {success && <p style={{ color: 'green' }}>{success}</p>}
    </div>
  );
}
```

---

#### **🐍 Implementación en Python**

```python
def upload_device_image(device_id: int, image_path: str, token: str) -> str:
    """Sube una imagen de dispositivo usando token"""
    
    # Validar que el archivo existe
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"Archivo no encontrado: {image_path}")
    
    # Validar tamaño (500 KB)
    file_size = os.path.getsize(image_path)
    MAX_SIZE = 500 * 1024  # 500 KB
    if file_size > MAX_SIZE:
        raise ValueError(f"La imagen es demasiado grande. Máximo {MAX_SIZE / 1024} KB")
    
    # Determinar Content-Type
    ext = os.path.splitext(image_path)[1].lower()
    content_types = {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.webp': 'image/webp',
        '.svg': 'image/svg+xml'
    }
    content_type = content_types.get(ext)
    if not content_type:
        raise ValueError(f"Tipo de imagen no soportado: {ext}")
    
    # Leer archivo
    with open(image_path, 'rb') as f:
        image_data = f.read()
    
    # Subir imagen
    url = f"{API_BASE_URL}/devices/{device_id}/image"
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': content_type
    }
    
    response = requests.post(url, headers=headers, data=image_data)
    response.raise_for_status()
    
    # La respuesta es el nombre del archivo
    return response.text.strip()

# Uso
token = await client.login('admin', 'admin')
filename = upload_device_image(34, 'vehiculo.jpg', token)
print(f"Imagen subida: {filename}")
```

---

### **2. Obtener URL de Imagen de Dispositivo**

Después de subir una imagen, se guarda en:
```
media/{uniqueId}/device.{extension}
```

Y se puede acceder vía:
```
GET /api/media/{uniqueId}/device.{extension}
```

#### **⚠️ Problema con MediaFilter**

El `MediaFilter` que protege `/api/media/*` **solo acepta autenticación por sesión (cookies)**, no tokens directamente en el header `Authorization: Bearer`.

**Soluciones:**

#### **Opción 1: Usar Token en Query Parameter (si está soportado)**

```typescript
/**
 * Obtiene la URL de la imagen del dispositivo
 */
function getDeviceImageUrl(device: Device, token?: string): string {
  if (!device || !device.uniqueId) {
    return '';
  }

  const baseUrl = API_BASE_URL.replace('/api', ''); // http://localhost:8082
  const imageUrl = `${baseUrl}/api/media/${device.uniqueId}/device.jpg`;
  
  // Intentar con token en query parameter (puede no funcionar)
  if (token) {
    return `${imageUrl}?token=${encodeURIComponent(token)}`;
  }
  
  return imageUrl;
}
```

#### **Opción 2: Convertir Imagen a Base64 (Recomendado)**

```typescript
/**
 * Obtiene la imagen del dispositivo como base64 usando token
 */
async function getDeviceImageAsBase64(
  device: Device,
  token: string
): Promise<string | null> {
  if (!device || !device.uniqueId) {
    return null;
  }

  const baseUrl = API_BASE_URL.replace('/api', '');
  const extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  
  for (const ext of extensions) {
    const imageUrl = `${baseUrl}/api/media/${device.uniqueId}/device.${ext}`;
    
    try {
      // Intentar obtener la imagen
      // Nota: Esto puede fallar si MediaFilter no acepta tokens
      const response = await fetch(imageUrl, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (response.ok) {
        // Convertir a base64
        const blob = await response.blob();
        return new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onloadend = () => resolve(reader.result as string);
          reader.onerror = reject;
          reader.readAsDataURL(blob);
        });
      }
    } catch (error) {
      // Continuar con siguiente extensión
      continue;
    }
  }
  
  return null; // No se encontró imagen
}
```

#### **Opción 3: Proxy/Backend Intermedio (Más Confiable)**

Si el `MediaFilter` no acepta tokens, puedes crear un endpoint proxy en tu backend:

```typescript
// En tu backend (Node.js/Express ejemplo)
app.get('/api/proxy/device-image/:uniqueId', async (req, res) => {
  const { uniqueId } = req.params;
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'Token requerido' });
  }

  // Verificar token con Traccar
  const sessionResponse = await fetch(
    `http://localhost:8082/api/session?token=${encodeURIComponent(token)}`
  );
  
  if (!sessionResponse.ok) {
    return res.status(401).json({ error: 'Token inválido' });
  }

  // Obtener imagen de Traccar (usando sesión o token si es posible)
  const imageUrl = `http://localhost:8082/api/media/${uniqueId}/device.jpg`;
  const imageResponse = await fetch(imageUrl, {
    headers: {
      'Cookie': sessionResponse.headers.get('set-cookie') || ''
    }
  });

  if (imageResponse.ok) {
    const imageBuffer = await imageResponse.arrayBuffer();
    res.set('Content-Type', imageResponse.headers.get('content-type') || 'image/jpeg');
    res.send(Buffer.from(imageBuffer));
  } else {
    res.status(404).json({ error: 'Imagen no encontrada' });
  }
});
```

---

### **3. Flujo Completo: Crear Dispositivo y Subir Imagen**

```typescript
/**
 * Flujo completo: Crear dispositivo y subir su imagen usando tokens
 */
async function createDeviceWithImage(
  token: string,
  deviceData: Partial<Device>,
  imageFile?: File
): Promise<{ device: Device; imageUrl?: string }> {
  console.log('🚀 Creando dispositivo con imagen...\n');

  // Paso 1: Crear dispositivo
  console.log('📱 Paso 1: Creando dispositivo...');
  const device = await authenticatedRequest<Device>(
    '/devices',
    token,
    {
      method: 'POST',
      body: JSON.stringify(deviceData)
    }
  );
  console.log(`✅ Dispositivo creado: ${device.name} (ID: ${device.id})\n`);

  // Paso 2: Subir imagen (si se proporciona)
  let imageUrl: string | undefined;
  if (imageFile) {
    console.log('📸 Paso 2: Subiendo imagen...');
    try {
      const filename = await uploadDeviceImage(device.id, imageFile, token);
      console.log(`✅ Imagen subida: ${filename}\n`);
      
      // Construir URL de la imagen
      const baseUrl = API_BASE_URL.replace('/api', '');
      imageUrl = `${baseUrl}/api/media/${device.uniqueId}/${filename}`;
    } catch (error: any) {
      console.warn(`⚠️ Error al subir imagen: ${error.message}\n`);
    }
  }

  return { device, imageUrl };
}

// Uso
const token = await generateToken('admin', 'admin');
const fileInput = document.querySelector('input[type="file"]') as HTMLInputElement;
const imageFile = fileInput.files?.[0];

const resultado = await createDeviceWithImage(
  token,
  {
    name: 'Vehículo Principal',
    uniqueId: '123456789012345',
    model: 'TK103',
    category: 'car'
  },
  imageFile
);

console.log('Dispositivo:', resultado.device);
console.log('URL de imagen:', resultado.imageUrl);
```

---

### **4. Método Mejorado: Clase para Gestión de Imágenes**

```typescript
class DeviceImageManager {
  private baseUrl: string;
  private token: string;

  constructor(baseUrl: string, token: string) {
    this.baseUrl = baseUrl;
    this.token = token;
  }

  /**
   * Sube una imagen de dispositivo
   */
  async upload(deviceId: number, imageFile: File): Promise<string> {
    return await uploadDeviceImage(deviceId, imageFile, this.token);
  }

  /**
   * Obtiene la imagen como base64
   */
  async getAsBase64(device: Device): Promise<string | null> {
    return await getDeviceImageAsBase64(device, this.token);
  }

  /**
   * Obtiene la URL de la imagen (puede requerir autenticación adicional)
   */
  getUrl(device: Device, extension: string = 'jpg'): string {
    const baseUrl = this.baseUrl.replace('/api', '');
    return `${baseUrl}/api/media/${device.uniqueId}/device.${extension}`;
  }

  /**
   * Verifica si existe una imagen para el dispositivo
   */
  async exists(device: Device): Promise<boolean> {
    const extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    
    for (const ext of extensions) {
      const url = this.getUrl(device, ext);
      try {
        const response = await fetch(url, {
          method: 'HEAD',
          headers: {
            'Authorization': `Bearer ${this.token}`
          }
        });
        if (response.ok) {
          return true;
        }
      } catch {
        continue;
      }
    }
    
    return false;
  }

  /**
   * Obtiene la imagen como Blob
   */
  async getAsBlob(device: Device): Promise<Blob | null> {
    const extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    const baseUrl = this.baseUrl.replace('/api', '');
    
    for (const ext of extensions) {
      const url = `${baseUrl}/api/media/${device.uniqueId}/device.${ext}`;
      try {
        const response = await fetch(url, {
          headers: {
            'Authorization': `Bearer ${this.token}`
          }
        });
        
        if (response.ok) {
          return await response.blob();
        }
      } catch {
        continue;
      }
    }
    
    return null;
  }
}

// Uso
const token = await generateToken('admin', 'admin');
const imageManager = new DeviceImageManager(API_BASE_URL, token);

// Subir imagen
const filename = await imageManager.upload(34, imageFile);
console.log('Imagen subida:', filename);

// Verificar si existe
const device = await getDevice(34);
const exists = await imageManager.exists(device);
console.log('Imagen existe:', exists);

// Obtener como base64
const base64 = await imageManager.getAsBase64(device);
if (base64) {
  console.log('Imagen en base64:', base64.substring(0, 50) + '...');
}
```

---

### **5. Ejemplo Completo: Componente React para Gestión de Imágenes**

```typescript
import React, { useState, useEffect } from 'react';

interface DeviceImageManagerProps {
  device: Device;
  token: string;
}

function DeviceImageManager({ device, token }: DeviceImageManagerProps) {
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Cargar imagen existente
  useEffect(() => {
    loadImage();
  }, [device, token]);

  const loadImage = async () => {
    try {
      const base64 = await getDeviceImageAsBase64(device, token);
      setImageUrl(base64);
    } catch (err: any) {
      console.warn('No se pudo cargar imagen:', err.message);
    }
  };

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploading(true);
    setError(null);

    try {
      await uploadDeviceImage(device.id, file, token);
      await loadImage(); // Recargar imagen
    } catch (err: any) {
      setError(err.message);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="device-image-manager">
      <h3>Imagen del Dispositivo</h3>
      
      {imageUrl ? (
        <div className="current-image">
          <img src={imageUrl} alt={device.name} style={{ maxWidth: '300px' }} />
        </div>
      ) : (
        <p>No hay imagen disponible</p>
      )}

      <div className="upload-section">
        <input
          type="file"
          accept="image/*"
          onChange={handleUpload}
          disabled={uploading}
        />
        {uploading && <p>Subiendo...</p>}
        {error && <p style={{ color: 'red' }}>Error: {error}</p>}
      </div>
    </div>
  );
}
```

---

### **📋 Resumen de Endpoints**

| Operación | Endpoint | Método | Token | Notas |
|-----------|----------|--------|-------|-------|
| **Subir imagen** | `/api/devices/{id}/image` | `POST` | ✅ Bearer | Funciona perfectamente |
| **Obtener imagen** | `/api/media/{uniqueId}/device.{ext}` | `GET` | ⚠️ Limitado | MediaFilter solo acepta sesiones |

---

### **✅ Checklist**

- [ ] Generar token de autenticación
- [ ] Validar tipo y tamaño de imagen antes de subir
- [ ] Subir imagen con `POST /api/devices/{id}/image` usando Bearer token
- [ ] Manejar errores 401 (token expirado)
- [ ] Obtener URL de imagen (puede requerir proxy si MediaFilter no acepta tokens)
- [ ] Convertir a base64 si es necesario para mostrar en frontend

---

**Última actualización:** 2025-02-13

