# 📱 Flujo Completo: Crear, Conectar, Editar y Eliminar Dispositivos GPS

Este documento explica el flujo completo para gestionar dispositivos GPS en Traccar, desde la creación hasta la eliminación, incluyendo cómo conectarlos.

---

## 📋 Tabla de Contenidos

1. [Crear un Nuevo Dispositivo](#1-crear-un-nuevo-dispositivo)
2. [Atributos y Extras del Dispositivo](#2-atributos-y-extras-del-dispositivo)
3. [Subir Imagen del Dispositivo](#3-subir-imagen-del-dispositivo)
4. [Flujo Completo desde el Frontend](#4-flujo-completo-desde-el-frontend)
5. [Conectar el Dispositivo GPS](#5-conectar-el-dispositivo-gps)
6. [Editar un Dispositivo](#6-editar-un-dispositivo)
7. [Eliminar un Dispositivo](#7-eliminar-un-dispositivo)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Crear un Nuevo Dispositivo

### 📝 Campos Requeridos y Opcionales

#### **Campos Obligatorios:**
- `name`: Nombre descriptivo del dispositivo (ej: "Vehículo 1", "Carro de Juan")
- `uniqueId`: Identificador único del dispositivo GPS (IMEI, número de serie, etc.)

#### **Campos Opcionales:**
- `status`: Estado inicial (`"online"`, `"offline"`, `"unknown"`) - Por defecto: `"offline"`
- `disabled`: Si el dispositivo está deshabilitado (`true`/`false`) - Por defecto: `false`
- `phone`: Número de teléfono para comandos SMS
- `model`: Modelo del dispositivo (ej: "GT06", "TK103")
- `contact`: Información de contacto del responsable
- `category`: Categoría libre (ej: "Vehicle", "Person", "Asset")
- `groupId`: ID del grupo al que pertenece
- `attributes`: Objetos JSON con atributos personalizados

---

### 🔧 Método 1: Usando la API REST

#### **Endpoint:**
```
POST /api/devices
```

#### **Ejemplo con curl:**
```bash
curl -X POST http://localhost:8082/api/devices \
  -u "admin:admin" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Vehículo Principal",
    "uniqueId": "123456789012345",
    "status": "offline",
    "disabled": false,
    "phone": "+1234567890",
    "model": "GT06",
    "contact": "Juan Pérez",
    "category": "Vehicle",
    "attributes": {}
  }'
```

#### **Ejemplo con JavaScript/Fetch:**
```javascript
async function createDevice(deviceData) {
  const response = await fetch('http://localhost:8082/api/devices', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ' + btoa('admin:admin')
    },
    body: JSON.stringify({
      name: deviceData.name,
      uniqueId: deviceData.uniqueId,
      status: 'offline',
      disabled: false,
      phone: deviceData.phone || null,
      model: deviceData.model || null,
      contact: deviceData.contact || null,
      category: deviceData.category || 'Vehicle',
      attributes: {}
    })
  });

  if (response.ok) {
    const device = await response.json();
    console.log('Dispositivo creado:', device);
    return device;
  } else {
    const error = await response.text();
    throw new Error(`Error al crear dispositivo: ${error}`);
  }
}

// Uso
createDevice({
  name: 'Mi Vehículo',
  uniqueId: '123456789012345',
  phone: '+1234567890',
  model: 'GT06'
});
```

#### **Ejemplo con Bruno:**
```bru
meta {
  name: Create Device
  type: http
}

post {
  url: {{baseUrl}}/devices
  body: json
  auth: basic
}

headers {
  Content-Type: application/json
}

body:json {
  {
    "name": "Vehículo Principal",
    "uniqueId": "123456789012345",
    "status": "offline",
    "disabled": false,
    "phone": "+1234567890",
    "model": "GT06",
    "contact": "Juan Pérez",
    "category": "Vehicle",
    "attributes": {}
  }
}

auth:basic {
  username: {{email}}
  password: {{password}}
}
```

---

### 🖥️ Método 2: Usando la Interfaz Web

1. **Inicia sesión** en Traccar: `http://localhost:8082/login`
2. Ve a **Settings** → **Devices**
3. Haz clic en **Add** (botón verde)
4. Completa el formulario:
   - **Name**: Nombre del dispositivo
   - **Unique ID**: Identificador único (IMEI)
   - **Phone**: (Opcional) Número de teléfono
   - **Model**: (Opcional) Modelo del dispositivo
   - **Contact**: (Opcional) Contacto responsable
   - **Category**: (Opcional) Categoría
5. Haz clic en **Save**

---

### ⚠️ Errores Comunes al Crear

#### **Error: `Duplicate entry 'XXX' for key 'tc_devices.uniqueid'`**

**Causa:** Ya existe un dispositivo con ese `uniqueId`.

**Solución:**
1. Verifica si el dispositivo existe:
   ```bash
   curl -u admin:admin "http://localhost:8082/api/devices?uniqueId=123456789012345"
   ```
2. Si existe, elimínalo primero o usa un `uniqueId` diferente.

#### **Error: `HTTP 401 Unauthorized`**

**Causa:** Credenciales incorrectas o sesión expirada.

**Solución:**
- Verifica que las credenciales sean correctas
- Si usas la interfaz web, cierra sesión y vuelve a iniciar sesión
- Si usas la API, verifica el header `Authorization`

---

### ✅ Respuesta Exitosa

```json
{
  "id": 1,
  "name": "Vehículo Principal",
  "uniqueId": "123456789012345",
  "status": "offline",
  "disabled": false,
  "lastUpdate": null,
  "positionId": 0,
  "phone": "+1234567890",
  "model": "GT06",
  "contact": "Juan Pérez",
  "category": "Vehicle",
  "attributes": {}
}
```

**Nota:** El `id` es asignado automáticamente por Traccar.

---

## 2. Atributos y Extras del Dispositivo

Los dispositivos en Traccar tienen dos formas de almacenar información adicional:

1. **Campos estándar** (`model`, `contact`, `category`, `phone`)
2. **Atributos personalizados** (`attributes`) - Un objeto JSON flexible que puede contener cualquier dato

### 📦 Campos Estándar (Extras)

Estos campos están directamente en el modelo del dispositivo:

| Campo | Tipo | Descripción | Ejemplo |
|-------|------|-------------|---------|
| `model` | `string` | Modelo del dispositivo GPS o del vehículo | `"GT06"`, `"Toyota Corolla"` |
| `contact` | `string` | Contacto responsable | `"Juan Pérez"`, `"juan@email.com"` |
| `category` | `string` | Categoría del vehículo/dispositivo | `"Auto"`, `"Bus"`, `"Camión"`, `"Moto"` |
| `phone` | `string` | Número de teléfono para comandos SMS | `"+1234567890"` |

### 🎯 Atributos Personalizados (`attributes`)

Los `attributes` son un objeto JSON (`Map<String, Object>`) que permite almacenar cualquier información personalizada. Es especialmente útil para:

- **Información del vehículo:** placa, año, color, marca, etc.
- **Configuración del dispositivo:** límite de velocidad, alertas, etc.
- **Datos de negocio:** cliente, ruta, conductor, etc.

#### **Atributos Comunes para Vehículos:**

```json
{
  "attributes": {
    "speedLimit": 80.0,           // Límite de velocidad en knots (nudos)
    "placa": "ABC-123",           // Placa del vehículo
    "marca": "Toyota",            // Marca del vehículo
    "año": 2020,                  // Año del vehículo
    "color": "Blanco",            // Color del vehículo
    "tipoVehiculo": "Auto",       // Tipo: Auto, Bus, Camión, Moto
    "numeroMotor": "123456789",   // Número de motor
    "numeroChasis": "987654321",  // Número de chasis
    "combustible": "Gasolina",    // Tipo de combustible
    "capacidadTanque": 50.0       // Capacidad del tanque en litros
  }
}
```

---

### 🚗 Ejemplo Completo: Crear Dispositivo con Todos los Campos

#### **Estructura de Datos Recomendada:**

```json
{
  "name": "Vehículo Principal",
  "uniqueId": "123456789012345",
  "status": "offline",
  "disabled": false,
  "phone": "+1234567890",
  "model": "Toyota Corolla 2020",      // Modelo del vehículo
  "contact": "Juan Pérez",             // Contacto responsable
  "category": "Auto",                  // Categoría: Auto, Bus, Camión, Moto
  "attributes": {
    "speedLimit": 80.0,                // Límite de velocidad (knots)
    "placa": "ABC-123",                // Placa del vehículo
    "marca": "Toyota",                 // Marca
    "año": 2020,                       // Año
    "color": "Blanco",                 // Color
    "tipoVehiculo": "Auto",           // Tipo de vehículo
    "numeroMotor": "123456789",        // Número de motor
    "numeroChasis": "987654321"        // Número de chasis
  }
}
```

#### **Ejemplo con curl:**

```bash
curl -X POST http://localhost:8082/api/devices \
  -u "admin:admin" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Vehículo Principal",
    "uniqueId": "123456789012345",
    "status": "offline",
    "disabled": false,
    "phone": "+1234567890",
    "model": "Toyota Corolla 2020",
    "contact": "Juan Pérez",
    "category": "Auto",
    "attributes": {
      "speedLimit": 80.0,
      "placa": "ABC-123",
      "marca": "Toyota",
      "año": 2020,
      "color": "Blanco",
      "tipoVehiculo": "Auto",
      "numeroMotor": "123456789",
      "numeroChasis": "987654321"
    }
  }'
```

---

### ⚡ Límite de Velocidad (`speedLimit`)

El límite de velocidad es un atributo especial que Traccar usa para generar eventos de exceso de velocidad.

#### **Formato:**
- **Tipo:** `number` (double)
- **Unidad:** **Knots (nudos)** - No kilómetros por hora
- **Clave en attributes:** `"speedLimit"`

#### **Conversión de Unidades:**

```javascript
// Convertir km/h a knots (nudos)
function kmhToKnots(kmh) {
  return kmh / 1.852;  // 1 knot = 1.852 km/h
}

// Convertir knots a km/h
function knotsToKmh(knots) {
  return knots * 1.852;
}

// Ejemplo: 80 km/h = 43.2 knots
const speedLimitKmh = 80;
const speedLimitKnots = kmhToKnots(speedLimitKmh); // 43.2
```

#### **Ejemplo de Configuración:**

```json
{
  "attributes": {
    "speedLimit": 43.2  // 80 km/h en knots
  }
}
```

#### **Cómo Funciona:**

1. Traccar compara la velocidad del vehículo con el `speedLimit`
2. Si la velocidad excede el límite, genera un evento `overspeed`
3. El evento se puede usar para notificaciones y alertas

---

### 📋 Categorías de Vehículos Recomendadas

Para el campo `category`, puedes usar estas categorías estándar:

| Categoría | Descripción | Ejemplo |
|-----------|-------------|---------|
| `"Auto"` | Automóvil de pasajeros | Sedán, Hatchback |
| `"Bus"` | Autobús o buseta | Bus urbano, Bus escolar |
| `"Camión"` | Camión de carga | Camión de carga pesada |
| `"Moto"` | Motocicleta | Moto, Scooter |
| `"Taxi"` | Taxi | Taxi, Uber |
| `"Ambulancia"` | Vehículo de emergencia | Ambulancia |
| `"Policía"` | Vehículo policial | Patrulla |
| `"Otro"` | Otro tipo de vehículo | - |

---

### 🔧 Actualizar Atributos

Para actualizar solo los atributos sin modificar otros campos:

```bash
# 1. Obtener el dispositivo actual
curl -u admin:admin "http://localhost:8082/api/devices/1" > device.json

# 2. Modificar los atributos en device.json
# 3. Actualizar el dispositivo
curl -X PUT http://localhost:8082/api/devices/1 \
  -u "admin:admin" \
  -H "Content-Type: application/json" \
  -d @device.json
```

O con JavaScript:

```javascript
async function updateDeviceAttributes(deviceId, newAttributes) {
  // 1. Obtener dispositivo actual
  const deviceResponse = await fetch(`http://localhost:8082/api/devices/${deviceId}`, {
    headers: {
      'Authorization': 'Basic ' + btoa('admin:admin')
    }
  });
  const device = await deviceResponse.json();

  // 2. Fusionar atributos nuevos con los existentes
  const updatedAttributes = {
    ...device.attributes,
    ...newAttributes
  };

  // 3. Actualizar dispositivo
  const updateResponse = await fetch(`http://localhost:8082/api/devices/${deviceId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ' + btoa('admin:admin')
    },
    body: JSON.stringify({
      ...device,
      attributes: updatedAttributes
    })
  });

  return await updateResponse.json();
}

// Uso: Actualizar solo la placa y el límite de velocidad
updateDeviceAttributes(1, {
  placa: 'XYZ-789',
  speedLimit: 90.0
});
```

---

## 3. Subir Imagen del Dispositivo

Traccar permite subir una imagen para cada dispositivo, que se muestra en la interfaz web y puede ser útil para identificar visualmente el vehículo.

### 📸 Endpoint para Subir Imagen

#### **Endpoint:**
```
POST /api/devices/{id}/image
```

#### **Características:**
- **Content-Type:** `image/*` (jpeg, png, gif, webp, svg)
- **Límite de tamaño:** 500 KB (500,000 bytes)
- **Formato de guardado:** `device.{extension}` en `media/{uniqueId}/`
- **Autenticación:** Requerida (Basic Auth o Token)

---

### 🔧 Ejemplo con curl:

```bash
# Subir imagen JPEG
curl -X POST http://localhost:8082/api/devices/1/image \
  -u "admin:admin" \
  -H "Content-Type: image/jpeg" \
  --data-binary @vehiculo.jpg
```

#### **Con FormData (multipart/form-data):**

```bash
curl -X POST http://localhost:8082/api/devices/1/image \
  -u "admin:admin" \
  -F "file=@vehiculo.jpg"
```

---

### 💻 Ejemplo con JavaScript/Fetch:

```javascript
async function uploadDeviceImage(deviceId, imageFile) {
  const formData = new FormData();
  formData.append('file', imageFile);

  const response = await fetch(`http://localhost:8082/api/devices/${deviceId}/image`, {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + btoa('admin:admin')
      // NO incluyas Content-Type, el navegador lo hace automáticamente con FormData
    },
    body: formData
  });

  if (response.ok) {
    const filename = await response.text();
    console.log('Imagen subida:', filename);
    return filename;
  } else {
    const error = await response.text();
    throw new Error(`Error al subir imagen: ${error}`);
  }
}

// Uso con input file
const fileInput = document.querySelector('input[type="file"]');
fileInput.addEventListener('change', async (e) => {
  const file = e.target.files[0];
  if (file) {
    try {
      await uploadDeviceImage(1, file);
      alert('Imagen subida exitosamente');
    } catch (error) {
      alert('Error: ' + error.message);
    }
  }
});
```

#### **Con FileReader (para preview):**

```javascript
async function uploadDeviceImageWithPreview(deviceId, imageFile) {
  // Validar tipo de archivo
  const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
  if (!validTypes.includes(imageFile.type)) {
    throw new Error('Tipo de archivo no válido. Use JPEG, PNG, GIF o WebP');
  }

  // Validar tamaño (500 KB)
  const maxSize = 500 * 1024; // 500 KB
  if (imageFile.size > maxSize) {
    throw new Error('El archivo es demasiado grande. Máximo 500 KB');
  }

  // Crear preview
  const reader = new FileReader();
  reader.onload = (e) => {
    const preview = document.getElementById('image-preview');
    preview.src = e.target.result;
    preview.style.display = 'block';
  };
  reader.readAsDataURL(imageFile);

  // Subir imagen
  return await uploadDeviceImage(deviceId, imageFile);
}
```

---

### 📱 Ejemplo con React:

```jsx
import React, { useState } from 'react';

function DeviceImageUpload({ deviceId }) {
  const [uploading, setUploading] = useState(false);
  const [preview, setPreview] = useState(null);
  const [error, setError] = useState(null);

  const handleFileChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    // Validar tipo
    if (!file.type.startsWith('image/')) {
      setError('Por favor seleccione una imagen');
      return;
    }

    // Validar tamaño (500 KB)
    if (file.size > 500 * 1024) {
      setError('La imagen es demasiado grande. Máximo 500 KB');
      return;
    }

    // Crear preview
    const reader = new FileReader();
    reader.onload = (e) => setPreview(e.target.result);
    reader.readAsDataURL(file);

    // Subir imagen
    setUploading(true);
    setError(null);

    try {
      const formData = new FormData();
      formData.append('file', file);

      const response = await fetch(`http://localhost:8082/api/devices/${deviceId}/image`, {
        method: 'POST',
        headers: {
          'Authorization': 'Basic ' + btoa('admin:admin')
        },
        body: formData
      });

      if (response.ok) {
        const filename = await response.text();
        alert(`Imagen subida: ${filename}`);
      } else {
        const errorText = await response.text();
        throw new Error(errorText);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div>
      <input
        type="file"
        accept="image/*"
        onChange={handleFileChange}
        disabled={uploading}
      />
      {preview && (
        <img
          src={preview}
          alt="Preview"
          style={{ maxWidth: '200px', marginTop: '10px' }}
        />
      )}
      {uploading && <p>Subiendo...</p>}
      {error && <p style={{ color: 'red' }}>{error}</p>}
    </div>
  );
}
```

---

### 🔗 Obtener URL de la Imagen

Después de subir la imagen, se guarda en:
```
media/{uniqueId}/device.{extension}
```

Y se puede acceder vía:
```
http://localhost:8082/api/media/{uniqueId}/device.{extension}
```

#### **Ejemplo de función para obtener URL:**

```javascript
function getDeviceImageUrl(device) {
  if (!device || !device.uniqueId) {
    return null;
  }
  // Asumimos que la imagen es JPEG (puedes verificar la extensión real)
  return `http://localhost:8082/api/media/${device.uniqueId}/device.jpg`;
}

// Uso
const device = {
  id: 1,
  uniqueId: '123456789012345',
  name: 'Mi Vehículo'
};

const imageUrl = getDeviceImageUrl(device);
// Resultado: http://localhost:8082/api/media/123456789012345/device.jpg
```

---

### ⚠️ Errores Comunes

#### **Error: `Image size limit exceeded`**

**Causa:** La imagen es mayor a 500 KB.

**Solución:**
- Comprime la imagen antes de subirla
- Usa herramientas como `jpegoptim`, `pngquant`, o servicios online
- Redimensiona la imagen si es necesario

#### **Error: `Unsupported image type`**

**Causa:** El tipo de imagen no es soportado.

**Solución:**
- Usa solo: JPEG, PNG, GIF, WebP, o SVG
- Verifica el `Content-Type` del archivo

#### **Error: `HTTP 404 Not Found`**

**Causa:** El dispositivo no existe o no tienes permisos.

**Solución:**
- Verifica que el `deviceId` sea correcto
- Verifica que tengas permisos sobre el dispositivo

---

## 4. Flujo Completo desde el Frontend

Esta sección explica cómo implementar un formulario completo en el frontend para crear un dispositivo con todos los campos necesarios, incluyendo información del vehículo e imagen.

### 🎨 Estructura del Formulario

El formulario debe incluir:

1. **Información del Dispositivo GPS:**
   - Nombre del dispositivo
   - Unique ID (IMEI)
   - Modelo del dispositivo GPS
   - Teléfono (para comandos SMS)

2. **Información del Vehículo:**
   - Placa
   - Marca
   - Modelo del vehículo
   - Año
   - Color
   - Categoría (Auto, Bus, Camión, Moto, etc.)
   - Número de motor (opcional)
   - Número de chasis (opcional)

3. **Configuración:**
   - Límite de velocidad (km/h)
   - Contacto responsable

4. **Imagen:**
   - Foto del vehículo

---

### 💻 Ejemplo Completo con React + TypeScript

```typescript
import React, { useState } from 'react';

interface VehicleFormData {
  // Dispositivo GPS
  deviceName: string;
  uniqueId: string;
  deviceModel: string;
  phone: string;

  // Vehículo
  placa: string;
  marca: string;
  vehiculoModelo: string;
  año: number;
  color: string;
  categoria: 'Auto' | 'Bus' | 'Camión' | 'Moto' | 'Taxi' | 'Otro';
  numeroMotor?: string;
  numeroChasis?: string;

  // Configuración
  speedLimitKmh: number;
  contact: string;

  // Imagen
  image?: File;
}

const API_BASE_URL = 'http://localhost:8082/api';
const API_USER = 'admin';
const API_PASS = 'admin';

function CreateDeviceForm() {
  const [formData, setFormData] = useState<VehicleFormData>({
    deviceName: '',
    uniqueId: '',
    deviceModel: '',
    phone: '',
    placa: '',
    marca: '',
    vehiculoModelo: '',
    año: new Date().getFullYear(),
    color: '',
    categoria: 'Auto',
    speedLimitKmh: 80,
    contact: ''
  });

  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Convertir km/h a knots
  const kmhToKnots = (kmh: number): number => {
    return kmh / 1.852;
  };

  // Manejar cambios en el formulario
  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'año' || name === 'speedLimitKmh' ? Number(value) : value
    }));
  };

  // Manejar selección de imagen
  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      // Validar tipo
      if (!file.type.startsWith('image/')) {
        setError('Por favor seleccione una imagen');
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
        setImagePreview(e.target?.result as string);
      };
      reader.readAsDataURL(file);

      setFormData(prev => ({ ...prev, image: file }));
      setError(null);
    }
  };

  // Crear dispositivo completo
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      // 1. Preparar datos del dispositivo
      const deviceData = {
        name: formData.deviceName,
        uniqueId: formData.uniqueId,
        status: 'offline',
        disabled: false,
        phone: formData.phone || null,
        model: formData.deviceModel || null,
        contact: formData.contact || null,
        category: formData.categoria,
        attributes: {
          speedLimit: kmhToKnots(formData.speedLimitKmh),
          placa: formData.placa,
          marca: formData.marca,
          año: formData.año,
          color: formData.color,
          tipoVehiculo: formData.categoria,
          numeroMotor: formData.numeroMotor || null,
          numeroChasis: formData.numeroChasis || null
        }
      };

      // 2. Crear dispositivo
      const deviceResponse = await fetch(`${API_BASE_URL}/devices`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
        },
        body: JSON.stringify(deviceData)
      });

      if (!deviceResponse.ok) {
        const errorText = await deviceResponse.text();
        throw new Error(`Error al crear dispositivo: ${errorText}`);
      }

      const device = await deviceResponse.json();
      console.log('Dispositivo creado:', device);

      // 3. Subir imagen si existe
      if (formData.image && device.id) {
        const formDataImage = new FormData();
        formDataImage.append('file', formData.image);

        const imageResponse = await fetch(`${API_BASE_URL}/devices/${device.id}/image`, {
          method: 'POST',
          headers: {
            'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
          },
          body: formDataImage
        });

        if (!imageResponse.ok) {
          console.warn('Dispositivo creado pero error al subir imagen');
        } else {
          const filename = await imageResponse.text();
          console.log('Imagen subida:', filename);
        }
      }

      alert('Dispositivo creado exitosamente');
      
      // Resetear formulario
      setFormData({
        deviceName: '',
        uniqueId: '',
        deviceModel: '',
        phone: '',
        placa: '',
        marca: '',
        vehiculoModelo: '',
        año: new Date().getFullYear(),
        color: '',
        categoria: 'Auto',
        speedLimitKmh: 80,
        contact: ''
      });
      setImagePreview(null);

    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} style={{ maxWidth: '600px', margin: '0 auto' }}>
      <h2>Crear Nuevo Dispositivo y Vehículo</h2>

      {/* Información del Dispositivo GPS */}
      <fieldset>
        <legend>Información del Dispositivo GPS</legend>
        
        <div>
          <label>
            Nombre del Dispositivo: *
            <input
              type="text"
              name="deviceName"
              value={formData.deviceName}
              onChange={handleChange}
              required
            />
          </label>
        </div>

        <div>
          <label>
            Unique ID (IMEI): *
            <input
              type="text"
              name="uniqueId"
              value={formData.uniqueId}
              onChange={handleChange}
              required
              pattern="[0-9]{10,15}"
              title="Debe ser un número de 10 a 15 dígitos"
            />
          </label>
        </div>

        <div>
          <label>
            Modelo del Dispositivo GPS:
            <input
              type="text"
              name="deviceModel"
              value={formData.deviceModel}
              onChange={handleChange}
              placeholder="Ej: GT06, TK103"
            />
          </label>
        </div>

        <div>
          <label>
            Teléfono (SMS):
            <input
              type="tel"
              name="phone"
              value={formData.phone}
              onChange={handleChange}
              placeholder="+1234567890"
            />
          </label>
        </div>
      </fieldset>

      {/* Información del Vehículo */}
      <fieldset>
        <legend>Información del Vehículo</legend>

        <div>
          <label>
            Placa: *
            <input
              type="text"
              name="placa"
              value={formData.placa}
              onChange={handleChange}
              required
              style={{ textTransform: 'uppercase' }}
            />
          </label>
        </div>

        <div>
          <label>
            Marca: *
            <input
              type="text"
              name="marca"
              value={formData.marca}
              onChange={handleChange}
              required
            />
          </label>
        </div>

        <div>
          <label>
            Modelo del Vehículo: *
            <input
              type="text"
              name="vehiculoModelo"
              value={formData.vehiculoModelo}
              onChange={handleChange}
              required
            />
          </label>
        </div>

        <div>
          <label>
            Año: *
            <input
              type="number"
              name="año"
              value={formData.año}
              onChange={handleChange}
              required
              min="1900"
              max={new Date().getFullYear() + 1}
            />
          </label>
        </div>

        <div>
          <label>
            Color:
            <input
              type="text"
              name="color"
              value={formData.color}
              onChange={handleChange}
            />
          </label>
        </div>

        <div>
          <label>
            Categoría: *
            <select
              name="categoria"
              value={formData.categoria}
              onChange={handleChange}
              required
            >
              <option value="Auto">Auto</option>
              <option value="Bus">Bus</option>
              <option value="Camión">Camión</option>
              <option value="Moto">Moto</option>
              <option value="Taxi">Taxi</option>
              <option value="Ambulancia">Ambulancia</option>
              <option value="Policía">Policía</option>
              <option value="Otro">Otro</option>
            </select>
          </label>
        </div>

        <div>
          <label>
            Número de Motor:
            <input
              type="text"
              name="numeroMotor"
              value={formData.numeroMotor || ''}
              onChange={handleChange}
            />
          </label>
        </div>

        <div>
          <label>
            Número de Chasis:
            <input
              type="text"
              name="numeroChasis"
              value={formData.numeroChasis || ''}
              onChange={handleChange}
            />
          </label>
        </div>
      </fieldset>

      {/* Configuración */}
      <fieldset>
        <legend>Configuración</legend>

        <div>
          <label>
            Límite de Velocidad (km/h): *
            <input
              type="number"
              name="speedLimitKmh"
              value={formData.speedLimitKmh}
              onChange={handleChange}
              required
              min="1"
              max="200"
            />
            <small>Se convertirá automáticamente a knots para Traccar</small>
          </label>
        </div>

        <div>
          <label>
            Contacto Responsable:
            <input
              type="text"
              name="contact"
              value={formData.contact}
              onChange={handleChange}
              placeholder="Nombre o email"
            />
          </label>
        </div>
      </fieldset>

      {/* Imagen */}
      <fieldset>
        <legend>Imagen del Vehículo</legend>

        <div>
          <label>
            Foto del Vehículo:
            <input
              type="file"
              accept="image/*"
              onChange={handleImageChange}
            />
            <small>Máximo 500 KB. Formatos: JPEG, PNG, GIF, WebP</small>
          </label>
        </div>

        {imagePreview && (
          <div>
            <img
              src={imagePreview}
              alt="Preview"
              style={{ maxWidth: '300px', marginTop: '10px' }}
            />
          </div>
        )}
      </fieldset>

      {/* Errores */}
      {error && (
        <div style={{ color: 'red', margin: '10px 0' }}>
          {error}
        </div>
      )}

      {/* Botón Submit */}
      <button type="submit" disabled={loading}>
        {loading ? 'Creando...' : 'Crear Dispositivo y Vehículo'}
      </button>
    </form>
  );
}

