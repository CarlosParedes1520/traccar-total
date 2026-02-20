# 📚 Guía Completa: CRUD de Usuarios y Asignación de Dispositivos

Esta guía cubre todas las operaciones para gestionar usuarios y asignar dispositivos en Traccar.

---

## 📋 Tabla de Contenidos

1. [Conceptos Básicos](#conceptos-básicos)
2. [Autenticación](#autenticación)
3. [CRUD de Usuarios](#crud-de-usuarios)
4. [Asignación de Dispositivos](#asignación-de-dispositivos)
5. [Consultas y Relaciones](#consultas-y-relaciones)
6. [Ejemplos Completos](#ejemplos-completos)
7. [Errores Comunes](#errores-comunes)

---

## 🔑 Conceptos Básicos

### **Relación Usuario-Dispositivo**

En Traccar, la relación entre usuarios y dispositivos se maneja mediante **permisos** (permissions):

- Un usuario puede tener acceso a múltiples dispositivos
- Un dispositivo puede ser accesible por múltiples usuarios
- La relación se almacena en la tabla `tc_user_device`
- Los permisos se gestionan mediante el endpoint `/api/permissions`

### **Tipos de Usuarios**

1. **Administrador (`administrator: true`)**
   - Acceso total al sistema
   - Puede gestionar todos los usuarios y dispositivos
   - Sin límites de dispositivos o usuarios

2. **Manager (`userLimit > 0`)**
   - Puede crear y gestionar usuarios limitados
   - Puede asignar dispositivos a sus usuarios gestionados

3. **Usuario Regular**
   - Acceso limitado a dispositivos asignados
   - Puede tener límite de dispositivos (`deviceLimit`)

### **Campos Importantes del Usuario**

```typescript
interface User {
  id: number;                    // ID único (generado automáticamente)
  name: string;                  // Nombre completo
  email: string;                 // Email (único, usado para login)
  password?: string;             // Solo al crear/actualizar (se hashea)
  login?: string;                // Login alternativo
  phone?: string;                // Teléfono
  readonly: boolean;             // Solo lectura
  administrator: boolean;        // Es administrador
  disabled: boolean;             // Usuario deshabilitado
  deviceLimit: number;           // Límite de dispositivos (-1 = ilimitado, 0 = ninguno)
  userLimit: number;             // Límite de usuarios gestionados (0 = no manager)
  deviceReadonly: boolean;       // Dispositivos en modo solo lectura
  limitCommands: boolean;        // Limitar comandos
  disableReports: boolean;       // Deshabilitar reportes
  fixedEmail: boolean;          // Email no modificable
  expirationTime?: Date;        // Fecha de expiración
  attributes?: Record<string, any>; // Atributos personalizados
}
```

---

## 🔐 Autenticación

Todas las operaciones requieren autenticación. Usa **Basic Auth** para las peticiones API:

```javascript
const API_BASE_URL = 'http://localhost:8082/api';
const API_USER = 'admin';
const API_PASS = 'admin';

// Headers para todas las peticiones
const headers = {
  'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`),
  'Content-Type': 'application/json'
};
```

---

## 👥 CRUD de Usuarios

### 1. **Crear Usuario**

**Endpoint:** `POST /api/users`

**Ejemplo en JavaScript/TypeScript:**

```typescript
interface CreateUserData {
  name: string;
  email: string;
  password: string;
  readonly?: boolean;
  administrator?: boolean;
  disabled?: boolean;
  deviceLimit?: number;
  userLimit?: number;
  deviceReadonly?: boolean;
  limitCommands?: boolean;
  disableReports?: boolean;
  fixedEmail?: boolean;
  attributes?: Record<string, any>;
}

async function createUser(userData: CreateUserData): Promise<User> {
  const response = await fetch(`${API_BASE_URL}/users`, {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`),
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      name: userData.name,
      email: userData.email,
      password: userData.password,
      readonly: userData.readonly ?? false,
      administrator: userData.administrator ?? false,
      disabled: userData.disabled ?? false,
      deviceLimit: userData.deviceLimit ?? -1,  // -1 = ilimitado
      userLimit: userData.userLimit ?? 0,        // 0 = no manager
      deviceReadonly: userData.deviceReadonly ?? false,
      limitCommands: userData.limitCommands ?? false,
      disableReports: userData.disableReports ?? false,
      fixedEmail: userData.fixedEmail ?? false,
      attributes: userData.attributes ?? {}
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error al crear usuario: ${errorText}`);
  }

  return await response.json();
}

// Uso
const newUser = await createUser({
  name: 'Juan Pérez',
  email: 'juan@example.com',
  password: 'password123',
  deviceLimit: 10,  // Máximo 10 dispositivos
  readonly: false
});

console.log('Usuario creado:', newUser);
```

**Ejemplo en Python:**

```python
import requests
import json

def create_user(name, email, password, device_limit=-1, readonly=False):
    url = "http://localhost:8082/api/users"
    headers = {
        "Authorization": "Basic " + base64.b64encode(f"admin:admin".encode()).decode(),
        "Content-Type": "application/json"
    }
    data = {
        "name": name,
        "email": email,
        "password": password,
        "readonly": readonly,
        "administrator": False,
        "disabled": False,
        "deviceLimit": device_limit,
        "userLimit": 0,
        "deviceReadonly": False,
        "limitCommands": False,
        "disableReports": False,
        "fixedEmail": False,
        "attributes": {}
    }
    
    response = requests.post(url, headers=headers, json=data)
    response.raise_for_status()
    return response.json()

# Uso
user = create_user("Juan Pérez", "juan@example.com", "password123", device_limit=10)
print(f"Usuario creado: {user['id']}")
```

**Ejemplo con cURL:**

```bash
curl -X POST http://localhost:8082/api/users \
  -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "password": "password123",
    "readonly": false,
    "administrator": false,
    "disabled": false,
    "deviceLimit": 10,
    "userLimit": 0,
    "deviceReadonly": false,
    "limitCommands": false,
    "disableReports": false,
    "fixedEmail": false,
    "attributes": {}
  }'
```

**Respuesta exitosa:**
```json
{
  "id": 5,
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "readonly": false,
  "administrator": false,
  "disabled": false,
  "deviceLimit": 10,
  "userLimit": 0,
  "deviceReadonly": false,
  "limitCommands": false,
  "disableReports": false,
  "fixedEmail": false,
  "attributes": {}
}
```

---

### 2. **Listar Todos los Usuarios**

**Endpoint:** `GET /api/users`

**Ejemplo en JavaScript/TypeScript:**

```typescript
async function getAllUsers(excludeAttributes: boolean = false): Promise<User[]> {
  const url = `${API_BASE_URL}/users${excludeAttributes ? '?excludeAttributes=true' : ''}`;
  
  const response = await fetch(url, {
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
    }
  });

  if (!response.ok) {
    throw new Error('Error al obtener usuarios');
  }

  return await response.json();
}

// Uso
const users = await getAllUsers();
console.log(`Total de usuarios: ${users.length}`);
users.forEach(user => {
  console.log(`- ${user.name} (${user.email}) - ID: ${user.id}`);
});
```

**Ejemplo con cURL:**

```bash
# Listar todos los usuarios
curl -u admin:admin http://localhost:8082/api/users

# Listar sin atributos (más rápido)
curl -u admin:admin "http://localhost:8082/api/users?excludeAttributes=true"
```

---

### 3. **Obtener Usuario por ID**

**Endpoint:** `GET /api/users/{id}`

**Ejemplo en JavaScript/TypeScript:**

```typescript
async function getUserById(userId: number): Promise<User> {
  const response = await fetch(`${API_BASE_URL}/users/${userId}`, {
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
    }
  });

  if (!response.ok) {
    if (response.status === 404) {
      throw new Error('Usuario no encontrado');
    }
    throw new Error('Error al obtener usuario');
  }

  return await response.json();
}

// Uso
const user = await getUserById(5);
console.log('Usuario:', user);
```

**Ejemplo con cURL:**

```bash
curl -u admin:admin http://localhost:8082/api/users/5
```

---

### 4. **Actualizar Usuario**

**Endpoint:** `PUT /api/users/{id}`

**Importante:** Debes incluir el `id` en el body` y todos los campos que quieres mantener.

**Ejemplo en JavaScript/TypeScript:**

```typescript
async function updateUser(userId: number, updates: Partial<User>): Promise<User> {
  // Primero obtener el usuario actual
  const currentUser = await getUserById(userId);
  
  // Combinar datos actuales con actualizaciones
  const updatedUser = {
    ...currentUser,
    ...updates,
    id: userId  // Siempre incluir el ID
  };

  const response = await fetch(`${API_BASE_URL}/users/${userId}`, {
    method: 'PUT',
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`),
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(updatedUser)
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error al actualizar usuario: ${errorText}`);
  }

  return await response.json();
}

// Uso: Actualizar nombre y límite de dispositivos
const updated = await updateUser(5, {
  name: 'Juan Carlos Pérez',
  deviceLimit: 20
});

// Uso: Cambiar contraseña
const updatedWithPassword = await updateUser(5, {
  password: 'nuevaPassword123'
});

// Uso: Deshabilitar usuario
const disabled = await updateUser(5, {
  disabled: true
});
```

**Ejemplo con cURL:**

```bash
# Actualizar nombre
curl -X PUT http://localhost:8082/api/users/5 \
  -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "id": 5,
    "name": "Juan Carlos Pérez",
    "email": "juan@example.com",
    "readonly": false,
    "administrator": false,
    "disabled": false,
    "deviceLimit": 20,
    "userLimit": 0,
    "deviceReadonly": false,
    "limitCommands": false,
    "disableReports": false,
    "fixedEmail": false,
    "attributes": {}
  }'
```

---

### 5. **Eliminar Usuario**

**Endpoint:** `DELETE /api/users/{id}`

**Ejemplo en JavaScript/TypeScript:**

```typescript
async function deleteUser(userId: number): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/users/${userId}`, {
    method: 'DELETE',
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
    }
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error al eliminar usuario: ${errorText}`);
  }
}

// Uso
await deleteUser(5);
console.log('Usuario eliminado');
```

**Ejemplo con cURL:**

```bash
curl -X DELETE http://localhost:8082/api/users/5 \
  -u admin:admin
```

**⚠️ Nota:** Al eliminar un usuario, se eliminan automáticamente todos sus permisos (relaciones con dispositivos).

---

## 🔗 Asignación de Dispositivos

### 1. **Asignar Dispositivo a Usuario**

**Endpoint:** `POST /api/permissions`

**Ejemplo en JavaScript/TypeScript:**

```typescript
interface Permission {
  userId: number;
  deviceId: number;
}

async function assignDeviceToUser(userId: number, deviceId: number): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/permissions`, {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`),
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      userId: userId,
      deviceId: deviceId
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error al asignar dispositivo: ${errorText}`);
  }
}

