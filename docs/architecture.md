# Architecture

## Chaîne de traitement

```
Sources brutes (PDF, XLSX, API)
        │
        ├─ scripts Python : téléchargement, extraction des tableaux PDF en CSV
        ▼
data/raw/ (intouchable)  →  data/extracted/ (CSV issus des PDF)
        │
        ▼
Talend Open Studio : nettoyage, référentiel géographique, contrôles qualité, orchestration
        │
        ▼
PostgreSQL : schémas staging → dwh (schéma en étoile) + audit
        │
        ▼
Power BI : carte, indice composite, côte / intérieur, tourisme, comparaison avec l'IDR
```

## Environnement

Relevé le 9 novembre 2026.

| Composant | Version | Emplacement |
|---|---|---|
| Système | Windows 11 Professionnel (10.0.26200) | |
| Talend Open Studio for Data Integration | 8.0.1 (build 20211109_1610) | `C:\talend` |
| Java | JDK 17.0.12 | `C:\Program Files\Java\jdk-17` |
| PostgreSQL | 18.1 (service `postgresql-x64-18`, démarrage automatique) | `C:\Program Files\PostgreSQL\18` |
| Pilote JDBC PostgreSQL | pgJDBC | `C:\Program Files (x86)\PostgreSQL\pgJDBC` |
| Python | 3.13 | environnement virtuel `.venv/` du dépôt |
| Power BI Desktop | installé | `C:\Program Files\Microsoft Power BI Desktop` |
| Git | installé | |

## Configuration

Un seul fichier de configuration locale, `.env`, à la racine du dépôt. Il est ignoré par git ; le modèle versionné est `.env.example`. Il est lu par :

- **psql** et les scripts Python : les variables `PG*` sont les variables standard de PostgreSQL (libpq) ;
- **Talend** : chargement implicite du contexte (paramètres du projet, *Implicit tContextLoad*, « From File », séparateur `=`), fichier lu au lancement de chaque job. Les variables de contexte portent les mêmes noms que les clés du fichier.

Le fichier ne contient que des lignes `CLE=valeur`, sans commentaire.

| Clé | Groupe de contexte Talend | Rôle |
|---|---|---|
| `PGHOST`, `PGPORT`, `PGDATABASE` | `ctx_dwh` | Serveur et base PostgreSQL |
| `PGUSER`, `PGPASSWORD` | `ctx_dwh` | Utilisateur applicatif `dwh_user` (décision D-006) |
| `PGSCHEMA`, `PGPARAMS` | `ctx_dwh` | Vides. Exigés par la connexion Talend en mode contexte ; le schéma est choisi dans chaque composant (`staging`, `dwh`, `audit`) |
| `RACINE_PROJET` | `ctx_chemins` | Chemin absolu du dépôt, base de tous les chemins de fichiers des jobs |

### Projet Talend

- Projet `TUNISIA_DWH`, environnement de contexte `DEV`.
- Deux groupes de contexte : `ctx_dwh` (connexion, 7 variables) et `ctx_chemins` (chemins). La connexion du référentiel ne peut être reliée qu'à un groupe dont chaque variable correspond à l'un de ses champs, d'où la séparation.
- Connexion du référentiel `cnx_tunisia_dwh` (PostgreSQL, « v9 and later ») : tous ses champs pointent vers `ctx_dwh` (`context.PGHOST`, etc.).
- Dans le projet Talend, la valeur de `PGPASSWORD` est **vide** : le mot de passe n'est lu que dans `.env`, au lancement. Il n'apparaît donc pas dans les exports de jobs.

Remarque : Talend Open Studio n'est plus maintenu depuis janvier 2024. La version 8.0.1 reste utilisable pour ce projet ; des pistes de migration sont présentées dans le README.
