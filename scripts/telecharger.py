"""Télécharge un fichier source dans data/raw/<source>/ et le consigne dans le manifeste.

Règles appliquées :
- un fichier déjà présent dans data/raw/ n'est jamais écrasé (données brutes intouchables) ;
- chaque téléchargement est tracé dans data/manifest_telechargements.csv
  (source, fichier, URL, date et heure UTC, taille, empreinte SHA-256) ;
- un fichier de plus de 10 Mo est ajouté au .gitignore : il n'est pas versionné,
  le manifeste suffit pour le retrouver et vérifier son intégrité.

Exemple :
    python scripts/telecharger.py hdx https://.../tun_admin_boundaries.xlsx
"""

import argparse
import csv
import hashlib
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote, urlparse

import requests

RACINE = Path(__file__).resolve().parent.parent
DOSSIER_RAW = RACINE / "data" / "raw"
MANIFESTE = RACINE / "data" / "manifest_telechargements.csv"
COLONNES = ["source", "fichier", "url", "telecharge_le_utc", "taille_octets", "sha256"]
USER_AGENT = "tunisia-regional-data-warehouse/0.1 (projet open data)"
GITIGNORE = RACINE / ".gitignore"
SEUIL_VERSIONNEMENT = 10 * 1024 * 1024  # 10 Mo


def exclure_du_versionnement(chemin: Path) -> None:
    entree = chemin.relative_to(RACINE).as_posix()
    lignes = GITIGNORE.read_text(encoding="utf-8").splitlines() if GITIGNORE.exists() else []
    if entree in lignes:
        return
    marqueur = "# Système"
    position = lignes.index(marqueur) if marqueur in lignes else len(lignes)
    # On insère juste avant la ligne vide qui précède la section « Système ».
    if position > 0 and lignes[position - 1] == "":
        position -= 1
    lignes.insert(position, entree)
    GITIGNORE.write_text("\n".join(lignes) + "\n", encoding="utf-8")
    print(f"Plus de 10 Mo : {entree} ajouté au .gitignore")


def nom_depuis_url(url: str) -> str:
    return unquote(Path(urlparse(url).path).name)


def telecharger(source: str, url: str, nom: str | None = None) -> Path:
    dossier = DOSSIER_RAW / source
    dossier.mkdir(parents=True, exist_ok=True)
    cible = dossier / (nom or nom_depuis_url(url))

    if cible.exists():
        print(f"Déjà présent, non retéléchargé : {cible.relative_to(RACINE)}")
        return cible

    temporaire = cible.with_suffix(cible.suffix + ".part")
    sha = hashlib.sha256()
    taille = 0
    with requests.get(url, stream=True, timeout=120, headers={"User-Agent": USER_AGENT}) as r:
        r.raise_for_status()
        with open(temporaire, "wb") as f:
            for bloc in r.iter_content(chunk_size=1 << 20):
                f.write(bloc)
                sha.update(bloc)
                taille += len(bloc)
    temporaire.rename(cible)

    nouveau = not MANIFESTE.exists()
    with open(MANIFESTE, "a", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=COLONNES)
        if nouveau:
            w.writeheader()
        w.writerow({
            "source": source,
            "fichier": cible.relative_to(RACINE).as_posix(),
            "url": url,
            "telecharge_le_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "taille_octets": taille,
            "sha256": sha.hexdigest(),
        })
    print(f"Téléchargé : {cible.relative_to(RACINE)} ({taille:,} octets)")
    if taille > SEUIL_VERSIONNEMENT:
        exclure_du_versionnement(cible)
    return cible


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("source", help="code de la source, devient le sous-dossier de data/raw/")
    p.add_argument("url")
    p.add_argument("--nom", help="nom du fichier local (par défaut : dernier segment de l'URL)")
    a = p.parse_args()
    telecharger(a.source, a.url, a.nom)
    return 0


if __name__ == "__main__":
    sys.exit(main())