export default CreateDeviceForm;
```

---

### 🎯 Flujo de Creación Paso a Paso

```
1. USUARIO LLENA EL FORMULARIO
   ↓
2. VALIDACIÓN CLIENTE-SIDE
   - Campos requeridos
   - Formato de uniqueId
   - Tamaño de imagen
   ↓
3. CONVERSIÓN DE DATOS
   - speedLimit: km/h → knots
   - Organizar datos en estructura de Traccar
   ↓
4. CREAR DISPOSITIVO (POST /api/devices)
   - Incluye todos los campos estándar
   - Incluye atributos personalizados
   ↓
5. OBTENER ID DEL DISPOSITIVO CREADO
   ↓
6. SUBIR IMAGEN (POST /api/devices/{id}/image)
   - Solo si el usuario seleccionó una imagen
   ↓
7. CONFIRMACIÓN Y RESET
   - Mostrar mensaje de éxito
   - Limpiar formulario
   - Opcional: Redirigir a lista de dispositivos
```

---

### 🔄 Función Helper Completa (JavaScript Vanilla)

```javascript
class TraccarDeviceManager {
  constructor(baseUrl, username, password) {
    this.baseUrl = baseUrl;
    this.auth = 'Basic ' + btoa(`${username}:${password}`);
  }

  // Convertir km/h a knots
  kmhToKnots(kmh) {
    return kmh / 1.852;
  }

