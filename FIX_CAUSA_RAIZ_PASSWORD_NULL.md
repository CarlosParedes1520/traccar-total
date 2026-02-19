# 🔧 Fix: Causa Raíz del Error de Password NULL

## 🔴 Problema Identificado

El error `NullPointerException: Cannot invoke "String.toCharArray()" because "data" is null` ocurría porque el campo `hashedPassword` o `salt` del usuario `admin` se estaba estableciendo como `NULL` en la base de datos.

## 🔍 Causa Raíz

El problema estaba en `BaseObjectResource.java`, método `update()` (líneas 114-123):

### Código Problemático (ANTES):

```java
storage.updateObject(entity, new Request(
        new Columns.Exclude("id"),
        new Condition.Equals("id", entity.getId())));
if (entity instanceof User user) {
    if (user.getHashedPassword() != null) {
        storage.updateObject(entity, new Request(
                new Columns.Include("hashedPassword", "salt"),
                new Condition.Equals("id", entity.getId())));
    }
}
```

### ¿Qué pasaba?

1. **Primer `updateObject`**: Actualizaba TODOS los campos excepto `id` usando `Columns.Exclude("id")`
2. **Problema**: Si el objeto `User` que venía del cliente tenía `hashedPassword` y `salt` como `null` (porque no se enviaron en el JSON), estos campos se actualizaban a `NULL` en la base de datos
3. **Aunque `hashedPassword` y `salt` tienen `@JsonIgnore`**, cuando Jackson deserializa un JSON que no incluye estos campos, Java los inicializa como `null` por defecto
4. **El primer `updateObject` escribía estos valores `null` en la base de datos**, sobrescribiendo los valores existentes
5. **El segundo `updateObject`** solo se ejecutaba si `hashedPassword != null`, pero ya era demasiado tarde - el primer update ya había puesto los valores como NULL

### Escenario que causaba el problema:

```json
// Cliente envía actualización de usuario (sin password)
PUT /api/users/1
{
  "id": 1,
  "name": "Administrator",
  "email": "admin",
  "administrator": true
  // hashedPassword y salt no se envían, pero en Java son null
}
```

El objeto `User` en Java tenía:
- `hashedPassword = null`
- `salt = null`

Y el primer `updateObject` actualizaba estos campos a `NULL` en la base de datos.

## ✅ Solución Implementada

### Código Corregido (DESPUÉS):

```java
// For User objects, exclude hashedPassword and salt from the main update
// to prevent them from being set to NULL when not provided
if (entity instanceof User) {
    storage.updateObject(entity, new Request(
            new Columns.Exclude("id", "hashedPassword", "salt"),
            new Condition.Equals("id", entity.getId())));
    User user = (User) entity;
    // Only update password if a new one was provided
    if (user.getHashedPassword() != null) {
        storage.updateObject(entity, new Request(
                new Columns.Include("hashedPassword", "salt"),
                new Condition.Equals("id", entity.getId())));
    }
} else {
    storage.updateObject(entity, new Request(
            new Columns.Exclude("id"),
            new Condition.Equals("id", entity.getId())));
}
```

### ¿Qué hace ahora?

1. **Para objetos `User`**: Excluye `hashedPassword` y `salt` del primer update usando `Columns.Exclude("id", "hashedPassword", "salt")`
2. **Solo actualiza el password** si se proporciona explícitamente (`hashedPassword != null`)
3. **Para otros objetos**: Mantiene el comportamiento original

### Resultado:

- ✅ `hashedPassword` y `salt` **nunca se actualizan a NULL** a menos que se proporcione un nuevo password
- ✅ Los valores existentes se preservan cuando se actualiza un usuario sin cambiar el password
- ✅ El password solo se actualiza cuando se proporciona explícitamente

## 📝 Archivos Modificados

- `src/main/java/org/traccar/api/BaseObjectResource.java`
  - Líneas 114-130: Modificado el método `update()` para excluir `hashedPassword` y `salt` del update principal

## 🧪 Verificación

Para verificar que el fix funciona:

1. **Actualizar un usuario sin cambiar el password:**
   ```bash
   curl -X PUT http://localhost:8082/api/users/1 \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "id": 1,
       "name": "Administrator",
       "email": "admin",
       "administrator": true
     }'
   ```

2. **Verificar que el password sigue funcionando:**
   ```bash
   curl -X POST http://localhost:8082/api/session \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "email=admin&password=admin"
   ```

3. **Verificar en la base de datos:**
   ```sql
   SELECT id, email, 
          hashedPassword IS NULL as sin_password,
          salt IS NULL as sin_salt
   FROM tc_users 
   WHERE email = 'admin';
   ```
   
   Deberías ver:
   - `sin_password: 0` (false)
   - `sin_salt: 0` (false)

## 🔄 Relación con el Script de Fix

El script `fix-admin-user.sh` sigue siendo útil para:
- ✅ Corregir usuarios que ya tienen `hashedPassword` o `salt` como NULL
- ✅ Crear el usuario admin inicial si no existe
- ✅ Restablecer el password del admin si se olvida

Pero ahora, **con este fix, el problema no debería volver a ocurrir** cuando se actualiza un usuario desde la API.

## 📚 Referencias

- `SOLUCION_ERROR_PASSWORD_NULL.md`: Documentación del error y solución temporal
- `GUIA_EJECUTAR_EN_SERVIDOR.md`: Guía para ejecutar el script de fix en el servidor
- `scripts/fix-admin-user.sh`: Script para corregir usuarios con password NULL

---

**Fecha del Fix:** 2026-02-18  
**Archivo:** `src/main/java/org/traccar/api/BaseObjectResource.java`  
**Líneas modificadas:** 114-130

