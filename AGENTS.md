# Instructions Codex pour ce dépôt

## Mission

Faire évoluer ce dépôt documentaire en **portfolio technique reproductible** pour un homelab Multi-AZ simulé : Proxmox, Multipass, trois Vikunja, HAProxy, PostgreSQL/Patroni/etcd, Garage S3 et Redis. Produire des exemples de configuration et scripts réutilisables **sans modifier le laboratoire en service**.

## Frontières de sécurité impératives

- Ce dépôt est **PUBLIC**. Considérer que **chaque commit est visible par tous**, y compris son historique.
- Travailler uniquement dans le clone Git de publication, par exemple `~/azlab-github`. Le laboratoire réel se trouve à `~/az-lab`, hors de l'espace de travail.
- **Aucune commande de modification**, restart/stop de VM ou conteneur, `multipass disable-zones`, `docker compose up/down`, écriture SQL, modification HAProxy ni modification firewall sur le lab réel.
- Ne pas parcourir, ouvrir, copier, afficher, inclure dans le contexte, transmettre ni indexer les secrets : `~/.config/azlab/**`, `.env*`, clés SSH, credentials S3, secrets Patroni/Vikunja, auth.json, volumes Garage/Postgres/Redis, dumps, logs de session et backups.
- Dans un premier temps, ne pas ouvrir de **fichiers de contenu** de `~/az-lab` ; autorisé : obtenir seulement la **liste des chemins relatifs** des fichiers `.sh`, `.cfg`, `.yaml`, `.yml`, `.toml` qui pourraient être candidats, sans lire leur contenu, et exclure secrets et dossiers de données. Cela reste un inventaire, pas une autorisation d'import.
- **Avant de lire un script original**, demander une autorisation explicite pour le chemin exact, vérifier qu'il n'expose pas de secret et utiliser une copie de travail expurgée. Un scanner automatique est utile mais ne suffit pas à garantir l'absence de secrets.
- Ne pas ajouter de jeton, mot de passe, clé, nom de domaine personnel, IP publique réelle, e-mail personnel, sauvegarde, clé SSH, fingerprint, cookie ou fichier `.env` réel, **même pour un commit privé**.
- Ne pas copier des identifiants réels de la VM ou des systèmes privés dans les diagrammes ; les IP de sous-réseaux simulés déjà documentés peuvent servir à expliquer la topologie, sans publication des accès d'administration.
- Aucun `git push`, aucune pull request et aucune publication sans confirmation humaine après contrôle des changements. Ne pas utiliser `--dangerously-bypass-approvals-and-sandbox`.

## État établi des tests

- 3 zones simulées sur **un hôte physique Proxmox unique**, 6 VM ; ceci **n'est pas** de la HA physique.
- Garage : 3 nœuds, 3 copies ; essai parallèle sous panne AZ1 6/6 lectures de l'objet testé OK ; essai antérieur avec HTTP 504/timeouts **non expliqué**.
- Failover PostgreSQL : AZ2 ancien Primary, AZ3 promue sur timeline 4 ; **36 secondes jusqu'à la détection** du nouveau Primary par le script ; première tentative SQL échouée, suivante OK.
- Après remise en ligne : AZ3 Leader, AZ1 Sync Standby, AZ2 Replica, TL4, 0 Mo de lag affiché.
- Recette HTTP finale : 407 requêtes réparties 137/134/136 ; 0 erreurs 5xx détectées dans les logs examinés.
- Les manipulations navigateur (tâches, TXT, PNG) ont été faites **après** le failover, pas pendant la fenêtre d'élection.
- Redis et HAProxy centralisés, hôte Proxmox unique : **SPOF** à mentionner.

## Travaux attendus dans le clone

1. Auditer la documentation existante (exactitude, Mermaid rendu GitHub, liens, terminologie).
2. Ajouter un dossier `examples/` avec des **templates explicitement non opérationnels tant que paramètres non renseignés** : `haproxy.cfg.example`, `compose.*.example.yaml`, exemple de configuration Patroni/Garage sans credentials réels. **Ne pas inventer de déploiement testé**.
3. Ajouter des scripts **lecture seule** de santé/diagnostic, avec contrôles d'erreur, dépendances et documentation. Éviter tout script de panne prêt à exécuter sans confirmation.
4. Ajouter un guide de reproduction du laboratoire avec prérequis et placeholders, en différenciant instructions conceptuelles et étapes réellement validées.
5. Contrôler le rendu Mermaid, `git diff --check`, `bash -n` des scripts, syntaxe des YAML si outil disponible ; documenter ce qui n'a pas été testé.
6. Produire une synthèse des modifications, des risques, des fichiers exclus et des actions manuelles nécessaires.
7. **S'arrêter avant le commit/push** pour relecture et revue de sécurité par l'utilisateur.

## Style

Français, précis, honnête, professionnel, lisible sur GitHub. Diagrammes Mermaid simples, sans croisements superflus. Ne jamais annoncer « zéro downtime », « trois datacenters » ou « HA de l'hôte Proxmox ». Éviter les formulations qui laisseraient croire que les exemples ont été exécutés.
