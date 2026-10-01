# 🌋 Pokémon Eternal Emerald MMO — Encyclopédie & Documentation Ultime du Modpack

> **Guide Master Officiel & Encyclopédique**  
> *Version du jeu : Pokémon Essentials v21.1 / MKXP-Z | Moteur MMO Kernel PEMK | Module Légendes Z*

---

## 📑 Sommaire Hyper-Détaillé

- [1. Vue d'Ensemble Technique & Statistiques Globales](#1-vue-densemble-technique--statistiques-globales)
  - [1.1 Architecture & Moteur MKXP-Z](#11-architecture--moteur-mkxp-z)
  - [1.2 Chiffres Clés du Modpack (Pokémon, Objets, Capacités)](#12-chiffres-cl%C3%A9s-du-modpack)
- [2. Catalogue Exhaustif des 47+ Mods & Plugins](#2-catalogue-exhaustif-des-47-mods--plugins)
  - [2.1 Moteur de Combat & Graphismes (Deluxe Battle Kit - DBK)](#21-moteur-de-combat--graphismes-deluxe-battle-kit---dbk)
  - [2.2 Interfaces & Expérience Utilisateur (Modular UI & SV)](#22-interfaces--exp%C3%A9rience-utilisateur-modular-ui--sv)
  - [2.3 Multijoueur MMO Synchrone (PEMK Kernel)](#23-multijoueur-mmo-synchrone-pemk-kernel)
  - [2.4 Système de Housing & Peinture de Sol (PEMK_Housing)](#24-syst%C3%A8me-de-housing--peinture-de-sol-pemk_housing)
  - [2.5 Génération 9 & Extension Paldea](#25-g%C3%A9n%C3%A9ration-9--extension-paldea)
  - [2.6 Exploration, Quêtes & Overworld](#26-exploration-qu%C3%AAtes--overworld)
  - [2.7 Défis, Progression & Mini-Jeux](#27-d%C3%A9fis-progression--mini-jeux)
  - [2.8 Correctifs & Utilitaires Système](#28-correctifs--utilitaires-syst%C3%A8me)
- [3. L'Extension Légendes Z & Méga-Évolutions Exclusives](#3-lextension-l%C3%A9gendes-z--m%C3%A9ga-%C3%A9volutions-exclusives)
  - [3.1 Zygarde, Le Cube Zygarde et les 100 Cellules](#31-zygarde-le-cube-zygarde-et-les-100-cellules)
  - [3.2 Catalogue Complet des Méga-Évolutions Exclusives & Leurs Méga-Gemmes](#32-catalogue-complet-des-m%C3%A9ga-%C3%A9volutions-exclusives--leurs-m%C3%A9ga-gemmes)
  - [3.3 Anneau Z, Cristaux Z & Attaques Z](#33-anneau-z-cristaux-z--attaques-z)
- [4. Guide d'Obtention Complet : Tous les Pokémon & Légendaires](#4-guide-dobtention-complet--tous-les-pok%C3%A9mon--l%C3%A9gendaires)
  - [4.1 Méthodes de Capture & HUD d'Ensemble](#41-m%C3%A9thodes-de-capture--hud-densemble)
  - [4.2 Échanges de Formes (Form Trader)](#42-%C3%89changes-de-formes-form-trader)
  - [4.3 Quêtes Scénarisées (MQS) & Événements](#43-qu%C3%AAtes-sc%C3%A9naris%C3%A9es-mqs--%C3%89v%C3%A9nements)
  - [4.4 Artisanat de Pokéballs & Objets Spéciaux](#44-artisanat-de-pok%C3%A9balls--objets-sp%C3%A9ciaux)
  - [4.5 Entraînement Ultime & PWT (Tournoi Mondial)](#45-entra%C3%AEnement-ultime--pwt-tournoi-mondial)
  - [4.6 Cadeau Mystère & Codes d'Événements](#46-cadeau-myst%C3%A8re--codes-d%C3%A9v%C3%A9nements)
- [5. Guide Ultime du Housing (Maison Joueur & Peinture de Sol)](#5-guide-ultime-du-housing-maison-joueur--peinture-de-sol)
  - [5.1 Accès & Carte Modèle (Map 927)](#51-acc%C3%A8s--carte-mod%C3%A8le-map-927)
  - [5.2 Mode Décoration & Placement des Meubles](#52-mode-d%C3%A9coration--placement-des-meubles)
  - [5.3 Mode Peinture de Sol Procédurale (Guide Pas-à-Pas)](#53-mode-peinture-de-sol-proc%C3%A9durale-guide-pas-%C3%A0-pas)
  - [5.4 Synchronisation Serveur & Sécurité JSON](#54-synchronisation-serveur--s%C3%A9curit%C3%A9-json)
- [6. Guide des Commandes, Raccourcis Clavier & Touches](#6-guide-des-commandes-raccourcis-clavier--touches)

---

## 1. Vue d'Ensemble Technique & Statistiques Globales

### 1.1 Architecture & Moteur MKXP-Z
**Pokémon Eternal Emerald MMO** est propulsé par le moteur **Pokémon Essentials v21.1** exécuté sous l'environnement **MKXP-Z** (Ruby 3.x 64-bit avec accélération OpenGL). Il intègre une couche multijoueur temps réel synchrone autonome connectée à un serveur autoritaire avec base de données PostgreSQL.

### 1.2 Chiffres Clés du Modpack
- **Pokémon d'Espèces de Base :** `1 026 Pokémon` (Génération 1 à Génération 9 intégrale : Poussacha, Chochodile, Coiffeton, Koraidon, Miraidon, Ogerpon, Terapagos, Pecharunt).
- **Formes Alternatives & Régionales :** `527 Formes` (Alola, Galar, Hisui, Paldea, Formes Gigamax, Formes Z, Formes Paradoxe).
- **Méga-Évolutions :** `100+ Méga-Évolutions` (Toutes les 48 Mégas officielles Gen 6 + plus de 50 Méga-Évolutions exclusives Légendes Z et créations uniques).
- **Objets en Jeu :** `1 046 Objets` (Capsules d'Argent/Or, Cristaux Z, Méga-Gemmes, Recettes de Craft, Meubles de Housing, Objets de Paldea).
- **Attaques / Capacités :** `878 Attaques` (Gen 1-9, Capacités Z, Attaques Signature, Attaques Combinées).
- **Talents (Abilities) :** `333 Talents`.
- **Plugins/Mods Installés :** `47 Plugins`.

---

## 2. Catalogue Exhaustif des 47+ Mods & Plugins

### 2.1 Moteur de Combat & Graphismes (Deluxe Battle Kit - DBK)
- **`[DBK_000] Deluxe Battle Kit`** : Cœur de combat étendu permettant de gérer plusieurs formes de combat complexes (Méga-Évolution, Formes Z, Dynamax/Gigamax) simultanément sur la même instance de combat.
- **`[DBK_001] Enhanced Battle UI`** : Surcouche d'interface de combat affichant l'indicateur d'efficacité des types sous les attaques de l'adversaire, les modifications de statistiques en direct (buffs/débuffs ±6), le climat actuel et le terrain actif.
- **`[DBK_002] SOS Battles`** : Système de combat sauvage inspiré de Pokémon Soleil/Lune. Les Pokémon sauvages peuvent lancer des appels à l'aide pour faire venir des alliés en combat.
- **`[DBK_004] Z-Power`** : Moteur d'activation des Capacités Z via l'Anneau Z. Gère les animations Z, la conversion des attaques physiques/spéciales et les effets Z sur les attaques de statut.
- **`[DBK_009] Animated Pokemon System`** : Moteur d'affichage des sprites de Pokémon dynamiques et animés au combat (face et dos).
- **`[DBK_010] Animated Trainer Intros`** : Séquences d'entrée animées des dresseurs rivaux, Champions d'Arène et Maîtres avant le premier tour de combat.

---

### 2.2 Interfaces & Expérience Utilisateur (Modular UI & SV)
- **`[MUI_000] Modular UI Scenes`** : Framework d'interface modulaire offrant une architecture propre et extensible pour les menus du jeu.
- **`[MUI_001] Enhanced Pokemon UI`** : Écran d'équipe et de résumé amélioré affichant le détail exact des IVs (0-31) et EVs (0-252), les courbes de statistiques et l'organisation rapide des objets tenus.
- **`[MUI_002] Pokedex Data Page`** : Page Pokédex ultra-complète montrant les taux d'apparition exacts par carte, la météo requise, les lignes évolutives complètes et les différentes formes régionales.
- **`[MUI_004] Improved Field Skills`** : Menu d'action rapide permettant d'utiliser les capacités de terrain (Surf, Vol, Coupe, Force, Flash) directement sans ouvrir le menu Pokémon.
- **`[SV] Summary Screen`** : Interface de résumé des Pokémon au design moderne inspiré de Pokémon Écarlate et Violet.
- **`HGSS-style Dex List`** : Liste de sélection du Pokédex au design élégant hérité de HeartGold & SoulSilver.
- **`Emerald UI Pack`** : Theme graphique vert émeraude rétro-moderne habillant l'ensemble des fenêtres et boîtes de dialogue.
- **`Encounter List UI`** : Fenêtre overlay activable affichant la liste des Pokémon sauvages présents sur la zone actuelle, leurs probabilités de rencontre et leurs niveaux.
- **`Bag Screen with interactable Party`** : Sac à dos moderne permettant de sélectionner et d'utiliser un objet de soin ou de boost directement sur l'équipe affichée sur le côté droit.
- **`Modular Title Screen v21`** : Écran titre dynamique et animé au lancement du jeu.

---

### 2.3 Multijoueur MMO Synchrone (PEMK Kernel)
- **`PEMK (Pokemon Eternal Emerald MMO Kernel)`** : Moteur multijoueur synchrone en temps réel.
  - **Affichage des joueurs en direct :** Voir les autres dresseurs se déplacer dans le monde avec leurs tenues et leurs Pokémon suiveurs.
  - **Système de Chat Général & Guilde :** Taper `T` ou Ouvrir le chat pour discuter avec les joueurs en ligne.
  - **Échanges & Duels en ligne :** Proposer un échange ou un combat en direct à un autre dresseur dans le monde.
  - **Base de données autoritaire :** Synchronisation PostgreSQL du profil dresseur, de l'équipe, des objets et de la progression.

---

### 2.4 Système de Housing & Peinture de Sol (PEMK_Housing)
- **`PEMK_Housing`** : Système autonome de maison de joueur multijoueur.
  - **Entrée dans la Maison :** Téléportation vers la carte **Map 927**.
  - **Mode Décoration (Touche D) :** Déplacer, ajouter et supprimer des meubles avec mise à jour automatique de la passabilité du personnage.
  - **Mode Peinture de Sol Procédural (Guide à l'étape 5) :** Choisir parmi 10 motifs de sol (Parquet Bois, Marbre Royal, Carrelage, Tapis, Herbe) et peindre des zones rectangulaires avec l'outil de sélection dynamique.
  - **Sauvegarde JSON :** Persistance automatique du sol et du mobilier dans le serveur PostgreSQL.

---

### 2.5 Génération 9 & Extension Paldea
- **`Generation 9 Pack Scripts`** : Intègre les Pokémon #906 à #1025 de Paldea (Pokémon Écarlate & Violet), les talents Gen 9 (comme *Protosynthèse*, *Charge Quantique*, *Graine d'Herbe*), les attaques Gen 9 et le système de Téracristallisation.

---

### 2.6 Exploration, Quêtes & Overworld
- **`Following Pokemon EX`** : Le Pokémon en tête de votre équipe vous suit sur la carte. Cliquez dessus pour lui parler, voir son humeur, ou interagir avec l'environnement.
- **`SecretBasesRemade`** : Recréation fidèle du système de Bases Secrètes de la 3ème Génération. Trouvez des arbres à nichoir ou des parois rocheuses pour aménager votre base secrète privée.
- **`Wardrobe`** : Système de penderie/vestiaire pour personnaliser les vêtements, casquettes, sacs et coupes de cheveux de votre personnage.
- **`Item Crafting UI Plus`** : Table d'artisanat pour fabriquer des Pokéballs, médicaments et objets rares à partir de baies et de matériaux récoltés.
- **`MQS (Modern Quest System)`** : Journal de quêtes interactif (Quêtes Principales, Secondaires, Quêtes d'Arène, Chasse aux Légendaires) avec suivi des objectifs et repères.
- **`Caruban's Dynamic Darkness`** : Éclairage dynamique s'adaptant à l'heure réelle (Aube, Jour, Crépuscule, Nuit) et assombrissement réaliste des grottes nécessitant Flash.
- **`Event Indicators`** : Indicateurs visuels (Points d'interrogation, Exclamations, Icônes de quête) au-dessus de la tête des PNJs interactifs.
- **`Fly Animation`** : Animation cinématique de vol lors du déplacement rapide vers un centre Pokémon.
- **`Cable Car`** : Téléphérique interactif pour les traversées de montagnes.
- **`[ULQ_007] Book System`** : Livres, journaux de bord et documents anciens interactifs à lire dans les bibliothèques et laboratoires.

---

### 2.7 Défis, Progression & Mini-Jeux
- **`Challenge Modes`** : Menu de démarrage pour activer le mode **Nuzlocke** (K.O. = mort définitive), **Randomizer** (Pokémon/Objets aléatoires), **Monotype** ou **Hardcore**.
- **`Level Caps EX`** : Limites de niveau ajustables dynamiquement selon les badges d'arène possédés pour éviter le sur-entraînement.
- **`Hyper Training`** : Entraînement Ultime auprès du Spécialiste pour augmenter les IVs de vos Pokémon au maximum (31) avec des Capsules d'Argent ou d'Or.
- **`Pokemon World Tournament (PWT)`** : Arène de combat spéciale réunissant les Champions d'Arène et Maîtres de Kanto, Johto, Hoenn, Sinnoh, Unys, Kalos et Alola.
- **`BW Mystery Gift`** : Menu Cadeau Mystère par code secret pour débloquer des événements et Pokémon exclusifs.
- **`Form Trader`** : PNJ d'échange spécialisé permettant d'obtenir les formes alternatives (Alola, Galar, Hisui, Paldea).
- **`Regicode`** : Puzzles et énigmes de texte ancien pour déverrouiller l'accès aux ruines de Regirock, Regice, Registeel, Regieleki, Regidrago et Regigigas.
- **`Video Poker`** : Mini-jeu de poker vidéo au Casino de la ville avec jetons à gagner.
- **`Permanent Repel`** : Réapplication automatique des Repousses avec popup de confirmation.
- **`Item Find Description`** : Pop-up d'information détaillée lors de la découverte d'un objet au sol.

---

### 2.8 Correctifs & Utilitaires Système
- **`AZERTY_ZQSD_Controls`** : Support natif des claviers francophones (ZQSD pour les déplacements).
- **`Auto Multi Save` & `Periodic Autosave`** : Sauvegardes automatiques régulières et gestion multi-emplacements.
- **`Delta Speed Up` & `FastForward.rb`** : Mode vitesse accélérée (Turbo) pour les déplacements et les combats.
- **`Save Status HUD`** : HUD discret indiquant le temps écoulé depuis la dernière sauvegarde (masqué automatiquement en mode décoration).
- **`v21.1 Hotfixes`** : Correctifs officiels de stabilité pour Essentials v21.1.

---

## 3. L'Extension Légendes Z & Méga-Évolutions Exclusives

### 3.1 Zygarde, Le Cube Zygarde et les 100 Cellules
L'extension **Légendes Z** apporte la quête mythique du Pokémon Équilibre **Zygarde** :
1. **Obtenir le Cube Zygarde (`ZYGARDECUBE`) :** Offert lors de la quête principale Légendes Z dans le journal MQS.
2. **Récolte des Cellules (`ZYGARDECELL`) :** 100 Cellules Zygarde sont dispersées dans les différentes zones de la région.
3. **Formes de Zygarde :**
   - **Forme 10%** (Forme Canine) : Débloquée avec 10 Cellules.
   - **Forme 50%** (Forme Serpent) : Débloquée avec 50 Cellules.
   - **Forme Parfaite 100%** : Débloquée avec 100 Cellules (s'active en combat grâce au talent *Rassemblement / Power Construct* lorsque les PV passent sous 50%).
   - **Méga-Zygarde (`ZYGARDITE`)** : En équipant la **Zygardite** sur Zygarde Forme Parfaite, déclenchez la transformation ultime **Méga-Zygarde** !

---

### 3.2 Catalogue Complet des Méga-Évolutions Exclusives & Leurs Méga-Gemmes

| Pokémon | Forme Méga | Objet Requis (Méga-Gemme) |
| :--- | :--- | :--- |
| **Zygarde** | Méga-Zygarde | `ZYGARDITE` |
| **Raichu** | Méga-Raichu X / Méga-Raichu Y | `RAICHUNITEX` / `RAICHUNITEY` |
| **Greninja** | Méga-Greninja X / Méga-Greninja Y | `GRENINJITEX` / `GRENINJITE` |
| **Lucario** | Méga-Lucario Z | `LUCARIONITEZ` |
| **Garchomp** | Méga-Garchomp Z | `GARCHOMPITEZ` |
| **Absol** | Méga-Absol Z | `ABSOLITEZ` |
| **Dragonite** | Méga-Dragonite | `DRAGONITITE` |
| **Flygon** | Méga-Flygon X / Y | `FLYGONITE` / `FLYGONITEX` |
| **Eternatus** | Méga-Éternatos | `ETERNATITE` |
| **Darkrai** | Méga-Darkrai | `DARKRANITE` |
| **Heatran** | Méga-Heatran | `HEATRANITE` |
| **Regigigas** | Méga-Regigigas | `REGIGIGITE` |
| **Jirachi** | Méga-Jirachi | `JIRACHITE` |
| **Volcanion** | Méga-Volcanion Z | `VOLCANIONITE` |
| **Xerneas** | Méga-Xerneas | `XERNEASITE` |
| **Yveltal** | Méga-Yveltal | `YVELTALITE` |
| **Arceus** | Méga-Arceus | `ARCEUSITE` |
| **Typhlosion** | Méga-Typhlosion | `TYPHLOSITE` |
| **Feraligatr** | Méga-Feraligatr X / Y | `FERALIGITE` / `FERALITITEY` |
| **Meganium** | Méga-Meganium | `MEGANIUMITE` |
| **Torterra** | Méga-Torterra | `TORTERRANITE` |
| **Infernape** | Méga-Infernape | `INFERNITE` |
| **Empoleon** | Méga-Empoleon | `EMPOLEONITE` |
| **Chesnaught** | Méga-Chesnaught | `CHESNAUGHTITE` |
| **Delphox** | Méga-Delphox | `DELPHOXITE` |
| **Rillaboom** | Méga-Rillaboom | `RILLABOOMITE` |
| **Cinderace** | Méga-Cinderace | `CINDERACITE` |
| **Inteleon** | Méga-Inteleon | `INTELONITE` |
| **Baxcalibur** | Méga-Baxcalibur | `BAXCALIBRITE` |
| **Staraptor** | Méga-Staraptor | `STARAPTITE` |
| **Volcarona** | Méga-Volcarona | `VOLCARONITE` |
| **Snorlax** | Méga-Snorlax | `SNORLAXITE` |
| **Electivire** | Méga-Electivire | `ELECTIVIRITE` |
| **Magmortar** | Méga-Magmortar X / Y / Z | `MAGMORTARITE` / `MAGMORTARITEX` / `MAGMORTARITEY` |
| **Golisopod** | Méga-Golisopod | `GOLISOPITE` |
| **Corviknight** | Méga-Corviknight | `CORVINITE` |
| **Grimmsnarl** | Méga-Grimmsnarl | `GRIMSNARLITE` |
| **Hatterene** | Méga-Hatterene | `HATTERENITE` |
| **Golurk** | Méga-Golurk | `GOLURKITE` |
| **Excadrill** | Méga-Excadrill | `EXCADRITE` |
| **Scolipede** | Méga-Scolipede | `SCOLIPITE` |
| **Cofagrigus** | Méga-Cofagrigus | `COFAGRIGUSITE` |
| **Dusknoir** | Méga-Dusknoir | `DUSKNOIRITE` |
| **Rhyperior** | Méga-Rhyperior | `RHYPERIORITE` |

---

### 3.3 Anneau Z, Cristaux Z & Attaques Z
Le module **[DBK_004] Z-Power** active l'utilisation des Cristaux Z en combat :
- **Attaques Z Offensives :** Convertissent une attaque d'un type donné en une capacité Z surpuissante (ex: *Plaquage Z*, *Pyro-Explosion Z*, *Super Étincelle Z*).
- **Attaques Z de Statut :** Ajoutent des effets bonus uniques aux capacités de statut (ex: soin complet sur *Affûtage Z*, boost de +2 dans toutes les stats sur *Garde-Sort Z*).
- **Cristaux Z Exclusifs :** `PIKACHUNIUMZ`, `DECIDUIUMZ`, `INCINIUMZ`, `PRIMARIUMZ`, `MEWIUMZ`, `MARSHADOWIUMZ`, `KOMMOIUMZ`, `EEVIUMZ`, `ULTRANECROZIUMZ`.

---

## 4. Guide d'Obtention Complet : Tous les Pokémon & Légendaires

### 4.1 Méthodes de Capture & HUD d'Ensemble
- Appuyez sur la touche du **HUD des Rencontres (`Encounter List UI`)** sur n'importe quelle carte pour afficher la liste complète des Pokémon sauvages de la zone.
- Consultez la page **`Pokedex Data Page`** pour connaître l'heure exacte (Matin, Jour, Nuit) et la météo nécessaire pour faire apparaître chaque espèce.

### 4.2 Échanges de Formes (Form Trader)
- Parlez au PNJ **Form Trader** situé dans les grandes villes pour échanger une forme de base contre sa variante d'Alola, de Galar, de Hisui ou de Paldea.

### 4.3 Quêtes Scénarisées (MQS) & Événements
- **Mewtwo, Rayquaza, Kyogre, Groudon, Arceus, Dialga, Palkia, Giratina, Zygarde, Koraidon, Miraidon** sont tous débloqués via des quêtes dédiées inscrites dans le journal **MQS**.
- Ouvrez votre journal de quêtes (`MQS`) pour suivre les étapes et repères d'objectifs sur la carte.

### 4.4 Artisanat de Pokéballs & Objets Spéciaux
Utilisez le système **`Item Crafting UI Plus`** sur une table d'artisanat pour fabriquer :
- **Mascotte Ball, Sombre Ball, Chrono Ball, Honor Ball, Bis Ball, Masse Ball, Speed Ball**.
- **Rappel Max, Guérison, Potion Max, Super Bonbon**.

### 4.5 Entraînement Ultime & PWT (Tournoi Mondial)
1. Participez aux combats du **Pokemon World Tournament (PWT)** pour gagner des Points de Combat (PCO).
2. Échangez vos PCO contre des **Capsules d'Argent** ou **Capsules d’Or**.
3. Allez voir le Maître de l’Entraînement Ultime (`Hyper Training`) pour monter les IVs de n'importe quel Pokémon à 31 !

### 4.6 Cadeau Mystère & Codes d'Événements
- Depuis le menu principal, sélectionnez **Cadeau Mystère** (`BW Mystery Gift`) pour entrer des codes événementiels secrets et recevoir des Pokémon Shiny exclusifs ou des Cristaux Z rares.

---

## 5. Guide Ultime du Housing (Maison Joueur & Peinture de Sol)

### 5.1 Accès & Carte Modèle (Map 927)
1. Parlez au PNJ **Réceptionniste de l'Hôtel**.
2. Sélectionnez **"Entrer dans ma maison"**. Vous êtes téléporté sur votre grille personnelle (**Map 927**, Grille 11×7).

### 5.2 Mode Décoration & Placement des Meubles
1. Appuyez sur **`D`** ou sélectionnez **Mode Décoration** dans le menu Housing.
2. Parcourez votre inventaire de meubles (chaises, tables, tapis, télévisions, trophées).
3. Placez le meuble sur la case souhaitée. Le jeu recalcule immédiatement la passabilité du personnage (Z-ordering & collisions).

### 5.3 Mode Peinture de Sol Procédurale (Guide Pas-à-Pas)
1. En mode décoration, sélectionnez l'option **Peindre le sol**.
2. **Étape 1 (Choix du Motif) :** Le catalogue s'ouvre à gauche. Choisissez parmi les 10 motifs disponibles (Parquet Bois, Marbre Royal, Carrelage, Tapis, Herbe) et validez avec `Entrée`.
3. **Étape 2 (Sélection de Zone Rectangulaire) :**
   - Le catalogue se ferme et un badge indicatif apparaît en haut à gauche (`SOL : [MOTIF] Clic: Changer`).
   - Déplacez le curseur au 1er coin de la pièce et faites `Clic Gauche` ou `Entrée`.
   - Déplacez le curseur : un cadre rectangulaire vert de surbrillance s'affiche.
   - Faites `Clic Gauche` ou `Entrée` au 2ème coin : **la zone est peinte instantanément !**
4. Pour changer de motif, cliquez sur le badge en haut à gauche ou appuyez sur `Tab`.

### 5.4 Synchronisation Serveur & Sécurité JSON
Lors de la sortie du mode décoration, votre maison est convertie au format JSON via le parseur autonome `HousingJSON` et sauvegardée de manière permanente sur le serveur PostgreSQL.

---

## 6. Guide des Commandes, Raccourcis Clavier & Touches

| Touche / Commande | Action / Fonctionnalité |
| :--- | :--- |
| **`Z / Q / S / D`** ou **Flèches** | Déplacement du personnage (Support AZERTY natif). |
| **`Entrée` / `C` / `Espace`** | Interagir / Valider / Parler aux PNJs. |
| **`X` / `Échap`** | Annuler / Ouvrir le menu principal. |
| **`D`** | Activer / Quitter le mode Décoration du Housing. |
| **`Tab`** | Changer de motif de sol en mode Peinture de Sol / Rouvrir le catalogue. |
| **`F` / Touche Turbo** | Activer la vitesse accélérée (Delta Speed Up / FastForward). |
| **`T`** | Ouvrir la fenêtre de Chat Multijoueur MMO (PEMK). |
| **Menu Capacités de Terrain** | Lancer Surf / Vol / Coupe sans ouvrir le menu d'équipe (`MUI_004`). |
| **Menu Sac à Dos** | Utiliser directement un objet sur l'équipe affichée (`Bag Screen`). |

---

*Document Encyclopédique Officiel — Pokémon Eternal Emerald MMO.*