  // Crear dispositivo completo con vehículo e imagen
  async createDeviceWithVehicle(data) {
    try {
      // 1. Preparar datos del dispositivo
      const deviceData = {
        name: data.deviceName,
        uniqueId: data.uniqueId,
        status: 'offline',
        disabled: false,
        phone: data.phone || null,
        model: data.deviceModel || null,
        contact: data.contact || null,
        category: data.categoria,
        attributes: {
          speedLimit: this.kmhToKnots(data.speedLimitKmh),
          placa: data.placa,
          marca: data.marca,
          año: data.año,
          color: data.color || null,
          tipoVehiculo: data.categoria,
          numeroMotor: data.numeroMotor || null,
          numeroChasis: data.numeroChasis || null
        }
      };

      // 2. Crear dispositivo
      const deviceResponse = await fetch(`${this.baseUrl}/devices`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': this.auth
        },
        body: JSON.stringify(deviceData)
      });

      if (!deviceResponse.ok) {
        const errorText = await deviceResponse.text();
        throw new Error(`Error al crear dispositivo: ${errorText}`);
      }

      const device = await deviceResponse.json();

      // 3. Subir imagen si existe
      if (data.image && device.id) {
        await this.uploadDeviceImage(device.id, data.image);
      }

      return device;

    } catch (error) {
      console.error('Error al crear dispositivo:', error);
      throw error;
    }
  }

  // Subir imagen del dispositivo
  async uploadDeviceImage(deviceId, imageFile) {
    const formData = new FormData();
    formData.append('file', imageFile);

    const response = await fetch(`${this.baseUrl}/devices/${deviceId}/image`, {
      method: 'POST',
      headers: {
        'Authorization': this.auth
      },
      body: formData
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Error al subir imagen: ${errorText}`);
    }

    return await response.text();
  }

  // Obtener URL de la imagen del dispositivo
  getDeviceImageUrl(device) {
    if (!device || !device.uniqueId) {
      return null;
    }
    return `${this.baseUrl.replace('/api', '')}/api/media/${device.uniqueId}/device.jpg`;
  }
}

// Uso
const manager = new TraccarDeviceManager('http://localhost:8082/api', 'admin', 'admin');

const formData = {
  deviceName: 'Vehículo Principal',
  uniqueId: '123456789012345',
  deviceModel: 'GT06',
  phone: '+1234567890',
  placa: 'ABC-123',
  marca: 'Toyota',
  vehiculoModelo: 'Corolla',
  año: 2020,
  color: 'Blanco',
  categoria: 'Auto',
  speedLimitKmh: 80,
  contact: 'Juan Pérez',
  image: imageFile // File object
};

try {
  const device = await manager.createDeviceWithVehicle(formData);
  console.log('Dispositivo creado:', device);
} catch (error) {
  console.error('Error:', error);
}
```

---

### ✅ Mejores Prácticas para el Frontend

1. **Validación en Cliente:**
   - Valida campos requeridos antes de enviar
   - Valida formato de `uniqueId` (solo números, 10-15 dígitos)
   - Valida tamaño de imagen (máx 500 KB)
   - Valida tipo de imagen

2. **UX Amigable:**
   - Muestra preview de la imagen antes de subir
   - Muestra progreso de carga
   - Mensajes de error claros y específicos
   - Confirmación antes de crear

3. **Manejo de Errores:**
   - Captura errores de red
   - Muestra mensajes de error amigables
   - Permite reintentar en caso de error

4. **Optimización:**
   - Comprime imágenes antes de subir
   - Valida datos antes de hacer requests
   - Usa debounce para validaciones en tiempo real

---

## 5. Conectar el Dispositivo GPS

Una vez creado el dispositivo en Traccar, necesitas **configurar el dispositivo GPS físico** para que se conecte al servidor.

### 🔌 Información Necesaria para la Conexión

Para que el dispositivo GPS se conecte, necesitas:

1. **IP del servidor Traccar** (o dominio)
2. **Puerto del protocolo** que usa tu dispositivo
3. **Unique ID** del dispositivo (debe coincidir con el `uniqueId` en Traccar)

---

### 📡 Protocolos y Puertos Comunes

Traccar soporta más de 200 protocolos diferentes. Algunos de los más comunes:

| Protocolo | Puerto por Defecto | Descripción |
|-----------|-------------------|-------------|
| **GT06** | 5023 | Muy común en dispositivos chinos |
| **OSMAND** | 5055 | Para aplicaciones móviles |
| **GPS103** | 5001 | Protocolo estándar |
| **TK103** | 5002 | Similar a GPS103 |
| **H02** | 5003 | Protocolo H02 |
| **T55** | 5004 | Protocolo T55 |
| **T808** | 7611 | Protocolo T808 |
| **OsmAnd** | 5055 | Para apps móviles |

**Nota:** Los puertos pueden configurarse en `traccar.xml` o `debug.xml`.

---

### 🔧 Configuración del Dispositivo GPS

#### **Paso 1: Obtener la IP del Servidor**

Si Traccar está en:
- **Local:** `localhost` o `127.0.0.1` (solo para pruebas)
- **Servidor:** IP pública o dominio (ej: `192.168.1.100` o `traccar.tudominio.com`)

#### **Paso 2: Identificar el Protocolo**

Consulta el manual de tu dispositivo GPS o prueba con protocolos comunes:
- GT06 (muy común)
- GPS103
- TK103

#### **Paso 3: Configurar el Dispositivo**

La configuración varía según el dispositivo, pero generalmente necesitas:

1. **Conectarte al dispositivo** (vía SMS, web, o software)
2. **Configurar:**
   - **Servidor IP:** IP de tu servidor Traccar
   - **Puerto:** Puerto del protocolo (ej: 5023 para GT06)
   - **Unique ID / IMEI:** Debe coincidir con el `uniqueId` en Traccar
   - **Intervalo de reporte:** Cada cuántos segundos envía datos (ej: 10, 30, 60)

#### **Ejemplo de Configuración (GT06):**

```
Servidor IP: 192.168.1.100
Puerto: 5023
IMEI: 123456789012345
Intervalo: 30 segundos
```

---

### 📱 Configuración por Tipo de Dispositivo

#### **A. Dispositivo GPS con SIM Card (Tracker GPS)**

1. **Enviar comando SMS** al dispositivo:
   ```
   APN123456789012345,192.168.1.100,5023#
   ```
   (Formato puede variar según el modelo)

2. **O usar software de configuración:**
   - Conecta el dispositivo vía USB/Bluetooth
   - Usa el software del fabricante
   - Configura IP y puerto

#### **B. Aplicación Móvil (OSMAND, Traccar Client, etc.)**

1. **Instala la app** en tu teléfono
2. **Configuración:**
   - **Servidor:** `http://tu-servidor:8082` o `https://tu-servidor:8082`
   - **Unique ID:** Tu IMEI o un ID único
   - **Intervalo:** Cada cuántos segundos reporta posición

#### **C. Dispositivo OBD (On-Board Diagnostics)**

1. Conecta el dispositivo OBD al puerto del vehículo
2. Configura vía app móvil o web del dispositivo
3. Ingresa IP y puerto del servidor Traccar

---

### 🔍 Verificar la Conexión

#### **Método 1: Verificar en la Interfaz Web**

1. Ve a **Devices** en Traccar
2. Busca tu dispositivo
3. El estado debería cambiar a **"online"** (verde) cuando se conecte
4. Verás la última posición en el mapa

#### **Método 2: Verificar vía API**

```bash
# Obtener información del dispositivo
curl -u admin:admin "http://localhost:8082/api/devices?uniqueId=123456789012345"

# Verificar estado
curl -u admin:admin "http://localhost:8082/api/devices/1"
```

**Respuesta esperada:**
```json
{
  "id": 1,
  "name": "Vehículo Principal",
  "uniqueId": "123456789012345",
  "status": "online",  ← Debe ser "online" cuando está conectado
  "lastUpdate": "2025-01-15T10:30:00.000Z",  ← Última actualización
  "positionId": 12345
}
```

#### **Método 3: Ver Logs del Servidor**

```bash
# Ver logs en tiempo real
tail -f logs/tracker-server.log | grep "123456789012345"

# O buscar conexiones
tail -f logs/tracker-server.log | grep -i "connected\|online"
```

---

### ⚠️ Problemas Comunes de Conexión

#### **Problema 1: Dispositivo no se conecta**

**Posibles causas:**
- IP o puerto incorrectos
- Firewall bloqueando el puerto
- `uniqueId` no coincide
- Protocolo incorrecto

**Solución:**
1. Verifica que el puerto esté abierto:
   ```bash
   # En el servidor
   sudo netstat -tulpn | grep 5023
   # O
   sudo ss -tulpn | grep 5023
   ```

2. Verifica que el `uniqueId` coincida exactamente:
   ```bash
   curl -u admin:admin "http://localhost:8082/api/devices?uniqueId=TU_UNIQUE_ID"
   ```

3. Revisa los logs:
   ```bash
   tail -f logs/tracker-server.log
   ```

#### **Problema 2: Dispositivo se conecta pero no envía posiciones**

**Posibles causas:**
- GPS sin señal
- Dispositivo en interiores
- Configuración de intervalo muy larga

**Solución:**
- Mueve el dispositivo a un lugar con señal GPS
- Verifica la configuración del intervalo de reporte

#### **Problema 3: "Unknown device" en los logs**

**Causa:** El dispositivo se conecta pero el `uniqueId` no existe en Traccar.

**Solución:**
1. Crea el dispositivo con ese `uniqueId`, o
2. Habilita el registro automático en `traccar.xml`:
   ```xml
   <entry key='database.registerUnknown'>true</entry>
   ```

---

## 6. Editar un Dispositivo

### 🔧 Método 1: Usando la API REST

#### **Endpoint:**
```
PUT /api/devices/{id}
```

#### **Ejemplo con curl:**
```bash
curl -X PUT http://localhost:8082/api/devices/1 \
  -u "admin:admin" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "name": "Vehículo Actualizado",
    "uniqueId": "123456789012345",
    "status": "online",
    "disabled": false,
    "phone": "+9876543210",
    "model": "GT06N",
    "contact": "María García",
    "category": "Vehicle",
    "attributes": {}
  }'
```

**⚠️ Importante:** Debes incluir el `id` del dispositivo en el body.

#### **Ejemplo con JavaScript:**
```javascript
async function updateDevice(deviceId, updates) {
  const response = await fetch(`http://localhost:8082/api/devices/${deviceId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ' + btoa('admin:admin')
    },
    body: JSON.stringify({
      id: deviceId,
      ...updates  // Campos a actualizar
    })
  });

  if (response.ok) {
    const device = await response.json();
    console.log('Dispositivo actualizado:', device);
    return device;
  } else {
    const error = await response.text();
    throw new Error(`Error al actualizar: ${error}`);
  }
}

