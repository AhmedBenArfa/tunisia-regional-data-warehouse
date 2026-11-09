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

Remarque : Talend Open Studio n'est plus maintenu depuis janvier 2024. La version 8.0.1 reste utilisable pour ce projet ; des pistes de migration sont présentées dans le README.
