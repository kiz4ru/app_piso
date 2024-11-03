-- ***************************************************************
-- CREACIÓN DE LA BASE DE DATOS
-- ***************************************************************

-- Crear la base de datos si no existe y usarla
CREATE DATABASE IF NOT EXISTS app_piso_v1 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE app_piso_v1;

-- ***************************************************************
-- TABLA: Usuario
-- ***************************************************************

CREATE TABLE Usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    edad INT NOT NULL,
    género ENUM('masculino', 'femenino', 'otro') NOT NULL,
    correo_electrónico VARCHAR(100) NOT NULL UNIQUE,
    contraseña VARCHAR(255) NOT NULL, -- Almacenada con hashing
    foto_perfil VARCHAR(255), -- Ruta o URL de la foto
    descripción_personal TEXT,
    ubicación_actual VARCHAR(100),
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    última_conexión DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ***************************************************************
-- TABLA: PreferenciasUsuario
-- ***************************************************************

CREATE TABLE PreferenciasUsuario (
    id_preferencia INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    edad_preferida_min INT DEFAULT 18,
    edad_preferida_max INT DEFAULT 100,
    género_preferido ENUM('masculino', 'femenino', 'otro', 'todos') DEFAULT 'todos',
    ubicaciones_preferidas VARCHAR(255), -- Puede ser una lista separada por comas
    hábitos_preferidos VARCHAR(255), -- Por ejemplo: 'no fumador, sin mascotas'
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- ***************************************************************
-- TABLA: Interacción
-- ***************************************************************

CREATE TABLE Interacción (
    id_interacción INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario_origen INT NOT NULL,
    id_usuario_destino INT NOT NULL,
    tipo_interacción ENUM('like', 'dislike') NOT NULL,
    fecha_interacción DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_usuario_origen, id_usuario_destino), -- Evita interacciones duplicadas
    FOREIGN KEY (id_usuario_origen) REFERENCES Usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario_destino) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- ***************************************************************
-- TABLA: Match
-- ***************************************************************

CREATE TABLE MatchUsuario (
    id_match INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario1 INT NOT NULL,
    id_usuario2 INT NOT NULL,
    fecha_match DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('activo', 'eliminado') DEFAULT 'activo',
    UNIQUE (id_usuario1, id_usuario2), -- Evita matches duplicados
    FOREIGN KEY (id_usuario1) REFERENCES Usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario2) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- ***************************************************************
-- TABLA: Conversación
-- ***************************************************************

CREATE TABLE Conversación (
    id_conversación INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario1 INT NOT NULL,
    id_usuario2 INT NOT NULL,
    fecha_inicio DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_usuario1, id_usuario2),
    FOREIGN KEY (id_usuario1) REFERENCES Usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario2) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- ***************************************************************
-- TABLA: Mensaje
-- ***************************************************************

CREATE TABLE Mensaje (
    id_mensaje INT AUTO_INCREMENT PRIMARY KEY,
    id_conversación INT NOT NULL,
    id_remitente INT NOT NULL,
    contenido TEXT NOT NULL,
    fecha_envío DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_conversación) REFERENCES Conversación(id_conversación) ON DELETE CASCADE,
    FOREIGN KEY (id_remitente) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- ***************************************************************
-- TABLA: Notificación
-- ***************************************************************

CREATE TABLE Notificación (
    id_notificación INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    tipo_notificación ENUM('nuevo_match', 'mensaje_recibido', 'otro') NOT NULL,
    mensaje VARCHAR(255),
    fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('leído', 'no leído') DEFAULT 'no leído',
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- ***************************************************************
-- TABLA: Reporte
-- ***************************************************************

CREATE TABLE Reporte (
    id_reporte INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario_reportante INT NOT NULL,
    id_usuario_reportado INT NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    comentarios_adicionales TEXT,
    fecha_reporte DATETIME DEFAULT CURRENT_TIMESTAMP,
    estado_reporte ENUM('pendiente', 'en revisión', 'resuelto') DEFAULT 'pendiente',
    FOREIGN KEY (id_usuario_reportante) REFERENCES Usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario_reportado) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- ***************************************************************
-- TABLA: ConfiguraciónUsuario
-- ***************************************************************

CREATE TABLE ConfiguraciónUsuario (
    id_configuración INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    preferencias_notificación VARCHAR(255), -- Por ejemplo: 'email,push'
    configuración_privacidad VARCHAR(255), -- Por ejemplo: 'mostrar_edad,no_mostrar_distancia'
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- ***************************************************************
-- TABLA: AutenticaciónSocial (Opcional)
-- ***************************************************************

CREATE TABLE AutenticaciónSocial (
    id_autenticación INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    proveedor VARCHAR(50) NOT NULL, -- 'Facebook', 'Google', etc.
    id_proveedor VARCHAR(255) NOT NULL,
    token_autenticación VARCHAR(255),
    FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- ***************************************************************
-- TABLA: ValoraciónUsuario
-- ***************************************************************

CREATE TABLE ValoraciónUsuario (
    id_valoración INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario_evaluador INT NOT NULL,
    id_usuario_evaluado INT NOT NULL,
    puntuación INT NOT NULL CHECK (puntuación BETWEEN 1 AND 5),
    comentario TEXT,
    fecha_valoración DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_usuario_evaluador, id_usuario_evaluado), -- Evita valoraciones duplicadas
    FOREIGN KEY (id_usuario_evaluador) REFERENCES Usuario(id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_usuario_evaluado) REFERENCES Usuario(id_usuario) ON DELETE CASCADE
);

-- ***************************************************************
-- INDICES Y OPTIMIZACIONES
-- ***************************************************************

-- Índice para mejorar las consultas por edad y ubicación
CREATE INDEX idx_usuario_edad ON Usuario(edad);
CREATE INDEX idx_usuario_ubicación ON Usuario(ubicación_actual);

-- Índice para mejorar las consultas en ValoraciónUsuario
CREATE INDEX idx_valoración_usuario_evaluado ON ValoraciónUsuario(id_usuario_evaluado);

-- ***************************************************************
-- TRIGGERS (Opcional)
-- ***************************************************************

-- Trigger para actualizar la última conexión del usuario
DELIMITER $$
CREATE TRIGGER actualizar_última_conexión
BEFORE UPDATE ON Usuario
FOR EACH ROW
BEGIN
    SET NEW.última_conexión = CURRENT_TIMESTAMP;
END$$
DELIMITER ;

-- ***************************************************************
-- VISTAS (Opcional)
-- ***************************************************************

-- Vista para obtener la puntuación promedio y número de valoraciones de un usuario
CREATE VIEW VistaValoraciónUsuario AS
SELECT
    id_usuario_evaluado,
    AVG(puntuación) AS puntuación_promedio,
    COUNT(*) AS número_valoraciones
FROM ValoraciónUsuario
GROUP BY id_usuario_evaluado;

-- ***************************************************************
-- FIN DEL SCRIPT
-- ***************************************************************
