-- Ajouter la colonne role a la table utilisateurs
ALTER TABLE utilisateurs ADD COLUMN IF NOT EXISTS role VARCHAR(20) NOT NULL DEFAULT 'user';

-- Mettre le premier utilisateur (id=1) en admin (ajuste l'id si besoin)
-- UPDATE utilisateurs SET role = 'admin' WHERE id = 1;
