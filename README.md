# 🌋 Pokémon Eternal Emerald MMO (Édition Française)

Bienvenue sur le dépôt officiel de **Pokémon Eternal Emerald MMO**. Ce projet combine la région complète de Hoenn (Pokémon Émeraude) avec un moteur multijoueur synchrone en temps réel basé sur **Ruby** et **PostgreSQL**.

---

## 🌟 Fonctionnalités du Projet

- 🗺️ **Région de Hoenn (Émeraude Complète)** : Cartes intégrales d'Émeraude avec météo, événements, arènes et zones secrètes.
- 👥 **Multijoueur Temps Réel (PEMK)** : Visualisation synchrone des autres dresseurs sur la carte.
- 💬 **Chat Émeraude** : **T** ouvre la saisie et l’historique. Panneau bleu nuit, accents verts, bulles ivoire avec pseudos et fondu en temps réel.
- 🔐 **Système de Compte & Connexion** : Fenêtre de Login / Création de compte intégrée au jeu lors du clic sur **New Game**.
- ⚡ **Vitesse réglable** : **F4** alterne entre **×1, ×1,5 et ×2**, selon les options du jeu.
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

Profil **clavier AZERTY français + souris**. Les anciens réglages F1 ne sont plus utilisés ; **F1 sur la carte ouvre l’aide**.

| Touche | Action |
| --- | --- |
| **Z Q S D / Flèches** | Se déplacer et naviguer |
| **E / C / Entrée / Espace / clic gauche** | Interagir, valider la sélection, avancer les dialogues |
| **Échap / X / clic droit** | Ouvrir le menu sur la carte ; annuler/revenir ailleurs |
| **Maj maintenue** | Courir, ou marcher si la course automatique est activée ; chaussures et terrain requis |
| **Tab** | Menu sur la carte ; action secondaire selon l’écran (combat, sac, résumé…) |
| **F** | Objets enregistrés et capacités de terrain ; action spéciale selon l’écran |
| **T** | Ouvrir le chat sur la carte, hors dialogue/événement/menu |
| **A / Page précédente** | Fonction/page précédente ; afficher/masquer le Pokémon suiveur sur la carte |
| **R / Page suivante** | Fonction/page suivante, selon l’écran |
| **V** | Seconde action auxiliaire si utilisée par un écran |
| **F4** | Vitesse ×1 / ×1,5 / ×2, selon les options |
| **F1** | Aide des commandes sur la carte |
| **F8** | Capture d’écran |
| **F9** | Menu debug, seulement en mode debug |
| **Alt + Entrée** | Plein écran |

**Saisie de texte :** les lettres et espaces sont réservés au texte, Entrée valide, Échap annule, Retour arrière efface. Les raccourcis de jeu sont suspendus pendant la saisie et hors de la fenêtre active. Alt + Entrée ne valide pas un choix de jeu.

**Souris :** le clic gauche valide l’élément déjà sélectionné ; il ne déplace pas le personnage et ne sélectionne pas automatiquement un bouton sous le pointeur. Les clics hors de la fenêtre sont ignorés. F12 ne réinitialise plus la partie.


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

## Sauvegarde automatique

La partie se sauvegarde toutes les **2 minutes réelles**, même sans marcher.
Si un combat, dialogue, menu, déplacement ou événement est en cours, la sauvegarde
attend le prochain instant sûr. L'accélération F4 ne raccourcit pas ce délai.

En MMO, le système existant conserve aussi ses sauvegardes après les gains importants
et synchronise avec le serveur ; une connexion interrompue est réessayée en arrière-plan.
Hors ligne, les trois emplacements **Auto 1 / Auto 2 / Auto 3** tournent sans remplacer
les sauvegardes manuelles. Une écriture échouée conserve le fichier précédent et est
réessayée après 60 secondes. La sauvegarde manuelle reste disponible.

Un indicateur en haut à droite de la carte affiche une disquette et **Sauvegarde en cours…**, puis **Sauvegardé !** et l’âge de la dernière sauvegarde. Il distingue les échecs et les sauvegardes locales dont la synchronisation serveur est encore en attente. Le temps affiché est réel, même avec F4.

## Chat Émeraude

**T** ouvre le panneau de discussion et son champ de saisie. **Entrée** envoie,
**Échap** ferme en conservant le brouillon. **Page précédente / suivante** parcourent
les 80 derniers messages de la session. Un message non envoyé reste dans le champ.
Le panneau est complètement masqué tant que T n’est pas pressé ; Échap le referme sans bandeau permanent.
Les bulles sont limitées à quatre lignes (texte complet dans l’historique), restent
dans l’écran et disparaissent après 5 à 10 secondes réelles, même avec F4.

L’indicateur de sauvegarde utilise une petite pastille de 108 × 20 pixels en haut à droite, avec une disquette et une seule ligne (état ou temps écoulé).
