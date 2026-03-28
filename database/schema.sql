-- ============================================================
-- CHURCH MEDIA APP — MySQL Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS church_media_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE church_media_db;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  role          ENUM('admin', 'user') NOT NULL DEFAULT 'user',
  password_hash VARCHAR(255) NOT NULL,
  avatar_url    VARCHAR(500),
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Media Table
CREATE TABLE IF NOT EXISTS media (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  type          ENUM('video', 'photo', 'audio') NOT NULL,
  file_path     VARCHAR(500),
  title         VARCHAR(200),
  thumbnail_url VARCHAR(500),
  status        ENUM('pending', 'uploading', 'uploaded', 'failed') DEFAULT 'pending',
  uploaded_by   INT NOT NULL,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE CASCADE
);

-- Media Metadata Table
CREATE TABLE IF NOT EXISTS media_metadata (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  media_id      INT NOT NULL UNIQUE,
  event_name    VARCHAR(200),
  location      VARCHAR(200),
  description   TEXT,
  participants  TEXT,
  sermon_topic  VARCHAR(200),
  speaker_name  VARCHAR(150),
  service_date  DATE,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (media_id) REFERENCES media(id) ON DELETE CASCADE
);

-- Uploads Table
CREATE TABLE IF NOT EXISTS uploads (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  media_id         INT NOT NULL,
  platform         ENUM('telegram', 'youtube') NOT NULL,
  upload_status    ENUM('pending', 'in_progress', 'success', 'failed') DEFAULT 'pending',
  telegram_msg_id  VARCHAR(100),
  youtube_link     VARCHAR(500),
  youtube_video_id VARCHAR(100),
  retry_count      INT DEFAULT 0,
  error_message    TEXT,
  upload_date      DATETIME,
  created_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (media_id) REFERENCES media(id) ON DELETE CASCADE
);

-- Logs Table
CREATE TABLE IF NOT EXISTS logs (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  action    VARCHAR(200) NOT NULL,
  user_id   INT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  details   TEXT,
  ip_addr   VARCHAR(50),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Refresh Tokens Table
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT NOT NULL,
  token      VARCHAR(512) NOT NULL UNIQUE,
  expires_at DATETIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_media_status ON media(status);
CREATE INDEX idx_media_type ON media(type);
CREATE INDEX idx_media_uploaded_by ON media(uploaded_by);
CREATE INDEX idx_uploads_media_id ON uploads(media_id);
CREATE INDEX idx_uploads_status ON uploads(upload_status);
CREATE INDEX idx_logs_user_id ON logs(user_id);
CREATE INDEX idx_logs_timestamp ON logs(timestamp);

-- Seed: Default Admin User (password: Admin@Church123)
INSERT INTO users (name, email, role, password_hash) VALUES
('Church Admin', 'admin@church.org', 'admin', '$2b$12$placeholder_hash_replace_on_first_run');
