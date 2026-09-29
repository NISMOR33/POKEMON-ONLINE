# 🔒 Guide de Sécurité & Gestion des Sessions MMO

Ce document explique en détail le fonctionnement de la sécurité des comptes, de l'isolation des sauvegardes et de la prévention des doubles connexions simultanées dans **Pokémon Eternal Emerald MMO**.

---

## 1. Isolation des Sauvegardes (`Un Compte = Une Sauvegarde`)

### Comment ça fonctionne :
Dans la base de données PostgreSQL (`pemk_eternal_emerald`), chaque utilisateur possède son propre identifiant unique `account_id` (ex: `Account #1`, `Account #2`).

- Lors de la création d'un compte, le serveur génère un jeton d'authentification cryptographique unique lié uniquement à cet `account_id`.
- **Chaque compte a sa propre ligne dédiée dans la base de données PostgreSQL** contenant son équipe Pokémon, son sac, ses badges et ses statistiques.
- **Impossible d'accéder à la sauvegarde d'un autre joueur** : Le client du jeu transmet le jeton au serveur. Si le Joueur A tente de demander la sauvegarde du Joueur B, le serveur refuse le paquet et bloque l'accès (`Unauthorized`).

---

## 2. Système Anti-Double Connexion (`Kick de l'ancienne session`)

### Le problème :
Que se passe-t-il si le **Joueur A** est connecté sur son PC à la maison, et que quelqu'un essaie de se connecter sur le même **Compte A** depuis un autre ordinateur ?

### La solution intégrée dans le serveur (`bind` in `server.rb`) :
Le serveur Ruby conserve la liste de toutes les connexions actives dans la table `@online[account_id]`.

Lorsqu'une nouvelle tentative de connexion survient sur un compte déjà actif :
1. Le serveur détecte que l'identifiant `account_id` est déjà en jeu sur une autre fenêtre.
2. Le serveur **ferme immédiatement la première connexion** (`@reactor.finish(old)`).
3. Le premier PC est déconnecté du serveur en direct, et le nouveau PC prend la main sur la session.

> 💡 **Résultat :** Deux personnes ne peuvent **jamais** jouer en même temps sur le même compte ou dupliquer des objets via une double session.

---

## 🧪 Procédure de Test chez toi pour vérifier l'anti-double connexion :

1. Lance le serveur via `0_Restart_Serveur.bat`.
2. Lance le **Joueur 1** via `1_Lancer_Joueur_1.bat`.
3. Connecte-toi avec le compte **`joueur1`** (mot de passe: `mdp12345`). Ton personnage entre sur la carte.
4. Lance une deuxième fenêtre avec `2_Lancer_Joueur_2.bat`.
5. Sur la deuxième fenêtre, choisis **Log in** et entre le **MÊME compte** (`joueur1` / `mdp12345`).
6. **Observation :**
   - La fenêtre 2 se connecte à ton dresseur.
   - La fenêtre 1 reçoit instantanément un ordre de déconnexion du serveur et s'arrête !

---

## 🛠️ Code Serveur Référent (`server/lib/pemk/server.rb`)

Pour référence, voici le bout de code dans `server.rb` qui assure cette sécurité :

```ruby
def bind(conn, account_id)
  old = @online[account_id]
  if old && !old.equal?(conn)
    @log.call("server: account #{account_id} re-bound -> closing old session")
    old.data[:account_id] = nil
    @reactor.finish(old)  # Déconnecte immédiatement la première session !
  end
  @online[account_id] = conn
  conn.data[:account_id] = account_id
end
```
