# Guide de reconstruction du laboratoire Multi-AZ

## 1. Ce que ce laboratoire reproduit

Le but est de faire fonctionner **une même application Vikunja sur trois zones simulées**, avec :

- une instance web par zone, servie en round-robin par HAProxy ;
- une base PostgreSQL commune, répliquée et pilotée par Patroni/etcd ;
- des fichiers joints dans un stockage Garage S3 distribué entre les zones ;
- Redis commun aux applications ;
- des tests de coupure d'une zone, de promotion d'un Primary et de reprise.

Le laboratoire repose sur **un seul hôte physique Proxmox**. Les trois zones représentent des domaines de panne simulés dans Multipass, pas trois datacenters indépendants. HAProxy et Redis restent centralisés.

## 2. Topologie et ports

| Élément | Zone / adresse privée du lab | Ports |
|---|---|---|
| VM Ubuntu principale | LAN du laboratoire | HAProxy HTTP `8081`, SQL `5432`, Redis `6379` |
| `vm-az1` | AZ1, `10.97.0.8` | Vikunja `3456`, Garage `3900` / RPC `3901` |
| `db-az1` | AZ1, `10.97.0.14` | PostgreSQL `5432`, Patroni `8008`, etcd `2379` |
| `vm-az2` | AZ2, `10.97.1.179` | Vikunja `3456`, Garage `3900` / RPC `3901` |
| `db-az2` | AZ2, `10.97.1.43` | PostgreSQL `5432`, Patroni `8008`, etcd `2379` |
| `vm-az3` | AZ3, `10.97.2.141` | Vikunja `3456`, Garage `3900` / RPC `3901` |
| `db-az3` | AZ3, `10.97.2.128` | PostgreSQL `5432`, Patroni `8008`, etcd `2379` |

Réseaux : AZ1 `10.97.0.0/24`, AZ2 `10.97.1.0/24`, AZ3 `10.97.2.0/24`. Une VM de routeur Tailscale distincte du serveur Multi-AZ permet l'accès distant via le LAN privé.

## 3. Comprendre la circulation des requêtes

### Naviguer dans Vikunja

1. Le navigateur se connecte au HAProxy HTTP de l'Ubuntu principale sur `:8081`.
2. HAProxy distribue les nouvelles requêtes entre `vm-az1`, `vm-az2` et `vm-az3`.
3. Chaque instance Vikunja parle à la même base et utilise le même stockage Garage et le même Redis.
4. Le navigateur peut donc changer de backend sans changer de liste de tâches ni de pièces jointes.

### Créer une tâche

1. Vikunja transmet l'écriture au HAProxy SQL sur `:5432`.
2. Le proxy sonde les trois API Patroni `/primary` sur `:8008`.
3. **Seul** le backend qui répond HTTP 200 à `/primary` reçoit les connexions SQL nouvelles.
4. PostgreSQL réplique les modifications vers les autres bases ; Patroni suit les rôles.

Une ancienne session SQL peut être interrompue si le Primary change. L'application doit savoir se reconnecter. La configuration testée comportait `on-marked-down shutdown-sessions`.

### Ajouter un fichier

1. Vikunja stocke les métadonnées de la pièce jointe dans PostgreSQL.
2. Le contenu est écrit dans le bucket Garage S3 privé `vikunja-files`, via l'endpoint Garage accessible à l'application.
3. Garage répartit les copies entre les trois zones configurées.
4. Les trois applications utilisent donc un stockage de fichiers commun, plutôt que leurs seuls disques locaux.

## 4. Ordre de remise en place

Les sections suivantes donnent **l'ordre technique** et les vérifications. Elles ne remplacent pas les scripts originaux de déploiement, qui ne sont pas intégralement publiés. La commande `multipass zones` et les opérations `disable-zones` du laboratoire correspondent à son environnement particulier et ne doivent pas être supposées disponibles dans toutes les installations Multipass.

### Phase A : infrastructure

1. Installer Proxmox et créer une VM Ubuntu suffisamment dimensionnée.
2. Installer Multipass et préparer les trois domaines de réseau privés, y compris le routage entre eux.
3. Créer six VM Ubuntu : trois `vm-az*` pour Vikunja/Garage, trois `db-az*` pour PostgreSQL/Patroni/etcd.
4. Valider que chaque VM communique avec ses dépendances inter-zones, sans exposer de port de base ou de stockage sur Internet.

Premiers contrôles **déjà utilisés** dans le laboratoire :