// Uso: Asignar dispositivo ID 34 al usuario ID 5
await assignDeviceToUser(5, 34);
console.log('Dispositivo asignado correctamente');
```

**Ejemplo con cURL:**

```bash
curl -X POST http://localhost:8082/api/permissions \
  -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 5,
    "deviceId": 34
  }'
```

**Respuesta exitosa:** `HTTP 204 No Content`

---

### 2. **Asignar Múltiples Dispositivos (Bulk)**

**Endpoint:** `POST /api/permissions/bulk`

**Ejemplo en JavaScript/TypeScript:**

```typescript
async function assignMultipleDevicesToUser(
  userId: number, 
  deviceIds: number[]
): Promise<void> {
  const permissions = deviceIds.map(deviceId => ({
    userId: userId,
    deviceId: deviceId
  }));

  const response = await fetch(`${API_BASE_URL}/permissions/bulk`, {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`),
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(permissions)
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error al asignar dispositivos: ${errorText}`);
  }
}

// Uso: Asignar múltiples dispositivos al usuario 5
await assignMultipleDevicesToUser(5, [34, 35, 36]);
console.log('Dispositivos asignados correctamente');
```

**Ejemplo con cURL:**

```bash
curl -X POST http://localhost:8082/api/permissions/bulk \
  -u admin:admin \
  -H "Content-Type: application/json" \
  -d '[
    {"userId": 5, "deviceId": 34},
    {"userId": 5, "deviceId": 35},
    {"userId": 5, "deviceId": 36}
  ]'
