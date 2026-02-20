# 📸 Dónde Están las Imágenes en Traccar

## 📁 Ubicaciones de Imágenes

### 1. **Imágenes Estáticas del Frontend** (traccar-web/)

Estas son las imágenes que se muestran en la interfaz web:

```
traccar-web/
├── logo.svg                    # Logo principal de Traccar
├── favicon.ico                 # Favicon del navegador
├── apple-touch-icon-180x180.png  # Icono para iOS
├── pwa-64x64.png              # Icono PWA pequeño
├── pwa-192x192.png            # Icono PWA mediano
├── pwa-512x512.png            # Icono PWA grande
└── maskable-icon-512x512.png  # Icono PWA maskable
```

**Ubicación física:** `/home/mateo/Documents/Mateo/Proyectos/Physeter/Trackar/traccar-total/traccar-web/`

**Cómo se sirven:**
- Se sirven directamente desde `traccar-web/` a través del servidor web
- Configurado en `Keys.WEB_PATH` (por defecto: `./traccar-web`)

---

### 2. **Imágenes de Dispositivos** (Media Manager)

Las imágenes que subes para cada dispositivo se guardan en:

**Ubicación por defecto:** `./media/{deviceUniqueId}/`

**Ejemplo:**
```
media/
└── 123456789012345/
    ├── device.jpg          # Imagen del dispositivo
    └── 20260211123456.jpg # Fotos/videos del dispositivo
```

**Configuración:**
- Se configura con `Keys.MEDIA_PATH` en `traccar.xml` o `debug.xml`
- Por defecto: `./media`

**API para subir imágenes:**
- `POST /api/devices/{id}/image` - Sube imagen del dispositivo
- Las imágenes se guardan como: `device.{extension}`

---

### 3. **Imágenes Personalizadas (Override)**

Puedes sobrescribir imágenes del frontend usando el directorio `override/`:

**Ubicación:** `./override/`

**Ejemplo:**
```
override/
├── logo.svg              # Reemplaza traccar-web/logo.svg
├── favicon.ico           # Reemplaza traccar-web/favicon.ico
└── pwa-512x512.png      # Reemplaza traccar-web/pwa-512x512.png
```

**Configuración:**
- Se configura con `Keys.WEB_OVERRIDE` en `traccar.xml`
- Por defecto: `./override`

**Cómo funciona:**
- Si existe un archivo en `override/`, se usa ese en lugar del original
- Si no existe, se usa el archivo de `traccar-web/`

**API para subir archivos:**
- `POST /api/server/file/{path}` - Sube archivos al directorio override
- Ejemplo: `POST /api/server/file/logo.svg` → guarda en `override/logo.svg`

---

### 4. **Logos del Servidor** (Configuración del Servidor)

Los logos que se configuran en la interfaz (Settings → Server) se guardan en:

**Ubicación:** `override/` o en la base de datos como atributos del servidor

**Configuración:**
- `serverLogo` - Logo normal
- `serverLogoInverted` - Logo invertido (para modo oscuro)

**API:**
- `GET /api/server` - Obtiene configuración (incluye rutas de logos)
- `PUT /api/server` - Actualiza configuración

---

## 🔍 Cómo Encontrar las Imágenes

### Buscar todas las imágenes en el proyecto:

```bash
find . -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.svg" -o -name "*.ico" \) \
  ! -path "*/node_modules/*" ! -path "*/build/*" ! -path "*/target/*"
```

### Ver imágenes del frontend:

```bash
ls -lah traccar-web/*.{png,svg,ico}
```

### Ver imágenes de dispositivos:

```bash
ls -lah media/*/
```

### Ver imágenes personalizadas:

```bash
ls -lah override/
```

---

## 📝 Configuración en debug.xml

```xml
<!-- Ruta del frontend (donde están logo.svg, favicon.ico, etc.) -->
<entry key='web.path'>./traccar-web</entry>

<!-- Ruta para personalizar archivos (override) -->
<entry key='web.override'>./override</entry>

<!-- Ruta para imágenes de dispositivos -->
<entry key='media.path'>./media</entry>
```

---

## 🎯 Resumen Rápido

| Tipo de Imagen | Ubicación | Configuración |
|---------------|-----------|---------------|
| **Logo/Favicon** | `traccar-web/` | `web.path` |
| **Logo personalizado** | `override/` | `web.override` |
| **Imágenes de dispositivos** | `media/{deviceId}/` | `media.path` |
| **Iconos PWA** | `traccar-web/pwa-*.png` | `web.path` |

---

## 💡 Cómo Personalizar el Logo

### Opción 1: Reemplazar archivo directamente

```bash
# Copia tu logo
cp mi-logo.svg traccar-web/logo.svg

# O usa override (recomendado)
cp mi-logo.svg override/logo.svg
```

### Opción 2: Usar la API

```bash
# Subir logo personalizado
curl -X POST http://localhost:8082/api/server/file/logo.svg \
  -H "Authorization: Basic YWRtaW46YWRtaW4=" \
  -F "file=@mi-logo.svg"
```

### Opción 3: Configurar en la interfaz

1. Ve a **Settings → Server**
2. En **Logo Image**, sube tu logo
3. El logo se guardará en `override/` automáticamente

---

## 🔗 Rutas HTTP

Las imágenes se sirven en estas rutas:

- `http://localhost:8082/logo.svg` → `traccar-web/logo.svg` o `override/logo.svg`
- `http://localhost:8082/favicon.ico` → `traccar-web/favicon.ico` o `override/favicon.ico`
- `http://localhost:8082/api/media/{deviceId}/{filename}` → `media/{deviceId}/{filename}`

---

## 📚 Referencias

- **Código fuente:** `src/main/java/org/traccar/web/WebServer.java` - Configuración del servidor web
- **Media Manager:** `src/main/java/org/traccar/database/MediaManager.java` - Gestión de imágenes de dispositivos
- **Device Resource:** `src/main/java/org/traccar/api/resource/DeviceResource.java` - API para subir imágenes

