# Inicio Rápido - Deploy en Railway

## Pasos Rápidos

### 1. Conectar Repositorio
- Ve a [Railway](https://railway.app)
- Crea un nuevo proyecto
- Conecta este repositorio

### 2. Agregar Base de Datos
- En Railway, haz clic en "+ New" → "Database" → "PostgreSQL"
- Railway creará automáticamente las variables: `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`

### 3. Configurar Variables de Entorno
En la configuración de tu servicio, agrega:

```bash
CONFIG_USE_ENVIRONMENT_VARIABLES=true
DATABASE_DRIVER=org.postgresql.Driver
DATABASE_URL=jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}?sslmode=require
DATABASE_USER=${PGUSER}
DATABASE_PASSWORD=${PGPASSWORD}
JAVA_OPTS=-Xmx512m
```

### 4. Deploy
- Railway detectará el `Dockerfile` automáticamente
- El build puede tardar 5-10 minutos (compilación de Java)
- Una vez completado, tendrás tu URL pública

### 5. Acceder
- Usuario por defecto: `admin`
- Contraseña por defecto: `admin`
- **¡Cambia la contraseña inmediatamente después del primer login!**

## Notas Importantes

- Railway asigna automáticamente el puerto a través de `PORT`
- Traccar lee las variables de entorno directamente (no necesitas crear `traccar.xml` manualmente)
- Los datos se almacenan en la base de datos PostgreSQL
- Para más detalles, consulta `RAILWAY_DEPLOY.md`
