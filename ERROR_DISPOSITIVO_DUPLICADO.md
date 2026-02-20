# ⚠️ Error: Dispositivo Duplicado

## 🔍 Error Encontrado

```
SQLIntegrityConstraintViolationException: 
Duplicate entry '24959195' for key 'tc_devices.uniqueid'
```

## 🎯 Causa del Error

El error ocurre porque estás intentando **crear un dispositivo** con un `uniqueId` que **ya existe** en la base de datos.

### ¿Por qué `uniqueId` debe ser único?

En la base de datos, la columna `uniqueId` tiene una **restricción UNIQUE**:

```sql
CREATE TABLE tc_devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    uniqueid VARCHAR(128) NOT NULL UNIQUE,  ← Restricción UNIQUE
    ...
);
```

Esto significa que:
- ✅ **No puede haber dos dispositivos** con el mismo `uniqueId`
- ✅ El `uniqueId` es el **identificador único** del dispositivo GPS
- ✅ Es como el "IMEI" o "número de serie" del dispositivo

---

## 🤔 ¿Por qué hay un dispositivo si "no debería haber"?

Hay varias razones por las que puede existir un dispositivo en la BD:

### 1. **Registro Automático** (Más Probable)

Traccar tiene una función de **registro automático de dispositivos desconocidos**:

```java
// ConnectionManager.java:130-133
if (device == null && config.getBoolean(Keys.DATABASE_REGISTER_UNKNOWN)) {
    if (firstUniqueId.matches(config.getString(Keys.DATABASE_REGISTER_UNKNOWN_REGEX))) {
        device = addUnknownDevice(firstUniqueId);
    }
}
```

**¿Qué significa esto?**
- Si un dispositivo GPS se conecta con `uniqueId = '24959195'`
- Y Traccar tiene `database.registerUnknown = true`
- Y el `uniqueId` coincide con el regex (por defecto: `\w{3,15}`)
- **Traccar crea automáticamente el dispositivo** en la BD

### 2. **Dispositivo Creado Manualmente**

Alguien (o tú) creó el dispositivo manualmente desde:
- La interfaz web (Settings → Devices → Add)
- La API REST (`POST /api/devices`)
- Un script o herramienta

### 3. **Dispositivo de Pruebas Anterior**

Puede ser un dispositivo que se creó antes y no se eliminó.

---

## 🔍 Cómo Verificar

### Opción 1: Usar el script
```bash
./scripts/verificar-dispositivos.sh
```

### Opción 2: Consulta SQL directa
```sql
-- Ver todos los dispositivos
SELECT id, name, uniqueId, status, lastUpdate 
FROM tc_devices 
ORDER BY id;

-- Buscar el dispositivo específico
SELECT id, name, uniqueId, status, lastUpdate, disabled
FROM tc_devices 
WHERE uniqueId = '24959195';
```

### Opción 3: Desde la API
```bash
# Listar todos los dispositivos
curl -u admin:admin http://localhost:8082/api/devices

# Buscar por uniqueId
curl -u admin:admin "http://localhost:8082/api/devices?uniqueId=24959195"
```

---

## ✅ Soluciones

### Solución 1: Eliminar el Dispositivo Existente

Si el dispositivo ya existe y quieres usar ese `uniqueId`:

```bash
# Eliminar el dispositivo específico
./scripts/eliminar-dispositivo-duplicado.sh 24959195
```

O manualmente:
```sql
DELETE FROM tc_devices WHERE uniqueId = '24959195';
```

### Solución 2: Usar un uniqueId Diferente

Si quieres crear un nuevo dispositivo, usa un `uniqueId` diferente:

```json
{
  "name": "Mi Dispositivo",
  "uniqueId": "24959196",  ← Cambiar el uniqueId
  ...
}
```

### Solución 3: Actualizar el Dispositivo Existente

En lugar de crear uno nuevo, actualiza el existente:

```bash
# Obtener el ID del dispositivo
curl -u admin:admin "http://localhost:8082/api/devices?uniqueId=24959195"

# Actualizar el dispositivo (usar el ID obtenido)
curl -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "name": "Nuevo Nombre", ...}' \
  http://localhost:8082/api/devices/1
```

### Solución 4: Deshabilitar Registro Automático

Si no quieres que Traccar cree dispositivos automáticamente:

En `debug.xml` o `traccar.xml`:
```xml
<!-- Deshabilitar registro automático -->
<entry key='database.registerUnknown'>false</entry>
```

---

## 📋 Flujo de Registro Automático

```
1. Dispositivo GPS se conecta con uniqueId = '24959195'
   ↓
2. Traccar busca el dispositivo en la BD
   ↓
3. Si NO existe Y database.registerUnknown = true
   ↓
4. Traccar crea automáticamente el dispositivo
   ↓
5. El dispositivo queda registrado en tc_devices
```

**Problema:** Si luego intentas crear manualmente un dispositivo con el mismo `uniqueId`, falla porque ya existe.

---

## 🛠️ Scripts Disponibles

1. **`scripts/verificar-dispositivos.sh`** - Ver todos los dispositivos
2. **`scripts/eliminar-dispositivo-duplicado.sh <uniqueId>`** - Eliminar dispositivo duplicado

---

## 💡 Recomendaciones

1. **Antes de crear un dispositivo:**
   - Verifica si ya existe: `./scripts/verificar-dispositivos.sh`
   - O consulta la API: `GET /api/devices?uniqueId=XXXXX`

2. **Si usas registro automático:**
   - Los dispositivos se crearán automáticamente cuando se conecten
   - No necesitas crearlos manualmente

3. **Para limpiar dispositivos de prueba:**
   ```sql
   -- Eliminar todos los dispositivos (¡CUIDADO!)
   DELETE FROM tc_devices;
   
   -- O eliminar solo los que no tienen posiciones
   DELETE FROM tc_devices 
   WHERE id NOT IN (SELECT DISTINCT deviceId FROM tc_positions);
   ```

---

## 📚 Referencias

- **Código de registro automático:** `src/main/java/org/traccar/session/ConnectionManager.java:169-188`
- **Configuración:** `src/main/java/org/traccar/config/Keys.java:535-558`
- **Modelo de dispositivo:** `src/main/java/org/traccar/model/Device.java`
- **Esquema de BD:** `schema/changelog-4.0-clean.xml:129-130`

