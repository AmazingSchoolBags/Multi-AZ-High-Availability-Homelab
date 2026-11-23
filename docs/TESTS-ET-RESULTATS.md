# Campagne de tests de résilience

**Séances :** 21 et 23 novembre 2026. **Source :** sorties de commandes et manipulations de l'interface partagées lors de la construction du lab.

## Matrice synthétique

| ID | Scénario | Résultat observé | Conclusion |
|---|---|---|---|
| T01 | Application derrière HAProxy | Répartition sur AZ1/AZ2/AZ3 | Fonctionnel |
| T02 | Panne AZ1 | 9 requêtes API HTTP 200 sur 9 | Continuité HTTP simple |
| T03 | Lecture directe Garage sous panne AZ1, essai séquentiel | AZ2 : 3 timeouts ; AZ3 : 3 succès plus tard | Cause non identifiée |
| T04 | Lecture Garage sous panne AZ1, essai parallèle | 6 lectures OK sur 6 ; intégrité des octets confirmée | Résilience de l'objet testé |
| T05 | Perte du Primary db-az2 | Promotion db-az3, détection en 36 s | Failover automatique |
| T06 | Test écriture SQL après promotion | Première tentative fermée, suivante réussie | Reprise avec interruption transitoire |
| T07 | Retour zone2 | db-az2 Replica, timeline 4, lag affiché 0 Mo | Réintégration réussie |
| T08 | Vérification finale S3 | 3 nœuds healthy, `ResyncQueue=0` | État sain observé |
| T09 | Recette web après failover | Tâches modifiées, fichiers TXT/PNG ajoutés, page rechargée | Fonctionnel |
| T10 | Journaux HAProxy de la recette | 407 requêtes : 137/134/136, aucun 5xx détecté | Distribution équilibrée |

## Garage : comparaison des essais AZ1 indisponible

### Essai séquentiel précédent

Trois téléchargements directs depuis AZ2 ont expiré après environ 13 secondes chacun. Les trois mêmes catégories d'objets lues sur AZ3 ont ensuite réussi autour d'une seconde. **Les lectures AZ3 étant postérieures d'environ 40 secondes, l'asymétrie n'est pas démontrée.**

Lors d'un test applicatif, trois téléchargements ou aperçus de pièces jointes avaient aussi produit des erreurs HTTP 504.

### Essai parallèle du 23 novembre

| Déclenchement | AZ2 | AZ3 |
|---|---|---|
| Immédiatement après la coupure | OK 1 s | OK 1 s |
| Après 30 s | OK 1 s | OK 1 s |
| Après 75 s | OK 1 s | OK 2 s |

Même objet `files/3`, contenu comparé à une référence ; **6/6 lectures sans écart d'intégrité**. L'incident initial reste toutefois ouvert.

## PostgreSQL : promotion et reprise

Avant la panne : db-az2 Leader (TL3), db-az3 Sync Standby, db-az1 Replica.

Pendant la panne : db-az3 promue Leader (TL4), détectée par le script **36 secondes** après la coupure ; une tentative de connexion SQL a été fermée ; une nouvelle tentative a exécuté avec succès une transaction avec table temporaire, insertion et `ROLLBACK`.

Après la remise en ligne : db-az1 Sync Standby (TL4), db-az2 Replica (TL4), db-az3 Leader (TL4). Le client SQL HAProxy s'est connecté au nouveau Primary avec `transaction_read_only=off`.

## Recette finale

Les manipulations utilisateur **après basculement** ont porté sur la modification de tâches, l'envoi de TXT/PNG et l'actualisation. Les journaux HAProxy analysés depuis le début de cette recette montrent :

| Backend | Nombre de requêtes |
|---|---:|
| AZ1 | 137 |
| AZ2 | 134 |
| AZ3 | 136 |
| **Total** | **407** |

Aucune réponse 500/502/503/504 détectée dans le filtre de logs exécuté. Cela n'établit pas la disponibilité sans aucune erreur pendant toutes les fenêtres de panne.

## Ce qui reste à mesurer

RTO navigateur / écriture applicative durant l'élection SQL ; taux d'erreur S3 par objet et par taille sur plusieurs essais ; impact d'une panne Redis ou HAProxy ; reprise après panne physique de l'hôte Proxmox (non réalisable avec trois AZ sur le même hôte).
