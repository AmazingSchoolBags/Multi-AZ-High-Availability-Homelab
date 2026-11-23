# Exemples historiques Flask / HAProxy (anonymisés)

> **Sous-projet documentaire, pas le déploiement Vikunja actuel.**
>
> Ces fichiers proviennent d'une **copie locale** préparée avec Codex à partir d'un extrait des scripts d'origine. Ils ont été anonymisés puis soumis à un contrôle statique. Le laboratoire final documenté à la racine utilise **Vikunja 2.8.0, HAProxy 3.2, PostgreSQL/Patroni et Garage S3** : les versions, ports et exemples de cette section ne doivent pas être pris pour son déploiement exact.

## Contenu

| Fichier | Rôle |
| --- | --- |
| [cloud-init/app.yaml](cloud-init/app.yaml) | Amorçage Ubuntu/Docker sur une **nouvelle VM de lab** |
| [flask/compose.yaml](flask/compose.yaml) | Instance Flask paramétrable ; l'image et son code sont à fournir |
| [lb/compose.yaml](lb/compose.yaml) | HAProxy exemple avec publications des ports sur `127.0.0.1` |
| [lb/haproxy.cfg](lb/haproxy.cfg) | Répartition Flask/Vikunja et sélection du Primary PostgreSQL |
| [redis-service/compose.yaml](redis-service/compose.yaml) | Redis autonome avec un volume persistant ; **pas de HA** |

Les scripts de diagnostic génériques sont placés dans le dossier racine [scripts/](../../scripts/) :
- [check-http-health.sh](../../scripts/check-http-health.sh) : requête HTTP vers `/health`, `/primary` ou `/api/v1/info`.
- [test-garage-s3.sh](../../scripts/test-garage-s3.sh) : écrit puis lit et supprime un objet temporaire **dans un bucket jetable explicitement choisi** ; nécessité d'identifiants AWS CLI conservés **hors dépôt**.

## Prérequis

Linux avec Docker Compose v2 pour les manifests Compose. Image Flask avec un endpoint `/health` fournie par l'opérateur. Trois instances PostgreSQL gérées par Patroni pour la configuration SQL, et des instances Vikunja accessibles depuis le conteneur HAProxy.

Pour le contrôle de santé HTTP, Bash + curl. Pour l'essai S3, Bash + AWS CLI v2, configuration externe de la région, de l'adressage S3 et de la confiance TLS si nécessaire. Le test S3 **exige des endpoints HTTPS** et un bucket sans versioning/verrouillage, avec accès limité au préfixe `homelab-smoke/`.

## Validation préalable (ne déploie rien)

```bash
docker compose -f flask/compose.yaml config --quiet
docker compose -f lb/compose.yaml config --quiet
docker compose -f redis-service/compose.yaml config --quiet
cloud-init schema --config-file cloud-init/app.yaml
haproxy -c -f lb/haproxy.cfg
bash -n ../../scripts/check-http-health.sh
bash -n ../../scripts/test-garage-s3.sh
```

**Ces validations natives sont proposées, pas déclarées exécutées.** Elles nécessitent les binaires correspondants. La validation statique de la copie source a réussi : parsage YAML/JSON et `bash -n` pour les deux scripts publics.

## Limites pratiques

- Les IP `192.0.2.0/24`, `198.51.100.0/24` et `203.0.113.0/24` sont des **plages réservées à la documentation**. Ces backends ne sont donc pas destinés à répondre tels quels.
- Les ports hôte du Compose HAProxy sont **limités à 127.0.0.1** ; d'autres hôtes ne pourront pas y accéder sans réseau/proxy adapté.
- Flask expose par défaut `127.0.0.1:8080` sur son hôte ; sur la **même machine**, cette publication peut entrer en conflit avec le frontend HAProxy `:8080`. Utiliser d'autres ports ou des réseaux internes avant tout déploiement.
- Redis ici est **autonome**, sans mot de passe ni ACL déclarés ; pas d'exposition de port mais pas prêt pour des clients distants et surtout pas pour la production.
- HAProxy dirige les connexions SQL en TCP vers un Primary choisi grâce à `/primary`, mais une bascule peut interrompre les connexions actives. L'application doit savoir se reconnecter.
- Ce jeu d'exemples ne contient **ni les sources Flask, ni le cluster etcd/Patroni, ni la configuration Garage complète**, ni un déploiement autonome de Vikunja.

## Traçabilité

- [Rapport de sécurité de la copie Codex](../../docs/AUDIT-SOURCES-CODEX.md).
- [Inventaire des 14 originaux exclus et travaux restant à auditer](../../docs/ORIGINAUX-EXCLUS.md).
- [Architecture et tests réels du lab final](../../README.md).
