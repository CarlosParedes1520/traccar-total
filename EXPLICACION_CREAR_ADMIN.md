# Explicación: Cómo se creó el usuario Admin

## 1. Sistema de Autenticación de Traccar

Traccar **NUNCA** guarda contraseñas en texto plano. En su lugar, usa un sistema de hashing seguro:

- **Algoritmo**: PBKDF2 con SHA-1
- **Salt**: 24 bytes aleatorios (único para cada contraseña)
- **Iteraciones**: 1000
- **Hash resultante**: 24 bytes convertidos a hexadecimal

## 2. Estructura de la Tabla `tc_users`

Los campos importantes para autenticación son:

```sql
- id: INT (auto-increment)
- name: VARCHAR(128) - Nombre del usuario
- email: VARCHAR(128) - Email (usado para login)
- login: VARCHAR(128) - Login alternativo (opcional)
- hashedPassword: VARCHAR(128) - Hash de la contraseña (hex)
- salt: VARCHAR(128) - Salt usado para el hash (hex)
- administrator: BOOLEAN - Si es administrador
- disabled: BOOLEAN - Si está deshabilitado
```

## 3. Proceso de Creación del Usuario Admin

### Paso 1: Generar el Hash de la Contraseña

```java
// 1. Generar salt aleatorio (24 bytes)
byte[] salt = new byte[24];
SecureRandom random = new SecureRandom();
random.nextBytes(salt);

// 2. Aplicar PBKDF2
PBEKeySpec spec = new PBEKeySpec("admin".toCharArray(), salt, 1000, 24 * 8);
SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
byte[] hash = factory.generateSecret(spec).getEncoded();

// 3. Convertir a hexadecimal
String hashHex = convertirBytesAHex(hash);  // Ej: "a1b2c3d4..."
String saltHex = convertirBytesAHex(salt);  // Ej: "e5f6g7h8..."
```

### Paso 2: Insertar en la Base de Datos

```sql
INSERT INTO tc_users (
    name, 
    email, 
    login, 
    administrator, 
    hashedPassword, 
    salt, 
    disabled
) VALUES (
    'Administrator',    -- Nombre
    'admin',           -- Email (usado para login)
    'admin',           -- Login alternativo
    true,              -- Es administrador
    'a1b2c3d4...',     -- Hash hexadecimal de la contraseña
    'e5f6g7h8...',     -- Salt hexadecimal
    false              -- No está deshabilitado
);
```

## 4. Cómo Funciona el Login

Cuando intentas iniciar sesión con `admin` / `admin`:

1. **Traccar busca el usuario** por email o login:
   ```java
   SELECT * FROM tc_users WHERE email = 'admin' OR login = 'admin'
   ```

2. **Obtiene el hash y salt** de la base de datos

3. **Vuelve a calcular el hash** con la contraseña ingresada:
   ```java
   byte[] hashCalculado = PBKDF2("admin", saltDeBD, 1000);
   ```

4. **Compara los hashes**:
   ```java
   if (hashCalculado == hashDeBD) {
       // Login exitoso
   }
   ```

## 5. Por qué es Seguro

- **Salt único**: Cada usuario tiene un salt diferente, así que dos usuarios con la misma contraseña tendrán hashes diferentes
- **PBKDF2**: Es un algoritmo lento intencionalmente (1000 iteraciones) para hacer más difícil los ataques de fuerza bruta
- **No se puede revertir**: Con el hash no puedes obtener la contraseña original

## 6. Script Completo que Usé

El script Java que creé:

1. Se conecta a la base de datos MySQL
2. Verifica si ya existe un usuario "admin"
3. Si no existe, crea uno nuevo:
   - Genera el hash de "admin" usando PBKDF2
   - Inserta el usuario con todos los campos necesarios
4. Si ya existe, actualiza su contraseña

## 7. Resultado

Ahora puedes iniciar sesión con:
- **Email/Login**: `admin`
- **Password**: `admin`

Y el sistema validará correctamente porque:
- El hash almacenado en `hashedPassword` corresponde a la contraseña "admin"
- El `salt` almacenado es el que se usó para generar ese hash
- Cuando ingresas "admin", Traccar recalcula el hash y coincide

