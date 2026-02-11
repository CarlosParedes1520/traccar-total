#!/bin/bash

# Script para crear usuario admin en el servidor
# Uso: ./create-admin-server.sh

set -e

echo "=========================================="
echo "Creando usuario Admin en Traccar"
echo "=========================================="

# Configuración de base de datos (ajusta según tu configuración)
DB_HOST="${DB_HOST:-137.184.85.144}"
DB_PORT="${DB_PORT:-4406}"
DB_NAME="${DB_NAME:-traccar}"
DB_USER="${DB_USER:-physeter}"
DB_PASS="${DB_PASS:-Ph15eter\$2025\$R}"

# Directorio donde está Traccar
TRACCAR_DIR="${TRACCAR_DIR:-/opt/traccar}"
SCRIPTS_DIR="${SCRIPTS_DIR:-$(dirname "$0")}"

echo "Verificando dependencias..."

# Verificar Java
if ! command -v java &> /dev/null; then
    echo "ERROR: Java no está instalado"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1)
echo "Java encontrado: $JAVA_VERSION"

# Verificar MySQL client
if ! command -v mysql &> /dev/null; then
    echo "MySQL client no encontrado. Intentando instalar..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y mysql-client
    elif command -v yum &> /dev/null; then
        sudo yum install -y mysql
    else
        echo "ERROR: No se pudo instalar MySQL client automáticamente"
        echo "Por favor instálalo manualmente"
        exit 1
    fi
fi

# Buscar JAR de MySQL connector
MYSQL_JAR=$(find "$TRACCAR_DIR/lib" -name "mysql-connector-j-*.jar" 2>/dev/null | head -n 1)

if [ -z "$MYSQL_JAR" ]; then
    echo "ERROR: No se encontró mysql-connector-j-*.jar en $TRACCAR_DIR/lib"
    exit 1
fi

echo "MySQL connector encontrado: $MYSQL_JAR"

# Crear script Java temporal
JAVA_SCRIPT=$(mktemp /tmp/create-admin-XXXXXX.java)

cat > "$JAVA_SCRIPT" << 'JAVA_EOF'
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.PreparedStatement;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;

public class CreateAdminUser {
    private static final int ITERATIONS = 1000;
    private static final int SALT_SIZE = 24;
    private static final int HASH_SIZE = 24;
    
    private static SecretKeyFactory factory;
    static {
        try {
            factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    private static byte[] function(char[] password, byte[] salt) {
        try {
            PBEKeySpec spec = new PBEKeySpec(password, salt, ITERATIONS, HASH_SIZE * Byte.SIZE);
            return factory.generateSecret(spec).getEncoded();
        } catch (InvalidKeySpecException e) {
            throw new SecurityException(e);
        }
    }
    
    private static String printHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
    
    private static HashingResult createHash(String password) {
        byte[] salt = new byte[SALT_SIZE];
        new SecureRandom().nextBytes(salt);
        byte[] hash = function(password.toCharArray(), salt);
        return new HashingResult(printHex(hash), printHex(salt));
    }
    
    static class HashingResult {
        private final String hash;
        private final String salt;
        
        public HashingResult(String hash, String salt) {
            this.hash = hash;
            this.salt = salt;
        }
        
        public String getHash() { return hash; }
        public String getSalt() { return salt; }
    }
    
    public static void main(String[] args) {
        if (args.length < 5) {
            System.err.println("Uso: java CreateAdminUser <host> <port> <db> <user> <password>");
            System.exit(1);
        }
        
        String host = args[0];
        String port = args[1];
        String dbName = args[2];
        String dbUser = args[3];
        String dbPass = args[4];
        
        String url = "jdbc:mysql://" + host + ":" + port + "/" + dbName + 
                     "?serverTimezone=UTC&useSSL=false&allowPublicKeyRetrieval=true";
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(url, dbUser, dbPass);
            
            // Verificar si ya existe
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT id FROM tc_users WHERE email = 'admin' OR login = 'admin'");
            
            if (rs.next()) {
                int userId = rs.getInt("id");
                System.out.println("Usuario 'admin' ya existe (ID: " + userId + ")");
                System.out.println("Actualizando contraseña...");
                
                HashingResult result = createHash("admin");
                
                PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE tc_users SET hashedPassword = ?, salt = ?, administrator = 1 WHERE id = ?");
                pstmt.setString(1, result.getHash());
                pstmt.setString(2, result.getSalt());
                pstmt.setInt(3, userId);
                pstmt.executeUpdate();
                
                System.out.println("✓ Contraseña actualizada para usuario admin (ID: " + userId + ")");
            } else {
                System.out.println("Creando nuevo usuario admin...");
                
                HashingResult result = createHash("admin");
                
                PreparedStatement pstmt = conn.prepareStatement(
                    "INSERT INTO tc_users (name, email, login, administrator, hashedPassword, salt, disabled) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?)");
                pstmt.setString(1, "Administrator");
                pstmt.setString(2, "admin");
                pstmt.setString(3, "admin");
                pstmt.setBoolean(4, true);
                pstmt.setString(5, result.getHash());
                pstmt.setString(6, result.getSalt());
                pstmt.setBoolean(7, false);
                pstmt.executeUpdate();
                
                System.out.println("✓ Usuario admin creado exitosamente!");
            }
            
            System.out.println("\nCredenciales:");
            System.out.println("  Email/Login: admin");
            System.out.println("  Password: admin");
            
            conn.close();
        } catch (Exception e) {
            System.err.println("ERROR: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
JAVA_EOF

# Compilar el script Java
echo "Compilando script Java..."
javac -cp "$MYSQL_JAR" "$JAVA_SCRIPT" 2>&1 || {
    echo "ERROR: No se pudo compilar el script Java"
    rm -f "$JAVA_SCRIPT"
    exit 1
}

# Ejecutar el script
echo "Ejecutando script para crear usuario admin..."
java -cp "$(dirname "$JAVA_SCRIPT"):$MYSQL_JAR" CreateAdminUser \
    "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_USER" "$DB_PASS"

# Limpiar
rm -f "$JAVA_SCRIPT" "$(dirname "$JAVA_SCRIPT")/CreateAdminUser.class"

echo ""
echo "=========================================="
echo "Proceso completado!"
echo "=========================================="

