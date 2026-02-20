# Lista Completa de Endpoints en Bruno Collection

## Resumen
- **Total de endpoints:** 130+
- **Carpetas:** 24
- **Última actualización:** 2026-02-11

## Ubicación del Login (Admin)

**Carpeta:** `01 - Authentication & Session`  
**Archivo:** `Login - Create Session.bru`  
**Endpoint:** `POST /api/session`

## Estructura Completa

### 01 - Authentication & Session (8 endpoints)
- ✅ Login - Create Session
- ✅ Get Session Info
- ✅ Get Session with Token
- ✅ Logout - Close Session
- ✅ Generate Session Token
- ✅ Revoke Session Token
- ✅ OpenID Auth
- ✅ OpenID Callback

### 02 - Server (8 endpoints)
- ✅ Get Server Info
- ✅ Update Server
- ✅ Geocode Address
- ✅ Get Timezones
- ✅ Upload File
- ✅ Garbage Collection
- ✅ Get Cache Info
- ✅ Reboot Server

### 03 - Health (1 endpoint)
- ✅ Health Check

### 04 - Devices (11 endpoints)
- ✅ Get All Devices
- ✅ Get All Devices (Admin)
- ✅ Get Device by ID
- ✅ Get Device by Unique ID
- ✅ Get Devices by User ID
- ✅ Create Device
- ✅ Update Device
- ✅ Delete Device
- ✅ Update Device Accumulators
- ✅ Upload Device Image
- ✅ Share Device

### 05 - Positions (8 endpoints)
- ✅ Get All Positions
- ✅ Get Positions by Device ID
- ✅ Get Positions by ID
- ✅ Get Positions as CSV
- ✅ Get Positions as GPX
- ✅ Get Positions as KML
- ✅ Delete Position
- ✅ Delete Positions by Device and Time Range

### 06 - Events (1 endpoint)
- ✅ Get Event by ID

### 07 - Users (6 endpoints)
- ✅ Get All Users
- ✅ Get Users by User ID
- ✅ Create User
- ✅ Update User
- ✅ Delete User
- ✅ Generate TOTP Key

### 08 - Groups (6 endpoints)
- ✅ Get All Groups
- ✅ Get All Groups (Admin)
- ✅ Get Groups by User ID
- ✅ Create Group
- ✅ Update Group
- ✅ Delete Group

### 09 - Permissions (7 endpoints)
- ✅ Add Permission - User to Device
- ✅ Add Permission - User to Group
- ✅ Add Permission - Device to Geofence
- ✅ Add Permission - Device to Notification
- ✅ Remove Permission
- ✅ Bulk Add Permissions
- ✅ Bulk Remove Permissions

### 10 - Commands (11 endpoints)
- ✅ Get All Commands
- ✅ Get Commands by Device ID
- ✅ Get Command Types
- ✅ Get Command Types (SMS)
- ✅ Create Saved Command
- ✅ Update Saved Command
- ✅ Delete Saved Command
- ✅ Get Sendable Commands for Device
- ✅ Send Command to Device
- ✅ Send Command to Group
- ✅ Send Saved Command

### 11 - Geofences (5 endpoints)
- ✅ Get All Geofences
- ✅ Get Geofences by Device ID
- ✅ Create Geofence
- ✅ Update Geofence
- ✅ Delete Geofence

### 12 - Notifications (10 endpoints)
- ✅ Get All Notifications
- ✅ Get Notification Types
- ✅ Get Notificators
- ✅ Create Notification
- ✅ Update Notification
- ✅ Delete Notification
- ✅ Test Notification
- ✅ Test Notification by Type
- ✅ Send Custom Notification
- ✅ Simulate Event

### 13 - Reports (12 endpoints)
- ✅ Route Report
- ✅ Route Report (Excel)
- ✅ Events Report
- ✅ Events Report (Excel)
- ✅ Summary Report
- ✅ Summary Report (Excel)
- ✅ Trips Report
- ✅ Trips Report (Excel)
- ✅ Stops Report
- ✅ Stops Report (Excel)
- ✅ Devices Report (Excel)
- ✅ Combined Report

### 14 - Statistics (1 endpoint)
- ✅ Get Statistics

### 15 - Calendars (4 endpoints)
- ✅ Get All Calendars
- ✅ Create Calendar
- ✅ Update Calendar
- ✅ Delete Calendar

### 16 - Attributes (Computed) (5 endpoints)
- ✅ Get All Attributes
- ✅ Create Attribute
- ✅ Update Attribute
- ✅ Delete Attribute
- ✅ Test Attribute Expression

### 17 - Drivers (4 endpoints)
- ✅ Get All Drivers
- ✅ Create Driver
- ✅ Update Driver
- ✅ Delete Driver

### 18 - Maintenance (4 endpoints)
- ✅ Get All Maintenance
- ✅ Create Maintenance
- ✅ Update Maintenance
- ✅ Delete Maintenance

### 19 - Orders (4 endpoints)
- ✅ Get All Orders
- ✅ Create Order
- ✅ Update Order
- ✅ Delete Order

### 20 - Password (4 endpoints)
- ✅ Change Password
- ✅ Reset Password
- ✅ Update Password
- ✅ Generate Password Key

### 21 - Audit (1 endpoint)
- ✅ Get Audit Log

### 22 - Contacts (4 endpoints)
- ✅ Get All Contacts
- ✅ Create Contact
- ✅ Update Contact
- ✅ Delete Contact

### 23 - Notification Push (1 endpoint)
- ✅ Register Push Token

### 24 - OIDC (4 endpoints)
- ✅ OIDC Authorize
- ✅ OIDC Token
- ✅ OIDC UserInfo
- ✅ OIDC JWKS

## Endpoints Faltantes (si los hay)

Todos los endpoints principales están incluidos. Si encuentras algún endpoint faltante, por favor repórtalo.

## Notas

- El endpoint de login está en: `01 - Authentication & Session/Login - Create Session.bru`
- Todos los endpoints usan variables de entorno configurables
- La autenticación básica está configurada automáticamente
- Los endpoints de OIDC requieren configuración adicional del servidor

