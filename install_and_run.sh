#!/bin/bash
echo "Instalando OpenJDK 17 JDK..."
sudo apt update
sudo apt install -y openjdk-17-jdk

echo "Configurando JAVA_HOME..."
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

echo "Compilando el proyecto..."
./gradlew build -x test

echo "Ejecutando Traccar..."
java -jar target/tracker-server.jar debug.xml
