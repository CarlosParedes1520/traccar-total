# ⚠️ Solución: Error de Dispositivo Duplicado

## 🔍 Problema Identificado

**Error:**
```
SQLIntegrityConstraintViolationException: 
Duplicate entry '664944646464641' for key 'tc_devices.uniqueid'
```

**Causa:** Ya existe un dispositivo con `uniqueId = '664944646464641'` en la base de datos.

---

## 📊 Dispositivo Existente Encontrado

```json
{
    "id": 34,
    "name": "FERESAASD",
    "uniqueId": "664944646464641",
    "status": "offline",
    "model": "FERESAASD",
    "attributes": {
        "serial": "12312353254435",
        "brand": "Teltonika"
    },
    "disabled": false
}
```

**Estado:** El dispositivo existe con ID **34** y está **offline**.

---

## ✅ Soluciones Rápidas

### **Opción 1: Eliminar el Dispositivo Existente** (Recomendado si quieres recrearlo)

```bash
# Eliminar el dispositivo por ID
curl -X DELETE -u admin:admin http://localhost:8082/api/devices/34
```

O usando el script:
```bash
# Buscar y eliminar por uniqueId
curl -s -u admin:admin "http://localhost:8082/api/devices?uniqueId=664944646464641" | \
  python3 -c "import sys, json; d=json.load(sys.stdin)[0] if json.load(sys.stdin) else None; print(d['id'] if d else '')" | \
  xargs -I {} curl -X DELETE -u admin:admin "http://localhost:8082/api/devices/{}"
```

---

### **Opción 2: Actualizar el Dispositivo Existente** (Recomendado si quieres modificar el existente)

En lugar de crear uno nuevo, actualiza el existente:

```bash
# Actualizar el dispositivo existente
curl -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "id": 34,
    "name": "Nuevo Nombre",
    "uniqueId": "664944646464641",
    "model": "GT06",
    "category": "Auto",
    "attributes": {
      "placa": "ABC-123",
      "marca": "Toyota",
      "modeloVehiculo": "Corolla",
      "año": 2020,
      "speedLimit": 43.2
    }
  }' \
  http://localhost:8082/api/devices/34
```

---

### **Opción 3: Usar un uniqueId Diferente**

Si quieres crear un dispositivo completamente nuevo, usa un `uniqueId` diferente:

```json
{
  "name": "Mi Nuevo GPS",
  "uniqueId": "664944646464642",  ← Cambiar el último dígito
  ...
}
```

---

## 🛠️ Validación en el Frontend

Para evitar este error en el futuro, agrega validación en el frontend antes de crear:

### **JavaScript/TypeScript:**

```typescript
// Función para verificar si el uniqueId ya existe
async function checkUniqueIdExists(uniqueId: string): Promise<boolean> {
  try {
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
      return devices.length > 0;  // Si hay dispositivos, el uniqueId existe
    }
    return false;
  } catch (error) {
    console.error('Error al verificar uniqueId:', error);
    return false;
  }
}

// Usar antes de crear
const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault();
  
  // Verificar si el uniqueId ya existe
  const exists = await checkUniqueIdExists(formData.uniqueId);
  
  if (exists) {
    const confirm = window.confirm(
      `Ya existe un dispositivo con IMEI ${formData.uniqueId}. ` +
      `¿Desea actualizarlo en lugar de crear uno nuevo?`
    );
    
    if (confirm) {
      // Obtener el dispositivo existente y actualizarlo
      const response = await fetch(
        `http://localhost:8082/api/devices?uniqueId=${formData.uniqueId}`,
        {
          headers: {
            'Authorization': 'Basic ' + btoa('admin:admin')
          }
        }
      );
      const devices = await response.json();
      const existingDevice = devices[0];
      
      // Actualizar en lugar de crear
      await updateDevice(existingDevice.id, formData);
    } else {
      alert('Por favor use un IMEI diferente');
      return;
    }
  } else {
    // Crear nuevo dispositivo
    await createDevice(formData);
  }
};
```

---

## 📋 Script Completo para Verificar y Eliminar

```bash
#!/bin/bash
# verificar-y-eliminar-dispositivo.sh

UNIQUE_ID="$1"
BASE_URL="http://localhost:8082/api"
EMAIL="admin"
PASSWORD="admin"

if [ -z "$UNIQUE_ID" ]; then
  echo "Uso: $0 <uniqueId>"
  exit 1
fi

echo "🔍 Verificando dispositivo con uniqueId: $UNIQUE_ID"

# 1. Buscar el dispositivo
DEVICE_RESPONSE=$(curl -s -u "$EMAIL:$PASSWORD" "$BASE_URL/devices?uniqueId=$UNIQUE_ID")
DEVICE_COUNT=$(echo "$DEVICE_RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null)

if [ "$DEVICE_COUNT" = "0" ]; then
  echo "✅ No existe dispositivo con uniqueId '$UNIQUE_ID'"
  exit 0
fi

echo "⚠️  Dispositivo encontrado:"
echo "$DEVICE_RESPONSE" | python3 -m json.tool

# 2. Obtener el ID
DEVICE_ID=$(echo "$DEVICE_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data[0]['id'] if data and len(data) > 0 else '')" 2>/dev/null)

if [ -z "$DEVICE_ID" ]; then
  echo "❌ Error al obtener ID del dispositivo"
  exit 1
fi

# 3. Confirmar eliminación
read -p "¿Desea eliminar el dispositivo con ID $DEVICE_ID? (s/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
  echo "Operación cancelada"
  exit 0
fi

# 4. Eliminar
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
chmod +x verificar-y-eliminar-dispositivo.sh
./verificar-y-eliminar-dispositivo.sh 664944646464641
```

---

## 💡 Recomendaciones

1. **Siempre verifica antes de crear:**
   - Usa `GET /api/devices?uniqueId=XXXXX` para verificar si existe
   - Muestra un mensaje al usuario si ya existe

2. **En el frontend:**
   - Valida el `uniqueId` antes de enviar el formulario
   - Ofrece opciones: actualizar el existente o usar otro `uniqueId`

3. **Manejo de errores:**
   - Captura el error `409 Conflict` o `SQLIntegrityConstraintViolationException`
   - Muestra un mensaje amigable al usuario

---

## 🔗 Referencias

- **Documento completo:** `ERROR_DISPOSITIVO_DUPLICADO.md`
- **Scripts disponibles:** `scripts/eliminar-dispositivo-duplicado.sh`
- **API Endpoint:** `GET /api/devices?uniqueId=XXXXX`

---

**Última actualización:** 2025-02-13

