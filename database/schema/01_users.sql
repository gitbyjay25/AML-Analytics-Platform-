CREATE DATABASE IF NOT EXISTS aml_analytics
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  
USE aml_analytics;

CREATE TABLE users (
    user_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(150)        NOT NULL,
    email           VARCHAR(150)        NOT NULL,
    password_hash   VARCHAR(255)        NOT NULL,
    role            ENUM('admin', 'analyst', 'manager') NOT NULL DEFAULT 'analyst',
    is_active       TINYINT(1)          NOT NULL DEFAULT 1,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_users_email (email)
) ENGINE = InnoDB;