# 🎨 Interfaz Frontend: Crear GPS con Vehículo

Este documento explica paso a paso cómo crear una interfaz amigable en el frontend para que el usuario ingrese todos los datos necesarios antes de crear un "GPS" (que incluye el dispositivo GPS y la información del vehículo asociado).

---

## 📋 Tabla de Contenidos

1. [Conceptos Clave](#1-conceptos-clave)
2. [Estructura de Datos](#2-estructura-de-datos)
3. [Diseño de la Interfaz](#3-diseño-de-la-interfaz)
4. [Implementación Paso a Paso](#4-implementación-paso-a-paso)
5. [Código Completo](#5-código-completo)
6. [Obtener Datos de un Dispositivo](#6-obtener-datos-de-un-dispositivo)
7. [Editar un Dispositivo Existente](#7-editar-un-dispositivo-existente)
8. [Componente Completo: Crear y Editar](#8-componente-completo-crear-y-editar)

---

## 1. Conceptos Clave

### 🎯 ¿Qué es un "GPS" en nuestro sistema?

Un **"GPS"** en nuestro sistema es la combinación de:
- **Dispositivo GPS físico** (tracker, dispositivo de rastreo)
- **Vehículo asociado** (auto, bus, camión, moto, etc.)

**NO creamos relaciones nuevas.** Usamos los campos estándar y atributos del dispositivo Traccar.

---

### 📦 Campos Estándar vs Atributos

#### **Campos Estándar** (directamente en el modelo Device):

| Campo | Uso en nuestro sistema | Ejemplo |
|-------|------------------------|---------|
| `name` | Nombre del GPS/Vehículo | "Vehículo Principal" |
| `uniqueId` | IMEI del dispositivo GPS | "123456789012345" |
| `model` | **Modelo del dispositivo GPS** | "GT06", "TK103", "OsmAnd" |
| `phone` | Teléfono para comandos SMS | "+1234567890" |
| `contact` | Contacto responsable | "Juan Pérez" |
| `category` | **Tipo de vehículo** | "Auto", "Bus", "Camión", "Moto" |

#### **Atributos Personalizados** (`attributes` - objeto JSON):

| Atributo | Descripción | Ejemplo |
|----------|------------|---------|
| `placa` | Placa del vehículo | "ABC-123" |
| `marca` | Marca del vehículo | "Toyota" |
| `modeloVehiculo` | Modelo del vehículo | "Corolla" |
| `año` | Año del vehículo | 2020 |
| `color` | Color del vehículo | "Blanco" |
| `speedLimit` | Límite de velocidad (knots) | 43.2 (80 km/h) |

---

### ⚠️ Importante: Diferenciación de Campos

```
┌─────────────────────────────────────────────────┐
│  DISPOSITIVO GPS (model)                        │
│  - Modelo del tracker GPS                       │
│  - Ejemplos: GT06, TK103, OsmAnd                │
└─────────────────────────────────────────────────┘
                    ↓
         Se asocia con un vehículo
                    ↓
┌─────────────────────────────────────────────────┐
│  VEHÍCULO (attributes)                         │
│  - Placa (placa)                                │
│  - Marca (marca)                               │
│  - Modelo del vehículo (modeloVehiculo)        │
│  - Tipo (category)                             │
│  - Año, Color, etc.                            │
└─────────────────────────────────────────────────┘
```

---

## 2. Estructura de Datos

### 📊 Estructura Final del JSON

Cuando el usuario completa el formulario, enviamos esto a `POST /api/devices`:

```json
{
  "name": "Vehículo Principal",
  "uniqueId": "123456789012345",
  "status": "offline",
  "disabled": false,
  "phone": "+1234567890",
  "model": "GT06",                    // ← Modelo del DISPOSITIVO GPS
  "contact": "Juan Pérez",
  "category": "Auto",                 // ← Tipo de VEHÍCULO (Auto, Bus, Camión, Moto)
  "attributes": {
    "placa": "ABC-123",               // ← Placa del vehículo
    "marca": "Toyota",                 // ← Marca del vehículo
    "modeloVehiculo": "Corolla",       // ← Modelo del VEHÍCULO
    "año": 2020,                       // ← Año del vehículo
    "color": "Blanco",                 // ← Color del vehículo
    "speedLimit": 43.2,                // ← Límite de velocidad (knots)
    "numeroMotor": "123456789",        // ← Opcional
    "numeroChasis": "987654321"        // ← Opcional
  }
}
```

---

### 🎨 Mapeo: Formulario → JSON

| Campo en el Formulario | Campo en JSON | Ubicación |
|------------------------|---------------|-----------|
| **Nombre del GPS** | `name` | Campo estándar |
| **IMEI del GPS** | `uniqueId` | Campo estándar |
| **Modelo del Dispositivo GPS** | `model` | Campo estándar |
| **Teléfono** | `phone` | Campo estándar |
| **Contacto** | `contact` | Campo estándar |
| **Tipo de Vehículo** | `category` | Campo estándar |
| **Placa** | `attributes.placa` | Atributo |
| **Marca** | `attributes.marca` | Atributo |
| **Modelo del Vehículo** | `attributes.modeloVehiculo` | Atributo |
| **Año** | `attributes.año` | Atributo |
| **Color** | `attributes.color` | Atributo |
| **Límite de Velocidad** | `attributes.speedLimit` | Atributo (convertido a knots) |

---

## 3. Diseño de la Interfaz

### 🖼️ Estructura Visual del Formulario

```
┌─────────────────────────────────────────────────────────────┐
│  CREAR NUEVO GPS                                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─ INFORMACIÓN DEL DISPOSITIVO GPS ─────────────────┐   │
│  │                                                      │   │
│  │  Nombre del GPS: [________________]                │   │
│  │  IMEI del GPS:   [________________]                │   │
│  │  Modelo GPS:     [Dropdown ▼]                      │   │
│  │  Teléfono:      [________________]                │   │
│  │  Contacto:      [________________]                │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─ INFORMACIÓN DEL VEHÍCULO ───────────────────────┐   │
│  │                                                      │   │
│  │  Tipo de Vehículo:  [Dropdown ▼]                   │   │
│  │  Placa:             [________________]              │   │
│  │  Marca:             [________________]              │   │
│  │  Modelo:            [________________]              │   │
│  │  Año:               [____]                          │   │
│  │  Color:             [________________]              │   │
│  │  Límite Velocidad:  [____] km/h                    │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─ IMAGEN DEL VEHÍCULO ─────────────────────────────┐   │
│  │                                                      │   │
│  │  [📷 Seleccionar Imagen]                            │   │
│  │  [Preview de la imagen si se selecciona]            │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  [Cancelar]  [Crear GPS]                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

### 📋 Opciones para Dropdowns

#### **1. Modelos de Dispositivos GPS** (`model`)

Estas son opciones comunes que puedes mostrar en un dropdown:

```javascript
const GPS_MODELS = [
  { value: 'GT06', label: 'GT06' },
  { value: 'TK103', label: 'TK103' },
  { value: 'TK102', label: 'TK102' },
  { value: 'OsmAnd', label: 'OsmAnd (App móvil)' },
  { value: 'GPS103', label: 'GPS103' },
  { value: 'H02', label: 'H02' },
  { value: 'T55', label: 'T55' },
  { value: 'T808', label: 'T808' },
  { value: 'Meiligao', label: 'Meiligao' },
  { value: 'Teltonika', label: 'Teltonika' },
  { value: 'Otro', label: 'Otro' }
];
```

**Nota:** Si el usuario selecciona "Otro", puedes mostrar un campo de texto para que ingrese el modelo manualmente.

---

#### **2. Tipos de Vehículos** (`category`)

```javascript
const VEHICLE_TYPES = [
  { value: 'Auto', label: '🚗 Auto' },
  { value: 'Bus', label: '🚌 Bus' },
  { value: 'Camión', label: '🚚 Camión' },
  { value: 'Moto', label: '🏍️ Moto' },
  { value: 'Taxi', label: '🚕 Taxi' },
  { value: 'Ambulancia', label: '🚑 Ambulancia' },
  { value: 'Policía', label: '🚓 Policía' },
  { value: 'Otro', label: '❓ Otro' }
];
```

---

#### **3. Marcas de Vehículos** (opcional, para autocompletar)

```javascript
const VEHICLE_BRANDS = [
  'Toyota', 'Nissan', 'Chevrolet', 'Ford', 'Volkswagen',
  'Hyundai', 'Kia', 'Mazda', 'Honda', 'Mitsubishi',
  'Suzuki', 'Renault', 'Peugeot', 'Citroën', 'Fiat',
  'Mercedes-Benz', 'BMW', 'Audi', 'Volvo', 'Otro'
];
```

---

## 4. Implementación Paso a Paso

### 📝 Paso 1: Definir el Estado del Formulario

```typescript
interface GPSFormData {
  // Dispositivo GPS
  name: string;              // Nombre del GPS
  uniqueId: string;          // IMEI del dispositivo GPS
  deviceModel: string;       // Modelo del dispositivo GPS (GT06, TK103, etc.)
  phone: string;            // Teléfono para SMS
  contact: string;           // Contacto responsable

  // Vehículo
  vehicleType: string;       // Tipo de vehículo (Auto, Bus, Camión, Moto)
  placa: string;             // Placa del vehículo
  marca: string;             // Marca del vehículo
  modeloVehiculo: string;     // Modelo del vehículo
  año: number;               // Año del vehículo
  color: string;             // Color del vehículo
  speedLimitKmh: number;      // Límite de velocidad en km/h

  // Imagen
  image?: File;               // Archivo de imagen
}
```

---

### 📝 Paso 2: Crear el Componente del Formulario

```typescript
import React, { useState } from 'react';

const GPS_MODELS = [
  { value: 'GT06', label: 'GT06' },
  { value: 'TK103', label: 'TK103' },
  { value: 'OsmAnd', label: 'OsmAnd' },
  { value: 'Otro', label: 'Otro' }
];

const VEHICLE_TYPES = [
  { value: 'Auto', label: '🚗 Auto' },
  { value: 'Bus', label: '🚌 Bus' },
  { value: 'Camión', label: '🚚 Camión' },
  { value: 'Moto', label: '🏍️ Moto' },
  { value: 'Taxi', label: '🚕 Taxi' },
  { value: 'Otro', label: '❓ Otro' }
];

function CreateGPSForm() {
  const [formData, setFormData] = useState<GPSFormData>({
    name: '',
    uniqueId: '',
    deviceModel: '',
    phone: '',
    contact: '',
    vehicleType: 'Auto',
    placa: '',
    marca: '',
    modeloVehiculo: '',
    año: new Date().getFullYear(),
    color: '',
    speedLimitKmh: 80
  });

  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showOtherModel, setShowOtherModel] = useState(false);

  // ... continuará
}
```

---

### 📝 Paso 3: Manejar Cambios en los Campos

```typescript
// Función para manejar cambios en inputs de texto/número
const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
  const { name, value } = e.target;
  
  setFormData(prev => ({
    ...prev,
    [name]: name === 'año' || name === 'speedLimitKmh' 
      ? Number(value) 
      : value
  }));

  // Si selecciona "Otro" en modelo GPS, mostrar campo de texto
  if (name === 'deviceModel' && value === 'Otro') {
    setShowOtherModel(true);
  } else if (name === 'deviceModel') {
    setShowOtherModel(false);
  }
};

// Función para manejar selección de imagen
const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
  const file = e.target.files?.[0];
  if (file) {
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
      setImagePreview(e.target?.result as string);
    };
    reader.readAsDataURL(file);

    setFormData(prev => ({ ...prev, image: file }));
    setError(null);
  }
};
```

---

### 📝 Paso 4: Convertir km/h a Knots

```typescript
// Función para convertir km/h a knots (nudos)
const kmhToKnots = (kmh: number): number => {
  return kmh / 1.852;  // 1 knot = 1.852 km/h
};

// Ejemplo: 80 km/h = 43.2 knots
```

---

### 📝 Paso 5: Preparar y Enviar los Datos

```typescript
const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault();
  setLoading(true);
  setError(null);

  try {
    // 1. Validar campos requeridos
    if (!formData.name || !formData.uniqueId) {
      throw new Error('Nombre e IMEI son requeridos');
    }

    // 2. Preparar datos del dispositivo
    const deviceData = {
      name: formData.name,
      uniqueId: formData.uniqueId,
      status: 'offline',
      disabled: false,
      phone: formData.phone || null,
      model: formData.deviceModel || null,        // Modelo del DISPOSITIVO GPS
      contact: formData.contact || null,
      category: formData.vehicleType,             // Tipo de VEHÍCULO
      attributes: {
        placa: formData.placa,
        marca: formData.marca,
        modeloVehiculo: formData.modeloVehiculo,  // Modelo del VEHÍCULO
        año: formData.año,
        color: formData.color || null,
        speedLimit: kmhToKnots(formData.speedLimitKmh)  // Convertir a knots
      }
    };

    // 3. Crear dispositivo
    const deviceResponse = await fetch('http://localhost:8082/api/devices', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ' + btoa('admin:admin')
      },
      body: JSON.stringify(deviceData)
    });

    if (!deviceResponse.ok) {
      const errorText = await deviceResponse.text();
      throw new Error(`Error al crear dispositivo: ${errorText}`);
    }

    const device = await deviceResponse.json();
    console.log('Dispositivo creado:', device);

    // 4. Subir imagen si existe
    if (formData.image && device.id) {
      const formDataImage = new FormData();
      formDataImage.append('file', formData.image);

      const imageResponse = await fetch(
        `http://localhost:8082/api/devices/${device.id}/image`,
        {
          method: 'POST',
          headers: {
            'Authorization': 'Basic ' + btoa('admin:admin')
          },
          body: formDataImage
        }
      );

      if (!imageResponse.ok) {
        console.warn('Dispositivo creado pero error al subir imagen');
      }
    }

    alert('GPS creado exitosamente');
    
    // 5. Resetear formulario
    setFormData({
      name: '',
      uniqueId: '',
      deviceModel: '',
      phone: '',
      contact: '',
      vehicleType: 'Auto',
      placa: '',
      marca: '',
      modeloVehiculo: '',
      año: new Date().getFullYear(),
      color: '',
      speedLimitKmh: 80
    });
    setImagePreview(null);

  } catch (err: any) {
    setError(err.message);
  } finally {
    setLoading(false);
  }
};
```

---

### 📝 Paso 6: Renderizar el Formulario

```typescript
return (
  <form onSubmit={handleSubmit} className="gps-form">
    <h2>Crear Nuevo GPS</h2>

    {/* Sección: Información del Dispositivo GPS */}
    <fieldset>
      <legend>📡 Información del Dispositivo GPS</legend>
      
      <div className="form-group">
        <label>
          Nombre del GPS: *
          <input
            type="text"
            name="name"
            value={formData.name}
            onChange={handleChange}
            required
            placeholder="Ej: Vehículo Principal"
          />
        </label>
      </div>

        <div className="form-group">
          <label>
            IMEI del GPS: *
            <input
              type="text"
              name="uniqueId"
              value={formData.uniqueId}
              onChange={handleChange}
              required
              pattern="[0-9]{10,15}"
              title="Debe ser un número de 10 a 15 dígitos"
              placeholder="123456789012345"
              className={uniqueIdStatus.exists ? 'error' : ''}
            />
            {uniqueIdStatus.checking && (
              <small style={{ color: '#666' }}>🔍 Verificando...</small>
            )}
            {uniqueIdStatus.exists && !uniqueIdStatus.checking && (
              <small style={{ color: '#c62828' }}>
                ⚠️ Este IMEI ya está en uso. Dispositivo: "{uniqueIdStatus.device?.name}" (ID: {uniqueIdStatus.device?.id})
              </small>
            )}
            {!uniqueIdStatus.exists && !uniqueIdStatus.checking && formData.uniqueId.length >= 10 && (
              <small style={{ color: '#4CAF50' }}>✅ IMEI disponible</small>
            )}
          </label>
        </div>

      <div className="form-group">
        <label>
          Modelo del Dispositivo GPS: *
          <select
            name="deviceModel"
            value={formData.deviceModel}
            onChange={handleChange}
            required
          >
            <option value="">Seleccione un modelo</option>
            {GPS_MODELS.map(model => (
              <option key={model.value} value={model.value}>
                {model.label}
              </option>
            ))}
          </select>
        </label>
      </div>

      {showOtherModel && (
        <div className="form-group">
          <label>
            Especifique el modelo:
            <input
              type="text"
              name="deviceModel"
              value={formData.deviceModel}
              onChange={handleChange}
              placeholder="Ingrese el modelo del GPS"
            />
          </label>
        </div>
      )}

      <div className="form-group">
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

      <div className="form-group">
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

    {/* Sección: Información del Vehículo */}
    <fieldset>
      <legend>🚗 Información del Vehículo</legend>

      <div className="form-group">
        <label>
          Tipo de Vehículo: *
          <select
            name="vehicleType"
            value={formData.vehicleType}
            onChange={handleChange}
            required
          >
            {VEHICLE_TYPES.map(type => (
              <option key={type.value} value={type.value}>
                {type.label}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div className="form-group">
        <label>
          Placa: *
          <input
            type="text"
            name="placa"
            value={formData.placa}
            onChange={handleChange}
            required
            style={{ textTransform: 'uppercase' }}
            placeholder="ABC-123"
          />
        </label>
      </div>

      <div className="form-group">
        <label>
          Marca: *
          <input
            type="text"
            name="marca"
            value={formData.marca}
            onChange={handleChange}
            required
            placeholder="Toyota"
          />
        </label>
      </div>

      <div className="form-group">
        <label>
          Modelo del Vehículo: *
          <input
            type="text"
            name="modeloVehiculo"
            value={formData.modeloVehiculo}
            onChange={handleChange}
            required
            placeholder="Corolla"
          />
        </label>
      </div>

      <div className="form-group">
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

      <div className="form-group">
        <label>
          Color:
          <input
            type="text"
            name="color"
            value={formData.color}
            onChange={handleChange}
            placeholder="Blanco"
          />
        </label>
      </div>

      <div className="form-group">
        <label>
          Límite de Velocidad: *
          <input
            type="number"
            name="speedLimitKmh"
            value={formData.speedLimitKmh}
            onChange={handleChange}
            required
            min="1"
            max="200"
          />
          <span className="unit">km/h</span>
          <small>Se convertirá automáticamente a knots para Traccar</small>
        </label>
      </div>
    </fieldset>

    {/* Sección: Imagen */}
    <fieldset>
      <legend>📷 Imagen del Vehículo</legend>

      <div className="form-group">
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
        <div className="image-preview">
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
      <div className="error-message">
        ⚠️ {error}
      </div>
    )}

    {/* Botones */}
    <div className="form-actions">
      <button type="button" onClick={() => window.history.back()}>
        Cancelar
      </button>
      <button type="submit" disabled={loading}>
        {loading ? 'Creando...' : 'Crear GPS'}
      </button>
    </div>
  </form>
);
```

---

## 5. Código Completo

### 📄 Componente Completo (React + TypeScript)

```typescript
import React, { useState } from 'react';

// Opciones para dropdowns
const GPS_MODELS = [
  { value: 'GT06', label: 'GT06' },
  { value: 'TK103', label: 'TK103' },
  { value: 'TK102', label: 'TK102' },
  { value: 'OsmAnd', label: 'OsmAnd (App móvil)' },
  { value: 'GPS103', label: 'GPS103' },
  { value: 'H02', label: 'H02' },
  { value: 'T55', label: 'T55' },
  { value: 'T808', label: 'T808' },
  { value: 'Meiligao', label: 'Meiligao' },
  { value: 'Teltonika', label: 'Teltonika' },
  { value: 'Otro', label: 'Otro' }
];

const VEHICLE_TYPES = [
  { value: 'Auto', label: '🚗 Auto' },
  { value: 'Bus', label: '🚌 Bus' },
  { value: 'Camión', label: '🚚 Camión' },
  { value: 'Moto', label: '🏍️ Moto' },
  { value: 'Taxi', label: '🚕 Taxi' },
  { value: 'Ambulancia', label: '🚑 Ambulancia' },
  { value: 'Policía', label: '🚓 Policía' },
  { value: 'Otro', label: '❓ Otro' }
];

interface GPSFormData {
  name: string;
  uniqueId: string;
  deviceModel: string;
  phone: string;
  contact: string;
  vehicleType: string;
  placa: string;
  marca: string;
  modeloVehiculo: string;
  año: number;
  color: string;
  speedLimitKmh: number;
  image?: File;
}

const API_BASE_URL = 'http://localhost:8082/api';
const API_USER = 'admin';
const API_PASS = 'admin';

function CreateGPSForm() {
  const [formData, setFormData] = useState<GPSFormData>({
    name: '',
    uniqueId: '',
    deviceModel: '',
    phone: '',
    contact: '',
    vehicleType: 'Auto',
    placa: '',
    marca: '',
    modeloVehiculo: '',
    año: new Date().getFullYear(),
    color: '',
    speedLimitKmh: 80
  });

  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showOtherModel, setShowOtherModel] = useState(false);

  // Convertir km/h a knots
  const kmhToKnots = (kmh: number): number => {
    return kmh / 1.852;
  };

  // Validar uniqueId en tiempo real (con debounce)
  const validateUniqueId = async (uniqueId: string) => {
    if (!uniqueId || uniqueId.length < 10) {
      setUniqueIdStatus({ checking: false, exists: false, device: null });
      return;
    }

    setUniqueIdStatus({ checking: true, exists: false, device: null });
    
    const existingDevice = await checkUniqueIdExists(uniqueId);
    
    setUniqueIdStatus({
      checking: false,
      exists: existingDevice !== null,
      device: existingDevice
    });
  };

  // Manejar cambios en el formulario
  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    
    setFormData(prev => ({
      ...prev,
      [name]: name === 'año' || name === 'speedLimitKmh' 
        ? Number(value) 
        : value
    }));

    if (name === 'deviceModel' && value === 'Otro') {
      setShowOtherModel(true);
    } else if (name === 'deviceModel') {
      setShowOtherModel(false);
    }

    // Validar uniqueId en tiempo real cuando el usuario lo ingresa
    if (name === 'uniqueId') {
      // Debounce: esperar 500ms después de que el usuario deje de escribir
      const timeoutId = setTimeout(() => {
        validateUniqueId(value);
      }, 500);

      return () => clearTimeout(timeoutId);
    }
  };

  // Manejar selección de imagen
  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (!file.type.startsWith('image/')) {
        setError('Por favor seleccione una imagen válida');
        return;
      }

      if (file.size > 500 * 1024) {
        setError('La imagen es demasiado grande. Máximo 500 KB');
        return;
      }

      const reader = new FileReader();
      reader.onload = (e) => {
        setImagePreview(e.target?.result as string);
      };
      reader.readAsDataURL(file);

      setFormData(prev => ({ ...prev, image: file }));
      setError(null);
    }
  };

  // Verificar si el uniqueId ya existe
  const checkUniqueIdExists = async (uniqueId: string): Promise<any | null> => {
    try {
      const response = await fetch(
        `${API_BASE_URL}/devices?uniqueId=${uniqueId}`,
        {
          headers: {
            'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
          }
        }
      );

      if (response.ok) {
        const devices = await response.json();
        return devices.length > 0 ? devices[0] : null;  // Retorna el dispositivo si existe
      }
      return null;
    } catch (error) {
      console.error('Error al verificar uniqueId:', error);
      return null;
    }
  };

  // Actualizar dispositivo existente
  const updateDevice = async (deviceId: number, data: GPSFormData) => {
    const deviceData = {
      id: deviceId,
      name: data.name,
      uniqueId: data.uniqueId,
      status: 'offline',
      disabled: false,
      phone: data.phone || null,
      model: data.deviceModel || null,
      contact: data.contact || null,
      category: data.vehicleType,
      attributes: {
        placa: data.placa,
        marca: data.marca,
        modeloVehiculo: data.modeloVehiculo,
        año: data.año,
        color: data.color || null,
        speedLimit: kmhToKnots(data.speedLimitKmh)
      }
    };

    const response = await fetch(`${API_BASE_URL}/devices/${deviceId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
      },
      body: JSON.stringify(deviceData)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Error al actualizar dispositivo: ${errorText}`);
    }

    return await response.json();
  };

  // Enviar formulario
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      // Validar campos requeridos
      if (!formData.name || !formData.uniqueId || !formData.placa) {
        throw new Error('Por favor complete todos los campos requeridos');
      }

      // ⚠️ VALIDACIÓN: Verificar si el uniqueId ya existe
      const existingDevice = await checkUniqueIdExists(formData.uniqueId);
      
      if (existingDevice) {
        // El dispositivo ya existe
        const confirm = window.confirm(
          `⚠️ Ya existe un dispositivo con IMEI "${formData.uniqueId}".\n\n` +
          `Nombre actual: "${existingDevice.name}"\n` +
          `ID: ${existingDevice.id}\n\n` +
          `¿Desea actualizar el dispositivo existente en lugar de crear uno nuevo?`
        );

        if (!confirm) {
          setError(`El IMEI "${formData.uniqueId}" ya está en uso. Por favor use un IMEI diferente.`);
          setLoading(false);
          return;
        }

        // Actualizar dispositivo existente
        const device = await updateDevice(existingDevice.id, formData);
        console.log('Dispositivo actualizado:', device);

        // Subir imagen si existe
        if (formData.image && device.id) {
          const formDataImage = new FormData();
          formDataImage.append('file', formData.image);

          const imageResponse = await fetch(
            `${API_BASE_URL}/devices/${device.id}/image`,
            {
              method: 'POST',
              headers: {
                'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
              },
              body: formDataImage
            }
          );

          if (!imageResponse.ok) {
            console.warn('Dispositivo actualizado pero error al subir imagen');
          }
        }

        alert('✅ GPS actualizado exitosamente');
        
        // Resetear formulario
        setFormData({
          name: '',
          uniqueId: '',
          deviceModel: '',
          phone: '',
          contact: '',
          vehicleType: 'Auto',
          placa: '',
          marca: '',
          modeloVehiculo: '',
          año: new Date().getFullYear(),
          color: '',
          speedLimitKmh: 80
        });
        setImagePreview(null);
        setShowOtherModel(false);
        setLoading(false);
        return;
      }

      // Preparar datos del dispositivo (crear nuevo)
      const deviceData = {
        name: formData.name,
        uniqueId: formData.uniqueId,
        status: 'offline',
        disabled: false,
        phone: formData.phone || null,
        model: formData.deviceModel || null,        // Modelo del DISPOSITIVO GPS
        contact: formData.contact || null,
        category: formData.vehicleType,             // Tipo de VEHÍCULO
        attributes: {
          placa: formData.placa,
          marca: formData.marca,
          modeloVehiculo: formData.modeloVehiculo,  // Modelo del VEHÍCULO
          año: formData.año,
          color: formData.color || null,
          speedLimit: kmhToKnots(formData.speedLimitKmh)
        }
      };

      // Crear dispositivo
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
        
        // Verificar si es error de duplicado
        if (errorText.includes('Duplicate entry') || errorText.includes('uniqueid')) {
          throw new Error(
            `El IMEI "${formData.uniqueId}" ya está en uso. ` +
            `Por favor verifique el IMEI o use uno diferente.`
          );
        }
        
        throw new Error(`Error al crear dispositivo: ${errorText}`);
      }

      const device = await deviceResponse.json();

      // Subir imagen si existe
      if (formData.image && device.id) {
        const formDataImage = new FormData();
        formDataImage.append('file', formData.image);

        const imageResponse = await fetch(
          `${API_BASE_URL}/devices/${device.id}/image`,
          {
            method: 'POST',
            headers: {
              'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
            },
            body: formDataImage
          }
        );

        if (!imageResponse.ok) {
          console.warn('Dispositivo creado pero error al subir imagen');
        }
      }

      alert('✅ GPS creado exitosamente');
      
      // Resetear formulario
      setFormData({
        name: '',
        uniqueId: '',
        deviceModel: '',
        phone: '',
        contact: '',
        vehicleType: 'Auto',
        placa: '',
        marca: '',
        modeloVehiculo: '',
        año: new Date().getFullYear(),
        color: '',
        speedLimitKmh: 80
      });
      setImagePreview(null);
      setShowOtherModel(false);

    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="create-gps-container">
      <form onSubmit={handleSubmit} className="gps-form">
        <h2>Crear Nuevo GPS</h2>

        {/* Información del Dispositivo GPS */}
        <fieldset>
          <legend>📡 Información del Dispositivo GPS</legend>
          
          <div className="form-group">
            <label>
              Nombre del GPS: *
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleChange}
                required
                placeholder="Ej: Vehículo Principal"
              />
            </label>
          </div>

          <div className="form-group">
            <label>
              IMEI del GPS: *
              <input
                type="text"
                name="uniqueId"
                value={formData.uniqueId}
                onChange={handleChange}
                required
                pattern="[0-9]{10,15}"
                title="Debe ser un número de 10 a 15 dígitos"
                placeholder="123456789012345"
                className={uniqueIdStatus.exists ? 'error' : ''}
              />
              {uniqueIdStatus.checking && (
                <small style={{ color: '#666' }}>🔍 Verificando...</small>
              )}
              {uniqueIdStatus.exists && !uniqueIdStatus.checking && (
                <small style={{ color: '#c62828' }}>
                  ⚠️ Este IMEI ya está en uso. Dispositivo: "{uniqueIdStatus.device?.name}" (ID: {uniqueIdStatus.device?.id})
                </small>
              )}
              {!uniqueIdStatus.exists && !uniqueIdStatus.checking && formData.uniqueId.length >= 10 && (
                <small style={{ color: '#4CAF50' }}>✅ IMEI disponible</small>
              )}
            </label>
          </div>

          <div className="form-group">
            <label>
              Modelo del Dispositivo GPS: *
              <select
                name="deviceModel"
                value={formData.deviceModel}
                onChange={handleChange}
                required
              >
                <option value="">Seleccione un modelo</option>
                {GPS_MODELS.map(model => (
                  <option key={model.value} value={model.value}>
                    {model.label}
                  </option>
                ))}
              </select>
            </label>
          </div>

          {showOtherModel && (
            <div className="form-group">
              <label>
                Especifique el modelo:
                <input
                  type="text"
                  name="deviceModel"
                  value={formData.deviceModel}
                  onChange={handleChange}
                  placeholder="Ingrese el modelo del GPS"
                />
              </label>
            </div>
          )}

          <div className="form-group">
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

          <div className="form-group">
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

        {/* Información del Vehículo */}
        <fieldset>
          <legend>🚗 Información del Vehículo</legend>

          <div className="form-group">
            <label>
              Tipo de Vehículo: *
              <select
                name="vehicleType"
                value={formData.vehicleType}
                onChange={handleChange}
                required
              >
                {VEHICLE_TYPES.map(type => (
                  <option key={type.value} value={type.value}>
                    {type.label}
                  </option>
                ))}
              </select>
            </label>
          </div>

          <div className="form-group">
            <label>
              Placa: *
              <input
                type="text"
                name="placa"
                value={formData.placa}
                onChange={handleChange}
                required
                style={{ textTransform: 'uppercase' }}
                placeholder="ABC-123"
              />
            </label>
          </div>

          <div className="form-group">
            <label>
              Marca: *
              <input
                type="text"
                name="marca"
                value={formData.marca}
                onChange={handleChange}
                required
                placeholder="Toyota"
              />
            </label>
          </div>

          <div className="form-group">
            <label>
              Modelo del Vehículo: *
              <input
                type="text"
                name="modeloVehiculo"
                value={formData.modeloVehiculo}
                onChange={handleChange}
                required
                placeholder="Corolla"
              />
            </label>
          </div>

          <div className="form-group">
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

          <div className="form-group">
            <label>
              Color:
              <input
                type="text"
                name="color"
                value={formData.color}
                onChange={handleChange}
                placeholder="Blanco"
              />
            </label>
          </div>

          <div className="form-group">
            <label>
              Límite de Velocidad: *
              <input
                type="number"
                name="speedLimitKmh"
                value={formData.speedLimitKmh}
                onChange={handleChange}
                required
                min="1"
                max="200"
              />
              <span className="unit">km/h</span>
              <small>Se convertirá automáticamente a knots para Traccar</small>
            </label>
          </div>
        </fieldset>

        {/* Imagen */}
        <fieldset>
          <legend>📷 Imagen del Vehículo</legend>

          <div className="form-group">
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
            <div className="image-preview">
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
          <div className="error-message">
            ⚠️ {error}
          </div>
        )}

        {/* Botones */}
        <div className="form-actions">
          <button type="button" onClick={() => window.history.back()}>
            Cancelar
          </button>
          <button type="submit" disabled={loading}>
            {loading ? 'Creando...' : 'Crear GPS'}
          </button>
        </div>
      </form>
    </div>
  );
}

