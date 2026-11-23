# Limites et feuille de route

## Limites actuelles

- **Un seul hôte Proxmox** : pas de tolérance à sa perte physique.
- **HAProxy central** : si son hôte/processus tombe, pas de VIP redondante prouvée.
- **Redis central** : point de défaillance unique.
- **Garage S3** : anomalies transitoires observées sur le premier essai sous panne AZ1.
- **Observation partielle** : aucun SLO/SLA ni RTO bout-en-bout garanti.
- **Accès distant** : routeur Tailscale indépendant du lab, mais pas redondé.

## Évolutions prioritaires

### P1 : observabilité
Prometheus/Grafana, logs corrélés, mesures RTO en distinguant HTTP, SQL, pièces jointes, et essais répétés Garage.

### P2 : élimination des SPOF
HAProxy redondant, Redis HA, puis plusieurs hôtes Proxmox indépendants pour rendre les AZ réellement résistantes à une panne physique.

### P3 : sécurité et exploitation
Gestion centralisée des secrets, TLS, sauvegardes hors cluster **avec tests de restauration**, contrôle des accès et versionnement des configurations auditées.

### P4 : industrialisation
Ansible ou autre IaC, pipeline CI de vérification de scripts, procédures rollback, reprise après désastre.

## Valorisation professionnelle

> Conception et validation d'un homelab multi-zones simulées sous Proxmox/Multipass, PostgreSQL 16/Patroni/etcd, Garage S3 répliqué et HAProxy ; basculement automatique du Primary détecté en 36 s, reprise d'écritures SQL, tests d'injection de panne et analyse d'anomalies intermittentes S3.

Éviter les formulations « trois datacenters », « zéro downtime garanti » et « HA de l'hôte Proxmox ».
