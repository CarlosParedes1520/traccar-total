# Implementación de Endpoints: Dispositivos y Posiciones para Mapas

Este documento explica cómo implementar los endpoints de Traccar para obtener los dispositivos de un usuario y sus posiciones (latitud/longitud) para ubicarlos en un mapa.

---

## 📋 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Autenticación](#autenticación)
3. [Endpoints Principales](#endpoints-principales)
4. [Flujo de Implementación](#flujo-de-implementación)
5. [Estructura de Datos](#estructura-de-datos)
6. [Ejemplos de Código](#ejemplos-de-código)
7. [Casos de Uso Comunes](#casos-de-uso-comunes)
8. [Estados del Dispositivo y Detección de Movimiento](#-estados-del-dispositivo-y-detección-de-movimiento)
9. [Mejores Prácticas](#mejores-prácticas)

---

## 🎯 Resumen Ejecutivo

Para mostrar dispositivos en un mapa necesitas:

1. **Obtener los dispositivos del usuario** → `GET /api/devices`
2. **Obtener las posiciones (latitud/longitud)** → `GET /api/positions`
3. **Combinar ambos datos** para mostrar cada dispositivo en su ubicación

### Flujo Simplificado

```
Usuario → Autenticación → Obtener Dispositivos → Obtener Posiciones → Mostrar en Mapa
```

---

## 🔐 Autenticación

Todos los endpoints requieren autenticación. Traccar soporta dos métodos:

### 1. Basic Authentication (Recomendado para APIs)

```http
Authorization: Basic base64(email:password)
```

### 2. Session Cookie (Recomendado para Web)

Primero hacer login:
```http
POST /api/session
Content-Type: application/x-www-form-urlencoded

email=admin@example.com&password=admin
```

Luego usar la cookie `JSESSIONID` en las siguientes peticiones.

---

## 📡 Endpoints Principales

### 1. Obtener Dispositivos del Usuario

#### Endpoint: `GET /api/devices`

**Descripción:** Obtiene todos los dispositivos a los que el usuario tiene acceso.

**Parámetros de Query (opcionales):**
- `userId` (long): Filtrar por ID de usuario específico
- `all` (boolean): Si es `true` y el usuario es admin, devuelve todos los dispositivos
- `id` (List<Long>): Filtrar por IDs específicos de dispositivos
- `uniqueId` (List<String>): Filtrar por `uniqueId` específicos
- `excludeAttributes` (boolean): Excluir atributos del dispositivo

**Ejemplos de URLs:**

```http
# Obtener todos los dispositivos del usuario actual
GET /api/devices

# Obtener dispositivos de un usuario específico
GET /api/devices?userId=1

# Obtener dispositivos específicos por ID
GET /api/devices?id=1&id=2&id=3

# Obtener dispositivos por uniqueId
GET /api/devices?uniqueId=24959195&uniqueId=24959196
```

**Respuesta (Array de Device):**

```json
[
  {
    "id": 1,
    "name": "Mi Vehículo",
    "uniqueId": "24959195",
    "status": "online",
    "lastUpdate": "2025-01-15T10:30:00.000Z",
    "positionId": 12345,
    "disabled": false,
    "model": "GT06",
    "phone": "+1234567890",
    "contact": "Juan Pérez",
    "category": null,
    "groupId": 0,
    "attributes": {}
  },
  {
    "id": 2,
    "name": "Vehículo 2",
    "uniqueId": "24959196",
    "status": "offline",
    "lastUpdate": "2025-01-15T09:15:00.000Z",
    "positionId": 12346,
    "disabled": false,
    "model": "GT06",
    "phone": null,
    "contact": null,
    "category": null,
    "groupId": 0,
    "attributes": {}
  }
]
```

**Campos Importantes del Device:**
- `id`: ID único del dispositivo
- `name`: Nombre del dispositivo
- `uniqueId`: Identificador único del dispositivo (usado por el protocolo GPS)
- `status`: Estado del dispositivo (`"online"`, `"offline"`, `"unknown"`)
- `lastUpdate`: Última vez que se recibió una posición
- `positionId`: ID de la última posición registrada

---

### 2. Obtener Posiciones (Latitud/Longitud)

#### Endpoint: `GET /api/positions`

**Descripción:** Obtiene las posiciones (coordenadas GPS) de los dispositivos.

**Parámetros de Query:**
- `deviceId` (long): Filtrar por ID de dispositivo específico
- `id` (List<Long>): Filtrar por IDs específicos de posiciones
- `from` (Date): Fecha de inicio (formato ISO 8601)
- `to` (Date): Fecha de fin (formato ISO 8601)
- `geofenceId` (long): Filtrar posiciones dentro de una geocerca

**Comportamiento según parámetros:**

1. **Sin parámetros** → Devuelve las últimas posiciones de todos los dispositivos del usuario
2. **Solo `deviceId`** → Devuelve la última posición del dispositivo
3. **`deviceId` + `from` + `to`** → Devuelve todas las posiciones del dispositivo en ese rango de tiempo
4. **Solo `id`** → Devuelve posiciones específicas por ID

**Ejemplos de URLs:**

```http
# Obtener últimas posiciones de todos los dispositivos del usuario
GET /api/positions

# Obtener última posición de un dispositivo específico
GET /api/positions?deviceId=1

# Obtener todas las posiciones de un dispositivo en un rango de tiempo
GET /api/positions?deviceId=1&from=2025-01-01T00:00:00Z&to=2025-01-31T23:59:59Z

# Obtener posiciones específicas por ID
GET /api/positions?id=12345&id=12346
```

**Respuesta (Array de Position):**

```json
[
  {
    "id": 12345,
    "deviceId": 1,
    "protocol": "osmand",
    "deviceTime": "2025-01-15T10:30:00.000Z",
    "fixTime": "2025-01-15T10:30:00.000Z",
    "serverTime": "2025-01-15T10:30:05.000Z",
    "outdated": false,
    "valid": true,
    "latitude": 40.7128,
    "longitude": -74.0060,
    "altitude": 10.0,
    "speed": 0.0,
    "course": 0.0,
    "address": "New York, NY, USA",
    "accuracy": 0.0,
    "network": null,
    "attributes": {
      "sat": 12,
      "batteryLevel": 85,
      "ignition": false
    }
  },
  {
    "id": 12346,
    "deviceId": 2,
    "protocol": "osmand",
    "deviceTime": "2025-01-15T09:15:00.000Z",
    "fixTime": "2025-01-15T09:15:00.000Z",
    "serverTime": "2025-01-15T09:15:05.000Z",
    "outdated": false,
    "valid": true,
    "latitude": 34.0522,
    "longitude": -118.2437,
    "altitude": 100.0,
    "speed": 45.5,
    "course": 180.0,
    "address": "Los Angeles, CA, USA",
    "accuracy": 5.0,
    "network": null,
    "attributes": {
      "sat": 8,
      "batteryLevel": 60,
      "ignition": true
    }
  }
]
```

**Campos Importantes de Position:**
- `id`: ID único de la posición
- `deviceId`: ID del dispositivo al que pertenece
- `latitude`: Latitud en grados decimales (-90 a 90)
- `longitude`: Longitud en grados decimales (-180 a 180)
- `altitude`: Altitud en metros
- `speed`: Velocidad en nudos (knots)
- `course`: Dirección en grados (0-360)
- `address`: Dirección geocodificada (si está disponible)
- `valid`: Si la posición GPS es válida
- `fixTime`: Fecha/hora de la posición GPS
- `attributes`: Atributos adicionales (batería, satélites, etc.)

---

## 🔄 Flujo de Implementación

### Paso 1: Autenticación

```javascript
// Ejemplo en JavaScript
const credentials = btoa('admin@example.com:admin');
const authHeader = `Basic ${credentials}`;
```

### Paso 2: Obtener Dispositivos

```javascript
const response = await fetch('http://localhost:8082/api/devices', {
  headers: {
    'Authorization': authHeader
  }
});
const devices = await response.json();
```

### Paso 3: Obtener Posiciones

```javascript
// Opción A: Obtener últimas posiciones de todos los dispositivos
const positionsResponse = await fetch('http://localhost:8082/api/positions', {
  headers: {
    'Authorization': authHeader
  }
});
const positions = await positionsResponse.json();

// Opción B: Obtener posición de un dispositivo específico
const deviceId = devices[0].id;
const positionResponse = await fetch(
  `http://localhost:8082/api/positions?deviceId=${deviceId}`,
  {
    headers: {
      'Authorization': authHeader
    }
  }
);
const devicePosition = await positionResponse.json();
```

### Paso 4: Combinar Datos para el Mapa

```javascript
// Crear un mapa de deviceId -> Position para acceso rápido
const positionMap = new Map();
positions.forEach(position => {
  positionMap.set(position.deviceId, position);
});

// Combinar dispositivos con sus posiciones
const devicesWithPositions = devices.map(device => ({
  ...device,
  position: positionMap.get(device.id) || null
}));

// Filtrar solo dispositivos con posición válida
const devicesOnMap = devicesWithPositions.filter(
  device => device.position && device.position.valid
);
```

### Paso 5: Mostrar en el Mapa

```javascript
// Ejemplo con Leaflet
devicesOnMap.forEach(device => {
  const marker = L.marker([
    device.position.latitude,
    device.position.longitude
  ]).addTo(map);
  
  marker.bindPopup(`
    <b>${device.name}</b><br>
    Estado: ${device.status}<br>
    Velocidad: ${device.position.speed} knots<br>
    Última actualización: ${new Date(device.position.fixTime).toLocaleString()}
  `);
});
```

---

## 📊 Estructura de Datos

### Device (Dispositivo)

```typescript
interface Device {
  id: number;
  name: string;
  uniqueId: string;
  status: "online" | "offline" | "unknown";
  lastUpdate: string; // ISO 8601
  positionId: number;
  disabled: boolean;
  model?: string;
  phone?: string;
  contact?: string;
  category?: string;
  groupId: number;
  attributes: Record<string, any>;
}
```

### Position (Posición)

```typescript
interface Position {
  id: number;
  deviceId: number;
  protocol: string;
  deviceTime: string; // ISO 8601
  fixTime: string; // ISO 8601
  serverTime: string; // ISO 8601
  outdated: boolean;
  valid: boolean;
  latitude: number; // -90 a 90
  longitude: number; // -180 a 180
  altitude: number; // metros
  speed: number; // knots
  course: number; // grados (0-360)
  address?: string;
  accuracy: number;
  network?: any;
  attributes: Record<string, any>;
}
```

---

## 💻 Ejemplos de Código

### JavaScript/TypeScript (Fetch API)

```typescript
class TraccarClient {
  private baseUrl: string;
  private authHeader: string;

  constructor(baseUrl: string, email: string, password: string) {
    this.baseUrl = baseUrl;
    const credentials = btoa(`${email}:${password}`);
    this.authHeader = `Basic ${credentials}`;
  }

  async getDevices(): Promise<Device[]> {
    const response = await fetch(`${this.baseUrl}/api/devices`, {
      headers: {
        'Authorization': this.authHeader
      }
    });
    if (!response.ok) {
      throw new Error(`Error: ${response.status}`);
    }
    return response.json();
  }

  async getPositions(deviceId?: number, from?: Date, to?: Date): Promise<Position[]> {
    let url = `${this.baseUrl}/api/positions`;
    const params = new URLSearchParams();
    
    if (deviceId) params.append('deviceId', deviceId.toString());
    if (from) params.append('from', from.toISOString());
    if (to) params.append('to', to.toISOString());
    
    if (params.toString()) {
      url += `?${params.toString()}`;
    }

    const response = await fetch(url, {
      headers: {
        'Authorization': this.authHeader
      }
    });
    if (!response.ok) {
      throw new Error(`Error: ${response.status}`);
    }
    return response.json();
  }

  async getDevicesWithPositions(): Promise<Array<Device & { position: Position | null }>> {
    const [devices, positions] = await Promise.all([
      this.getDevices(),
      this.getPositions()
    ]);

    const positionMap = new Map<number, Position>();
    positions.forEach(position => {
      positionMap.set(position.deviceId, position);
    });

    return devices.map(device => ({
      ...device,
      position: positionMap.get(device.id) || null
    }));
  }
}

// Uso
const client = new TraccarClient('http://localhost:8082', 'admin@example.com', 'admin');
const devicesWithPositions = await client.getDevicesWithPositions();

// Mostrar en mapa
devicesWithPositions.forEach(device => {
  if (device.position && device.position.valid) {
    console.log(`${device.name}: ${device.position.latitude}, ${device.position.longitude}`);
  }
});
```

### Python (requests)

```python
import requests
from typing import List, Dict, Optional
from datetime import datetime

class TraccarClient:
    def __init__(self, base_url: str, email: str, password: str):
        self.base_url = base_url
        self.auth = (email, password)
    
    def get_devices(self) -> List[Dict]:
        """Obtiene todos los dispositivos del usuario"""
        response = requests.get(
            f"{self.base_url}/api/devices",
            auth=self.auth
        )
        response.raise_for_status()
        return response.json()
    
    def get_positions(
        self,
        device_id: Optional[int] = None,
        from_date: Optional[datetime] = None,
        to_date: Optional[datetime] = None
    ) -> List[Dict]:
        """Obtiene las posiciones de los dispositivos"""
        params = {}
        if device_id:
            params['deviceId'] = device_id
        if from_date:
            params['from'] = from_date.isoformat() + 'Z'
        if to_date:
            params['to'] = to_date.isoformat() + 'Z'
        
        response = requests.get(
            f"{self.base_url}/api/positions",
            auth=self.auth,
            params=params
        )
        response.raise_for_status()
        return response.json()
    
    def get_devices_with_positions(self) -> List[Dict]:
        """Obtiene dispositivos con sus posiciones"""
        devices = self.get_devices()
        positions = self.get_positions()
        
        # Crear mapa de deviceId -> Position
        position_map = {pos['deviceId']: pos for pos in positions}
        
        # Combinar datos
        result = []
        for device in devices:
            device_copy = device.copy()
            device_copy['position'] = position_map.get(device['id'])
            result.append(device_copy)
        
        return result

# Uso
client = TraccarClient('http://localhost:8082', 'admin@example.com', 'admin')
devices_with_positions = client.get_devices_with_positions()

for device in devices_with_positions:
    if device.get('position') and device['position'].get('valid'):
        pos = device['position']
        print(f"{device['name']}: {pos['latitude']}, {pos['longitude']}")
```

### cURL

```bash
# Obtener dispositivos
curl -u admin@example.com:admin \
  http://localhost:8082/api/devices

# Obtener posiciones
curl -u admin@example.com:admin \
  http://localhost:8082/api/positions

# Obtener posición de un dispositivo específico
curl -u admin@example.com:admin \
  "http://localhost:8082/api/positions?deviceId=1"

# Obtener posiciones en un rango de tiempo
curl -u admin@example.com:admin \
  "http://localhost:8082/api/positions?deviceId=1&from=2025-01-01T00:00:00Z&to=2025-01-31T23:59:59Z"
```

---

## 🎨 Casos de Uso Comunes

### 1. Mostrar Todos los Dispositivos en el Mapa

```javascript
// Obtener dispositivos y posiciones
const devices = await fetch('/api/devices', { headers: { Authorization: authHeader } })
  .then(r => r.json());
const positions = await fetch('/api/positions', { headers: { Authorization: authHeader } })
  .then(r => r.json());

// Crear mapa de posiciones
const positionMap = new Map(positions.map(p => [p.deviceId, p]));

// Agregar marcadores al mapa
devices.forEach(device => {
  const position = positionMap.get(device.id);
  if (position && position.valid) {
    L.marker([position.latitude, position.longitude])
      .addTo(map)
      .bindPopup(device.name);
  }
});
```

### 2. Obtener Historial de Posiciones de un Dispositivo

```javascript
const deviceId = 1;
const from = new Date('2025-01-01');
const to = new Date('2025-01-31');

const positions = await fetch(
  `/api/positions?deviceId=${deviceId}&from=${from.toISOString()}&to=${to.toISOString()}`,
  { headers: { Authorization: authHeader } }
).then(r => r.json());

// Dibujar ruta en el mapa
const latlngs = positions
  .filter(p => p.valid)
  .map(p => [p.latitude, p.longitude]);

L.polyline(latlngs, { color: 'blue' }).addTo(map);
```

### 3. Actualizar Posiciones en Tiempo Real

```javascript
// Función para actualizar posiciones cada 30 segundos
async function updatePositions() {
  const positions = await fetch('/api/positions', {
    headers: { Authorization: authHeader }
  }).then(r => r.json());

  // Actualizar marcadores existentes o crear nuevos
  positions.forEach(position => {
    if (position.valid) {
      const marker = markers.get(position.deviceId);
      if (marker) {
        marker.setLatLng([position.latitude, position.longitude]);
      } else {
        const newMarker = L.marker([position.latitude, position.longitude])
          .addTo(map);
        markers.set(position.deviceId, newMarker);
      }
    }
  });
}

// Actualizar cada 30 segundos
setInterval(updatePositions, 30000);
```

### 4. Filtrar Dispositivos por Estado

```javascript
// Obtener solo dispositivos online
const devices = await getDevices();
const onlineDevices = devices.filter(d => d.status === 'online');

// Obtener posiciones solo de dispositivos online
const deviceIds = onlineDevices.map(d => d.id);
const allPositions = await getPositions();
const onlinePositions = allPositions.filter(p => deviceIds.includes(p.deviceId));
```

---

## ✅ Mejores Prácticas

### 1. Manejo de Errores

```javascript
try {
  const devices = await fetch('/api/devices', {
    headers: { Authorization: authHeader }
  });
  
  if (!devices.ok) {
    if (devices.status === 401) {
      throw new Error('No autorizado. Verifica tus credenciales.');
    } else if (devices.status === 403) {
      throw new Error('No tienes permiso para acceder a estos dispositivos.');
    } else {
      throw new Error(`Error del servidor: ${devices.status}`);
    }
  }
  
  const data = await devices.json();
} catch (error) {
  console.error('Error al obtener dispositivos:', error);
}
```

### 2. Validación de Posiciones

```javascript
function isValidPosition(position) {
  return (
    position &&
    position.valid &&
    position.latitude >= -90 && position.latitude <= 90 &&
    position.longitude >= -180 && position.longitude <= 180
  );
}

const validPositions = positions.filter(isValidPosition);
```

### 3. Caché de Datos

```javascript
class TraccarCache {
  constructor(ttl = 30000) { // 30 segundos por defecto
    this.cache = new Map();
    this.ttl = ttl;
  }

  get(key) {
    const item = this.cache.get(key);
    if (!item) return null;
    
    if (Date.now() - item.timestamp > this.ttl) {
      this.cache.delete(key);
      return null;
    }
    
    return item.data;
  }

  set(key, data) {
    this.cache.set(key, {
      data,
      timestamp: Date.now()
    });
  }
}

const cache = new TraccarCache(30000); // 30 segundos

async function getCachedDevices() {
  let devices = cache.get('devices');
  if (!devices) {
    devices = await fetch('/api/devices', {
      headers: { Authorization: authHeader }
    }).then(r => r.json());
    cache.set('devices', devices);
  }
  return devices;
}
```

### 4. Optimización de Peticiones

```javascript
// En lugar de hacer una petición por dispositivo:
// ❌ MAL
for (const device of devices) {
  const position = await fetch(`/api/positions?deviceId=${device.id}`);
}

// ✅ BIEN: Obtener todas las posiciones de una vez
const allPositions = await fetch('/api/positions');
const positionMap = new Map(allPositions.map(p => [p.deviceId, p]));
```

### 5. Conversión de Unidades

```javascript
// Traccar devuelve velocidad en knots, convertir a km/h
function knotsToKmh(knots) {
  return knots * 1.852;
}

// Traccar devuelve course en grados (0-360)
function degreesToCardinal(degrees) {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  return directions[Math.round(degrees / 45) % 8];
}

const speedKmh = knotsToKmh(position.speed);
const direction = degreesToCardinal(position.course);
```

---

## 🔍 Troubleshooting

### Problema: No se obtienen dispositivos

**Solución:**
- Verifica que el usuario tenga permisos sobre los dispositivos
- Verifica que la autenticación sea correcta
- Usa el parámetro `all=true` si eres admin

### Problema: No hay posiciones para los dispositivos

**Solución:**
- Verifica que los dispositivos estén enviando datos GPS
- Verifica que `position.valid === true`
- Algunos dispositivos pueden no tener posición si están offline

### Problema: Posiciones desactualizadas

**Solución:**
- Verifica el campo `lastUpdate` del dispositivo
- Verifica el campo `fixTime` de la posición
- Implementa actualización periódica (polling o WebSocket)

### Problema: Coordenadas fuera de rango

**Solución:**
- Valida que `latitude` esté entre -90 y 90
- Valida que `longitude` esté entre -180 y 180
- Verifica que `position.valid === true` antes de usar las coordenadas

---

## 🚗 Estados del Dispositivo y Detección de Movimiento

### Estados del Dispositivo GPS

Traccar tiene **3 estados principales** para los dispositivos:

#### 1. `"online"` - En Línea
- El dispositivo está conectado y enviando datos
- Se está recibiendo información GPS regularmente
- El dispositivo está activo y funcionando

#### 2. `"offline"` - Fuera de Línea
- El dispositivo no está conectado
- No se está recibiendo información GPS
- Puede ser por falta de señal, batería agotada, o dispositivo apagado

#### 3. `"unknown"` - Estado Desconocido
- El estado del dispositivo no se puede determinar
- Puede ser una conexión intermitente o un problema de comunicación

**Ejemplo de uso:**

```javascript
const device = {
  id: 1,
  name: "Mi Vehículo",
  status: "online",  // "online" | "offline" | "unknown"
  lastUpdate: "2025-01-15T10:30:00.000Z"
};

// Verificar estado
if (device.status === "online") {
  console.log("Dispositivo conectado y funcionando");
} else if (device.status === "offline") {
  console.log("Dispositivo desconectado");
} else {
  console.log("Estado desconocido");
}
```

---

### 🔄 Detección de Movimiento

Hay **varias formas** de determinar si un vehículo está en movimiento:

#### 1. Por Velocidad (Método más Simple)

```javascript
const position = {
  speed: 15.5,  // en knots (nudos)
  valid: true
};

// Convertir knots a km/h (1 knot = 1.852 km/h)
const speedKmh = position.speed * 1.852;

// Si la velocidad es mayor a un umbral, está en movimiento
const isMoving = speedKmh > 5; // 5 km/h como umbral

if (isMoving) {
  console.log(`Vehículo en movimiento a ${speedKmh.toFixed(2)} km/h`);
} else {
  console.log("Vehículo detenido");
}
```

#### 2. Por Atributo `motion` en Position

```javascript
const position = {
  attributes: {
    motion: true,  // true = en movimiento, false = detenido
    ignition: true,
    speed: 15.5
  }
};

// Verificar movimiento
const isMoving = position.attributes?.motion === true;

if (isMoving) {
  console.log("Vehículo en movimiento");
}
```

#### 3. Por Atributo `ignition` (Encendido del Motor)

```javascript
const position = {
  attributes: {
    ignition: true  // true = motor encendido, false = motor apagado
  }
};

// Si el motor está encendido, probablemente está en movimiento
const isMoving = position.attributes?.ignition === true;
```

#### 4. Combinando Múltiples Indicadores (Recomendado)

```javascript
function isVehicleMoving(position) {
  if (!position || !position.valid) {
    return false;
  }

  // Método 1: Por velocidad (convertir knots a km/h)
  const speedKmh = position.speed * 1.852;
  const hasSpeed = speedKmh > 3; // Umbral mínimo de 3 km/h

  // Método 2: Por atributo motion
  const hasMotion = position.attributes?.motion === true;

  // Método 3: Por encendido del motor
  const isIgnitionOn = position.attributes?.ignition === true;

  // El vehículo está en movimiento si:
  // - Tiene velocidad significativa, O
  // - El atributo motion indica movimiento, O
  // - El motor está encendido (pero solo si también hay velocidad)
  return hasSpeed || hasMotion || (isIgnitionOn && speedKmh > 0);
}

// Uso
const position = await getPosition(deviceId);
if (isVehicleMoving(position)) {
  console.log("🚗 Vehículo en movimiento");
} else {
  console.log("🛑 Vehículo detenido");
}
```

---

### 📊 Información Adicional Disponible en Position

Además de latitud y longitud, la posición contiene mucha información útil:

#### Campos Principales de Position

```typescript
interface Position {
  // Coordenadas
  latitude: number;
  longitude: number;
  altitude: number;  // metros
  
  // Movimiento
  speed: number;     // knots (nudos)
  course: number;    // dirección en grados (0-360)
  
  // Tiempo
  fixTime: string;      // Fecha/hora de la posición GPS
  deviceTime: string;   // Fecha/hora del dispositivo
  serverTime: string;   // Fecha/hora del servidor
  
  // Estado
  valid: boolean;       // Si la posición GPS es válida
  outdated: boolean;     // Si la posición está desactualizada
  
  // Dirección
  address?: string;      // Dirección geocodificada
  
  // Atributos adicionales (en attributes)
  attributes: {
    // Movimiento y Motor
    motion?: boolean;           // true/false - si está en movimiento
    ignition?: boolean;         // true/false - si el motor está encendido
    
    // GPS
    sat?: number;              // Número de satélites
    hdop?: number;            // Precisión horizontal
    pdop?: number;            // Precisión de posición
    
    // Batería y Energía
    batteryLevel?: number;     // Nivel de batería (0-100)
    battery?: number;          // Voltaje de batería
    power?: number;            // Voltaje de alimentación
    
    // Combustible
    fuel?: number;             // Nivel de combustible (litros)
    fuelLevel?: number;        // Nivel de combustible (%)
    
    // Distancia
    odometer?: number;         // Odómetro (metros)
    totalDistance?: number;    // Distancia total (metros)
    
    // Velocidad
    obdSpeed?: number;         // Velocidad desde OBD (km/h)
    speedLimit?: number;       // Límite de velocidad
    
    // Motor
    rpm?: number;              // Revoluciones por minuto
    engineLoad?: number;       // Carga del motor
    engineTemp?: number;       // Temperatura del motor
    coolantTemp?: number;      // Temperatura del refrigerante
    
    // Eventos y Alarmas
    alarm?: string;            // Tipo de alarma
    event?: string;            // Tipo de evento
    
    // Otros
    driverUniqueId?: string;   // ID del conductor
    card?: string;             // Tarjeta de identificación
  };
}
```

---

### 💡 Ejemplos Prácticos

#### Ejemplo 1: Mostrar Estado Completo del Vehículo

```javascript
async function getVehicleStatus(deviceId) {
  const [device, position] = await Promise.all([
    fetch(`/api/devices/${deviceId}`, { headers: { Authorization: authHeader } })
      .then(r => r.json()),
    fetch(`/api/positions?deviceId=${deviceId}`, { headers: { Authorization: authHeader } })
      .then(r => r.json())
      .then(positions => positions[0]) // Última posición
  ]);

  const speedKmh = position.speed * 1.852;
  const isMoving = speedKmh > 3 || position.attributes?.motion === true;
  
  return {
    name: device.name,
    status: device.status,  // "online" | "offline" | "unknown"
    isMoving: isMoving,
    speed: speedKmh,
    location: {
      lat: position.latitude,
      lng: position.longitude,
      address: position.address
    },
    engine: {
      ignition: position.attributes?.ignition || false,
      rpm: position.attributes?.rpm || 0
    },
    battery: {
      level: position.attributes?.batteryLevel || 0,
      voltage: position.attributes?.battery || 0
    },
    fuel: {
      level: position.attributes?.fuelLevel || 0,
      liters: position.attributes?.fuel || 0
    },
    lastUpdate: position.fixTime
  };
}

// Uso
const status = await getVehicleStatus(1);
console.log(`
  Vehículo: ${status.name}
  Estado: ${status.status}
  En movimiento: ${status.isMoving ? 'Sí' : 'No'}
  Velocidad: ${status.speed.toFixed(2)} km/h
  Motor: ${status.engine.ignition ? 'Encendido' : 'Apagado'}
  Batería: ${status.battery.level}%
  Combustible: ${status.fuel.level}%
`);
```

#### Ejemplo 2: Filtrar Solo Vehículos en Movimiento

```javascript
async function getMovingVehicles() {
  const [devices, positions] = await Promise.all([
    fetch('/api/devices', { headers: { Authorization: authHeader } })
      .then(r => r.json()),
    fetch('/api/positions', { headers: { Authorization: authHeader } })
      .then(r => r.json())
  ]);

  const positionMap = new Map(positions.map(p => [p.deviceId, p]));

  return devices
    .map(device => ({
      device,
      position: positionMap.get(device.id)
    }))
    .filter(({ device, position }) => {
      if (!position || !position.valid) return false;
      
      const speedKmh = position.speed * 1.852;
      const isMoving = speedKmh > 3 || position.attributes?.motion === true;
      
      return isMoving && device.status === 'online';
    })
    .map(({ device, position }) => ({
      id: device.id,
      name: device.name,
      speed: position.speed * 1.852,
      location: [position.latitude, position.longitude]
    }));
}

// Uso
const movingVehicles = await getMovingVehicles();
console.log(`Hay ${movingVehicles.length} vehículos en movimiento`);
```

#### Ejemplo 3: Monitoreo en Tiempo Real

```javascript
async function monitorVehicleMovement(deviceId, callback) {
  const checkMovement = async () => {
    const position = await fetch(
      `/api/positions?deviceId=${deviceId}`,
      { headers: { Authorization: authHeader } }
    ).then(r => r.json()).then(positions => positions[0]);

    if (position && position.valid) {
      const speedKmh = position.speed * 1.852;
      const isMoving = speedKmh > 3 || position.attributes?.motion === true;
      
      callback({
        isMoving,
        speed: speedKmh,
        location: [position.latitude, position.longitude],
        timestamp: position.fixTime
      });
    }
  };

  // Verificar cada 10 segundos
  setInterval(checkMovement, 10000);
  checkMovement(); // Primera verificación inmediata
}

// Uso
monitorVehicleMovement(1, (status) => {
  if (status.isMoving) {
    console.log(`🚗 En movimiento a ${status.speed.toFixed(2)} km/h`);
  } else {
    console.log('🛑 Vehículo detenido');
  }
});
```

---

### 📋 Resumen de Estados y Movimiento

| Campo/Atributo | Tipo | Descripción | Valores Posibles |
|----------------|------|-------------|------------------|
| `device.status` | string | Estado de conexión del dispositivo | `"online"`, `"offline"`, `"unknown"` |
| `position.speed` | number | Velocidad actual | knots (nudos). Convertir a km/h: `speed * 1.852` |
| `position.attributes.motion` | boolean | Indica si está en movimiento | `true` = en movimiento, `false` = detenido |
| `position.attributes.ignition` | boolean | Estado del motor | `true` = encendido, `false` = apagado |
| `position.valid` | boolean | Si la posición GPS es válida | `true` = válida, `false` = inválida |
| `position.course` | number | Dirección del movimiento | 0-360 grados (0=Norte, 90=Este, 180=Sur, 270=Oeste) |

**Recomendación:** Para determinar si un vehículo está en movimiento, usa una combinación de:
1. Velocidad > 3 km/h
2. Atributo `motion === true`
3. Atributo `ignition === true` (si está disponible)

---

## 📚 Referencias

- **Bruno Collection:** `bruno-collection/04 - Devices/` y `bruno-collection/05 - Positions/`
- **Código Fuente:**
  - `src/main/java/org/traccar/api/resource/DeviceResource.java`
  - `src/main/java/org/traccar/api/resource/PositionResource.java`
  - `src/main/java/org/traccar/model/Device.java`
  - `src/main/java/org/traccar/model/Position.java`
- **Documentación de Autenticación:** `bruno-collection/COMO_FUNCIONA_AUTENTICACION.md`

---

## 📝 Notas Adicionales

1. **Permisos:** Los usuarios solo pueden ver dispositivos a los que tienen permiso. Los admins pueden ver todos los dispositivos usando `?all=true`.

2. **Rendimiento:** Para muchos dispositivos, es más eficiente obtener todas las posiciones de una vez que hacer una petición por dispositivo.

3. **Tiempo Real:** Para actualizaciones en tiempo real, considera usar WebSockets o polling periódico (cada 10-30 segundos).

4. **Geocodificación:** El campo `address` puede estar vacío si el geocodificador no está configurado o si la posición es muy reciente.

5. **Atributos Adicionales:** El campo `attributes` en Position puede contener información adicional como nivel de batería, número de satélites, estado de encendido, etc.

6. **Conversión de Velocidad:** Traccar almacena la velocidad en **knots (nudos)**. Para convertir a km/h: `kmh = knots * 1.852`. Para convertir a mph: `mph = knots * 1.151`.

7. **Detección de Movimiento:** No todos los dispositivos GPS envían el atributo `motion`. En esos casos, usa la velocidad (`speed`) como indicador principal.

---

**Última actualización:** 2025-01-15

