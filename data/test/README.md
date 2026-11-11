# Jeux de test

Fichiers **volontairement faux**, utilisés pour vérifier que les flux de rejets des jobs fonctionnent. Ils ne sont jamais chargés dans l'entrepôt : un job pointé sur eux doit envoyer les lignes concernées dans `audit.etl_rejets`.

Chaque fichier est dérivé d'un fichier réel du dépôt ; les altérations sont décrites ci-dessous.

| Fichier | Dérivé de | Altération | Effet attendu |
|---|---|---|---|
| `gouvernorat_district_sans_TN24.csv` | `data/reference/gouvernorat_district.csv` | Ligne de Siliana (`TN24`) supprimée | `TN24` rejeté par la jointure (`rejet_jointure`), motif « P-code absent de gouvernorat_district.csv » |
| `manifest_sha_invalide.csv` | `data/manifest_telechargements.csv` | Empreinte du fichier HDX remplacée par `empreinte-invalide-pour-test` | Les autres gouvernorats rejetés par les contrôles (`rejet_controle`), motif « Empreinte SHA-256 invalide » |
| `synonymes_geo_erreurs.csv` | `data/reference/synonymes_geo.csv` | Les 5 variantes réelles, plus 4 lignes fausses : « Le Kef » rattaché à TN24 (au lieu de TN23), un P-code inexistant (TN99), un type de libellé invalide, un libellé vide | J02 : 3 rejets de contrôle (P-code inconnu, type invalide, libellé vide) et 1 conflit (« le kef » déjà rattaché à TN23 par le nom officiel) ; les 53 synonymes corrects restent chargés |

Procédure et résultats : section « Test des flux de rejets » du guide de chaque job (`docs/guides/`).
