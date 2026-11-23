# Incident : HTTP 504 et timeouts Garage S3 sous panne AZ1

## Symptômes constatés

Lors de la panne simulée d'AZ1, des lectures de pièces jointes Vikunja ont produit **trois HTTP 504** après environ 60 s. Les nœuds Garage survivants mentionnaient des tentatives de connexion au nœud AZ1 indisponible.

Un test S3 direct a donné trois timeouts successifs depuis AZ2 (environ 13 s), suivis de trois lectures AZ3 réussies (environ 1 s). Ces opérations étaient **séquentielles** : AZ3 a été interrogée bien plus tard qu'AZ2.

## Contre-test

Le 23 novembre, les appels AZ2 et AZ3 ont été lancés **en parallèle**, immédiatement après arrêt AZ1 puis à 30 s et 75 s :

- AZ2 : 1 s, 1 s, 1 s, trois succès.
- AZ3 : 1 s, 1 s, 2 s, trois succès.
- Comparaison à la référence : fichiers identiques.
- Après la remise en ligne, **Garage 3/3 healthy et ResyncQueue=0**.

## Conclusion

La disponibilité du stockage pour **l'objet testé** a été démontrée sur le second essai. La cause racine des premiers échecs **n'a pas été établie**. Les logs sont compatibles avec une période de détection des peers indisponibles mais ne permettent pas de prouver cette hypothèse.

## Suite du diagnostic

1. Répéter plusieurs fois sur des objets de tailles différentes.
2. Synchroniser les horodatages HTTP, Garage RPC et client S3.
3. Mesurer la fréquence des requêtes en échec depuis chaque AZ, au même instant.
4. Tester lecture / téléchargement de pièces jointes pendant et non uniquement après la panne.
5. Vérifier que toutes les zones ont redémarré et que la réplication est saine après chaque essai.

Ne pas réduire arbitrairement les quorums Garage, supprimer les données ou simplement masquer les HTTP 504 avec des timeouts HAProxy plus longs.