```

---

### 3. **Remover Dispositivo de Usuario**

**Endpoint:** `DELETE /api/permissions`

**Ejemplo en JavaScript/TypeScript:**

```typescript
async function removeDeviceFromUser(userId: number, deviceId: number): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/permissions`, {
    method: 'DELETE',
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`),
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      userId: userId,
      deviceId: deviceId
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error al remover dispositivo: ${errorText}`);
  }
}

// Uso
await removeDeviceFromUser(5, 34);
console.log('Dispositivo removido del usuario');
```

**Ejemplo con cURL:**

```bash
curl -X DELETE http://localhost:8082/api/permissions \
  -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 5,
    "deviceId": 34
  }'
```

---

### 4. **Remover Múltiples Dispositivos (Bulk)**

**Endpoint:** `DELETE /api/permissions/bulk`

**Ejemplo en JavaScript/TypeScript:**

```typescript
async function removeMultipleDevicesFromUser(
  userId: number, 
  deviceIds: number[]
): Promise<void> {
  const permissions = deviceIds.map(deviceId => ({
    userId: userId,
    deviceId: deviceId
  }));

  const response = await fetch(`${API_BASE_URL}/permissions/bulk`, {
    method: 'DELETE',
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`),
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(permissions)
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error al remover dispositivos: ${errorText}`);
  }
}

// Uso
await removeMultipleDevicesFromUser(5, [34, 35]);
```

