# Passation Codex CLI depuis la VM Ubuntu

Cette procédure permet de compléter le dépôt public **sans toucher aux services du laboratoire**.

## Installation et authentification

Installer Codex CLI depuis le [dépôt officiel](https://github.com/openai/codex) avec son script Linux, ou via npm si Node.js est déjà présent.

Pour SSH sans navigateur sur Ubuntu, utiliser :

```bash
codex login --device-auth
```

Ouvrir l'URL affichée sur son poste local, puis saisir le code affiché par Codex. Ne pas publier ce code ni les fichiers `~/.codex` dans le dépôt.

## Clone isolé

```bash
git clone https://github.com/AmazingSchoolBags/Multi-AZ-High-Availability-Homelab.git ~/azlab-github
cd ~/azlab-github
git status --short
```

Le dépôt est **public**. La connexion GitHub à ChatGPT n'authentifie pas automatiquement Git sur Ubuntu.

## Lancement

```bash
cd ~/azlab-github
codex --sandbox workspace-write
```

Lire `AGENTS.md` : Codex doit travailler dans le clone, créer **uniquement** des modèles anonymisés et des scripts non destructifs, puis s'arrêter pour revue **avant toute publication**.

## Contrôle avant publication

```bash
git status --short
git diff --check
git diff --stat
git diff -- . ':!docs/screenshots'
find . -type f -name '*.sh' -not -path './.git/*' -exec bash -n {} +
```

Une commande de scan de secrets externe est recommandée ; même avec un scan sans alerte, inspecter les changements et les fichiers ajoutés manuellement.

**Ne pas faire :** `git add -A` depuis `~/az-lab`, `git push --force`, `sudo codex`, arrêt de la zone2, installation automatique de services sur l'hôte, ou import aveugle des fichiers secrets.

Pour publier après relecture, utiliser GitHub CLI avec une authentification utilisateur ou un push Git habituel à partir du clone. L'intégration GitHub de ChatGPT peut également publier des fichiers dont le contenu a été contrôlé.