// Uso
updateDevice(1, {
  name: 'Nuevo Nombre',
  phone: '+1234567890',
  contact: 'Nuevo Contacto'
});
```

#### **Ejemplo con Bruno:**
```bru
meta {
  name: Update Device
  type: http
}

put {
  url: {{baseUrl}}/devices/{{deviceId}}
  body: json
  auth: basic
}

headers {
  Content-Type: application/json
}

body:json {
  {
    "id": {{deviceId}},
    "name": "Vehículo Actualizado",
    "uniqueId": "123456789012345",
    "status": "online",
    "disabled": false,
    "phone": "+9876543210",
    "model": "GT06N",
    "contact": "María García",
    "category": "Vehicle",
    "attributes": {}
  }
}

auth:basic {
  username: {{email}}
  password: {{password}}
}
```

---

### 🖥️ Método 2: Usando la Interfaz Web

1. Ve a **Settings** → **Devices**
2. Haz clic en el dispositivo que quieres editar
3. Modifica los campos necesarios
4. Haz clic en **Save**

---

### 📝 Campos que Puedes Actualizar

- ✅ `name`: Nombre del dispositivo
- ✅ `phone`: Número de teléfono
- ✅ `model`: Modelo del dispositivo
- ✅ `contact`: Contacto responsable
- ✅ `category`: Categoría
- ✅ `disabled`: Habilitar/deshabilitar dispositivo
- ✅ `groupId`: Cambiar de grupo
- ✅ `attributes`: Atributos personalizados
- ⚠️ `uniqueId`: **Solo si el dispositivo no está conectado** (cambiar esto puede causar problemas)

---

### ⚠️ Advertencias

1. **No cambies `uniqueId` si el dispositivo está conectado:**
   - El dispositivo seguirá enviando datos con el `uniqueId` antiguo
   - Traccar no podrá asociar las posiciones al dispositivo

2. **El campo `status` se actualiza automáticamente:**
   - No necesitas actualizarlo manualmente
   - Traccar lo actualiza cuando el dispositivo se conecta/desconecta

---

## 7. Eliminar un Dispositivo

### 🗑️ Método 1: Usando la API REST

#### **Endpoint:**
```
DELETE /api/devices/{id}
```

#### **Ejemplo con curl:**
```bash
# Primero, obtener el ID del dispositivo
curl -u admin:admin "http://localhost:8082/api/devices?uniqueId=123456789012345"

