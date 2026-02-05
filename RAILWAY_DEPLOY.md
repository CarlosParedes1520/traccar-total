# Guía de Deploy en Railway para Traccar

Esta guía te ayudará a desplegar Traccar en Railway de manera correcta.

## Requisitos Previos

1. Cuenta en [Railway](https://railway.app)
2. Repositorio Git conectado a Railway
3. Base de datos (PostgreSQL o MySQL) - Railway puede proporcionarla

## Pasos para el Deploy

### 1. Crear un Nuevo Proyecto en Railway

1. Ve a [Railway Dashboard](https://railway.app/dashboard)
2. Haz clic en "New Project"
3. Selecciona "Deploy from GitHub repo"
4. Conecta tu repositorio `traccar-total`

### 2. Configurar la Base de Datos

Railway puede crear automáticamente una base de datos PostgreSQL o MySQL:

1. En tu proyecto de Railway, haz clic en "+ New"
2. Selecciona "Database" → "PostgreSQL" o "MySQL"
3. Railway creará automáticamente las variables de entorno:
   - `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD` (para PostgreSQL)
   - O `MYSQLHOST`, `MYSQLPORT`, `MYSQLDATABASE`, `MYSQLUSER`, `MYSQLPASSWORD` (para MySQL)

### 3. Configurar Variables de Entorno

En la configuración de tu servicio de Traccar, agrega las siguientes variables de entorno:

#### Variables Obligatorias

```bash
# Habilitar uso de variables de entorno (Traccar las leerá directamente)
CONFIG_USE_ENVIRONMENT_VARIABLES=true

# Para PostgreSQL (recomendado)
# Railway crea automáticamente: PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
DATABASE_DRIVER=org.postgresql.Driver
DATABASE_URL=jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}?sslmode=require
DATABASE_USER=${PGUSER}
DATABASE_PASSWORD=${PGPASSWORD}

# O para MySQL
# Railway crea automáticamente: MYSQLHOST, MYSQLPORT, MYSQLDATABASE, MYSQLUSER, MYSQLPASSWORD
# DATABASE_DRIVER=com.mysql.cj.jdbc.Driver
# DATABASE_URL=jdbc:mysql://${MYSQLHOST}:${MYSQLPORT}/${MYSQLDATABASE}?zeroDateTimeBehavior=round&serverTimezone=UTC&allowPublicKeyRetrieval=true&useSSL=true&allowMultiQueries=true&autoReconnect=true&useUnicode=yes&characterEncoding=UTF-8&sessionVariables=sql_mode=''
# DATABASE_USER=${MYSQLUSER}
# DATABASE_PASSWORD=${MYSQLPASSWORD}
```

**Nota importante**: Traccar lee directamente las variables de entorno cuando `CONFIG_USE_ENVIRONMENT_VARIABLES=true`. No necesitas crear manualmente el archivo `traccar.xml` - el script de entrada lo genera automáticamente como respaldo.

#### Variables Opcionales

```bash
# Configuración de Java
JAVA_OPTS=-Xmx512m

# Puerto (Railway lo maneja automáticamente, pero puedes configurarlo)
PORT=8082

# Configuración de logs
LOG_LEVEL=INFO

# Configuración de notificaciones (opcional)
# SMTP_HOST=smtp.gmail.com
# SMTP_PORT=587
# SMTP_USER=tu-email@gmail.com
# SMTP_PASSWORD=tu-password
# SMTP_FROM=tu-email@gmail.com
```

### 4. Configurar el Puerto

Railway asigna automáticamente un puerto a través de la variable `PORT`. Traccar necesita saber que debe usar este puerto:

1. Railway expone automáticamente la variable `PORT`
2. Traccar debería detectar esta variable, pero si no, puedes agregar:
   ```bash
   WEB_PORT=${PORT}
   ```

### 5. Desplegar

1. Railway detectará automáticamente el `Dockerfile` y comenzará a construir
2. El proceso de build puede tardar varios minutos (compilación de Java)
3. Una vez completado, Railway asignará una URL pública a tu aplicación

### 6. Verificar el Deploy

1. Ve a la pestaña "Settings" de tu servicio
2. En "Domains", Railway habrá creado una URL pública
3. Accede a `https://tu-url.railway.app` para ver la interfaz web de Traccar
4. El endpoint de salud estará en: `https://tu-url.railway.app/api/health`

## Configuración Adicional

### Puertos para Dispositivos GPS

Traccar necesita puertos adicionales (5000-5500) para recibir datos de dispositivos GPS. Railway permite configurar esto:

1. En Railway, ve a "Settings" → "Networking"
2. Puedes configurar puertos adicionales si es necesario
3. Nota: Railway puede tener limitaciones en el rango de puertos disponibles

### Persistencia de Datos

Los datos de Traccar se almacenan en la base de datos, así que no necesitas volúmenes adicionales. Sin embargo, si necesitas logs persistentes:

1. Railway proporciona almacenamiento persistente limitado
2. Los logs también se pueden ver en la pestaña "Logs" de Railway

### Monitoreo

- **Logs**: Ve a la pestaña "Logs" en Railway para ver los logs en tiempo real
- **Métricas**: Railway proporciona métricas básicas de CPU y memoria
- **Health Checks**: El Dockerfile incluye un healthcheck que Railway puede usar

## Solución de Problemas

### Error: "Database connection failed"

- Verifica que las variables de entorno de la base de datos estén correctamente configuradas
- Asegúrate de que la base de datos esté en el mismo proyecto de Railway
- Verifica que la URL de conexión incluya los parámetros SSL necesarios

### Error: "Port already in use"

- Railway maneja los puertos automáticamente
- Asegúrate de usar la variable `${PORT}` en lugar de un puerto fijo

### Build falla

- Verifica que el Dockerfile esté en la raíz del proyecto
- Revisa los logs de build en Railway para ver errores específicos
- Asegúrate de que todas las dependencias estén en `build.gradle`

### La aplicación no inicia

- Revisa los logs en Railway
- Verifica que todas las variables de entorno estén configuradas
- Asegúrate de que el JAR se haya construido correctamente

## Notas Importantes

1. **Primera ejecución**: La primera vez que Traccar se ejecuta, crea las tablas en la base de datos automáticamente usando Liquibase
2. **Usuario por defecto**: El usuario por defecto es `admin` con contraseña `admin` - **cámbialo inmediatamente después del primer login**
3. **SSL/TLS**: Railway proporciona SSL automáticamente para tu dominio
4. **Escalado**: Railway puede escalar automáticamente según el uso

## Recursos Adicionales

- [Documentación de Railway](https://docs.railway.app)
- [Documentación de Traccar](https://www.traccar.org/documentation/)
- [Configuración de Traccar](https://www.traccar.org/configuration-file/)
