# Dockerfile para Railway - Construye Traccar desde el código fuente
FROM eclipse-temurin:17-jdk-alpine AS build

# Instalar dependencias necesarias para la compilación
RUN apk add --no-cache bash git

WORKDIR /build

# Copiar archivos de Gradle
COPY gradle/ ./gradle/
COPY gradlew ./
COPY gradlew.bat ./
COPY build.gradle ./
COPY settings.gradle ./

# Copiar código fuente
COPY src/ ./src/
COPY schema/ ./schema/
COPY templates/ ./templates/

# Dar permisos de ejecución al gradlew
RUN chmod +x ./gradlew

# Construir el proyecto
RUN ./gradlew assemble --no-daemon

# Crear estructura de directorios para Traccar
RUN mkdir -p /opt/traccar/{conf,data,logs}

# Copiar el JAR y dependencias
RUN cp target/tracker-server.jar /opt/traccar/ && \
    cp -r target/lib /opt/traccar/

# Imagen final
FROM eclipse-temurin:17-jre-alpine

# Instalar dependencias del sistema
RUN apk add --no-cache tzdata curl

WORKDIR /opt/traccar

# Copiar archivos construidos
COPY --from=build /opt/traccar/tracker-server.jar ./
COPY --from=build /opt/traccar/lib ./lib

# Crear directorios necesarios
RUN mkdir -p conf data logs

# Copiar archivo de configuración por defecto como plantilla
COPY setup/traccar.xml conf/traccar.xml.template

# Copiar script de entrada
COPY docker-entrypoint.sh /opt/traccar/docker-entrypoint.sh
RUN chmod +x /opt/traccar/docker-entrypoint.sh

# Exponer puertos
# Railway asignará el puerto automáticamente a través de la variable PORT
EXPOSE 8082

# Variables de entorno por defecto
ENV JAVA_OPTS="-Xmx512m"
ENV CONFIG_USE_ENVIRONMENT_VARIABLES="true"

# Healthcheck (Railway puede usar esto, pero el puerto se configura dinámicamente)
HEALTHCHECK --interval=2m --timeout=5s --start-period=1m --retries=3 \
  CMD sh -c 'PORT=${PORT:-8082}; curl -f http://localhost:$PORT/api/health || exit 1'

# Usar script de entrada
ENTRYPOINT ["/opt/traccar/docker-entrypoint.sh"]
