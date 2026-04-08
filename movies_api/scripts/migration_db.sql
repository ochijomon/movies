-- ============================================
-- Base de donnees : books_movies_db
-- Script de creation des tables
-- ============================================

CREATE DATABASE IF NOT EXISTS books_movies_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE books_movies_db;

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS utilisateurs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pseudo VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des notes / avis sur les films
CREATE TABLE IF NOT EXISTS notes_films (
    id INT AUTO_INCREMENT PRIMARY KEY,
    imdb_id VARCHAR(20) NOT NULL,
    id_utilisateur INT NOT NULL,
    scenario DECIMAL(3,1) NOT NULL,
    jeu_acteur DECIMAL(3,1) NOT NULL,
    qualite_av DECIMAL(3,1) NOT NULL,
    commentaire TEXT DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_utilisateur) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_movie (imdb_id, id_utilisateur)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