export default CreateGPSForm;
```

---

### 🎨 CSS Básico (Opcional)

```css
.create-gps-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.gps-form {
  background: white;
  padding: 30px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.gps-form h2 {
  margin-bottom: 20px;
  color: #333;
}

.gps-form fieldset {
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 20px;
  margin-bottom: 20px;
}

.gps-form legend {
  font-weight: bold;
  padding: 0 10px;
  color: #555;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: 500;
  color: #333;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #4CAF50;
}

.form-group small {
  display: block;
  margin-top: 5px;
  color: #666;
  font-size: 12px;
}

.unit {
  margin-left: 5px;
  color: #666;
}

.image-preview img {
  border-radius: 4px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.error-message {
  background: #ffebee;
  color: #c62828;
  padding: 12px;
  border-radius: 4px;
  margin-bottom: 20px;
}

.form-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  margin-top: 20px;
}

.form-actions button {
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.form-actions button[type="submit"] {
  background: #4CAF50;
  color: white;
}

.form-actions button[type="submit"]:hover:not(:disabled) {
  background: #45a049;
}

.form-actions button[type="submit"]:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.form-actions button[type="button"] {
  background: #f5f5f5;
  color: #333;
}

.form-actions button[type="button"]:hover {
  background: #e0e0e0;
}
```

---

## 📝 Resumen del Flujo

```
1. USUARIO ABRE EL FORMULARIO
   ↓
2. LLENA LOS CAMPOS:
   - Información del Dispositivo GPS (name, uniqueId, model, phone, contact)
   - Información del Vehículo (tipo, placa, marca, modelo, año, color, límite velocidad)
   - Imagen (opcional)
   ↓
3. VALIDACIÓN CLIENTE-SIDE
   - Campos requeridos
   - Formato de IMEI
   - Tamaño de imagen
   ↓
4. CONVERSIÓN DE DATOS
   - speedLimit: km/h → knots
   - Organizar en estructura de Traccar
   ↓
5. CREAR DISPOSITIVO (POST /api/devices)
   {
     name, uniqueId,
     model: "GT06",              // ← Modelo del DISPOSITIVO GPS
     category: "Auto",           // ← Tipo de VEHÍCULO
     attributes: {
       placa, marca,
       modeloVehiculo: "Corolla", // ← Modelo del VEHÍCULO
       año, color, speedLimit
     }
   }
   ↓
6. OBTENER ID DEL DISPOSITIVO CREADO
   ↓
7. SUBIR IMAGEN (POST /api/devices/{id}/image)
   - Solo si el usuario seleccionó una imagen
   ↓
8. CONFIRMACIÓN
   - Mostrar mensaje de éxito
   - Limpiar formulario
   - Opcional: Redirigir a lista de GPS
```

---

## 6. Obtener Datos de un Dispositivo

### 📥 Endpoints para Obtener Dispositivos

#### **1. Obtener Todos los Dispositivos**

```typescript
// GET /api/devices
async function getAllDevices(): Promise<Device[]> {
  const response = await fetch('http://localhost:8082/api/devices', {
    headers: {
      'Authorization': 'Basic ' + btoa('admin:admin')
    }
  });

  if (response.ok) {
    return await response.json();
  }
  throw new Error('Error al obtener dispositivos');
}
```

#### **2. Obtener un Dispositivo por ID**

```typescript
// GET /api/devices/{id}
async function getDeviceById(deviceId: number): Promise<Device> {
  const response = await fetch(`http://localhost:8082/api/devices/${deviceId}`, {
    headers: {
      'Authorization': 'Basic ' + btoa('admin:admin')
    }
  });

  if (response.ok) {
    return await response.json();
  }
  throw new Error(`Error al obtener dispositivo ${deviceId}`);
}
```

#### **3. Buscar Dispositivo por uniqueId**

```typescript
// GET /api/devices?uniqueId=XXXXX
async function getDeviceByUniqueId(uniqueId: string): Promise<Device | null> {
  const response = await fetch(
    `http://localhost:8082/api/devices?uniqueId=${uniqueId}`,
    {
      headers: {
        'Authorization': 'Basic ' + btoa('admin:admin')
      }
    }
  );

  if (response.ok) {
    const devices = await response.json();
    return devices.length > 0 ? devices[0] : null;
  }
  throw new Error('Error al buscar dispositivo');
}
```

---

### 🔄 Convertir Datos del Backend al Formulario

Cuando obtienes un dispositivo de la API, necesitas convertir los datos del formato de Traccar al formato del formulario:

```typescript
// Función para convertir Device (API) a GPSFormData (Formulario)
function deviceToFormData(device: Device): GPSFormData {
  // Convertir knots a km/h para el límite de velocidad
  const speedLimitKnots = device.attributes?.speedLimit || 0;
  const speedLimitKmh = speedLimitKnots * 1.852;

  return {
    name: device.name || '',
    uniqueId: device.uniqueId || '',
    deviceModel: device.model || '',           // Modelo del DISPOSITIVO GPS
    phone: device.phone || '',
    contact: device.contact || '',
    vehicleType: device.category || 'Auto',    // Tipo de VEHÍCULO
    placa: device.attributes?.placa || '',
    marca: device.attributes?.marca || '',
    modeloVehiculo: device.attributes?.modeloVehiculo || '',  // Modelo del VEHÍCULO
    año: device.attributes?.año || new Date().getFullYear(),
    color: device.attributes?.color || '',
    speedLimitKmh: speedLimitKmh || 80
  };
}
```

---

### 📋 Ejemplo Completo: Cargar Dispositivo para Editar

```typescript
import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom'; // Si usas React Router

function EditGPSForm() {
  const { deviceId } = useParams<{ deviceId: string }>();
  const [formData, setFormData] = useState<GPSFormData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Cargar dispositivo al montar el componente
  useEffect(() => {
    if (deviceId) {
      loadDevice(Number(deviceId));
    }
  }, [deviceId]);

  const loadDevice = async (id: number) => {
    try {
      setLoading(true);
      setError(null);

      // 1. Obtener dispositivo de la API
      const device = await getDeviceById(id);

      // 2. Convertir a formato del formulario
      const formDataConverted = deviceToFormData(device);

      // 3. Cargar imagen si existe
      const imageUrl = getDeviceImageUrl(device);
      if (imageUrl) {
        // Opcional: cargar la imagen como preview
        // Puedes usar fetch para obtener la imagen y convertirla a base64
      }

      setFormData(formDataConverted);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div>Cargando dispositivo...</div>;
  }

  if (error) {
    return <div>Error: {error}</div>;
  }

  if (!formData) {
    return <div>No se encontró el dispositivo</div>;
  }

  // Renderizar formulario con los datos cargados
  return (
    <CreateGPSForm 
      initialData={formData} 
      deviceId={deviceId ? Number(deviceId) : undefined}
      mode="edit"
    />
  );
}
```

---

### 🖼️ Obtener URL de la Imagen del Dispositivo

#### **Endpoint para Obtener Imagen:**

```
GET /api/media/{uniqueId}/{filename}
```

**Estructura:**
- **Base URL:** `http://localhost:8082/api/media`
- **Path:** `/{uniqueId}/{filename}`
- **Ejemplo:** `http://localhost:8082/api/media/123456789012345/device.jpg`

**Características:**
- ✅ **Requiere autenticación** (sesión válida o token)
- ✅ **Verifica permisos** - Solo usuarios con acceso al dispositivo pueden ver la imagen
- ✅ **Formato del archivo:** `device.{extension}` (device.jpg, device.png, etc.)
- ✅ **Extensiones soportadas:** jpg, jpeg, png, gif, webp, svg

**Nota:** El `uniqueId` en la URL es el `uniqueId` del dispositivo, NO el `id`.

---

#### **Ejemplo de Función para Obtener URL:**

```typescript
// Función para obtener la URL de la imagen del dispositivo
function getDeviceImageUrl(device: Device): string | null {
  if (!device || !device.uniqueId) {
    return null;
  }
  
  // La imagen se guarda como: device.{extension}
  // Por defecto intentamos con .jpg (más común)
  const baseUrl = 'http://localhost:8082/api/media';
  return `${baseUrl}/${device.uniqueId}/device.jpg`;
}

// Función mejorada que intenta diferentes extensiones
async function getDeviceImageUrlWithFallback(device: Device): Promise<string | null> {
  if (!device || !device.uniqueId) {
    return null;
  }
  
  const baseUrl = 'http://localhost:8082/api/media';
  const extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  
  // Intentar con cada extensión hasta encontrar una que exista
  for (const ext of extensions) {
    const url = `${baseUrl}/${device.uniqueId}/device.${ext}`;
    if (await checkImageExists(url)) {
      return url;
    }
  }
  
  return null; // No se encontró imagen
}

// Función para verificar si la imagen existe
async function checkImageExists(imageUrl: string): Promise<boolean> {
  try {
    const response = await fetch(imageUrl, { 
      method: 'HEAD',
      credentials: 'include'  // Incluir cookies de sesión
    });
    return response.ok;
  } catch {
    return false;
  }
}
```

---

#### **Ejemplo Completo: Cargar y Mostrar Imagen**

```typescript
import React, { useState, useEffect } from 'react';

function DeviceImage({ device }: { device: Device }) {
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDeviceImage();
  }, [device]);

  const loadDeviceImage = async () => {
    if (!device || !device.uniqueId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      // Intentar diferentes extensiones
      const extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      const baseUrl = 'http://localhost:8082/api/media';

      for (const ext of extensions) {
        const url = `${baseUrl}/${device.uniqueId}/device.${ext}`;
        
        const response = await fetch(url, {
          method: 'HEAD',
          credentials: 'include'  // Incluir cookies de sesión
        });

        if (response.ok) {
          setImageUrl(url);
          setLoading(false);
          return;
        }
      }

      // No se encontró imagen
      setImageUrl(null);
      setError('No hay imagen disponible');
    } catch (err: any) {
      setError('Error al cargar imagen');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div>Cargando imagen...</div>;
  }

  if (error || !imageUrl) {
    return (
      <div className="no-image">
        <span>📷</span>
        <p>No hay imagen disponible</p>
      </div>
    );
  }

  return (
    <img
      src={imageUrl}
      alt={`Imagen de ${device.name}`}
      onError={() => setError('Error al cargar imagen')}
      style={{ maxWidth: '100%', height: 'auto' }}
    />
  );
}
```

---

#### **⚠️ Importante: Autenticación**

El endpoint `/api/media/{uniqueId}/{filename}` **requiere autenticación**. Tienes dos opciones:

**Opción 1: Usar cookies de sesión (si estás en la misma aplicación web)**
```typescript
fetch(imageUrl, {
  credentials: 'include'  // Incluye cookies automáticamente
});
```

**Opción 2: Usar Basic Auth o Token**
```typescript
fetch(imageUrl, {
  headers: {
    'Authorization': 'Basic ' + btoa('admin:admin')
    // O
    // 'Authorization': 'Bearer ' + token
  }
});
```

---

#### **Ejemplo con Basic Auth:**

```typescript
function getDeviceImageUrlWithAuth(device: Device, username: string, password: string): string | null {
  if (!device || !device.uniqueId) {
    return null;
  }
  
  const baseUrl = 'http://localhost:8082/api/media';
  const imageUrl = `${baseUrl}/${device.uniqueId}/device.jpg`;
  
  // La autenticación se hace en el fetch, no en la URL
  return imageUrl;
}

// Usar la imagen en un <img> tag con autenticación
function DeviceImageWithAuth({ device }: { device: Device }) {
  const [imageDataUrl, setImageDataUrl] = useState<string | null>(null);

  useEffect(() => {
    const loadImage = async () => {
      const imageUrl = getDeviceImageUrlWithAuth(device, 'admin', 'admin');
      if (!imageUrl) return;

      try {
        const response = await fetch(imageUrl, {
          headers: {
            'Authorization': 'Basic ' + btoa('admin:admin')
          }
        });

        if (response.ok) {
          const blob = await response.blob();
          const reader = new FileReader();
          reader.onloadend = () => {
            setImageDataUrl(reader.result as string);
          };
          reader.readAsDataURL(blob);
        }
      } catch (error) {
        console.error('Error al cargar imagen:', error);
      }
    };

    loadImage();
  }, [device]);

  if (!imageDataUrl) {
    return <div>No hay imagen disponible</div>;
  }

  return <img src={imageDataUrl} alt={device.name} />;
}
```

---

#### **📋 Resumen del Endpoint**

| Aspecto | Detalle |
|---------|---------|
| **Endpoint** | `GET /api/media/{uniqueId}/{filename}` |
| **Ejemplo** | `GET /api/media/123456789012345/device.jpg` |
| **Autenticación** | ✅ Requerida (sesión o Basic Auth/Token) |
| **Permisos** | ✅ Verifica que el usuario tenga acceso al dispositivo |
| **Formato archivo** | `device.{extension}` |
| **Extensiones** | jpg, jpeg, png, gif, webp, svg |
| **Ubicación física** | `media/{uniqueId}/device.{extension}` |
| **Código 200** | Imagen encontrada y servida |
| **Código 401** | No autenticado |
| **Código 403** | Sin permisos para ver el dispositivo |
| **Código 404** | Imagen no encontrada |

---

## 7. Editar un Dispositivo Existente

### ✏️ Endpoint para Actualizar

```typescript
// PUT /api/devices/{id}
async function updateDevice(deviceId: number, deviceData: Partial<Device>): Promise<Device> {
  // Primero obtener el dispositivo actual para mantener los campos que no se actualizan
  const currentDevice = await getDeviceById(deviceId);

  // Fusionar datos actuales con los nuevos
  const updatedDevice = {
    ...currentDevice,
    ...deviceData,
    id: deviceId  // Asegurar que el ID esté presente
  };

  const response = await fetch(`http://localhost:8082/api/devices/${deviceId}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ' + btoa('admin:admin')
    },
    body: JSON.stringify(updatedDevice)
  });

  if (response.ok) {
    return await response.json();
  }

  const errorText = await response.text();
  throw new Error(`Error al actualizar dispositivo: ${errorText}`);
}
```

---

### 🔄 Convertir Formulario a Datos del Backend

```typescript
// Función para convertir GPSFormData (Formulario) a Device (API)
function formDataToDevice(formData: GPSFormData, existingDevice?: Device): Partial<Device> {
  return {
    name: formData.name,
    uniqueId: formData.uniqueId,
    phone: formData.phone || null,
    model: formData.deviceModel || null,        // Modelo del DISPOSITIVO GPS
    contact: formData.contact || null,
    category: formData.vehicleType,             // Tipo de VEHÍCULO
    attributes: {
      // Mantener atributos existentes que no se editan
      ...(existingDevice?.attributes || {}),
      // Actualizar con los nuevos valores
      placa: formData.placa,
      marca: formData.marca,
      modeloVehiculo: formData.modeloVehiculo,  // Modelo del VEHÍCULO
      año: formData.año,
      color: formData.color || null,
      speedLimit: kmhToKnots(formData.speedLimitKmh)
    }
  };
}
```

---

### 📝 Función Completa de Actualización

```typescript
const handleUpdate = async (deviceId: number, formData: GPSFormData) => {
  try {
    setLoading(true);
    setError(null);

    // 1. Validar campos requeridos
    if (!formData.name || !formData.uniqueId || !formData.placa) {
      throw new Error('Por favor complete todos los campos requeridos');
    }

    // 2. Obtener dispositivo actual (para mantener datos no editados)
    const currentDevice = await getDeviceById(deviceId);

    // 3. Convertir datos del formulario al formato de la API
    const deviceData = formDataToDevice(formData, currentDevice);

    // 4. Actualizar dispositivo
    const updatedDevice = await updateDevice(deviceId, deviceData);
    console.log('Dispositivo actualizado:', updatedDevice);

    // 5. Actualizar imagen si se seleccionó una nueva
    if (formData.image) {
      const formDataImage = new FormData();
      formDataImage.append('file', formData.image);

      const imageResponse = await fetch(
        `http://localhost:8082/api/devices/${deviceId}/image`,
        {
          method: 'POST',
          headers: {
            'Authorization': 'Basic ' + btoa('admin:admin')
          },
          body: formDataImage
        }
      );

      if (!imageResponse.ok) {
        console.warn('Dispositivo actualizado pero error al subir imagen');
      } else {
        console.log('Imagen actualizada exitosamente');
      }
    }

    alert('✅ GPS actualizado exitosamente');
    
    // 6. Opcional: Redirigir o recargar datos
    // window.location.href = '/devices';
    // O recargar el dispositivo actualizado
    await loadDevice(deviceId);

  } catch (err: any) {
    setError(err.message);
  } finally {
    setLoading(false);
  }
};
```

---

### 🎯 Manejo de Errores al Actualizar

```typescript
const handleUpdate = async (deviceId: number, formData: GPSFormData) => {
  try {
    // ... código de actualización ...
  } catch (err: any) {
    // Manejar diferentes tipos de errores
    if (err.message.includes('Duplicate entry') || err.message.includes('uniqueid')) {
      setError(
        `El IMEI "${formData.uniqueId}" ya está en uso por otro dispositivo. ` +
        `Por favor use un IMEI diferente.`
      );
    } else if (err.message.includes('404') || err.message.includes('Not Found')) {
      setError('El dispositivo no existe o fue eliminado.');
    } else if (err.message.includes('401') || err.message.includes('Unauthorized')) {
      setError('No tiene permisos para editar este dispositivo.');
    } else {
      setError(`Error al actualizar: ${err.message}`);
    }
  }
};
```

---

## 8. Componente Completo: Crear y Editar

### 📄 Componente Unificado (React + TypeScript)

```typescript
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';