---

## 🔍 Consultas y Relaciones

### 1. **Obtener Dispositivos de un Usuario**

**Endpoint:** `GET /api/devices` (retorna solo los dispositivos accesibles por el usuario autenticado)

**Ejemplo en JavaScript/TypeScript:**

```typescript
async function getDevicesForUser(userId: number): Promise<Device[]> {
  // Nota: Esto requiere autenticarse como el usuario o como admin
  // Si eres admin, puedes usar el endpoint normal
  const response = await fetch(`${API_BASE_URL}/devices`, {
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
    }
  });

  if (!response.ok) {
    throw new Error('Error al obtener dispositivos');
  }

  return await response.json();
}

// Obtener dispositivos del usuario actual
const devices = await getDevicesForUser(5);
console.log(`Usuario tiene acceso a ${devices.length} dispositivos`);
```

**Alternativa: Usar el endpoint de usuarios con parámetro `deviceId`**

```typescript
// Obtener usuarios que tienen acceso a un dispositivo específico
async function getUsersForDevice(deviceId: number): Promise<User[]> {
  const response = await fetch(`${API_BASE_URL}/users?deviceId=${deviceId}`, {
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
    }
  });

  if (!response.ok) {
    throw new Error('Error al obtener usuarios');
  }

  return await response.json();
}

// Uso
const users = await getUsersForDevice(34);
console.log(`Dispositivo 34 es accesible por ${users.length} usuarios`);
```

---

### 2. **Verificar si Usuario Tiene Acceso a Dispositivo**

**Ejemplo en JavaScript/TypeScript:**

```typescript
async function userHasDeviceAccess(userId: number, deviceId: number): Promise<boolean> {
  try {
    // Intentar obtener el dispositivo como ese usuario
    // Si tiene acceso, la petición será exitosa
    const response = await fetch(`${API_BASE_URL}/devices/${deviceId}`, {
      headers: {
        'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
      }
    });
    
    return response.ok;
  } catch {
    return false;
  }
}

// Alternativa: Verificar mediante lista de usuarios del dispositivo
async function userHasDeviceAccess2(userId: number, deviceId: number): Promise<boolean> {
  const users = await getUsersForDevice(deviceId);
  return users.some(user => user.id === userId);
}
```

---

## 📝 Ejemplos Completos

### **Ejemplo 1: Crear Usuario y Asignar Dispositivos**

