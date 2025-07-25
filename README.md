# Projet de gestion de bibliothèque 📚

Ce projet Java est destiné à gérer les emprunts, retours, clients et employés d'une bibliothèque.

## Technologies utilisées
- Java 17
- Maven
- Spring Boot (à venir)

### Base de données visible avec looping
1. **Table `profil`**  
   Définit les quotas et durées selon le type d’adhérent.  
2. **Table `utilisateur`**  
   Gère les logins et rôles (`ADMIN`, `EMPLOYE`, `CLIENT`).  
3. **Table `adherent`**  
   Les clients (profil, statut, sanction, quotas).  
4. **Table `employe`**  
   Les bibliothécaires et admins back‑office.  
5. **Table `livre`** et **`exemplaire`**  
   Catalogue et exemplaires physiques.  
6. **Table `pret`**  
   Enregistre les prêts avec :
   - `date_pret` : date d’emprunt  
   - `date_retour_prevu` : date de retour planifiée (modifiable)  
   - `date_retour_effectif` : date saisie au retour  
7. **Tables annexes**  
   `reservation`, `prolongement`, `penalite`, `inscription`.

---

## Auteur
Tsilavo Andriantaolo ETU003525


