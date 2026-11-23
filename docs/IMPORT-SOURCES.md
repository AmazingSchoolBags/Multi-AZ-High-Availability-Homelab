# Import des scripts originaux Ubuntu

La documentation a été produite à partir des sorties et essais du laboratoire. L'intégration GitHub ne donne **pas directement accès à** `~/az-lab` sur le serveur Ubuntu.

Pour ajouter les configurations et scripts exacts :

1. Travailler dans un répertoire de staging dédié, **hors du répertoire de données actives**.
2. Examiner chaque `compose.yaml`, script shell et configuration HAProxy.
3. Remplacer identifiants, secrets, clés S3, hostnames et noms de domaines privés par des placeholders.
4. N'importer que les scripts réutilisables, avec prérequis et implications clairement décrits.
5. Exécuter `bash -n` et un scanner de secrets ; inspecter les changements avant commit.
6. Éviter `git add -A` depuis le répertoire de fonctionnement de l'application.

Les scripts d'injection de panne observés incluaient `test-garage-parallel.sh` et `test-failover-primary-az2.sh`. Ils ne sont **pas** copiés ici sans accès et audit du contenu exact. Ne jamais lancer ces tests sur une infrastructure de production.
