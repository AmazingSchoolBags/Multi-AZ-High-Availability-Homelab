# Inventaire des scripts du laboratoire

Les scripts ci-dessous ont été utilisés ou identifiés lors de la construction de la plateforme. Seuls les exemples liés sont présents dans le dépôt. Leurs versions locales complètes ne sont pas toutes publiées ; certaines dépendent de configurations privées, de secrets et de volumes persistants.

| Fichier | Rôle | Présence dans le dépôt |
| --- | --- | --- |
| `cloud-init/app.yaml` | Préparation d'une VM et activation Docker | Exemple générique dans `examples/legacy-flask/` |
| `flask/compose.yaml` | Lancement d'une application Flask par zone | Compose paramétrable sans image réelle |
| `redis-service/compose.yaml` | Redis autonome avec stockage local | Compose générique avec volume nommé |
| `lb/compose.yaml` | Lancement HAProxy et montage de config | Compose anonymisé à ports locaux |
| `lb/haproxy.cfg` | Routage Flask, Primary PostgreSQL et Vikunja | Exemple utilisant des IP de documentation |
| `configure-haproxy-postgres.sh` | Interrogation Patroni et reconfiguration du proxy SQL | Non inclus |
| `fix-haproxy-postgres-sessions.sh` | Fermeture des sessions SQL obsolètes après bascule | Comportement illustré dans l'exemple HAProxy |
| `configure-haproxy-vikunja.sh` | Sondes Vikunja et reconfiguration du frontend | **Non publié**, configuration spécifique |
| `activate-vikunja-lb.sh` | Activation du proxy HTTP Vikunja | **Non publié**, audit nécessaire |
| `connect-garage-cluster.sh` | Enregistrement des peers Garage et état du cluster | **Non publié**, audit nécessaire |
| `test-garage-s3.sh` | Lecture/écriture d'un objet pour validation S3 | Réécriture **générique**, non la copie brute |
| `test-garage-zone1-failure.sh` | Simulation de panne et restauration de zone | Non inclus : arrêt de zone |
| `reprise-azlab.sh` | Relance VM et conteneurs / ordre de reprise | **Non publié**, audit nécessaire |
| `etcd/bootstrap.sh` | Bootstrap etcd via systemd | Non inclus : bootstrap |

## Pièces encore absentes

- Le code source et le Dockerfile d'origine de l'application Flask.
- Les vrais déploiements PostgreSQL/Patroni, Garage et Vikunja.
- Les scripts de création des VM/réseaux et les paramètres de zone.
- Des procédures de sauvegarde et restauration vérifiées.
- Les fichiers d'environnement privés **doivent rester absents** du dépôt.

**Sécurité :** les fichiers `.env`, les clés S3/JWT, les identifiants, les volumes de données, les dumps et les journaux de session ne doivent pas être publiés.
