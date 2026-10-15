CREATE DATABASE IF NOT EXISTS gestion_turnos
    CHARACTER SET utf8mb4;

USE gestion_turnos;

CREATE TABLE IF NOT EXISTS turnos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    estado ENUM(
        'pendiente',
        'llamado',
        'atendido'
    ) NOT NULL DEFAULT 'pendiente',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_llamado DATETIME NULL,
    fecha_atencion DATETIME NULL
) ENGINE = InnoDB;