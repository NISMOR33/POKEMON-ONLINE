# 🌋 Pokémon Eternal Emerald MMO — Bilan Technique & Documentation Modpack

> 📖 **DOCUMENTATION COMPLÈTE DU MODPACK & DU JEU :**  
> Consultez le guide encyclopédique complet : **[`DOCUMENTATION_COMPLETE_MODPACK.md`](file:///c:/Users/brosi/POKEMON-ONLINE/DOCUMENTATION_COMPLETE_MODPACK.md)**  
> *Inclus : 47+ Mods expliqués, 1 026+ Pokémon (Gen 1 à 9), 100+ Méga-Évolutions & Légendes Z, Système de Housing, Quêtes MQS et Guide d'Obtention.*

---

## 📌 1. Contexte & Architecture du Système


Le système de **Housing** est une fonctionnalité multijoueur synchrone en temps réel (PEMK) permettant aux joueurs d'acheter, décorer et personnaliser leur propre maison.

### 📐 Configuration de la carte & de la grille
- **Carte modèle :** Map ID 927 (`Maison Joueur Modèle`).
- **Grille Tier 1 (Taille S) :** 11 colonnes × 7 lignes.
- **Origine de la grille sur la carte :** `GRID_ORIGIN_X = 0`, `GRID_ORIGIN_Y = 2`.
- **Case d'entrée / Téléportation :** Grille `[3, 6]` (Carte `(3, 8)`).
- **Zone de sortie (paillasson) :** Ligne `y = 9`, colonnes `x = 2..4`.

### 🗂️ Fichiers du projet concernés
- **`Plugins/PEMK_Housing/001_HousingConfig.rb`** : Constantes de grille, 10 bitmaps de motifs de sol procéduraux, helpers `set_floor_tile` et `fill_floor`.
- **`Plugins/PEMK_Housing/002_HousingNet.rb`** : Communication réseau client/serveur (`house_enter`, `house_floor_paint`).
- **`Plugins/PEMK_Housing/003_HousingMenu.rb`** : Menu de téléportation PNJ hôtel et gestionnaire d'entrée/sortie.
- **`Plugins/PEMK_Housing/004_HousingRenderer.rb`** : Rendu graphique du sol (`@floor_sprite`), des meubles, calcul des Z-indexes et de la passabilité.
- **`Plugins/PEMK_Housing/005_HousingEditor.rb`** : Mode édition/décoration, machine à états du mode peinture (Sélection motif vs Sélection zone), HUDs et entrées clavier/souris.
- **`Plugins/PEMK_Housing/007_HousingJSON.rb`** : Parseur JSON autonome en Ruby pur (sans dépendance stdlib).
- **`Plugins/Save Status HUD/Save_Status.rb`** : Masquage du HUD de sauvegarde ("Il y a X s") pendant le mode décoration.
- **`server/lib/pemk/housing.rb`** : Serveur Ruby autoritaire (PostgreSQL), persistance de `floor_paint` dans `houses.appearance_json`.

---

## ✅ 2. Fonctionnalités Valides et Fonctionnelles

1. **Masquage du HUD de Sauvegarde :** Le bandeau "Il y a X s" est correctement masqué pendant le mode décoration (`HousingEditor.active?`).
2. **Dimensions de la Grille Tier 1 :** Grille ajustée à 11×7 avec l'entrée abaissée à `[3, 6]`.
3. **Parseur JSON Pure-Ruby :** `HousingJSON.dump` et `HousingJSON.generate` opérationnels (résolvant les exceptions `NoMethodError`).
4. **Flux du Mode Peinture de Sol en 2 Étapes :**
   - **Étape 1 :** Ouverture du catalogue à gauche, sélection du motif avec flèches/souris, validation par `Entrée`.
   - **Étape 2 :** Le catalogue se ferme. Un badge indicatif s'affiche en haut à gauche (`SOL : [MOTIF] Clic: Changer`). Un clic sur le badge ou la touche `Tab` réouvre le catalogue.
   - **Étape 3 (Sélection de zone) :** Clic/Entrée 1 = fixation du 1er coin (`@zone_start`). Déplacement du curseur = rectangle vert de surbrillance (`W × H`). Clic/Entrée 2 = application du motif sur la zone (`x1..x2, y1..y2`).

---

## ⚠️ 3. Problème Persistant : Superposition du Joueur et du Sol/Meubles (Z-Ordering)

### 🔴 Symptôme du Problème
Le personnage du joueur (`$game_player`) passe **sous le sol peint** (`@floor_sprite`) ou **sous certains meubles**, le rendant invisible ou partiellement masqué lorsqu'il se déplace sur la carte.

### 🧪 Essais et Tentatives Déjà Effectués

1. **`@floor_sprite.z = -5`** :
   - *Résultat :* Le sol peint était totalement invisible car dessiné derrière la couche de sol par défaut du Tilemap RMXP (`Z = 0`).
2. **`@floor_sprite.z = 1`** :
   - *Résultat :* Le sol devenait visible sur la carte, mais s'affichait au-dessus du joueur quand celui-ci marchait dessus.
3. **`@floor_sprite.z = 0` avec récupération de `viewport1` via inspection réflexive** :
   - *Résultat :* Correction des erreurs `NameError` sur `instance_variable_defined?`, mais le sprite du joueur continue d'être masqué par les tuiles de sol ou les meubles selon les lignes Y.
4. **Ajustements de la formule Z des meubles solides (`y * 32 + 1` vs `y * 32 + 16`)** :
   - *Résultat :* Problèmes de profondeur lorsque le joueur se tient sur la même ligne Y que la base d'un meuble.

---

## 💡 4. Pistes & Recommandations pour la Prochaine IA / Développeur

Dans le moteur Pokémon Essentials d'origine (RPG Maker XP / MKXP) :

### Piste 1 : Fonctionnement des Bases Secrètes d'origine (`PField_SecretBases`)
Dans les bases secrètes officielles de Pokémon Essentials :
- Les **décorations / meubles** ne sont pas des `Sprite` autonomes gérés manuellement, mais des instances d'**Événements de carte (`Game_Event`)**.
- Comme chaque objet est un `Game_Event`, il hérite nativement de `Game_Character#screen_z` (`y * 32 + 32`). Le moteur trie ainsi automatiquement le joueur et les meubles sans aucun décalage.

### Piste 2 : Modification directe de la table de données de la Carte (`$game_map.map.data`)
- Pour les **motifs de sol (peinture de sol)**, la méthode la plus propre dans RPG Maker XP consiste à modifier directement la table de données de la carte `$game_map.map.data[x, y, 0]` avec les Tile IDs correspondants du Tileset.
- Étant donné que ces tuiles deviennent directement gérées par la classe C++ `Tilemap` du moteur au niveau de la couche 0, elles restent **toujours sous le joueur, sous les événements et sous les meubles**, sans nécessiter de `Sprite` séparé.

---

## 📝 5. Résumé des Modifications à Pousser sur Git
- `Plugins/PEMK_Housing/001_HousingConfig.rb`
- `Plugins/PEMK_Housing/002_HousingNet.rb`
- `Plugins/PEMK_Housing/004_HousingRenderer.rb`
- `Plugins/PEMK_Housing/005_HousingEditor.rb`
- `Plugins/PEMK_Housing/007_HousingJSON.rb`
- `Plugins/Save Status HUD/Save_Status.rb`
- `server/lib/pemk/housing.rb`
- `README.md` (mis à jour avec ce bilan technique)

