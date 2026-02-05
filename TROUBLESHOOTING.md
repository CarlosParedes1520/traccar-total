# Solución de Problemas - Traccar en Railway

## Problema: El contenedor está crasheando

### Posibles causas y soluciones:

#### 1. Error de conexión a la base de datos

**Síntomas:**
- El contenedor se reinicia continuamente
- Logs muestran errores de conexión a PostgreSQL

**Solución:**
- Verifica que la base de datos PostgreSQL esté corriendo en Railway
- Verifica que las variables de entorno de la base de datos estén disponibles
- Asegúrate de que la URL de conexión sea correcta
- Verifica que el usuario y contraseña sean correctos

**Verificación:**
En Railway, ve a tu servicio de base de datos y verifica:
- `PGHOST`
- `PGPORT`
- `PGDATABASE`
- `PGUSER`
- `PGPASSWORD`

#### 2. Error al inicializar las tablas (Liquibase)

**Síntomas:**
- Error relacionado con `DATABASECHANGELOG`
- Error de "Database is in a locked state"

**Solución:**
Si la base de datos está bloqueada, puedes ejecutar este SQL en Railway:
```sql
UPDATE DATABASECHANGELOGLOCK SET locked = 0;
```

**Nota:** Asegúrate de que el esquema esté actualizado antes de desbloquear.

#### 3. Problema de memoria

**Síntomas:**
- `OutOfMemoryError` en los logs
- El contenedor se reinicia por falta de memoria

**Solución:**
- La memoria ya está configurada a 1024m en el Dockerfile
- Si necesitas más, puedes ajustar `JAVA_OPTS` en Railway:
  ```
  JAVA_OPTS=-Xmx2048m -Xms512m
  ```

#### 4. Problema con el puerto

**Síntomas:**
- Error de "Port already in use"
- El servidor no responde

**Solución:**
- Railway asigna el puerto automáticamente a través de `PORT`
- El script ya configura `web.port` desde la variable `PORT`
- No necesitas configurar el puerto manualmente

#### 5. Error en la configuración XML

**Síntomas:**
- Error al leer el archivo de configuración
- "Configuration file is not a valid XML document"

**Solución:**
- El script genera automáticamente el archivo XML
- Verifica los logs para ver el contenido del archivo generado
- Asegúrate de que todas las variables de entorno estén configuradas

## Cómo ver los logs completos en Railway

1. Ve a tu proyecto en Railway
2. Haz clic en el servicio de Traccar
3. Ve a la pestaña "Logs"
4. Revisa los logs completos para ver el error específico

## Verificación de la configuración

El script de entrada muestra información de diagnóstico. Busca en los logs:

```
=== Archivo de configuración creado exitosamente ===
Contenido de /opt/traccar/conf/traccar.xml:
```

Verifica que el archivo contenga:
- `database.driver`
- `database.url`
- `database.user`
- `database.password`
- `web.port`

## Verificación de la conexión a la base de datos

Si el problema persiste, puedes verificar la conexión manualmente:

1. En Railway, ve a tu base de datos PostgreSQL
2. Abre la consola SQL
3. Ejecuta: `SELECT version();`
4. Si funciona, la base de datos está accesible

## Contacto y soporte

Si el problema persiste después de intentar estas soluciones:
1. Revisa los logs completos en Railway
2. Verifica la configuración de las variables de entorno
3. Asegúrate de que la base de datos esté corriendo
4. Verifica que el servicio tenga suficientes recursos asignados
