# Sécurité et confidentialité du dépôt

Ce dépôt est **public**. Aucun fichier de production ou secret de laboratoire ne doit être importé brut.

## Fichiers interdits à la publication

- `.env`, mots de passe PostgreSQL, secrets Patroni ou JWT.
- Access keys et secret keys S3/Garage, clé RPC Garage.
- Clés privées SSH, cookies/session web, captures contenant des tokens.
- Dumps SQL, volumes Redis/PostgreSQL/Garage, sauvegardes, bases SQLite.
- Configurations complètes avec domaines internes, comptes de service ou jetons.
- Fichiers personnels présents dans le serveur hôte.

Ne jamais transmettre de clé privée ou token GitHub à un assistant.

## Publication du code source

1. Faire une **copie de travail distincte** de `~/az-lab`.
2. Sélectionner seulement les fichiers à publier.
3. Utiliser des paramètres fictifs `YOUR_SECRET_HERE`, `HOST_EXAMPLE`.
4. Vérifier `git status`, `git diff --cached` et l'historique Git.
5. Scanner les secrets (par exemple Gitleaks).
6. N'effectuer le push qu'après revue manuelle.

**Attention :** `.gitignore` ne protège pas contre un secret collé dans un README ou un script déjà suivi. Si un secret est publié, le révoquer / remplacer ; un nouveau commit qui supprime le secret ne supprime pas son historique Git.

## Bonnes pratiques réseau

Interdire l'accès public direct à Redis, etcd, PostgreSQL, Garage RPC et aux endpoints administratifs. Privilégier les réseaux privés, les ACL minimales, le VPN et TLS. La résilience à la panne ne remplace jamais les contrôles de sécurité.