```bash
multipass zones
multipass list
```

**Critère de succès :** les trois zones sont `Available` et les six VM sont `Running`.

### Phase B : base de données et consensus

1. Installer/configurer les membres etcd sur les trois VM de base.
2. Installer PostgreSQL 16 et Patroni, avec identifiants et clés de contrôle conservés hors dépôt.
3. Configurer le même identifiant de cluster Patroni et les trois endpoints etcd.
4. Démarrer le cluster et vérifier **un seul Leader** et deux réplicas.
5. Vérifier les politiques de réplication, l'état synchrone et le comportement voulu en cas de perte de quorum.

```bash
multipass exec db-az3 -- sudo \
  patronictl -c /etc/patroni/config.yml list azlab-postgres
```

**Ne pas forcer de promotion** lorsqu'un nœud est indisponible sans vérifier l'état de consensus. Une mauvaise manipulation peut provoquer deux nœuds Primary ou une divergence de données.

### Phase C : proxy SQL

1. Configurer HAProxy avec un frontend TCP sur `:5432`.
2. Définir trois serveurs PostgreSQL, avec un contrôle HTTP Patroni sur le port `8008`, chemin `/primary`, statut attendu `200`.
3. Fermer les anciennes sessions sur un backend marqué indisponible avec `on-marked-down shutdown-sessions`.
4. Tester une connexion SQL via HAProxy : elle doit arriver sur le **Leader réel**, et non sur un Replica.

Le dépôt propose un [exemple de configuration HAProxy](../examples/haproxy.cfg.example), **pas** le fichier en production.

```bash
for ip in 10.97.0.14 10.97.1.43 10.97.2.128; do
  printf '%s ' "$ip"
  curl -s --max-time 3 -o /dev/null -w '%{http_code}\n' \
    "http://$ip:8008/primary"
done
```

**Critère de succès :** un seul HTTP 200 ; les autres devraient renvoyer une réponse différente, typiquement HTTP 503.

### Phase D : stockage Garage S3

1. Déployer un Garage sur chaque VM applicative.
2. Connecter les nœuds via leur RPC `:3901`.
3. Attribuer les nœuds à trois zones de stockage et appliquer le layout désiré.
4. Créer un bucket privé `vikunja-files`, une clé à droits minimaux et les identifiants nécessaires **hors dépôt**.
5. Vérifier écriture, lecture et intégrité d'un objet depuis les trois endpoints S3 `:3900`.

```bash
multipass exec vm-az3 -- sudo \
  docker exec azlab-garage /garage status
```

**Critère de succès :** trois nœuds connectés, objets accessibles. La colonne `ResyncQueue` doit revenir à zéro après stabilisation. Le premier essai de panne AZ1 avait néanmoins produit des timeouts : voir [incident Garage](INCIDENT-GARAGE-S3.md).

### Phase E : Redis et Vikunja

1. Démarrer Redis sur l'hôte central, avec mot de passe conservé hors dépôt.
2. Préparer la base `vikunja` et un utilisateur SQL à privilèges adaptés.
3. Démarrer **une** instance Vikunja par zone.
4. Configurer les trois instances avec :
   - la même base PostgreSQL **via HAProxy SQL**, jamais via l'IP fixe d'un Primary ;
   - le même `VIKUNJA_SERVICE_SECRET` privé ;
   - le même Redis central ;
   - le même bucket Garage S3 et une clé adaptée ;
   - l'endpoint Garage propre à l'AZ concernée.
5. Configurer HAProxy HTTP sur `:8081`, avec round-robin et sonde Vikunja.
6. Se connecter à l'application, créer une tâche, ajouter un fichier, actualiser et vérifier que les changements persistent.

Les [exemples Vikunja](../examples/vikunja.compose.example.yaml) et [HAProxy](../examples/haproxy.cfg.example) illustrent le câblage. Ils contiennent volontairement des valeurs à remplacer, ne sont pas des manifests de production et n'ont pas été revalidés par un déploiement natif.

### Phase F : administration distante

La VM de routeur Tailscale est distincte des AZ Multipass. Depuis le poste distant, l'administration passe par SSH. Si le navigateur ne peut pas joindre le port `8081` sur le LAN, on peut utiliser un tunnel SOCKS5 :

```powershell
ssh -N -D 127.0.0.1:1080 -o ExitOnForwardFailure=yes ubuntu@HOTE_LAN_PRIVE
```

