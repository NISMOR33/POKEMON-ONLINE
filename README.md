# 🌋 Pokémon Eternal Emerald MMO (Édition Française)

Bienvenue sur le dépôt officiel de **Pokémon Eternal Emerald MMO**. Ce projet combine la région complète de Hoenn (Pokémon Émeraude) avec un moteur multijoueur synchrone en temps réel basé sur **Ruby** et **PostgreSQL**.

---

## 🌟 Fonctionnalités du Projet

- 🗺️ **Région de Hoenn (Émeraude Complète)** : Cartes intégrales d'Émeraude avec météo, événements, arènes et zones secrètes.
- 👥 **Multijoueur Temps Réel (PEMK)** : Visualisation synchrone des autres dresseurs sur la carte.
- 💬 **Chat HUD Intégré** : Appuie sur **`T`** en jeu pour discuter. Bulles de parole au-dessus des dresseurs avec pseudos colorés, adaptation dynamique et masquage après 10s.
- 🔐 **Système de Compte & Connexion** : Fenêtre de Login / Création de compte intégrée au jeu lors du clic sur **New Game**.
- ⚡ **Avance Rapide x10** : Maintiens la touche **`ALT`** enfoncée pour accélérer le moteur du jeu de 40 à 400 FPS (idéal pour les tests).
- 🛠️ **Lanceurs 1-Clic (`.bat`)** :
  - `0_Restart_Serveur.bat` : Démarre/Redémarre PostgreSQL et le serveur Ruby.
  - `1_Lancer_Joueur_1.bat` : Lance le jeu principal (Joueur 1).
  - `2_Lancer_Joueur_2.bat` : Lance une 2ème fenêtre indépendante (Joueur 2 / Invité) sur le même PC.

---

## 🖥️ Prérequis pour travailler depuis ton PC chez toi

Pour pouvoir exécuter et modifier le jeu sur ton ordinateur personnel, tu dois installer les logiciels suivants :

1. **RPG Maker XP** (Logiciel d'édition des cartes et événements `Game.rxproj`).
2. **Ruby 3.1.x (x64)** (Nécessaire pour exécuter le serveur réseau PEMK).
   - Téléchargeable sur [rubyinstaller.org](https://rubyinstaller.org/).
   - Coche l'option d'ajout au `PATH` lors de l'installation.
3. **PostgreSQL 16** (Base de données du serveur MMO).
   - Port de connexion utilisé : **`55433`** (ou port par défaut `5432` réajustable).
   - Utilisateur : `postgres` | Mot de passe : `pemk_dev` | Base : `pemk_eternal_emerald`.
4. **Git for Windows** (Pour cloner et pousser le code).

---

## 🚀 Guide de Démarrage Rapide (Chez toi)

### Étape 1 : Cloner le projet Git
Ouvre un terminal (PowerShell ou Git Bash) et exécute :
```bash
git clone https://github.com/NISMOR33/POKEMON-ONLINE.git
cd POKEMON-ONLINE
```

### Étape 2 : Installer les dépendances du serveur Ruby
```bash
cd server
bundle install
bundle exec rake db:migrate
```

### Étape 3 : Lancer le jeu et le serveur
De retour dans le dossier principal du projet :
1. Double-clique sur **`0_Restart_Serveur.bat`** pour démarrer PostgreSQL et le serveur Ruby.
2. Double-clique sur **`1_Lancer_Joueur_1.bat`** pour ouvrir ton jeu.
3. (Optionnel) Double-clique sur **`2_Lancer_Joueur_2.bat`** pour tester le multijoueur avec 2 fenêtres à côté.

---

## 🎮 Commandes et Raccourcis en Jeu

| Touche | Action |
| :--- | :--- |
| **Flèches directionnelles** | Se déplacer |
| **Entrée / Espace / C** | Interagir / Confirmer |
| **X / Échap** | Ouvrir le menu / Annuler |
| **ALT (maintenir)** | **Avance Rapide x10** (Passer les dialogues/cinématiques à 400 FPS) |
| **T** | Ouvrir la fenêtre de **Chat Multijoueur** |
| **F9** | Menu Debug (Utiliser *PEMK: Export World* si tu ajoutes de nouvelles cartes) |

---

## 📁 Structure du Projet

```text
POKEMON-ONLINE/
├── 0_Restart_Serveur.bat      # Script de démarrage du serveur & DB
├── 1_Lancer_Joueur_1.bat      # Script de lancement Joueur 1
├── 2_Lancer_Joueur_2.bat      # Script de lancement Joueur 2 (Mode Invité)
├── Game.exe                   # Exécutable du jeu (moteur MKXP-z)
├── Game.rxproj                # Fichier de projet RPG Maker XP
├── Data/                      # Fichiers de cartes (.rxdata)
├── Graphics/                  # Sprites, décors, interfaces
├── PBS/                       # Données brutes (Pokémon, capacités, objets traduits)
├── Plugins/                   # Plugins Ruby (Moteur PEMK, Chat HUD, SpeedUp, etc.)
└── server/                    # Code source du serveur multijoueur Ruby + Sequel DB
```