// ... (GPS_MODELS, VEHICLE_TYPES, interfaces, etc. del código anterior) ...

interface CreateEditGPSFormProps {
  deviceId?: number;  // Si está presente, es modo edición
  mode?: 'create' | 'edit';
}

function CreateEditGPSForm({ deviceId, mode = 'create' }: CreateEditGPSFormProps) {
  const navigate = useNavigate();
  const isEditMode = mode === 'edit' && deviceId !== undefined;

  const [formData, setFormData] = useState<GPSFormData>({
    name: '',
    uniqueId: '',
    deviceModel: '',
    phone: '',
    contact: '',
    vehicleType: 'Auto',
    placa: '',
    marca: '',
    modeloVehiculo: '',
    año: new Date().getFullYear(),
    color: '',
    speedLimitKmh: 80
  });

  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [existingImageUrl, setExistingImageUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [loadingDevice, setLoadingDevice] = useState(isEditMode);
  const [error, setError] = useState<string | null>(null);
  const [showOtherModel, setShowOtherModel] = useState(false);
  const [uniqueIdStatus, setUniqueIdStatus] = useState<{
    checking: boolean;
    exists: boolean;
    device: any | null;
  }>({ checking: false, exists: false, device: null });

  // Cargar dispositivo si está en modo edición
  useEffect(() => {
    if (isEditMode && deviceId) {
      loadDevice(deviceId);
    }
  }, [isEditMode, deviceId]);

  // Función para cargar dispositivo
  const loadDevice = async (id: number) => {
    try {
      setLoadingDevice(true);
      setError(null);

      // 1. Obtener dispositivo
      const device = await getDeviceById(id);

      // 2. Convertir a formato del formulario
      const formDataConverted = deviceToFormData(device);
      setFormData(formDataConverted);

      // 3. Cargar imagen existente si hay
      const imageUrl = getDeviceImageUrl(device);
      if (imageUrl && await checkImageExists(imageUrl)) {
        setExistingImageUrl(imageUrl);
      }

      // 4. Verificar si "Otro" está seleccionado en modelo
      if (formDataConverted.deviceModel && 
          !GPS_MODELS.some(m => m.value === formDataConverted.deviceModel)) {
        setShowOtherModel(true);
      }

    } catch (err: any) {
      setError(`Error al cargar dispositivo: ${err.message}`);
    } finally {
      setLoadingDevice(false);
    }
  };

  // Función para convertir Device a FormData
  const deviceToFormData = (device: Device): GPSFormData => {
    const speedLimitKnots = device.attributes?.speedLimit || 0;
    const speedLimitKmh = speedLimitKnots * 1.852;

    return {
      name: device.name || '',
      uniqueId: device.uniqueId || '',
      deviceModel: device.model || '',
      phone: device.phone || '',
      contact: device.contact || '',
      vehicleType: device.category || 'Auto',
      placa: device.attributes?.placa || '',
      marca: device.attributes?.marca || '',
      modeloVehiculo: device.attributes?.modeloVehiculo || '',
      año: device.attributes?.año || new Date().getFullYear(),
      color: device.attributes?.color || '',
      speedLimitKmh: speedLimitKmh || 80
    };
  };

  // Función para convertir FormData a Device
  const formDataToDevice = (data: GPSFormData, existingDevice?: Device): Partial<Device> => {
    return {
      name: data.name,
      uniqueId: data.uniqueId,
      phone: data.phone || null,
      model: data.deviceModel || null,
      contact: data.contact || null,
      category: data.vehicleType,
      attributes: {
        ...(existingDevice?.attributes || {}),
        placa: data.placa,
        marca: data.marca,
        modeloVehiculo: data.modeloVehiculo,
        año: data.año,
        color: data.color || null,
        speedLimit: kmhToKnots(data.speedLimitKmh)
      }
    };
  };

  // Función para obtener dispositivo por ID
  const getDeviceById = async (id: number): Promise<Device> => {
    const response = await fetch(`${API_BASE_URL}/devices/${id}`, {
      headers: {
        'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
      }
    });

    if (response.ok) {
      return await response.json();
    }
    throw new Error(`Error al obtener dispositivo ${id}`);
  };

  // Función para actualizar dispositivo
  const updateDevice = async (id: number, deviceData: Partial<Device>): Promise<Device> => {
    const currentDevice = await getDeviceById(id);
    const updatedDevice = {
      ...currentDevice,
      ...deviceData,
      id: id
    };

    const response = await fetch(`${API_BASE_URL}/devices/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
      },
      body: JSON.stringify(updatedDevice)
    });

    if (response.ok) {
      return await response.json();
    }

    const errorText = await response.text();
    throw new Error(`Error al actualizar: ${errorText}`);
  };

  // Función para crear dispositivo
  const createDevice = async (deviceData: Partial<Device>): Promise<Device> => {
    const response = await fetch(`${API_BASE_URL}/devices`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
      },
      body: JSON.stringify(deviceData)
    });

    if (response.ok) {
      return await response.json();
    }

    const errorText = await response.text();
    throw new Error(`Error al crear: ${errorText}`);
  };

  // Función para subir imagen
  const uploadImage = async (deviceId: number, imageFile: File): Promise<void> => {
    const formDataImage = new FormData();
    formDataImage.append('file', imageFile);

    const response = await fetch(`${API_BASE_URL}/devices/${deviceId}/image`, {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
      },
      body: formDataImage
    });

    if (!response.ok) {
      throw new Error('Error al subir imagen');
    }
  };

  // Función para obtener URL de imagen
  const getDeviceImageUrl = (device: Device): string | null => {
    if (!device || !device.uniqueId) return null;
    return `http://localhost:8082/api/media/${device.uniqueId}/device.jpg`;
  };

  // Función para verificar si imagen existe
  const checkImageExists = async (imageUrl: string): Promise<boolean> => {
    try {
      const response = await fetch(imageUrl, { method: 'HEAD' });
      return response.ok;
    } catch {
      return false;
    }
  };

  // Convertir km/h a knots
  const kmhToKnots = (kmh: number): number => {
    return kmh / 1.852;
  };

  // Verificar si el uniqueId ya existe
  const checkUniqueIdExists = async (uniqueId: string): Promise<any | null> => {
    try {
      const response = await fetch(
        `${API_BASE_URL}/devices?uniqueId=${uniqueId}`,
        {
          headers: {
            'Authorization': 'Basic ' + btoa(`${API_USER}:${API_PASS}`)
          }
        }
      );

      if (response.ok) {
        const devices = await response.json();
        return devices.length > 0 ? devices[0] : null;
      }
      return null;
    } catch (error) {
      console.error('Error al verificar uniqueId:', error);
      return null;
    }
  };

  // Validar uniqueId en tiempo real (con debounce)
  const validateUniqueId = async (uniqueId: string) => {
    if (!uniqueId || uniqueId.length < 10) {
      setUniqueIdStatus({ checking: false, exists: false, device: null });
      return;
    }

    setUniqueIdStatus({ checking: true, exists: false, device: null });
    
    const existingDevice = await checkUniqueIdExists(uniqueId);
    
    // En modo edición, ignorar si el dispositivo encontrado es el mismo que estamos editando
    if (isEditMode && deviceId && existingDevice && existingDevice.id === deviceId) {
      setUniqueIdStatus({ checking: false, exists: false, device: null });
      return;
    }
    
    setUniqueIdStatus({
      checking: false,
      exists: existingDevice !== null,
      device: existingDevice
    });
  };

  // Manejar cambios en el formulario
  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    
    setFormData(prev => ({
      ...prev,
      [name]: name === 'año' || name === 'speedLimitKmh' 
        ? Number(value) 
        : value
    }));

    if (name === 'deviceModel' && value === 'Otro') {
      setShowOtherModel(true);
    } else if (name === 'deviceModel') {
      setShowOtherModel(false);
    }

    // Validar uniqueId en tiempo real cuando el usuario lo ingresa
    if (name === 'uniqueId') {
      // Debounce: esperar 500ms después de que el usuario deje de escribir
      const timeoutId = setTimeout(() => {
        validateUniqueId(value);
      }, 500);

      return () => clearTimeout(timeoutId);
    }
  };

  // Manejar selección de imagen
  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (!file.type.startsWith('image/')) {
        setError('Por favor seleccione una imagen válida');
        return;
      }

      if (file.size > 500 * 1024) {
        setError('La imagen es demasiado grande. Máximo 500 KB');
        return;
      }

      const reader = new FileReader();
      reader.onload = (e) => {
        setImagePreview(e.target?.result as string);
        setExistingImageUrl(null); // Ocultar imagen existente si se selecciona nueva
      };
      reader.readAsDataURL(file);

      setFormData(prev => ({ ...prev, image: file }));
      setError(null);
    }
  };

  // Función principal de envío (crear o actualizar)
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      // Validar campos requeridos
      if (!formData.name || !formData.uniqueId || !formData.placa) {
        throw new Error('Por favor complete todos los campos requeridos');
      }

      let device: Device;

      if (isEditMode && deviceId) {
        // MODO EDICIÓN: Actualizar dispositivo existente
        
        // Verificar si el uniqueId cambió y si ya existe en otro dispositivo
        const currentDevice = await getDeviceById(deviceId);
        if (formData.uniqueId !== currentDevice.uniqueId) {
          const existingDevice = await checkUniqueIdExists(formData.uniqueId);
          if (existingDevice && existingDevice.id !== deviceId) {
            throw new Error(
              `El IMEI "${formData.uniqueId}" ya está en uso por otro dispositivo. ` +
              `Por favor use un IMEI diferente.`
            );
          }
        }

        // Convertir datos y actualizar
        const deviceData = formDataToDevice(formData, currentDevice);
        device = await updateDevice(deviceId, deviceData);
        
        // Subir nueva imagen si se seleccionó
        if (formData.image) {
          await uploadImage(deviceId, formData.image);
        }

        alert('✅ GPS actualizado exitosamente');
        
        // Opcional: Recargar datos actualizados
        await loadDevice(deviceId);

      } else {
        // MODO CREACIÓN: Crear nuevo dispositivo
        
        // Verificar si el uniqueId ya existe
        const existingDevice = await checkUniqueIdExists(formData.uniqueId);
        
        if (existingDevice) {
          const confirm = window.confirm(
            `⚠️ Ya existe un dispositivo con IMEI "${formData.uniqueId}".\n\n` +
            `Nombre actual: "${existingDevice.name}"\n` +
            `ID: ${existingDevice.id}\n\n` +
            `¿Desea actualizar el dispositivo existente en lugar de crear uno nuevo?`
          );

          if (confirm) {
            // Actualizar dispositivo existente
            const deviceData = formDataToDevice(formData, existingDevice);
            device = await updateDevice(existingDevice.id, deviceData);
            
            if (formData.image) {
              await uploadImage(existingDevice.id, formData.image);
            }

            alert('✅ GPS actualizado exitosamente');
            navigate(`/devices/${existingDevice.id}/edit`);
            return;
          } else {
            setError(`El IMEI "${formData.uniqueId}" ya está en uso. Por favor use un IMEI diferente.`);
            setLoading(false);
            return;
          }
        }

        // Crear nuevo dispositivo
        const deviceData = formDataToDevice(formData);
        device = await createDevice(deviceData);
        
        // Subir imagen si existe
        if (formData.image && device.id) {
          await uploadImage(device.id, formData.image);
        }

        alert('✅ GPS creado exitosamente');
        
        // Opcional: Redirigir a edición del nuevo dispositivo
        navigate(`/devices/${device.id}/edit`);
      }

      // Resetear formulario solo si no estamos en modo edición
      if (!isEditMode) {
        setFormData({
          name: '',
          uniqueId: '',
          deviceModel: '',
          phone: '',
          contact: '',
          vehicleType: 'Auto',
          placa: '',
          marca: '',
          modeloVehiculo: '',
          año: new Date().getFullYear(),
          color: '',
          speedLimitKmh: 80
        });
        setImagePreview(null);
        setShowOtherModel(false);
      }

    } catch (err: any) {
      if (err.message.includes('Duplicate entry') || err.message.includes('uniqueid')) {
        setError(
          `El IMEI "${formData.uniqueId}" ya está en uso. ` +
          `Por favor verifique el IMEI o use uno diferente.`
        );
      } else {
        setError(err.message);
      }
    } finally {
      setLoading(false);
    }
  };

  // Mostrar loading mientras se carga el dispositivo
  if (loadingDevice) {
    return (
      <div className="loading-container">
        <div>Cargando dispositivo...</div>
      </div>
    );
  }

  return (
    <div className="create-gps-container">
      <form onSubmit={handleSubmit} className="gps-form">
        <h2>{isEditMode ? 'Editar GPS' : 'Crear Nuevo GPS'}</h2>

        {/* Información del Dispositivo GPS */}
        <fieldset>
          <legend>📡 Información del Dispositivo GPS</legend>
          
          <div className="form-group">
            <label>
              Nombre del GPS: *
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleChange}
                required
                placeholder="Ej: Vehículo Principal"
              />
            </label>
          </div>

          <div className="form-group">
            <label>
              IMEI del GPS: *
              <input
                type="text"
                name="uniqueId"
                value={formData.uniqueId}
                onChange={handleChange}
                required
                pattern="[0-9]{10,15}"
                title="Debe ser un número de 10 a 15 dígitos"
                placeholder="123456789012345"
                className={uniqueIdStatus.exists ? 'error' : ''}
                disabled={isEditMode}  // No permitir cambiar IMEI en edición
              />
              {isEditMode && (
                <small style={{ color: '#666' }}>
                  ℹ️ El IMEI no se puede cambiar después de crear el dispositivo
                </small>
              )}
              {!isEditMode && uniqueIdStatus.checking && (
                <small style={{ color: '#666' }}>🔍 Verificando...</small>
              )}
              {!isEditMode && uniqueIdStatus.exists && !uniqueIdStatus.checking && (
                <small style={{ color: '#c62828' }}>
                  ⚠️ Este IMEI ya está en uso. Dispositivo: "{uniqueIdStatus.device?.name}" (ID: {uniqueIdStatus.device?.id})
                </small>
              )}
              {!isEditMode && !uniqueIdStatus.exists && !uniqueIdStatus.checking && formData.uniqueId.length >= 10 && (
                <small style={{ color: '#4CAF50' }}>✅ IMEI disponible</small>
              )}
            </label>
          </div>

          <div className="form-group">
            <label>
              Modelo del Dispositivo GPS: *
              <select
                name="deviceModel"
                value={formData.deviceModel}
                onChange={handleChange}
                required
              >
                <option value="">Seleccione un modelo</option>
                {GPS_MODELS.map(model => (
                  <option key={model.value} value={model.value}>
                    {model.label}
                  </option>
                ))}
              </select>
            </label>
          </div>

          {showOtherModel && (
            <div className="form-group">
              <label>
                Especifique el modelo:
                <input
                  type="text"
                  name="deviceModel"
                  value={formData.deviceModel}
                  onChange={handleChange}
                  placeholder="Ingrese el modelo del GPS"
                />
              </label>
            </div>
          )}

          <div className="form-group">
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

          <div className="form-group">
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

        {/* Información del Vehículo */}
        <fieldset>
          <legend>🚗 Información del Vehículo</legend>

          <div className="form-group">
            <label>
              Tipo de Vehículo: *
              <select
                name="vehicleType"
                value={formData.vehicleType}
                onChange={handleChange}
                required
              >
                {VEHICLE_TYPES.map(type => (
                  <option key={type.value} value={type.value}>
                    {type.label}
                  </option>
                ))}
              </select>
            </label>
          </div>

          <div className="form-group">
            <label>
              Placa: *
              <input
                type="text"
                name="placa"
                value={formData.placa}
                onChange={handleChange}
                required
                style={{ textTransform: 'uppercase' }}
                placeholder="ABC-123"
              />
            </label>
          </div>

          <div className="form-group">
            <label>
              Marca: *
              <input
                type="text"
                name="marca"
                value={formData.marca}
                onChange={handleChange}
                required
                placeholder="Toyota"
              />
            </label>
          </div>

          <div className="form-group">
            <label>
              Modelo del Vehículo: *
              <input
                type="text"
                name="modeloVehiculo"
                value={formData.modeloVehiculo}
                onChange={handleChange}
                required
                placeholder="Corolla"
              />
            </label>
          </div>

          <div className="form-group">
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

          <div className="form-group">
            <label>
              Color:
              <input
                type="text"
                name="color"
                value={formData.color}
                onChange={handleChange}
                placeholder="Blanco"
              />
            </label>
          </div>

          <div className="form-group">
            <label>
              Límite de Velocidad: *
              <input
                type="number"
                name="speedLimitKmh"
                value={formData.speedLimitKmh}
                onChange={handleChange}
                required
                min="1"
                max="200"
              />
              <span className="unit">km/h</span>
              <small>Se convertirá automáticamente a knots para Traccar</small>
            </label>
          </div>
        </fieldset>

        {/* Imagen */}
        <fieldset>
          <legend>📷 Imagen del Vehículo</legend>

          {/* Mostrar imagen existente si está en modo edición */}
          {isEditMode && existingImageUrl && !imagePreview && (
            <div className="existing-image">
              <p>Imagen actual:</p>
              <img
                src={existingImageUrl}
                alt="Imagen actual"
                style={{ maxWidth: '300px', marginTop: '10px' }}
              />
              <small>Seleccione una nueva imagen para reemplazarla</small>
            </div>
          )}

          <div className="form-group">
            <label>
              {isEditMode ? 'Nueva Foto del Vehículo:' : 'Foto del Vehículo:'}
              <input
                type="file"
                accept="image/*"
                onChange={handleImageChange}
              />
              <small>Máximo 500 KB. Formatos: JPEG, PNG, GIF, WebP</small>
            </label>
          </div>

          {imagePreview && (
            <div className="image-preview">
              <img
                src={imagePreview}
                alt="Preview"
                style={{ maxWidth: '300px', marginTop: '10px' }}
              />
            </div>
          )}
        </fieldset>

        {/* Botones */}
        <div className="form-actions">
          <button 
            type="button" 
            onClick={() => navigate(-1)}
          >
            Cancelar
          </button>
          <button type="submit" disabled={loading}>
            {loading 
              ? (isEditMode ? 'Actualizando...' : 'Creando...') 
              : (isEditMode ? 'Actualizar GPS' : 'Crear GPS')
            }
          </button>
        </div>
      </form>
    </div>
  );
}

