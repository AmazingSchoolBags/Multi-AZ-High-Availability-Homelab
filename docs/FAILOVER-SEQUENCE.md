# Basculement PostgreSQL : panne du Primary AZ2

## Diagramme de séquence

```mermaid
sequenceDiagram
    autonumber
    participant O as Opérateur
    participant M as Multipass
    participant E as Patroni / etcd
    participant A2 as db-az2 (ancien Primary)
    participant A3 as db-az3 (Sync Standby)
    participant LB as HAProxy SQL
    participant APP as Vikunja

    Note over A2,A3: Avant panne : timeline 3, AZ2 Leader, AZ3 Sync Standby
    O->>M: disable-zones zone2
    M-xA2: Arrêt forcé
    E->>E: Détection perte de Leader et quorum
    E->>A3: Élection / promotion
    A3-->>E: Leader, timeline 4
    Note over O,A3: Nouveau Primary détecté en 36 s (mesure du script)
    LB->>A2: Ancienne connexion
    A2--xLB: Session interrompue
    APP->>LB: Première tentative SQL
    LB--xAPP: Connexion fermée
    APP->>LB: Nouvelle tentative SQL
    LB->>A3: /primary = HTTP 200
    A3-->>APP: INSERT temporaire réussi
    O->>M: enable-zones zone2
    M->>A2: Redémarrage
    E->>A2: Réintégration en Replica, timeline 4
    Note over A2,A3: Un seul Leader et réplication revenue à 0 Mo de lag affiché
```

## Mesures et nuances

- **36 secondes** : temps entre coupure et détection du nouveau Primary par le script, pas un RTO utilisateur garanti.
- **Une erreur transitoire SQL** observée avant succès de la transaction suivante.
- **9/9 HTTP 200** sur `/api/v1/info` après la détection de la promotion.
- Après restauration : db-az3 Leader ; db-az1 Sync Standby ; db-az2 Replica ; tous en timeline 4.
- Les vérifications finales de tâches et d'envoi de TXT/PNG ont eu lieu **après** le failover, pas durant les 36 secondes de transition.

La preuve est reproductible uniquement dans le périmètre exact de ce laboratoire. Aucune suppression ou reconstruction forcée des volumes n'a été nécessaire.
