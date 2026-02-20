# ✅ Solución: Error de Dispositivo Duplicado

## 🔍 Problema Identificado

**Error:**
```
SQLIntegrityConstraintViolationException: 
Duplicate entry '24959195' for key 'tc_devices.uniqueid'
```

**Causa:** Ya existe un dispositivo con `uniqueId = '24959195'` en la base de datos.

## 📊 Dispositivo Encontrado

```json
{
    "id": 22,
    "name": "car1",
    "uniqueId": "24959195",
    "status": "online",
    "lastUpdate": "2026-02-11T21:49:46.000+00:00",
    "positionId": 754417,
    "disabled": false
}
```

**Estado:** El dispositivo está **activo** y **en línea**.

---

## 🤔 ¿Por qué existe si "no debería haber dispositivos"?

### Posibles Razones:

1. **Registro Automático** (Más Probable)
   - Un dispositivo GPS se conectó con `uniqueId = '24959195'`
   - Traccar lo registró automáticamente
   - Esto ocurre cuando `database.registerUnknown = true` (por defecto puede estar activo)

2. **Creado Manualmente**
   - Alguien creó el dispositivo desde la interfaz web o API
   - Puede ser de una sesión anterior

3. **Dispositivo de Pruebas**
   - Dispositivo creado para pruebas y no eliminado

---

## ✅ Soluciones

### Opción 1: Eliminar el Dispositivo Existente (Recomendado)

Si quieres crear uno nuevo con el mismo `uniqueId`:

#### Usando el script:
```bash
./scripts/eliminar-dispositivo-api.sh 24959195
```

#### Usando la API directamente:
```bash
# 1. Obtener el ID del dispositivo
curl -u admin:admin "http://localhost:8082/api/devices?uniqueId=24959195"

# 2. Eliminar el dispositivo (usar el ID obtenido, en este caso 22)
curl -X DELETE -u admin:admin http://localhost:8082/api/devices/22
```

#### Usando SQL (si tienes acceso):
```sql
DELETE FROM tc_devices WHERE uniqueId = '24959195';
-- O por ID
DELETE FROM tc_devices WHERE id = 22;
```

---

### Opción 2: Actualizar el Dispositivo Existente

En lugar de crear uno nuevo, actualiza el existente:

```bash
# Actualizar el dispositivo existente
curl -X PUT -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "id": 22,
    "name": "Nuevo Nombre",
    "uniqueId": "24959195",
    ...
  }' \
  http://localhost:8082/api/devices/22
```

---

### Opción 3: Usar un uniqueId Diferente

Si quieres crear un dispositivo nuevo, usa un `uniqueId` diferente:

```bash
curl -X POST -u admin:admin \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mi Dispositivo",
    "uniqueId": "24959196",  ← Cambiar el uniqueId
    ...
  }' \
  http://localhost:8082/api/devices
```

---

## 🔧 Prevenir Registro Automático

Si no quieres que Traccar cree dispositivos automáticamente:

### En `debug.xml`:
```xml
<!-- Deshabilitar registro automático de dispositivos desconocidos -->
<entry key='database.registerUnknown'>false</entry>
```

**Nota:** Con esto, los dispositivos GPS que se conecten pero no estén registrados serán rechazados.

---

## 📋 Ver Todos los Dispositivos

```bash
# Listar todos los dispositivos
curl -u admin:admin http://localhost:8082/api/devices | python3 -m json.tool

# O usar el script
./scripts/verificar-dispositivos.sh
```

---

## 🎯 Resumen

| Aspecto | Valor |
|---------|-------|
| **Dispositivo existente** | ✅ Sí (ID: 22) |
| **uniqueId** | `24959195` |
| **Nombre** | `car1` |
| **Estado** | `online` |
| **Última actualización** | 2026-02-11 21:49:46 |
| **Solución** | Eliminar o actualizar el dispositivo existente |

---

## 💡 Recomendación

**Si el dispositivo `24959195` es el que quieres usar:**
- ✅ **Actualiza** el dispositivo existente (Opción 2)
- ❌ No intentes crear uno nuevo

**Si quieres un dispositivo completamente nuevo:**
- ✅ **Elimina** el dispositivo existente (Opción 1)
- ✅ Luego crea uno nuevo con el mismo `uniqueId`

**Si quieres mantener ambos:**
- ✅ Usa un `uniqueId` diferente para el nuevo dispositivo (Opción 3)

---

## 🛠️ Scripts Disponibles

1. **`scripts/verificar-dispositivos.sh`** - Ver todos los dispositivos
2. **`scripts/eliminar-dispositivo-api.sh <uniqueId>`** - Eliminar dispositivo vía API
3. **`scripts/eliminar-dispositivo-duplicado.sh <uniqueId>`** - Eliminar dispositivo vía SQL

