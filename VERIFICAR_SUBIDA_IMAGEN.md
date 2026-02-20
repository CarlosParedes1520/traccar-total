# 🔍 Verificar si se Está Subiendo una Imagen

## 📋 Cómo Verificar si la Imagen se Subió Correctamente

### 1. **Verificar el Directorio de Media**

Según tu configuración en `debug.xml`:
```xml
<entry key='media.path'>./target/media</entry>
```

Las imágenes se guardan en:
```
target/media/{uniqueId}/device.{extension}
```

**Comando para verificar:**
```bash
# Ver si existe el directorio
ls -lah target/media/

# Ver imágenes de un dispositivo específico
ls -lah target/media/664944646464641/

# Buscar todas las imágenes de dispositivos
find target/media -type f -name "device.*"
```

---

### 2. **Verificar en los Logs**

El código de `DeviceResource.java` **NO escribe logs explícitos** cuando se sube una imagen, pero puedes verificar:

**Logs que deberías ver:**
- `SELECT * FROM tc_devices WHERE id = ?` - Verifica que el dispositivo existe
- `SELECT * FROM tc_users WHERE id = ?` - Verifica permisos del usuario

**Si la imagen se sube exitosamente:**
- El endpoint retorna: `HTTP 200 OK` con el body: `device.{extension}` (ej: "device.jpg")

**Si hay error:**
- `HTTP 404 Not Found` - Dispositivo no encontrado
- `HTTP 401 Unauthorized` - No autenticado
- `HTTP 403 Forbidden` - Sin permisos
- `HTTP 400 Bad Request` - Error en la imagen (tamaño, formato, etc.)

---

### 3. **Probar la Subida de Imagen Manualmente**

#### **Con curl:**
```bash
# Subir imagen
curl -X POST http://localhost:8082/api/devices/34/image \
  -u "admin:admin" \
  -H "Content-Type: image/jpeg" \
  --data-binary @imagen.jpg

# Respuesta esperada si es exitoso:
# device.jpg
```

#### **Verificar que se guardó:**
```bash
# Verificar archivo
ls -lah target/media/664944646464641/device.jpg

# Ver tamaño del archivo
stat target/media/664944646464641/device.jpg
```

---

### 4. **Verificar desde el Frontend**

```typescript
// Función para subir imagen y verificar
async function uploadAndVerifyImage(deviceId: number, imageFile: File) {
  const formData = new FormData();
  formData.append('file', imageFile);

  console.log('📤 Subiendo imagen...', {
    deviceId,
    fileName: imageFile.name,
    fileSize: imageFile.size,
    fileType: imageFile.type
  });

  const response = await fetch(`http://localhost:8082/api/devices/${deviceId}/image`, {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + btoa('admin:admin')
    },
    body: formData
  });

  console.log('📥 Respuesta:', {
    status: response.status,
    statusText: response.statusText,
    headers: Object.fromEntries(response.headers.entries())
  });

  if (response.ok) {
    const filename = await response.text();
    console.log('✅ Imagen subida exitosamente:', filename);
    
    // Verificar que la imagen existe
    const device = await getDeviceById(deviceId);
    const imageUrl = `http://localhost:8082/api/media/${device.uniqueId}/${filename}`;
    
    const verifyResponse = await fetch(imageUrl, { method: 'HEAD' });
    console.log('🔍 Verificación de imagen:', {
      url: imageUrl,
      exists: verifyResponse.ok,
      status: verifyResponse.status
    });
    
    return { success: true, filename, imageUrl };
  } else {
    const errorText = await response.text();
    console.error('❌ Error al subir imagen:', errorText);
    throw new Error(`Error: ${errorText}`);
  }
}
```

---

### 5. **Verificar Acceso a la Imagen**

Después de subir, verifica que puedes acceder a la imagen:

```bash
# Obtener el uniqueId del dispositivo
DEVICE_ID=34
UNIQUE_ID=$(curl -s -u admin:admin "http://localhost:8082/api/devices/$DEVICE_ID" | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['uniqueId'])")

echo "UniqueId: $UNIQUE_ID"

# Intentar acceder a la imagen
curl -I -u admin:admin "http://localhost:8082/api/media/$UNIQUE_ID/device.jpg"

# Si retorna HTTP 200, la imagen existe
# Si retorna HTTP 404, la imagen no existe
```

---

### 6. **Script Completo de Verificación**

```bash
#!/bin/bash
# verificar-imagen-dispositivo.sh

DEVICE_ID="$1"
BASE_URL="http://localhost:8082/api"
EMAIL="admin"
PASSWORD="admin"

if [ -z "$DEVICE_ID" ]; then
  echo "Uso: $0 <deviceId>"
  exit 1
fi

echo "🔍 Verificando imagen del dispositivo ID: $DEVICE_ID"

# 1. Obtener información del dispositivo
echo "📋 Obteniendo información del dispositivo..."
DEVICE_RESPONSE=$(curl -s -u "$EMAIL:$PASSWORD" "$BASE_URL/devices/$DEVICE_ID")
UNIQUE_ID=$(echo "$DEVICE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('uniqueId', ''))" 2>/dev/null)

