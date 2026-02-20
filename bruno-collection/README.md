# Traccar API - Bruno Collection

Colección completa de endpoints de la API de Traccar para Bruno.

## Instalación

1. Instala [Bruno](https://www.usebruno.com/)
2. Abre Bruno
3. Click en "Open Collection" o "Import Collection"
4. Selecciona la carpeta `bruno-collection`

## Configuración

### Variables de Entorno

La colección incluye dos entornos preconfigurados:

- **Local**: `http://localhost:8082/api`
- **Production**: `https://traccar.viajeromorlaco.com/api`

Puedes modificar las variables en:
- `environments/local.bru`
- `environments/production.bru`

### Variables Disponibles

- `baseUrl`: URL base de la API
- `email`: Email del usuario
- `password`: Contraseña del usuario
- `deviceId`: ID de dispositivo de prueba
- `userId`: ID de usuario de prueba

## Estructura

La colección está organizada en 23 carpetas:

1. **01 - Authentication & Session**: Login, logout, tokens
2. **02 - Server**: Información y configuración del servidor
3. **03 - Health**: Health check
4. **04 - Devices**: CRUD de dispositivos
5. **05 - Positions**: Posiciones GPS
6. **06 - Events**: Eventos del sistema
7. **07 - Users**: Gestión de usuarios
8. **08 - Groups**: Grupos de dispositivos
9. **09 - Permissions**: Permisos y enlaces
10. **10 - Commands**: Comandos a dispositivos
11. **11 - Geofences**: Cercas virtuales
12. **12 - Notifications**: Notificaciones
13. **13 - Reports**: Reportes (route, events, summary, trips, stops)
14. **14 - Statistics**: Estadísticas del servidor
15. **15 - Calendars**: Calendarios
16. **16 - Attributes (Computed)**: Atributos computados
17. **17 - Drivers**: Conductores
18. **18 - Maintenance**: Mantenimiento
19. **19 - Orders**: Órdenes
20. **20 - Password**: Gestión de contraseñas
21. **21 - Audit**: Auditoría
22. **22 - Contacts**: Contactos
23. **23 - Notification Push**: Tokens push

## Uso

1. Selecciona el entorno (Local o Production)
2. Ajusta las variables si es necesario
3. Ejecuta los requests desde Bruno
4. Los requests incluyen autenticación básica automática

## Notas

- Todos los endpoints requieren autenticación (excepto `/health` y `/server`)
- La autenticación se configura automáticamente usando las variables `email` y `password`
- Algunos endpoints requieren permisos de administrador
- Los reportes pueden exportarse en formato Excel usando el parámetro `type=xlsx`

## Endpoints Principales

### Autenticación
- `POST /api/session` - Login
- `GET /api/session` - Obtener información de sesión
- `DELETE /api/session` - Logout

### Dispositivos
- `GET /api/devices` - Listar dispositivos
- `POST /api/devices` - Crear dispositivo
- `PUT /api/devices/{id}` - Actualizar dispositivo
- `DELETE /api/devices/{id}` - Eliminar dispositivo

### Posiciones
- `GET /api/positions` - Obtener posiciones
- `GET /api/positions?deviceId=X&from=...&to=...` - Posiciones por dispositivo y rango de fechas

### Reportes
- `GET /api/reports/route` - Reporte de ruta
- `GET /api/reports/events` - Reporte de eventos
- `GET /api/reports/summary` - Reporte resumen
- `GET /api/reports/trips` - Reporte de viajes
- `GET /api/reports/stops` - Reporte de paradas

## Más Información

Para más detalles sobre la API de Traccar, consulta:
- [Documentación oficial](https://www.traccar.org/documentation/)
- [OpenAPI Specification](./openapi.yaml)

