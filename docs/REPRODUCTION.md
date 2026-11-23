# Reproduire le principe du laboratoire

> Document de conception, pas procédure de déploiement automatisée validée. Les exemples ne sont pas les configurations originales d'Ubuntu.

## Prérequis

Proxmox avec un hôte Ubuntu central, simulation de trois zones Multipass et six VM, Docker sur les VM applicatives, PostgreSQL 16 / Patroni / etcd sur les VM de base, trois Garage S3, Redis et HAProxy sur l'hôte central.

Le projet ne reproduit **pas** de véritables AZ physiques : il dépend d'un **seul hôte Proxmox**.

## Ordre de construction suggéré

1. Préparer trois réseaux privés simulés et six VM, puis vérifier les connexions interzones.
2. Configurer etcd/Patroni et obtenir un seul Primary PostgreSQL, avec deux réplicas.
3. Configurer le proxy SQL HAProxy pour vérifier l'endpoint Patroni `/primary`.
4. Mettre en place un bucket privé Garage S3 répliqué entre trois zones, puis valider les lectures et écritures.
5. Configurer Redis central, en notant le point de défaillance unique.
6. Déployer une instance Vikunja par zone avec la même base, le même secret de service et le même stockage S3.
7. Activer le round-robin HTTP et valider navigation, tâches et pièces jointes.
8. Mesurer les temps et erreurs pendant les pannes **seulement avec accès de secours**.

## Exemples publiés

- [HAProxy](../examples/haproxy.cfg.example) : round-robin HTTP et proxy SQL lié au Primary Patroni.
- [Vikunja Compose](../examples/vikunja.compose.example.yaml) : exemple d'une seule AZ avec placeholders explicites ; ne pas déployer tel quel.
- [Diagnostic lecture seule](../scripts/check-health-readonly.sh) : contrôles de santé HTTP/Patroni, sans lecture de secrets.

Les véritables configurations Garage, Patroni et Compose utilisées lors des essais ne sont pas dans ce dépôt : elles requièrent inspection et anonymisation depuis Ubuntu.

## Périmètre des tests déjà prouvés

Consulter le [rapport d'essais](TESTS-ET-RESULTATS.md) et l'[incident S3](INCIDENT-GARAGE-S3.md). Les 36 secondes sont une mesure de détection du nouveau Primary, non un SLA. L'anomalie S3 reste inexpliquée.

## Références

- [Vikunja : configuration](https://vikunja.io/docs/config-options/)
- [Patroni](https://patroni.readthedocs.io/)
- [Garage](https://garagehq.deuxfleurs.fr/documentation/)
- [HAProxy](https://docs.haproxy.org/)