Configurer Firefox sur SOCKS5 `127.0.0.1:1080`. Cette méthode conserve l'URL interne de Vikunja, ce qui évite les incohérences d'URL d'API. Ne pas exposer HAProxy, PostgreSQL, etcd, Redis ou Garage publiquement pour contourner un problème de routage interne.

## 5. Contrôles après installation ou redémarrage

```bash
multipass zones
multipass list

multipass exec db-az3 -- sudo \
  patronictl -c /etc/patroni/config.yml list azlab-postgres

multipass exec vm-az3 -- sudo \
  docker exec azlab-garage /garage status

for ip in 10.97.0.8 10.97.1.179 10.97.2.141; do
  curl -fsS --max-time 5 "http://$ip:3456/health"
done

curl -fsS --max-time 5 "http://127.0.0.1:8081/health"
```

Vérifier séparément une **écriture SQL**, la modification d'une tâche et le téléchargement d'une pièce jointe. Un HTTP 200 sur `/health` ne garantit pas qu'une écriture SQL ou une lecture S3 fonctionnera.

Le script [check-health-readonly.sh](../scripts/check-health-readonly.sh) réalise un contrôle de base non destructif.

## 6. Tester les pannes sans se verrouiller dehors

Avant toute coupure : console Proxmox de secours, routeur Tailscale indépendant de la zone arrêtée, vérification du cluster PostgreSQL et de Garage, sauvegardes et plan de restauration.

**Panne de l'AZ applicative :** stopper dans un lab une seule zone, vérifier que les applications survivantes répondent via HAProxy. Tester **aussi** les pièces jointes, pas seulement les endpoints HTTP.

**Panne du Primary PostgreSQL :** relever le Leader initial, couper la zone concernée et mesurer séparément :
- délai de détection d'un nouveau Primary ;
- durée des erreurs SQL transitoires ;
- reprise d'une **vraie** écriture applicative ;
- état des réplicas après restauration.

Le 23 novembre 2026, une panne d'AZ2 a donné une promotion d'AZ3 détectée en **36 secondes**, avec une tentative SQL interrompue puis une écriture SQL réussie. L'ancien Primary a rejoint en Replica sur la timeline 4. Ces mesures sont des résultats de laboratoire, pas des garanties.

**Ne jamais** appliquer un script de panne ou de réparation de volume directement dans une plateforme de production.

## 7. Points de défaillance et prochaines étapes

- **Proxmox unique :** si l'hôte physique tombe, les trois AZ simulées tombent.
- **HAProxy unique :** un seul point d'entrée pour HTTP et SQL.
- **Redis unique :** dépendance centrale non redondée.
- **Garage :** timeouts intermittents à approfondir avec mesures simultanées et journaux corrélés.
- **Sauvegardes :** réplication ne remplace pas sauvegardes versionnées et restauration testée.

Pour passer à une véritable architecture multi-AZ : répartir les VM sur plusieurs hôtes physiques, redonder les points d'entrée, traiter Redis, superviser les erreurs et mesurer RTO/RPO lors de tests répétables.

## 8. Les questions à savoir expliquer à l'oral

**Pourquoi trois instances Vikunja ?** Pour que le frontal puisse distribuer le trafic et retirer une instance indisponible sans perdre les données, puisque PostgreSQL et Garage sont partagés.

**Pourquoi Patroni + etcd ?** PostgreSQL sait répliquer, mais la réplication seule ne décide pas qui devient Primary. Patroni et son magasin de consensus servent à orchestrer l'élection.

**Pourquoi HAProxy devant PostgreSQL ?** L'application pointe vers une adresse SQL stable tandis que le rôle de Primary peut passer d'AZ2 à AZ3. HAProxy interroge `/primary` pour cibler les écritures.

**Pourquoi Garage S3 ?** Pour partager les pièces jointes entre les trois applications et conserver plusieurs copies dans des zones différentes.

**Pourquoi Redis est un risque ?** Les trois applications dépendent d'un même service central : le perdre peut affecter l'ensemble du service, même si les AZ applicatives restent disponibles.

**Pourquoi la panne de zone ne garantit-elle pas zéro interruption ?** L'élection du nouveau Primary prend du temps, les connexions en cours peuvent être rompues et les clients doivent réessayer.

**Quel est le principal compromis ?** Le laboratoire démontre des mécanismes distribués et des scénarios de reprise, mais il reste dépendant d'un hôte physique et de services centraux.
