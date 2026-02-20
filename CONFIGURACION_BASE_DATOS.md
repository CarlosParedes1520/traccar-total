# 🗄️ Configuración de Base de Datos

## 📍 Base de Datos Actual

**Tipo:** Base de datos **EXTERNA** (remota)

### Configuración en `debug.xml`:

```xml
<entry key='database.driver'>com.mysql.cj.jdbc.Driver</entry>
<entry key='database.url'>jdbc:mysql://137.184.85.144:4406/traccar?serverTimezone=UTC&amp;useSSL=false&amp;allowPublicKeyRetrieval=true</entry>
<entry key='database.user'>physeter</entry>
<entry key='database.password'>Ph15eter$2025$R</entry>
```

### Detalles de Conexión:

| Parámetro | Valor |
|-----------|-------|
| **Tipo** | MySQL (MariaDB compatible) |
| **Host** | `137.184.85.144` (IP externa) |
| **Puerto** | `4406` |
| **Base de Datos** | `traccar` |
| **Usuario** | `physeter` |
| **Password** | `Ph15eter$2025$R` |
| **Timezone** | UTC |
| **SSL** | Deshabilitado |
| **Ubicación** | Externa (no localhost) |

---

## 🔍 ¿Es Externa o Local?

### ✅ **EXTERNA** (Remota)

**Evidencia:**
- Host: `137.184.85.144` (IP pública, no `localhost` ni `127.0.0.1`)
- Puerto: `4406` (puerto no estándar, probablemente configurado en el servidor remoto)
- La IP `137.184.85.144` parece ser un servidor de Digital Ocean o similar

### ❌ **NO es Local**

Si fuera local, la configuración sería:
```xml
<entry key='database.url'>jdbc:mysql://localhost:3306/traccar</entry>
<!-- o -->
<entry key='database.url'>jdbc:mysql://127.0.0.1:3306/traccar</entry>
```

---

## 🌐 Ubicación del Servidor

La IP `137.184.85.144` es una **dirección IP pública**, lo que indica:

1. **Servidor remoto** (probablemente Digital Ocean, AWS, o similar)
2. **No está en tu máquina local**
3. **Requiere conexión de red** para acceder

---

## ⚙️ Configuración en el Servidor

Cuando despliegues en el servidor (`/opt/traccar/conf/traccar.xml`), puedes:

### Opción 1: Usar la misma base de datos externa
```xml
<entry key='database.url'>jdbc:mysql://137.184.85.144:4406/traccar?serverTimezone=UTC&amp;useSSL=false&amp;allowPublicKeyRetrieval=true</entry>
<entry key='database.user'>physeter</entry>
<entry key='database.password'>Ph15eter$2025$R</entry>
```

### Opción 2: Usar una base de datos local en el servidor
```xml
<entry key='database.url'>jdbc:mysql://localhost:3306/traccar?serverTimezone=UTC&amp;useSSL=false</entry>
<entry key='database.user'>traccar</entry>
<entry key='database.password'>tu_password_local</entry>
```

---

## 🔐 Seguridad

⚠️ **Nota de Seguridad:**
- El password está en texto plano en `debug.xml`
- En producción, considera usar variables de entorno o un archivo de configuración protegido
- El archivo `debug.xml` no debería estar en el repositorio con credenciales

---

## 📝 Verificar Conexión

### Desde tu máquina local:
```bash
# Probar conexión
mysql -h 137.184.85.144 -P 4406 -u physeter -p'Ph15eter$2025$R' traccar -e "SELECT 1;"
```

### Desde el servidor:
```bash
# Si la BD está en el mismo servidor
mysql -h localhost -u traccar -p traccar -e "SELECT 1;"

# Si la BD es externa (misma configuración)
mysql -h 137.184.85.144 -P 4406 -u physeter -p'Ph15eter$2025$R' traccar -e "SELECT 1;"
```

---

## 🎯 Resumen

| Aspecto | Valor |
|--------|-------|
| **Tipo** | Externa (remota) |
| **Host** | 137.184.85.144 |
| **Puerto** | 4406 |
| **Base de Datos** | traccar |
| **Usuario** | physeter |
| **Local** | ❌ No |
| **Externa** | ✅ Sí |

---

## 💡 Recomendaciones

1. **Para desarrollo local:** Puedes usar la misma BD externa o crear una local
2. **Para producción:** Considera usar una BD local en el servidor para mejor rendimiento
3. **Seguridad:** No subas `debug.xml` con credenciales al repositorio
4. **Backup:** Asegúrate de tener backups de la BD externa