export default CreateEditGPSForm;
```

---

### 🛣️ Uso con React Router

```typescript
// App.tsx o Router.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import CreateEditGPSForm from './components/CreateEditGPSForm';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Ruta para crear nuevo GPS */}
        <Route 
          path="/devices/new" 
          element={<CreateEditGPSForm mode="create" />} 
        />
        
        {/* Ruta para editar GPS existente */}
        <Route 
          path="/devices/:deviceId/edit" 
          element={<CreateEditGPSForm mode="edit" />} 
        />
      </Routes>
    </BrowserRouter>
  );
}
```

---

### 📋 Resumen de Funciones de Conversión

```typescript
// ============================================
// CONVERSIONES ENTRE FORMATOS
// ============================================

// 1. Backend → Formulario (para cargar datos)
function deviceToFormData(device: Device): GPSFormData {
  return {
    name: device.name,
    uniqueId: device.uniqueId,
    deviceModel: device.model,              // Modelo GPS
    phone: device.phone,
    contact: device.contact,
    vehicleType: device.category,           // Tipo vehículo
    placa: device.attributes?.placa,
    marca: device.attributes?.marca,
    modeloVehiculo: device.attributes?.modeloVehiculo,  // Modelo vehículo
    año: device.attributes?.año,
    color: device.attributes?.color,
    speedLimitKmh: (device.attributes?.speedLimit || 0) * 1.852  // knots → km/h
  };
}

