-- Script para liberar el lock de Liquibase
-- Ejecutar solo si estás seguro de que no hay otra instancia de Traccar ejecutándose

-- Ver el estado actual del lock
SELECT * FROM DATABASECHANGELOGLOCK;

-- Liberar el lock (ejecutar solo si es necesario)
UPDATE DATABASECHANGELOGLOCK SET LOCKED = 0, LOCKGRANTED = NULL, LOCKEDBY = NULL;

-- Verificar que se liberó
SELECT * FROM DATABASECHANGELOGLOCK;

