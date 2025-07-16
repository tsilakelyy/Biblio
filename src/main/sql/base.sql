-- ─────────────────────────────────────────────────────────────────────
-- 1) Création de la base et choix de l'encodage
-- ─────────────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS bibliotheque
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE bibliotheque;

-- ─────────────────────────────────────────────────────────────────────
-- 2) Tables principales
-- ─────────────────────────────────────────────────────────────────────

-- profils d'adhérents (quotas, durées, etc.)
CREATE TABLE profil (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  max_prets_sur_place INT NOT NULL DEFAULT 0,
  max_prets_domicile INT NOT NULL DEFAULT 0,
  duree_pret_jours INT NOT NULL DEFAULT 14,
  max_reservations INT NOT NULL DEFAULT 3,
  max_prolongations INT NOT NULL DEFAULT 1,
  duree_prolongation_jours INT NOT NULL DEFAULT 7
) ENGINE=InnoDB;
-- comptes de connexion (login) pour ADMIN/EMPLOYE/CLIENT
CREATE TABLE utilisateur (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,       -- à stocker haché en pratique
  role ENUM('ADMIN','EMPLOYE','CLIENT') NOT NULL
) ENGINE=InnoDB;

-- adhérents / clients de la bibliothèque
CREATE TABLE adherent (
  id INT AUTO_INCREMENT PRIMARY KEY,
  utilisateur_id INT NOT NULL,
  nom VARCHAR(100) NOT NULL,
  prenom VARCHAR(100) NOT NULL,
  profil_id INT NOT NULL,
  actif BOOLEAN NOT NULL DEFAULT TRUE,
  sanction BOOLEAN NOT NULL DEFAULT FALSE,
  nb_emprunts_actuels INT NOT NULL DEFAULT 0,
  date_inscription DATE NOT NULL,
  FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (profil_id) REFERENCES profil(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- employés / bibliothécaires
CREATE TABLE employe (
  id INT AUTO_INCREMENT PRIMARY KEY,
  utilisateur_id INT NOT NULL,
  nom VARCHAR(100) NOT NULL,
  role ENUM('BIBLIOTHECAIRE','ADMIN') NOT NULL,
  FOREIGN KEY (utilisateur_id) REFERENCES utilisateur(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- catalogue des livres
CREATE TABLE livre (
  id INT AUTO_INCREMENT PRIMARY KEY,
  titre VARCHAR(255) NOT NULL,
  edition VARCHAR(100),
  auteur VARCHAR(200),
  date_sortie DATE,
  categorie VARCHAR(100),
  nombre_exemplaires_total INT NOT NULL DEFAULT 0,
  nombre_exemplaires_disponibles INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- exemplaires physiques
CREATE TABLE exemplaire (
  id INT AUTO_INCREMENT PRIMARY KEY,
  livre_id INT NOT NULL,
  etat ENUM('BON','ABIME','PERDU') NOT NULL DEFAULT 'BON',
  disponible BOOLEAN NOT NULL DEFAULT TRUE,
  FOREIGN KEY (livre_id) REFERENCES livre(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- prêts
CREATE TABLE pret (
  id INT AUTO_INCREMENT PRIMARY KEY,
  adherent_id INT NOT NULL,
  exemplaire_id INT NOT NULL,
  date_pret DATETIME NOT NULL,
  date_retour_prevu DATETIME NOT NULL,
  date_retour_effectif DATETIME,            -- peut être saisie librement
  statut ENUM('EN_COURS','TERMINE','EN_RETARD') NOT NULL DEFAULT 'EN_COURS',
  nb_prolongations INT NOT NULL DEFAULT 0,
  type_pret ENUM('SUR_PLACE','A_DOMICILE') NOT NULL,
  FOREIGN KEY (adherent_id) REFERENCES adherent(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (exemplaire_id) REFERENCES exemplaire(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- prolongements
CREATE TABLE prolongement (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pret_id INT NOT NULL,
  jours_suppl INT NOT NULL,
  date_demande DATE NOT NULL,
  date_nouvelle_retour DATETIME NOT NULL,
  statut ENUM('EN_ATTENTE','ACCEPTEE','REFUSEE') NOT NULL DEFAULT 'EN_ATTENTE',
  FOREIGN KEY (pret_id) REFERENCES pret(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- réservations
CREATE TABLE reservation (
  id INT AUTO_INCREMENT PRIMARY KEY,
  adherent_id INT NOT NULL,
  exemplaire_id INT NOT NULL,
  date_debut DATE NOT NULL,
  date_fin DATE NOT NULL,
  statut ENUM('ACTIVE','TERMINEE','ANNULEE') NOT NULL DEFAULT 'ACTIVE',
  FOREIGN KEY (adherent_id) REFERENCES adherent(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (exemplaire_id) REFERENCES exemplaire(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- pénalités
CREATE TABLE penalite (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pret_id INT NOT NULL,
  montant DECIMAL(10,2) NOT NULL,
  date_calcul DATE NOT NULL,
  FOREIGN KEY (pret_id) REFERENCES pret(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- inscriptions / abonnements
CREATE TABLE inscription (
  id INT AUTO_INCREMENT PRIMARY KEY,
  adherent_id INT NOT NULL,
  date_inscription DATE NOT NULL,
  type_abonnement ENUM('STANDARD','PREMIUM') NOT NULL DEFAULT 'STANDARD',
  FOREIGN KEY (adherent_id) REFERENCES adherent(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────
-- 3) Vues utiles
-- ─────────────────────────────────────────────────────────────────────

-- vue des prêts en cours avec date prévue
CREATE VIEW vue_prets_en_cours AS
SELECT p.id, a.nom, a.prenom, l.titre, p.date_pret, p.date_retour_prevu
FROM pret p
JOIN adherent a ON p.adherent_id = a.id
JOIN exemplaire e ON p.exemplaire_id = e.id
JOIN livre l ON e.livre_id = l.id
WHERE p.statut = 'EN_COURS';

-- vue des prêts en retard
CREATE VIEW vue_prets_en_retard AS
SELECT *, TIMESTAMPDIFF(DAY, date_retour_prevu, NOW()) AS jours_retard
FROM pret
WHERE statut = 'EN_RETARD';

-- vue du nombre d’exemplaires disponibles par livre
CREATE VIEW vue_disponibilite AS
SELECT l.id AS livre_id, l.titre, COUNT(e.id) AS dispo
FROM livre l
LEFT JOIN exemplaire e ON e.livre_id = l.id AND e.disponible = TRUE
GROUP BY l.id, l.titre;

-- ─────────────────────────────────────────────────────────────────────
-- 4) Données de test
-- ─────────────────────────────────────────────────────────────────────

-- profils
INSERT INTO profil (nom, max_prets_sur_place, max_prets_domicile, duree_pret_jours, max_reservations, max_prolongations, duree_prolongation_jours)
VALUES
  ('ETUDIANT', 2, 3, 14, 2, 1, 7),
  ('PROF',     2, 3, 30, 5, 2,14),
  ('ANONYME',  1, 1, 7,  1, 0, 0);

-- utilisateurs (hachage simulé pour l’exemple)
INSERT INTO utilisateur (username,password,role) VALUES
  ('admin','$2a$10$XXXXXXXXXXXXXXXXXXXXXXXXXXXX', 'ADMIN'),
  ('biblio','$2a$10$YYYYYYYYYYYYYYYYYYYYYYYY', 'EMPLOYE'),
  ('alice','$2a$10$AAAAAAAAAAAAAAAAAAAAAAAA', 'CLIENT'),
  ('bob',  '$2a$10$BBBBBBBBBBBBBBBBBBBBBBBB', 'CLIENT');

-- adhérents
INSERT INTO adherent (utilisateur_id,nom,prenom,profil_id,actif,sanction,nb_emprunts_actuels,date_inscription)
VALUES
  (3,'Dupont','Alice',1,TRUE,FALSE,0,'2025-01-10'),
  (4,'Martin','Bob',2,TRUE,FALSE,1,'2024-11-05');

-- employés
INSERT INTO employe (utilisateur_id,nom,role)
VALUES
  (2,'Durand','BIBLIOTHECAIRE'),
  (1,'Admin','ADMIN');

-- livres
INSERT INTO livre (titre,edition,auteur,date_sortie,categorie,nombre_exemplaires_total,nombre_exemplaires_disponibles)
VALUES
  ('Le Petit Prince','Gallimard','Antoine de Saint-Exupéry','1943-04-06','Roman',5,5),
  ('1984','Secker & Warburg','George Orwell','1949-06-08','Dystopie',3,3);

-- exemplaires
INSERT INTO exemplaire (livre_id,etat,disponible)
VALUES
  (1,'BON',TRUE),(1,'BON',TRUE),(1,'BON',TRUE),(1,'ABIME',TRUE),(1,'BON',TRUE),
  (2,'BON',TRUE),(2,'BON',TRUE),(2,'BON',TRUE);

-- prêts
INSERT INTO pret (adherent_id,exemplaire_id,date_pret,date_retour_prevu,date_retour_effectif,statut,nb_prolongations,type_pret)
VALUES
  -- Alice emprunte un exemplaire du Petit Prince
  (1,1,'2025-07-01 10:00:00','2025-07-15 10:00:00',NULL,'EN_COURS',0,'A_DOMICILE'),
  -- Bob avait un prêt terminé
  (2,6,'2025-06-01 09:00:00','2025-06-30 09:00:00','2025-06-29 15:00:00','TERMINE',0,'SUR_PLACE'),
  -- Bob en retard
  (2,7,'2025-06-10 14:00:00','2025-06-20 14:00:00',NULL,'EN_RETARD',0,'A_DOMICILE');

-- prolongements
INSERT INTO prolongement (pret_id,jours_suppl,date_demande,date_nouvelle_retour,statut)
VALUES
  (1,7,'2025-07-10','2025-07-22 10:00:00','EN_ATTENTE');

-- réservations
INSERT INTO reservation (adherent_id,exemplaire_id,date_debut,date_fin,statut)
VALUES
  (1,2,'2025-07-20','2025-07-30','ACTIVE');

-- pénalités
INSERT INTO penalite (pret_id,montant,date_calcul)
VALUES
  (3,5.00,'2025-06-21');

-- inscriptions
INSERT INTO inscription (adherent_id,date_inscription,type_abonnement)
VALUES
  (1,'2025-01-10','STANDARD'),
  (2,'2024-11-05','PREMIUM');

-- ─────────────────────────────────────────────────────────────────────
-- 5) Exemples de SELECT pour vérification
-- ─────────────────────────────────────────────────────────────────────

-- a) lister tous les prêts en cours
SELECT * FROM vue_prets_en_cours;

-- b) lister les prêts en retard
SELECT * FROM vue_prets_en_retard;

-- c) disponibilité par livre
SELECT * FROM vue_disponibilite;

-- d) détail d’un adhérent, comptes et profil
SELECT a.*, u.username, p.nom AS profil
FROM adherent a
JOIN utilisateur u ON a.utilisateur_id=u.id
JOIN profil p ON a.profil_id=p.id
WHERE a.nom='Dupont';

-- e) historique des prêts d’Alice
SELECT p.*, l.titre
FROM pret p
JOIN exemplaire e ON p.exemplaire_id=e.id
JOIN livre l ON e.livre_id=l.id
WHERE p.adherent_id=1;
