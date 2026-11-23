# Réseau, accès et ports

## Segmentation logique

| Zone | Subnet | Rôle |
|---|---|---|
| AZ1 | `10.97.0.0/24` | Applications et SQL zone 1 |
| AZ2 | `10.97.1.0/24` | Applications et SQL zone 2 |
| AZ3 | `10.97.2.0/24` | Applications et SQL zone 3 |

Ces adresses sont privées et propres au laboratoire. Le diagramme n'expose volontairement ni domaine public, ni clé, ni configuration VPN d'administration.

## Matrice de flux

| Flux | Port TCP | Observation |
|---|---:|---|
| Client privé → HAProxy HTTP | 8081 | Interface Vikunja |
| Application → HAProxy SQL | 5432 | Proxy de connexions PostgreSQL |
| HAProxy → Vikunja | 3456 | Répartition HTTP |
| HAProxy → Patroni REST | 8008 | Vérification `/primary` |
| Patroni / etcd | 2379 | Consensus |
| Vikunja → Garage local | 3900 | API S3 |
| Garage ↔ Garage | 3901 | RPC inter-nœuds |
| Vikunja → Redis | 6379 | État partagé |
| Poste admin → SSH Ubuntu | 22 | Tunnel privé via Tailscale |

**Sécurité :** ne publier aucun de ces services directement sur Internet. Privilégier le VPN, les règles de filtrage locales et un proxy TLS en entrée pour toute évolution au-delà du lab.

## Administration distante

Un routeur de sous-réseau Tailscale distinct de la VM Multi-AZ donne accès au réseau interne. Pendant la recette, SSH fonctionnait depuis le poste distant, mais le navigateur ne pouvait pas se connecter directement au port HTTP du laboratoire. Le contournement était un **tunnel SOCKS5 sur SSH** :

```bash
ssh -N -D 127.0.0.1:1080 -o ExitOnForwardFailure=yes USER@HOTE_PRIVE
```

Le navigateur utilise SOCKS5 `127.0.0.1:1080` et conserve l'URL applicative initiale. Cette solution n'ouvre pas le port 8081 au public.
