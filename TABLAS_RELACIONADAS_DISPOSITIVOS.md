# 📊 Tablas Relacionadas con Dispositivos

## 🔗 Tablas que Contienen Datos de Dispositivos

Cuando eliminas un dispositivo, estas tablas pueden contener datos relacionados:

### 1. **Datos Principales** (Eliminados automáticamente con CASCADE)

| Tabla | Descripción | Foreign Key | CASCADE |
|-------|-------------|-------------|---------|
| `tc_positions` | Posiciones GPS del dispositivo | `deviceid` | ✅ Sí |
| `tc_events` | Eventos del dispositivo (alarmas, geocercas, etc.) | `deviceid` | ✅ Sí |
| `tc_commands_queue` | Comandos pendientes para el dispositivo | `deviceid` | ✅ Sí |

### 2. **Relaciones de Dispositivos** (Eliminadas automáticamente con CASCADE)

| Tabla | Descripción | Foreign Key | CASCADE |
|-------|-------------|-------------|---------|
| `tc_device_attribute` | Atributos computados del dispositivo | `deviceid` | ✅ Sí |
| `tc_device_command` | Comandos guardados del dispositivo | `deviceid` | ✅ Sí |
| `tc_device_driver` | Conductores asignados al dispositivo | `deviceid` | ✅ Sí |
| `tc_device_geofence` | Geocercas asignadas al dispositivo | `deviceid` | ✅ Sí |
| `tc_device_maintenance` | Mantenimientos del dispositivo | `deviceid` | ✅ Sí |
| `tc_device_notification` | Notificaciones del dispositivo | `deviceid` | ✅ Sí |
| `tc_device_order` | Órdenes del dispositivo | `deviceid` | ✅ Sí |
| `tc_device_report` | Reportes del dispositivo | `deviceid` | ✅ Sí |
| `tc_user_device` | Relación usuario-dispositivo | `deviceid` | ✅ Sí |

---

## ⚠️ Problema: Datos Huérfanos

Aunque las foreign keys tienen `ON DELETE CASCADE`, pueden quedar datos huérfanos si:

1. **Las foreign keys no están activas** (FOREIGN_KEY_CHECKS = 0)
2. **Se eliminaron dispositivos manualmente** sin respetar las restricciones
3. **Hay datos insertados directamente en SQL** sin validar foreign keys
4. **La versión de la BD no tiene todas las foreign keys** configuradas

---

## 🧹 Script de Limpieza Completa

### Opción 1: Script Automático (Recomendado)

```bash
# Elimina dispositivos Y todos sus datos relacionados
./scripts/eliminar-todos-dispositivos-completo.sh
```

Este script:
1. ✅ Elimina dispositivos vía API
2. ✅ Elimina posiciones de la BD
3. ✅ Elimina eventos de la BD
4. ✅ Elimina comandos en cola
5. ✅ Elimina todas las relaciones

### Opción 2: Limpieza SQL Directa

```bash
# Solo limpiar datos huérfanos (si ya eliminaste dispositivos)
./scripts/limpiar-datos-dispositivos-sql.sh
```

### Opción 3: SQL Manual

```sql
-- Deshabilitar verificación de foreign keys temporalmente
SET FOREIGN_KEY_CHECKS = 0;

-- Eliminar datos relacionados
DELETE FROM tc_positions;
DELETE FROM tc_events;
DELETE FROM tc_commands_queue;
DELETE FROM tc_device_attribute;
DELETE FROM tc_device_command;
DELETE FROM tc_device_driver;
DELETE FROM tc_device_geofence;
DELETE FROM tc_device_maintenance;
DELETE FROM tc_device_notification;
DELETE FROM tc_device_order;
DELETE FROM tc_device_report;
DELETE FROM tc_user_device;

-- Eliminar dispositivos
DELETE FROM tc_devices;

-- Rehabilitar verificación
SET FOREIGN_KEY_CHECKS = 1;
```

---

## 📋 Orden de Eliminación

El orden correcto es:

1. **Primero:** Datos dependientes (posiciones, eventos, comandos)
2. **Segundo:** Relaciones (tablas de unión)
3. **Tercero:** Dispositivos

**Razón:** Aunque CASCADE debería manejar esto, es mejor ser explícito para evitar errores.

---

## 🔍 Verificar Datos Huérfanos

```sql
-- Verificar posiciones sin dispositivo
SELECT COUNT(*) as posiciones_huerfanas
FROM tc_positions p
LEFT JOIN tc_devices d ON p.deviceid = d.id
WHERE d.id IS NULL;

-- Verificar eventos sin dispositivo
SELECT COUNT(*) as eventos_huerfanos
FROM tc_events e
LEFT JOIN tc_devices d ON e.deviceid = d.id
WHERE d.id IS NULL;

-- Verificar relaciones sin dispositivo
SELECT 
    (SELECT COUNT(*) FROM tc_device_attribute da LEFT JOIN tc_devices d ON da.deviceid = d.id WHERE d.id IS NULL) as atributos_huerfanos,
    (SELECT COUNT(*) FROM tc_device_command dc LEFT JOIN tc_devices d ON dc.deviceid = d.id WHERE d.id IS NULL) as comandos_huerfanos,
    (SELECT COUNT(*) FROM tc_device_geofence dg LEFT JOIN tc_devices d ON dg.deviceid = d.id WHERE d.id IS NULL) as geocercas_huerfanas;
```

---

## 💡 Recomendaciones

1. **Siempre usa el script completo** para eliminar dispositivos
2. **Verifica datos huérfanos** periódicamente
3. **Haz backup** antes de eliminar grandes cantidades de datos
4. **Usa transacciones** si eliminas manualmente

---

## 📚 Referencias

- **Esquema de BD:** `schema/changelog-4.0-clean.xml`
- **Foreign Keys:** Líneas 542-582, 558, 594-596
- **Scripts:** 
  - `scripts/eliminar-todos-dispositivos-completo.sh`
  - `scripts/limpiar-datos-dispositivos-sql.sh`