```typescript
async function createUserWithDevices(
  userData: CreateUserData,
  deviceIds: number[]
): Promise<{ user: User; devices: Device[] }> {
  // 1. Crear usuario
  console.log('Creando usuario...');
  const user = await createUser(userData);
  console.log(`Usuario creado: ${user.name} (ID: ${user.id})`);

  // 2. Asignar dispositivos
  if (deviceIds.length > 0) {
    console.log(`Asignando ${deviceIds.length} dispositivos...`);
    await assignMultipleDevicesToUser(user.id, deviceIds);
    console.log('Dispositivos asignados correctamente');
  }

  // 3. Verificar dispositivos asignados
  const devices = await getDevicesForUser(user.id);
  console.log(`Usuario tiene acceso a ${devices.length} dispositivos`);

  return { user, devices };
}

// Uso
const { user, devices } = await createUserWithDevices(
  {
    name: 'María García',
    email: 'maria@example.com',
    password: 'password123',
    deviceLimit: 5
  },
  [34, 35, 36]
);
```

---

### **Ejemplo 2: Transferir Dispositivos entre Usuarios**

```typescript
async function transferDevices(
  fromUserId: number,
  toUserId: number,
  deviceIds: number[]
): Promise<void> {
  console.log(`Transfiriendo ${deviceIds.length} dispositivos de usuario ${fromUserId} a ${toUserId}...`);

  // 1. Remover dispositivos del usuario origen
  await removeMultipleDevicesFromUser(fromUserId, deviceIds);
  console.log('Dispositivos removidos del usuario origen');

  // 2. Asignar dispositivos al usuario destino
  await assignMultipleDevicesToUser(toUserId, deviceIds);
  console.log('Dispositivos asignados al usuario destino');
}

// Uso
await transferDevices(5, 6, [34, 35]);
```

---

### **Función Helper: Obtener Todos los Dispositivos**

```typescript
async function getAllDevices(): Promise<Device[]> {
  const response = await fetch(`${API_BASE_URL}/devices`, {
    headers: {
      'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
    }
  });

  if (!response.ok) {
    throw new Error('Error al obtener dispositivos');
  }

  return await response.json();
}
```

---

### **Ejemplo 3: Componente React para Gestionar Usuarios y Dispositivos**

```typescript
import React, { useState, useEffect } from 'react';

interface UserManagementProps {
  userId?: number;
}

function UserManagement({ userId }: UserManagementProps) {
  const [user, setUser] = useState<User | null>(null);
  const [devices, setDevices] = useState<Device[]>([]);
  const [allDevices, setAllDevices] = useState<Device[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Cargar datos
  useEffect(() => {
    if (userId) {
      loadUserData();
    }
  }, [userId]);

  const loadUserData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Cargar usuario
      const userData = await getUserById(userId!);
      setUser(userData);

      // Cargar dispositivos del usuario
      const userDevices = await getDevicesForUser(userId!);
      setDevices(userDevices);

      // Cargar todos los dispositivos disponibles
      const allDevicesData = await getAllDevices();
      setAllDevices(allDevicesData);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleAssignDevice = async (deviceId: number) => {
    try {
      await assignDeviceToUser(userId!, deviceId);
      await loadUserData(); // Recargar datos
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleRemoveDevice = async (deviceId: number) => {
    try {
      await removeDeviceFromUser(userId!, deviceId);
      await loadUserData(); // Recargar datos
    } catch (err: any) {
      setError(err.message);
    }
  };

  if (loading) return <div>Cargando...</div>;
  if (error) return <div>Error: {error}</div>;
  if (!user) return <div>Usuario no encontrado</div>;

  // Dispositivos asignados y no asignados
  const assignedDeviceIds = new Set(devices.map(d => d.id));
  const unassignedDevices = allDevices.filter(d => !assignedDeviceIds.has(d.id));

  return (
    <div className="user-management">
      <h2>Gestión de Usuario: {user.name}</h2>
      <p>Email: {user.email}</p>
      <p>Límite de dispositivos: {user.deviceLimit === -1 ? 'Ilimitado' : user.deviceLimit}</p>

      <div className="devices-section">
        <h3>Dispositivos Asignados ({devices.length})</h3>
        <ul>
          {devices.map(device => (
            <li key={device.id}>
              {device.name} ({device.uniqueId})
              <button onClick={() => handleRemoveDevice(device.id)}>
                Remover
              </button>
            </li>
          ))}
        </ul>

        <h3>Dispositivos Disponibles</h3>
        <ul>
          {unassignedDevices.map(device => (
            <li key={device.id}>
              {device.name} ({device.uniqueId})
              <button onClick={() => handleAssignDevice(device.id)}>
                Asignar
              </button>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

export default UserManagement;
```