// 2. Formulario → Backend (para enviar datos)
function formDataToDevice(formData: GPSFormData, existingDevice?: Device): Partial<Device> {
  return {
    name: formData.name,
    uniqueId: formData.uniqueId,
    phone: formData.phone || null,
    model: formData.deviceModel || null,        // Modelo GPS
    contact: formData.contact || null,
    category: formData.vehicleType,             // Tipo vehículo
    attributes: {
      ...(existingDevice?.attributes || {}),    // Mantener atributos existentes
      placa: formData.placa,
      marca: formData.marca,
      modeloVehiculo: formData.modeloVehiculo,  // Modelo vehículo
      año: formData.año,
      color: formData.color || null,
      speedLimit: formData.speedLimitKmh / 1.852  // km/h → knots
    }
  };
}
```

---

### 📋 Ejemplo: Lista de Dispositivos con Botón de Editar

```typescript
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

interface Device {
  id: number;
  name: string;
  uniqueId: string;
  status: string;
  category?: string;
  attributes?: {
    placa?: string;
    marca?: string;
    modeloVehiculo?: string;
  };
}

function DevicesList() {
  const navigate = useNavigate();
  const [devices, setDevices] = useState<Device[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadDevices();
  }, []);

  const loadDevices = async () => {
    try {
      setLoading(true);
      const response = await fetch('http://localhost:8082/api/devices', {
        headers: {
          'Authorization': 'Basic ' + btoa('admin:admin')
        }
      });

      if (response.ok) {
        const data = await response.json();
        setDevices(data);
      } else {
        throw new Error('Error al cargar dispositivos');
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (deviceId: number) => {
    navigate(`/devices/${deviceId}/edit`);
  };

  const handleCreate = () => {
    navigate('/devices/new');
  };

  if (loading) {
    return <div>Cargando dispositivos...</div>;
  }

  if (error) {
    return <div>Error: {error}</div>;
  }

  return (
    <div className="devices-list">
      <div className="list-header">
        <h2>Dispositivos GPS</h2>
        <button onClick={handleCreate} className="btn-create">
          ➕ Crear Nuevo GPS
        </button>
      </div>

      <table className="devices-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Nombre</th>
            <th>IMEI</th>
            <th>Placa</th>
            <th>Marca</th>
            <th>Modelo</th>
            <th>Tipo</th>
            <th>Estado</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          {devices.map(device => (
            <tr key={device.id}>
              <td>{device.id}</td>
              <td>{device.name}</td>
              <td>{device.uniqueId}</td>
              <td>{device.attributes?.placa || '-'}</td>
              <td>{device.attributes?.marca || '-'}</td>
              <td>{device.attributes?.modeloVehiculo || '-'}</td>
              <td>{device.category || '-'}</td>
              <td>
                <span className={`status status-${device.status}`}>
                  {device.status}
                </span>
              </td>
              <td>
                <button 
                  onClick={() => handleEdit(device.id)}
                  className="btn-edit"
                >
                  ✏️ Editar
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default DevicesList;
```

---

### 🔄 Flujo Completo: Crear → Listar → Editar

```
1. CREAR DISPOSITIVO
   /devices/new
   → Usuario llena formulario
   → POST /api/devices
   → Redirige a /devices/{id}/edit
   ↓
2. LISTAR DISPOSITIVOS
   /devices
   → GET /api/devices
   → Muestra tabla con todos los dispositivos
   → Botón "Editar" en cada fila
   ↓
3. EDITAR DISPOSITIVO
   /devices/{id}/edit
   → GET /api/devices/{id}
   → Carga datos en formulario
   → Usuario modifica campos
   → PUT /api/devices/{id}
   → Muestra mensaje de éxito
```

---

### 📝 Ejemplo: Hook Personalizado para Gestionar Dispositivos

```typescript
// hooks/useDevice.ts
import { useState, useEffect } from 'react';

interface UseDeviceResult {
  device: Device | null;
  loading: boolean;
  error: string | null;
  loadDevice: (id: number) => Promise<void>;
  updateDevice: (data: Partial<Device>) => Promise<void>;
  createDevice: (data: Partial<Device>) => Promise<Device>;
}

export function useDevice(deviceId?: number): UseDeviceResult {
  const [device, setDevice] = useState<Device | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadDevice = async (id: number) => {
    try {
      setLoading(true);
      setError(null);
      
      const response = await fetch(`http://localhost:8082/api/devices/${id}`, {
        headers: {
          'Authorization': 'Basic ' + btoa('admin:admin')
        }
      });

      if (response.ok) {
        const data = await response.json();
        setDevice(data);
      } else {
        throw new Error('Error al cargar dispositivo');
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const updateDevice = async (data: Partial<Device>) => {
    if (!device) throw new Error('No hay dispositivo cargado');

    try {
      setLoading(true);
      setError(null);

      const updated = { ...device, ...data, id: device.id };
      
      const response = await fetch(`http://localhost:8082/api/devices/${device.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ' + btoa('admin:admin')
        },
        body: JSON.stringify(updated)
      });

      if (response.ok) {
        const updatedDevice = await response.json();
        setDevice(updatedDevice);
      } else {
        throw new Error('Error al actualizar dispositivo');
      }
    } catch (err: any) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const createDevice = async (data: Partial<Device>): Promise<Device> => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch('http://localhost:8082/api/devices', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ' + btoa('admin:admin')
        },
        body: JSON.stringify(data)
      });

      if (response.ok) {
        const newDevice = await response.json();
        setDevice(newDevice);
        return newDevice;
      } else {
        const errorText = await response.text();
        throw new Error(`Error al crear dispositivo: ${errorText}`);
      }
    } catch (err: any) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (deviceId) {
      loadDevice(deviceId);
    }
  }, [deviceId]);

  return {
    device,
    loading,
    error,
    loadDevice,
    updateDevice,
    createDevice
  };
}

// Uso del hook
function EditDevicePage({ deviceId }: { deviceId: number }) {
  const { device, loading, error, updateDevice } = useDevice(deviceId);

  if (loading) return <div>Cargando...</div>;
  if (error) return <div>Error: {error}</div>;
  if (!device) return <div>Dispositivo no encontrado</div>;

  const handleSave = async (formData: GPSFormData) => {
    const deviceData = formDataToDevice(formData, device);
    await updateDevice(deviceData);
  };

  return <CreateEditGPSForm initialData={deviceToFormData(device)} onSave={handleSave} />;
}
```

---

### 🎯 Resumen de Endpoints Utilizados

| Operación | Método | Endpoint | Descripción |
|-----------|--------|----------|-------------|
| **Listar todos** | `GET` | `/api/devices` | Obtiene todos los dispositivos del usuario |
| **Obtener por ID** | `GET` | `/api/devices/{id}` | Obtiene un dispositivo específico |
| **Buscar por IMEI** | `GET` | `/api/devices?uniqueId=XXX` | Busca dispositivo por uniqueId |
| **Crear** | `POST` | `/api/devices` | Crea un nuevo dispositivo |
| **Actualizar** | `PUT` | `/api/devices/{id}` | Actualiza un dispositivo existente |
| **Eliminar** | `DELETE` | `/api/devices/{id}` | Elimina un dispositivo |
| **Subir imagen** | `POST` | `/api/devices/{id}/image` | Sube imagen del dispositivo |
| **Obtener imagen** | `GET` | `/api/media/{uniqueId}/device.jpg` | Obtiene URL de la imagen |

---

### 💡 Mejores Prácticas

1. **Validación antes de crear:**
   - Siempre verifica si el `uniqueId` ya existe
   - Muestra mensaje claro al usuario si existe

2. **En modo edición:**
   - No permitas cambiar el `uniqueId` (puede causar problemas)
   - Mantén los atributos existentes que no se editan
   - Muestra la imagen actual si existe

3. **Manejo de errores:**
   - Captura errores de red
   - Muestra mensajes específicos según el tipo de error
   - Permite reintentar en caso de error

4. **UX:**
   - Muestra loading mientras carga/guarda
   - Confirma antes de acciones destructivas
   - Feedback visual inmediato (validación en tiempo real)

5. **Conversión de datos:**
   - Siempre convierte knots → km/h al cargar
   - Siempre convierte km/h → knots al guardar
   - Mantén los atributos existentes al actualizar

---

## ✅ Puntos Clave

1. **NO creamos relaciones nuevas** - Usamos campos estándar y atributos
2. **`model`** = Modelo del **dispositivo GPS** (GT06, TK103, etc.)
3. **`category`** = Tipo de **vehículo** (Auto, Bus, Camión, Moto)
4. **`attributes.modeloVehiculo`** = Modelo del **vehículo** (Corolla, Civic, etc.)
5. **Dropdowns estáticos** - No hay endpoint para obtener opciones, usamos arrays estáticos
6. **Conversión automática** - km/h se convierte a knots automáticamente
7. **Interfaz amigable** - Todo en un solo formulario, organizado por secciones
8. **Modo crear/editar** - El mismo componente puede crear o editar según el `deviceId`
9. **Conversión bidireccional** - Funciones para convertir entre formato API y formato formulario
10. **Validación de uniqueId** - Verifica si el IMEI ya existe antes de crear/actualizar

---

**Última actualización:** 2025-02-13

