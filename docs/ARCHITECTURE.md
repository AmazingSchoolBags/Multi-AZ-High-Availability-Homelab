# Architecture technique et flux

## 1. Vue logique

Le schéma isole les **services partagés** des trois zones simulées. Les chemins SQL et S3 sont distincts : HAProxy prend les décisions SQL, Garage gère la réplication des objets.

```mermaid
flowchart TB
    remote["Poste distant"] --> ts["Tailscale subnet router<br/>VM Proxmox dédiée"]
    ts --> host

    subgraph host["VM Ubuntu principale sur un hôte Proxmox unique"]
      lb["HAProxy<br/>HTTP 8081 / SQL 5432"]
      redis[("Redis partagé<br/>SPOF")]
      subgraph multipass["Multipass : trois zones simulées"]
        direction LR
        subgraph az1["AZ 1"]
          v1["Vikunja 2.8.0"] --> g1[("Garage S3")]
          p1[("PostgreSQL<br/>Patroni + etcd")]
        end
        subgraph az2["AZ 2"]
          v2["Vikunja 2.8.0"] --> g2[("Garage S3")]
          p2[("PostgreSQL<br/>Patroni + etcd")]
        end
        subgraph az3["AZ 3"]
          v3["Vikunja 2.8.0"] --> g3[("Garage S3")]
          p3[("PostgreSQL<br/>Patroni + etcd")]
        end
      end
    end
    lb --> v1 & v2 & v3
    v1 & v2 & v3 --> redis
    v1 & v2 & v3 --> sql["Backend SQL HAProxy<br/>seul Patroni /primary = 200"]
    sql --> p1 & p2 & p3
    g1 <-->|"RPC"| g2
    g2 <-->|"RPC"| g3
    g1 <-->|"RPC"| g3
    p1 <-. "Réplication" .-> p2
    p2 <-. "Réplication" .-> p3

    classDef app fill:#e0f2fe,stroke:#0284c7,color:#0c4a6e;
    classDef storage fill:#dcfce7,stroke:#16a34a,color:#14532d;
    classDef single fill:#fff7ed,stroke:#ea580c,color:#7c2d12;
    class v1,v2,v3 app;
    class g1,g2,g3,p1,p2,p3 storage;
    class lb,redis single;
```

> ⚠️ Trois zones virtuelles ne signifient pas trois zones physiques. L'hôte Proxmox, Redis et HAProxy restent des points de défaillance uniques.

## 2. Inventaire

| Zone | Réseau simulé | VM application | VM base de données |
|---|---|---|---|
| AZ1 | `10.97.0.0/24` | `vm-az1` | `db-az1` |
| AZ2 | `10.97.1.0/24` | `vm-az2` | `db-az2` |
| AZ3 | `10.97.2.0/24` | `vm-az3` | `db-az3` |

Trois Vikunja partagent **une même base**, **le même secret applicatif**, **un Redis** et **un bucket S3**. Chaque Vikunja parle à son Garage local pour les objets. Les nœuds Garage échangent entre eux pour assurer la réplication sur les zones.

## 3. Chemins critiques

- **HTTP** : client → HAProxy (round-robin) → l'une des trois applications.
- **SQL** : application → HAProxy SQL → seul nœud Patroni dont `/primary` répond HTTP 200.
- **Pièces jointes** : application → endpoint Garage S3 → réplication interne entre trois zones.
- **Cache partagé** : chaque instance applicative → Redis central.
- **Consensus** : Patroni et etcd suivent l'état du cluster et l'élection du Primary.

## 4. Haute disponibilité SQL

Après perte d'AZ2, ancien Primary, le laboratoire a observé une promotion d'AZ3. Au retour d'AZ2, AZ3 est restée Leader et AZ2 a rejoint comme Replica sur la **timeline 4**, avec un retard affiché de 0 Mo. HAProxy possède `on-marked-down shutdown-sessions` pour fermer des sessions vers un backend devenu indisponible.

Le basculement n'est **pas transparent à toutes les connexions** : une première tentative SQL a été fermée, puis la suivante a réussi.

## 5. Stockage Garage

Trois nœuds Garage 2.5.0, zones distinctes, réplication configurée à trois copies. Un test parallèle de lecture sous panne d'AZ1 a été réussi **6 fois sur 6**, mais un essai antérieur avait produit des timeouts et des HTTP 504. Voir [l'incident](INCIDENT-GARAGE-S3.md).

## 6. Dimensionnement et limites

Ce projet ne démontre ni résilience inter-datacenters, ni quorum en cas de partition prolongée, ni tolérance à la panne de l'hôte physique. Les applications continuent à utiliser des dépendances centrales hors des zones. Voir [roadmap](LIMITES-ET-ROADMAP.md).