---

### **Ejemplo 4: Script Completo de Gestión**

```typescript
// user-device-manager.ts
class UserDeviceManager {
  private baseUrl: string;
  private auth: string;

  constructor(baseUrl: string, username: string, password: string) {
    this.baseUrl = baseUrl;
    this.auth = 'Basic ' + btoa(`${username}:${password}`);
  }

  // Usuarios
  async createUser(userData: CreateUserData): Promise<User> {
    const response = await fetch(`${this.baseUrl}/users`, {
      method: 'POST',
      headers: {
        'Authorization': this.auth,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(userData)
    });
    if (!response.ok) throw new Error(await response.text());
    return await response.json();
  }

  async getUser(userId: number): Promise<User> {
    const response = await fetch(`${this.baseUrl}/users/${userId}`, {
      headers: { 'Authorization': this.auth }
    });
    if (!response.ok) throw new Error('Usuario no encontrado');
    return await response.json();
  }

  async updateUser(userId: number, updates: Partial<User>): Promise<User> {
    const current = await this.getUser(userId);
    const response = await fetch(`${this.baseUrl}/users/${userId}`, {
      method: 'PUT',
      headers: {
        'Authorization': this.auth,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ ...current, ...updates, id: userId })
    });
    if (!response.ok) throw new Error(await response.text());
    return await response.json();
  }

  async deleteUser(userId: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/users/${userId}`, {
      method: 'DELETE',
      headers: { 'Authorization': this.auth }
    });
    if (!response.ok) throw new Error(await response.text());
  }

  async listUsers(): Promise<User[]> {
    const response = await fetch(`${this.baseUrl}/users`, {
      headers: { 'Authorization': this.auth }
    });
    if (!response.ok) throw new Error('Error al listar usuarios');
    return await response.json();
  }

  // Permisos
  async assignDevice(userId: number, deviceId: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/permissions`, {
      method: 'POST',
      headers: {
        'Authorization': this.auth,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ userId, deviceId })
    });
    if (!response.ok) throw new Error(await response.text());
  }

  async removeDevice(userId: number, deviceId: number): Promise<void> {
    const response = await fetch(`${this.baseUrl}/permissions`, {
      method: 'DELETE',
      headers: {
        'Authorization': this.auth,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ userId, deviceId })
    });
    if (!response.ok) throw new Error(await response.text());
  }

  async assignMultipleDevices(userId: number, deviceIds: number[]): Promise<void> {
    const permissions = deviceIds.map(deviceId => ({ userId, deviceId }));
    const response = await fetch(`${this.baseUrl}/permissions/bulk`, {
      method: 'POST',
      headers: {
        'Authorization': this.auth,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(permissions)
    });
    if (!response.ok) throw new Error(await response.text());
  }

  async getUserDevices(userId: number): Promise<Device[]> {
    const response = await fetch(`${this.baseUrl}/devices`, {
      headers: { 'Authorization': this.auth }
    });
    if (!response.ok) throw new Error('Error al obtener dispositivos');
    // Nota: Esto retorna todos los dispositivos accesibles por el usuario autenticado
    // Para obtener dispositivos de un usuario específico, necesitas autenticarte como ese usuario
    return await response.json();
  }

  async getDeviceUsers(deviceId: number): Promise<User[]> {
    const response = await fetch(`${this.baseUrl}/users?deviceId=${deviceId}`, {
      headers: { 'Authorization': this.auth }
    });
    if (!response.ok) throw new Error('Error al obtener usuarios');
    return await response.json();
  }
}

// Uso
const manager = new UserDeviceManager(
  'http://localhost:8082/api',
  'admin',
  'admin'
);

// Crear usuario y asignar dispositivos
async function setupUser() {
  const user = await manager.createUser({
    name: 'Nuevo Usuario',
    email: 'nuevo@example.com',
    password: 'password123',
    deviceLimit: 10
  });

  await manager.assignMultipleDevices(user.id, [34, 35, 36]);
  console.log(`Usuario ${user.name} creado con 3 dispositivos asignados`);
}

setupUser();
```

---

## ⚠️ Errores Comunes

### **Error 1: "Manager user limit reached"**

**Causa:** El usuario manager ha alcanzado su límite de usuarios gestionados.

**Solución:**
- Aumentar el `userLimit` del manager
- Eliminar usuarios gestionados existentes
- Usar un administrador para crear el usuario

---

### **Error 2: "Device limit reached"**

**Causa:** El usuario ha alcanzado su límite de dispositivos (`deviceLimit`).

**Solución:**
- Aumentar el `deviceLimit` del usuario
- Remover dispositivos asignados
- Establecer `deviceLimit: -1` para ilimitado

---

### **Error 3: "Write access denied"**

**Causa:** El usuario tiene `readonly: true` o el servidor está en modo solo lectura.

**Solución:**
- Verificar que `readonly: false`
- Verificar permisos de administrador
- Verificar configuración del servidor

---

### **Error 4: "Registration disabled"**

**Causa:** Intentas crear un usuario sin ser admin y el registro está deshabilitado.

**Solución:**
- Usar un administrador para crear el usuario
- Habilitar el registro en la configuración del servidor

---

### **Error 5: Permiso duplicado**

**Causa:** Intentas asignar un dispositivo que ya está asignado al usuario.

**Solución:**
- Verificar permisos existentes antes de asignar
- El sistema no lanza error, simplemente ignora el permiso duplicado

---

## 📋 Resumen de Endpoints

| Operación | Método | Endpoint | Descripción |
|-----------|--------|----------|-------------|
| **Crear usuario** | `POST` | `/api/users` | Crea un nuevo usuario |
| **Listar usuarios** | `GET` | `/api/users` | Obtiene todos los usuarios |
| **Obtener usuario** | `GET` | `/api/users/{id}` | Obtiene un usuario específico |
| **Actualizar usuario** | `PUT` | `/api/users/{id}` | Actualiza un usuario |
| **Eliminar usuario** | `DELETE` | `/api/users/{id}` | Elimina un usuario |
| **Asignar dispositivo** | `POST` | `/api/permissions` | Asigna dispositivo a usuario |
| **Asignar múltiples** | `POST` | `/api/permissions/bulk` | Asigna múltiples dispositivos |
| **Remover dispositivo** | `DELETE` | `/api/permissions` | Remueve dispositivo de usuario |
| **Remover múltiples** | `DELETE` | `/api/permissions/bulk` | Remueve múltiples dispositivos |
| **Usuarios de dispositivo** | `GET` | `/api/users?deviceId={id}` | Obtiene usuarios con acceso a un dispositivo |

---

## ✅ Checklist de Operaciones

### **Crear y Configurar Usuario:**
- [ ] Crear usuario con `POST /api/users`
- [ ] Verificar que el usuario se creó correctamente
- [ ] Configurar límites (`deviceLimit`, `userLimit`)
- [ ] Configurar permisos (`readonly`, `deviceReadonly`)

### **Asignar Dispositivos:**
- [ ] Obtener lista de dispositivos disponibles
- [ ] Asignar dispositivos con `POST /api/permissions`
- [ ] Verificar que los dispositivos están asignados
- [ ] Probar acceso del usuario a los dispositivos

### **Gestionar Usuario:**
- [ ] Actualizar información del usuario
- [ ] Cambiar contraseña si es necesario
- [ ] Habilitar/deshabilitar usuario
- [ ] Ajustar límites según necesidades

### **Gestionar Asignaciones:**
- [ ] Listar dispositivos asignados
- [ ] Agregar nuevos dispositivos
- [ ] Remover dispositivos
- [ ] Transferir dispositivos entre usuarios

---

**Última actualización:** 2025-02-13

