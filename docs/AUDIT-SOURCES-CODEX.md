# Audit de la copie `publish-ready` préparée avec Codex

**Date :** 23 novembre 2026. **Type :** revue statique de fichiers de démonstration destinés à un dépôt GitHub **public**.

## Périmètre réel

L'archive reçue contient **12 fichiers** : cinq configurations d'exemple (cloud-init, Flask Compose, HAProxy Compose, configuration HAProxy et Redis Compose), deux scripts Bash, trois documents Markdown, `.gitignore` et `.gitattributes`.

Codex indique avoir inventorié **14 fichiers originaux** sur la **copie locale de l'utilisateur**. Ces originaux n'ont pas été joints à la conversation et n'ont pas été inspectés directement par l'assistant. **Notre revue propre** porte uniquement sur les 12 éléments de l'archive publique, et non sur toutes les configurations privées du serveur Ubuntu.

## Vérifications rapportées par Codex

- Syntaxe `bash -n` : **9 scripts sources** (après conversion des fins de lignes en mémoire) et **2 scripts publics**.
- Quatre fichiers YAML publics analysés, cohérence statique des ports HAProxy, Compose et routes de santé.
- Recherche de signatures courantes de secrets sur les fichiers de la copie, sans correspondance détectée.
- Validateurs natifs Docker Compose, cloud-init et HAProxy **non disponibles sur le poste** ; aucun déploiement réalisé.
- Aucune modification des scripts originaux, des VM ou des services ; aucun commit/push par Codex.

## Contrôles supplémentaires effectués lors de l'import ici

- Archive ZIP inspectée avant import : **12 fichiers texte**.
- `bash -n` relancé sur les **deux scripts joints** : aucune erreur de syntaxe.
- Parsage YAML sur les **quatre configurations** : réussi (les exemples utilisent un format JSON accepté en YAML).
- Recherche sur l'archive des formats fréquents de clés privées, tokens GitHub, clés AWS, JWT et identifiants incorporés aux URL : **aucune correspondance**.
- Vérification du fichier HAProxy : backends utilisant des **plages d'adresses de documentation**, et non les sous-réseaux réels du homelab.
- Vérification de l'absence de données de session, de dumps et de fichiers `.env` dans cette archive.

Ces contrôles **ne garantissent pas** l'absence de toute donnée privée ou de tout défaut de sécurité. Une revue complémentaire est nécessaire pour toute nouvelle source.

## Décisions de publication

- **Conserver le README racine** (application actuelle Vikunja / Patroni / Garage) plutôt que de le remplacer par le README de la maquette Flask.
- Publier les exemples historiques dans [`examples/legacy-flask/`](../examples/legacy-flask/), séparément du laboratoire courant.
- Publier deux scripts génériques de diagnostic dans [`scripts/`](../scripts/), avec avertissement explicite pour le test S3 qui **écrit puis supprime un objet**.
- **Conserver le `.gitignore` racine plus strict**. La copie en contenait un autre, moins complet : il n'a pas été utilisé pour remplacer les protections existantes.
- Ne publier aucun script destructif d'arrêt de zone, d'installation de bases, de redémarrage ou de migration sans examen de son contenu exact.

## Risques résiduels

Les validations natives HAProxy, cloud-init et Docker Compose n'ont pas été réalisées. Les exemples ne constituent pas un déploiement reproductible testé. Les nœuds Garage et les données SQL du lab final n'ont pas été exposés. Pour publier davantage d'originaux, réexaminer les secrets y compris **dans les scripts non détectés par les signatures classiques**, et scanner l'historique Git avant toute mise à jour.

Voir [politique de sécurité](SECURITE.md) et [inventaire des exclusions](ORIGINAUX-EXCLUS.md).
