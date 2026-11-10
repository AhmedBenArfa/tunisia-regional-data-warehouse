# Jeux de test

Fichiers **volontairement faux**, utilisés pour vérifier que les flux de rejets des jobs fonctionnent. Ils ne sont jamais chargés dans l'entrepôt : un job pointé sur eux doit envoyer les lignes concernées dans `audit.etl_rejets`.

Chaque fichier est dérivé d'un fichier réel du dépôt, avec une seule altération documentée ci-dessous.

| Fichier | Dérivé de | Altération | Effet attendu dans J01 |
|---|---|---|---|
| `gouvernorat_district_sans_TN24.csv` | `data/reference/gouvernorat_district.csv` | Ligne de Siliana (`TN24`) supprimée | `TN24` rejeté par la jointure (`rejet_jointure`), motif « P-code absent de gouvernorat_district.csv » |
| `manifest_sha_invalide.csv` | `data/manifest_telechargements.csv` | Empreinte du fichier HDX remplacée par `empreinte-invalide-pour-test` | Les autres gouvernorats rejetés par les contrôles (`rejet_controle`), motif « Empreinte SHA-256 invalide » |

Procédure et résultats : `docs/guides/02_job_J01_referentiel_geo.md`, section « Test des flux de rejets ».