if [ -z "$UNIQUE_ID" ]; then
  echo "❌ No se pudo obtener el uniqueId del dispositivo"
  exit 1
fi

echo "✅ UniqueId: $UNIQUE_ID"

# 2. Verificar archivo físico
MEDIA_PATH="./target/media/$UNIQUE_ID"
echo "📁 Verificando directorio: $MEDIA_PATH"

if [ -d "$MEDIA_PATH" ]; then
  echo "✅ Directorio existe"
  ls -lah "$MEDIA_PATH" | grep "device\."
  
  if [ -f "$MEDIA_PATH/device.jpg" ]; then
    echo "✅ Imagen encontrada: device.jpg"
    stat "$MEDIA_PATH/device.jpg"
  elif [ -f "$MEDIA_PATH/device.png" ]; then
    echo "✅ Imagen encontrada: device.png"
    stat "$MEDIA_PATH/device.png"
  else
    echo "⚠️  No se encontró archivo device.* en el directorio"
  fi
else
  echo "⚠️  Directorio no existe: $MEDIA_PATH"
fi

# 3. Verificar acceso HTTP
echo ""
echo "🌐 Verificando acceso HTTP..."

EXTENSIONS=("jpg" "jpeg" "png" "gif" "webp")
for ext in "${EXTENSIONS[@]}"; do
  IMAGE_URL="$BASE_URL/media/$UNIQUE_ID/device.$ext"
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -u "$EMAIL:$PASSWORD" "$IMAGE_URL")
  
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Imagen accesible: device.$ext (HTTP $HTTP_STATUS)"
    echo "   URL: $IMAGE_URL"
    break
  elif [ "$HTTP_STATUS" = "404" ]; then
    echo "❌ No encontrada: device.$ext (HTTP $HTTP_STATUS)"
  elif [ "$HTTP_STATUS" = "401" ]; then
    echo "⚠️  No autenticado: device.$ext (HTTP $HTTP_STATUS)"
  elif [ "$HTTP_STATUS" = "403" ]; then
    echo "⚠️  Sin permisos: device.$ext (HTTP $HTTP_STATUS)"
  else
    echo "⚠️  Error: device.$ext (HTTP $HTTP_STATUS)"
  fi
done
```

**Uso:**
```bash
chmod +x verificar-imagen-dispositivo.sh
./verificar-imagen-dispositivo.sh 34
```

---

### 7. **Problemas Comunes**

#### **Problema 1: La imagen no se guarda**

**Posibles causas:**
- El directorio `target/media` no existe o no tiene permisos de escritura
- Error al crear el archivo

**Solución:**
```bash
# Crear directorio si no existe
mkdir -p target/media

# Verificar permisos
ls -ld target/media

# Dar permisos de escritura si es necesario
chmod 755 target/media
```

---

#### **Problema 2: HTTP 404 al acceder a la imagen**

**Posibles causas:**
- El `uniqueId` en la URL no coincide
- La imagen no se subió correctamente
- El archivo tiene otra extensión

**Solución:**
```bash
# Verificar el uniqueId correcto
curl -s -u admin:admin "http://localhost:8082/api/devices/34" | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['uniqueId'])"

# Verificar qué archivos hay en el directorio
ls -lah target/media/664944646464641/
```

---

#### **Problema 3: HTTP 401/403 al acceder a la imagen**

**Causa:** Falta autenticación o permisos

**Solución:**
- Asegúrate de incluir las credenciales en la petición
- Verifica que el usuario tenga acceso al dispositivo

---

### 8. **Verificar desde el Código Java**

El código de `DeviceResource.java` no escribe logs explícitos, pero puedes agregar logs temporales para debugging:

```java
@Path("{id}/image")
@POST
@Consumes("image/*")
public Response uploadImage(
        @PathParam("id") long deviceId, File file,
        @HeaderParam(HttpHeaders.CONTENT_TYPE) String type) throws StorageException, IOException {

    LOGGER.info("Uploading image for device {}", deviceId);  // ← Agregar este log
    
    Device device = storage.getObject(Device.class, new Request(...));
    if (device != null) {
        String name = "device";
        String extension = imageExtension(type);
        
        LOGGER.info("Saving image: {}/{}.{}", device.getUniqueId(), name, extension);  // ← Agregar este log
        
        try (var input = new FileInputStream(file);
                var output = mediaManager.createFileStream(device.getUniqueId(), name, extension)) {
            // ... código de copia ...
        }
        
        LOGGER.info("Image saved successfully: {}.{}", name, extension);  // ← Agregar este log
        return Response.ok(name + "." + extension).build();
    }
    return Response.status(Response.Status.NOT_FOUND).build();
}
```

---

## ✅ Checklist de Verificación

- [ ] El endpoint retorna `HTTP 200 OK` con el nombre del archivo
- [ ] El directorio `target/media/{uniqueId}/` existe
- [ ] El archivo `device.{extension}` existe en el directorio
- [ ] Puedes acceder a la imagen vía `GET /api/media/{uniqueId}/device.{extension}`
- [ ] La imagen se muestra correctamente en el navegador/frontend

---

**Última actualización:** 2025-02-13


