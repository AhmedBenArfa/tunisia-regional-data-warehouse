"""Normalisation des libellés géographiques : copie Python de la routine Talend Libelles.normaliser.

Sert aux contrôles hors Talend : vérifier qu'un libellé observé dans une source trouve
son gouvernorat, et comparer le résultat du job J02 à un calcul indépendant.
Les deux implémentations doivent rester identiques (décision D-012).

Usage :
    python scripts/normaliser_libelle.py "l’Ariana" "Kébili" "سليانـــة"
"""

from __future__ import annotations

import re
import sys
import unicodedata

TATWEEL = "\u0640"
ALEF_MAQSURA, YEH = "\u0649", "\u064A"
TEH_MARBUTA, HEH = "\u0629", "\u0647"
PONCTUATION = re.compile("[!-/:-@\\[-`{-~\u2018\u2019\u2013\u2014\u00A0]")  # ponctuation ASCII, apostrophes et tirets typographiques, espace insécable


def normaliser(libelle: str | None) -> str | None:
    if libelle is None:
        return None
    s = unicodedata.normalize("NFD", libelle)
    s = "".join(c for c in s if not unicodedata.category(c).startswith("M"))  # accents, hamza, voyelles arabes
    s = s.replace(TATWEEL, "")
    s = s.replace(ALEF_MAQSURA, YEH).replace(TEH_MARBUTA, HEH)
    s = s.lower()
    s = PONCTUATION.sub(" ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s or None


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    for arg in sys.argv[1:]:
        print(f"{arg!r} -> {normaliser(arg)!r}")