# Luego, eliminar usando el ID
curl -X DELETE http://localhost:8082/api/devices/1 \
  -u "admin:admin"
```

#### **Ejemplo con JavaScript:**
```javascript
async function deleteDevice(deviceId) {
  const response = await fetch(`http://localhost:8082/api/devices/${deviceId}`, {
    method: 'DELETE',
    headers: {
      'Authorization': 'Basic ' + btoa('admin:admin')
    }
  });

  if (response.status === 204 || response.status === 200) {
    console.log('Dispositivo eliminado exitosamente');
    return true;
  } else {
    const error = await response.text();
    throw new Error(`Error al eliminar: ${error}`);
  }
}

// Uso
deleteDevice(1);
```

#### **Ejemplo con Bruno:**
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

---

### 🖥️ Método 2: Usando la Interfaz Web

1. Ve a **Settings** → **Devices**
2. Haz clic en el dispositivo que quieres eliminar
3. Haz clic en **Delete** (botón rojo)
4. Confirma la eliminación

---

### 🧹 Eliminar Dispositivo y Todos sus Datos Relacionados

Cuando eliminas un dispositivo, Traccar elimina automáticamente:
- ✅ El dispositivo (`tc_devices`)
- ✅ Las posiciones (`tc_positions`) - **CASCADE DELETE**
- ✅ Los eventos (`tc_events`) - **CASCADE DELETE**
- ✅ Las geocercas asociadas (`tc_device_geofence`) - **CASCADE DELETE**
- ✅ Los comandos (`tc_commands`) - **CASCADE DELETE**
- ✅ Las notificaciones (`tc_device_notification`) - **CASCADE DELETE**
- ✅ Los grupos (`tc_device_group`) - **CASCADE DELETE**
- ✅ Los atributos (`tc_device_attribute`) - **CASCADE DELETE**
- ✅ Los drivers (`tc_drivers`) - si están asociados
- ✅ Los mantenimientos (`tc_maintenances`) - **CASCADE DELETE**
- ✅ Los estadios (`tc_statistics`) - **CASCADE DELETE**

**Nota:** Los datos se eliminan en cascada gracias a las restricciones de clave foránea en la base de datos.

---

### 📋 Script para Eliminar por uniqueId

Si solo tienes el `uniqueId` y no el `id`:

```bash
#!/bin/bash
# eliminar-dispositivo.sh

