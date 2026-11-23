# Inventaire des 14 originaux non publiés

Cette liste est issue du **rapport de Codex**, qui a travaillé sur une copie locale. Les **fichiers originaux** ne sont pas inclus dans l'archive transmise ici ; leurs rôles ci-dessous correspondent donc à l'inventaire rapporté, et non à une nouvelle inspection de leur code.

| Fichier d'origine | Rôle rapporté | Publication |
| --- | --- | --- |
| `cloud-init/app.yaml` | Préparation d'une VM et activation Docker | Exemple générique dans `examples/legacy-flask/` |
| `flask/compose.yaml` | Lancement d'une application Flask par zone | Compose paramétrable sans image réelle |
| `redis-service/compose.yaml` | Redis autonome avec stockage local | Compose générique avec volume nommé |
| `lb/compose.yaml` | Lancement HAProxy et montage de config | Compose anonymisé à ports locaux |
| `lb/haproxy.cfg` | Routage Flask, Primary PostgreSQL et Vikunja | Exemple utilisant des IP de documentation |
| `configure-haproxy-postgres.sh` | Interrogation Patroni et reconfiguration du proxy SQL | **Non publié**, audit nécessaire |
| `fix-haproxy-postgres-sessions.sh` | Fermeture des sessions SQL obsolètes après bascule | Comportement illustré dans l'exemple HAProxy |
| `configure-haproxy-vikunja.sh` | Sondes Vikunja et reconfiguration du frontend | **Non publié**, audit nécessaire |
| `activate-vikunja-lb.sh` | Activation du proxy HTTP Vikunja | **Non publié**, audit nécessaire |
| `connect-garage-cluster.sh` | Enregistrement des peers Garage et état du cluster | **Non publié**, audit nécessaire |
| `test-garage-s3.sh` | Lecture/écriture d'un objet pour validation S3 | Réécriture **générique**, non la copie brute |
| `test-garage-zone1-failure.sh` | Simulation de panne et restauration de zone | **Non publié**, script potentiellement destructif |
| `reprise-azlab.sh` | Relance VM et conteneurs / ordre de reprise | **Non publié**, audit nécessaire |
| `etcd/bootstrap.sh` | Bootstrap etcd via systemd | **Non publié**, audit et contrôle du quorum nécessaires |

## Pièces encore absentes

- Le code source et le Dockerfile d'origine de l'application Flask.
- Les vrais déploiements PostgreSQL/Patroni, Garage et Vikunja.
- Les scripts de création des VM/réseaux et les paramètres de zone.
- Des procédures de sauvegarde et restauration vérifiées.
- Les fichiers d'environnement privés **doivent rester absents** du dépôt.

**Important :** ne pas conclure qu'un script est sûr parce que son nom n'a pas été signalé par une expression régulière. Les fichiers privés `.env`, les secrets, les clés S3/JWT, les dumps et les logs de session ne doivent jamais être ajoutés, même dans un dépôt temporairement privé.