UNIQUE_ID="$1"
BASE_URL="http://localhost:8082/api"
EMAIL="admin"
PASSWORD="admin"

if [ -z "$UNIQUE_ID" ]; then
  echo "Uso: $0 <uniqueId>"
  exit 1
fi

# 1. Obtener el ID del dispositivo
DEVICE_RESPONSE=$(curl -s -u "$EMAIL:$PASSWORD" "$BASE_URL/devices?uniqueId=$UNIQUE_ID")
DEVICE_ID=$(echo "$DEVICE_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data[0]['id'] if data and len(data) > 0 else '')" 2>/dev/null)

if [ -z "$DEVICE_ID" ]; then
  echo "❌ No se encontró dispositivo con uniqueId '$UNIQUE_ID'"
  exit 1
fi

echo "✅ Dispositivo encontrado: ID=$DEVICE_ID"

# 2. Eliminar el dispositivo
DELETE_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE -u "$EMAIL:$PASSWORD" "$BASE_URL/devices/$DEVICE_ID")
HTTP_STATUS=$(echo "$DELETE_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)

if [ "$HTTP_STATUS" = "204" ] || [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Dispositivo eliminado exitosamente"
else
  echo "❌ Error al eliminar dispositivo (HTTP $HTTP_STATUS)"
  exit 1
fi
```

**Uso:**
```bash
chmod +x eliminar-dispositivo.sh
./eliminar-dispositivo.sh 123456789012345
```

---

### ⚠️ Errores Comunes al Eliminar

#### **Error: `HTTP 401 Unauthorized`**

**Causa:** Credenciales incorrectas o sesión expirada.

**Solución:**
- Verifica las credenciales
- Si usas la interfaz web, cierra sesión y vuelve a iniciar sesión
- Si usas la API, verifica el header `Authorization`

#### **Error: `HTTP 403 Forbidden`**

**Causa:** No tienes permisos para eliminar el dispositivo.

**Solución:**
- Verifica que seas administrador, o
- Verifica que tengas permisos sobre ese dispositivo

---

### ✅ Respuesta Exitosa

La eliminación exitosa devuelve:
- **HTTP 204 No Content** (sin body), o
- **HTTP 200 OK** (sin body)

---

## 8. Troubleshooting

### 🔍 Problemas Comunes

#### **1. Dispositivo creado pero no se conecta**

**Verificar:**
- ✅ IP y puerto correctos en el dispositivo GPS
- ✅ Puerto abierto en el firewall
- ✅ `uniqueId` coincide exactamente
- ✅ Protocolo correcto configurado

**Solución:**
```bash
# Verificar que el dispositivo existe
curl -u admin:admin "http://localhost:8082/api/devices?uniqueId=TU_UNIQUE_ID"

# Verificar logs
tail -f logs/tracker-server.log | grep "TU_UNIQUE_ID"

# Verificar puerto
sudo netstat -tulpn | grep 5023
```

---

#### **2. Dispositivo se conecta pero aparece como "unknown"**

**Causa:** El `uniqueId` no existe en Traccar.

**Solución:**
1. Crea el dispositivo con ese `uniqueId`, o
2. Habilita registro automático:
   ```xml
   <entry key='database.registerUnknown'>true</entry>
   ```

---

#### **3. Error al eliminar: "Foreign key constraint"**

**Causa:** Hay datos relacionados que no se pueden eliminar.

**Solución:**
- Traccar debería eliminar todo en cascada automáticamente
- Si persiste, verifica los logs:
  ```bash
  tail -f logs/tracker-server.log
  ```

---

#### **4. Dispositivo duplicado al crear**

**Causa:** Ya existe un dispositivo con ese `uniqueId`.

**Solución:**
```bash
# Buscar dispositivo existente
curl -u admin:admin "http://localhost:8082/api/devices?uniqueId=TU_UNIQUE_ID"

# Eliminar si existe
curl -X DELETE -u admin:admin "http://localhost:8082/api/devices/ID"
```

---

### 📊 Verificar Estado del Dispositivo

```bash
# Obtener todos los dispositivos
curl -u admin:admin http://localhost:8082/api/devices

# Obtener dispositivo específico
curl -u admin:admin "http://localhost:8082/api/devices?uniqueId=TU_UNIQUE_ID"

# Obtener por ID
curl -u admin:admin http://localhost:8082/api/devices/1
```

---

### 📝 Logs Útiles

```bash
# Ver todas las conexiones
tail -f logs/tracker-server.log | grep -i "connected\|online\|offline"

# Ver errores
tail -f logs/tracker-server.log | grep -i "error\|exception"

# Ver actividad de un dispositivo específico
tail -f logs/tracker-server.log | grep "TU_UNIQUE_ID"
```

---

## 📚 Resumen de Endpoints

| Operación | Método | Endpoint | Body Requerido |
|-----------|--------|----------|----------------|
| **Crear** | `POST` | `/api/devices` | `name`, `uniqueId` |
| **Listar** | `GET` | `/api/devices` | - |
| **Obtener** | `GET` | `/api/devices/{id}` | - |
| **Buscar** | `GET` | `/api/devices?uniqueId=XXX` | - |
| **Actualizar** | `PUT` | `/api/devices/{id}` | `id` + campos a actualizar |
| **Eliminar** | `DELETE` | `/api/devices/{id}` | - |
| **Subir Imagen** | `POST` | `/api/devices/{id}/image` | `image/*` (file) |
| **Obtener Imagen** | `GET` | `/api/media/{uniqueId}/device.{ext}` | - |

---

## 🎯 Flujo Completo Resumido

```
1. CREAR DISPOSITIVO CON VEHÍCULO
   POST /api/devices
   { name, uniqueId, model, contact, category, attributes: { placa, speedLimit, ... } }
   ↓
2. SUBIR IMAGEN (opcional)
   POST /api/devices/{id}/image
   { file: imagen }
   ↓
3. CONFIGURAR DISPOSITIVO GPS FÍSICO
   IP: tu-servidor
   Puerto: 5023 (ejemplo)
   Unique ID: debe coincidir
   ↓
4. DISPOSITIVO SE CONECTA
   Estado cambia a "online"
   Empieza a recibir posiciones
   ↓
5. EDITAR (si es necesario)
   PUT /api/devices/{id}
   { id, name, phone, attributes: { ... } }
   ↓
6. ELIMINAR (si es necesario)
   DELETE /api/devices/{id}
   Se eliminan todos los datos relacionados
```

---

## 💡 Mejores Prácticas

1. **Usa `uniqueId` únicos:** Nunca reutilices un `uniqueId` a menos que hayas eliminado el dispositivo anterior
2. **Verifica antes de crear:** Busca si el dispositivo ya existe antes de crearlo
3. **Configura correctamente:** Asegúrate de que IP, puerto y `uniqueId` coincidan exactamente
4. **Monitorea los logs:** Revisa los logs cuando tengas problemas de conexión
5. **Backup antes de eliminar:** Si eliminas un dispositivo importante, haz backup de los datos primero
6. **Usa grupos:** Organiza dispositivos en grupos para mejor gestión
7. **Documenta configuraciones:** Guarda la configuración de cada dispositivo GPS

---

**Última actualización:** 2025-01-15

