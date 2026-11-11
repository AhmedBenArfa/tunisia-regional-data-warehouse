"""Génère la version PDF de la documentation à partir des fichiers Markdown.

Les fichiers Markdown restent la source : ils sont lus sur GitHub et modifiés au
fil du projet. Ce script en produit une copie PDF, mise en page pour l'impression
et le partage, dans docs/pdf/.

Chaîne : Markdown -> HTML (bibliothèque markdown) -> PDF (navigateur Edge ou
Chrome en mode sans interface, fonction « imprimer en PDF »).

Usage :
    python scripts/generer_pdf.py              # toute la documentation
    python scripts/generer_pdf.py docs/guides/02_job_J01_referentiel_geo.md
"""

from __future__ import annotations

import argparse
import html
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import date
from pathlib import Path

import markdown

RACINE = Path(__file__).resolve().parent.parent
SORTIE = RACINE / "docs" / "pdf"

# Ordre de lecture : les guides d'abord, puis les documents de référence.
SOURCES = [
    "docs/guides/01_mise_en_place.md",
    "docs/guides/02_job_J01_referentiel_geo.md",
    "docs/guides/03_job_J02_synonymes.md",
    "docs/architecture.md",
    "docs/sources.md",
    "docs/decisions.md",
]

NAVIGATEURS = [
    Path(r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
    Path(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"),
    Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
]

FEUILLE_DE_STYLE = """
@page {
  size: A4;
  margin: 18mm 16mm 20mm 16mm;
  @bottom-left  { content: "Observatoire des disparités régionales en Tunisie"; font: 8pt 'Segoe UI', sans-serif; color: #888; }
  @bottom-right { content: counter(page) " / " counter(pages); font: 8pt 'Segoe UI', sans-serif; color: #888; }
}
html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
body { font-family: 'Segoe UI', 'Noto Sans', Arial, sans-serif; font-size: 10pt; line-height: 1.5; color: #1f2328; }
h1 { font-size: 20pt; color: #0b3d5c; border-bottom: 3px solid #c8102e; padding-bottom: 6px; margin: 0 0 10px; }
h2 { font-size: 14pt; color: #0b3d5c; border-bottom: 1px solid #d0d7de; padding-bottom: 3px; margin-top: 22px; break-after: avoid; }
h3 { font-size: 11.5pt; color: #0b3d5c; margin-top: 16px; break-after: avoid; }
p, li { orphans: 3; widows: 3; }
a { color: #0b5cad; text-decoration: none; }
code { font-family: Consolas, 'Cascadia Mono', monospace; font-size: 8.8pt; background: #f2f4f7; padding: 1px 4px; border-radius: 3px; }
pre { background: #f6f8fa; border: 1px solid #d0d7de; border-left: 4px solid #0b3d5c; border-radius: 4px; padding: 8px 10px; white-space: pre-wrap; word-break: break-word; break-inside: avoid; }
pre code { background: none; padding: 0; font-size: 8.5pt; }
table { border-collapse: collapse; width: 100%; margin: 8px 0 12px; font-size: 8.8pt; break-inside: auto; }
thead { display: table-header-group; }
tr { break-inside: avoid; }
th { background: #0b3d5c; color: #fff; text-align: left; padding: 5px 7px; }
td { border: 1px solid #d0d7de; padding: 4px 7px; vertical-align: top; }
tbody tr:nth-child(even) td { background: #f6f8fa; }
blockquote { margin: 8px 0; padding: 4px 12px; border-left: 4px solid #c8102e; background: #fdf3f4; color: #444; }
img { max-width: 100%; border: 1px solid #d0d7de; border-radius: 4px; margin: 6px 0; break-inside: avoid; }
p em { color: #555; }
hr { border: none; border-top: 1px solid #d0d7de; margin: 14px 0; }
.genere { font-size: 8pt; color: #888; margin-top: 24px; border-top: 1px solid #d0d7de; padding-top: 4px; }
"""


def trouver_navigateur() -> Path:
    for chemin in NAVIGATEURS:
        if chemin.exists():
            return chemin
    for nom in ("msedge", "chrome", "chromium"):
        trouve = shutil.which(nom)
        if trouve:
            return Path(trouve)
    sys.exit("Aucun navigateur Edge ou Chrome trouvé : impossible d'imprimer en PDF.")


def liens_vers_pdf(contenu_html: str) -> str:
    """Les liens vers un autre document Markdown pointent vers sa version PDF (même dossier)."""
    def remplacer(m: re.Match) -> str:
        cible = m.group(1)
        if cible.startswith(("http://", "https://")):
            return m.group(0)
        nom, _, ancre = cible.partition("#")
        nouveau = Path(nom).stem + ".pdf" + (f"#{ancre}" if ancre else "")
        return f'href="{nouveau}"'
    return re.sub(r'href="([^"]+?\.md(?:#[^"]*)?)"', remplacer, contenu_html)


def images_absolues(contenu_html: str, dossier: Path) -> str:
    """La page HTML est imprimée depuis un dossier temporaire : les images sont référencées par leur chemin absolu."""
    def remplacer(m: re.Match) -> str:
        cible = m.group(1)
        if cible.startswith(("http://", "https://", "data:", "file:")):
            return m.group(0)
        return f'src="{(dossier / cible).resolve().as_uri()}"'
    return re.sub(r'src="([^"]+)"', remplacer, contenu_html)


def vers_html(source: Path) -> str:
    texte = source.read_text(encoding="utf-8")
    titre = next((l[2:].strip() for l in texte.splitlines() if l.startswith("# ")), source.stem)
    titre = re.sub(r"[`*]", "", titre)
    corps = markdown.markdown(texte, extensions=["tables", "fenced_code", "sane_lists"], output_format="html5")
    corps = liens_vers_pdf(corps)
    corps = images_absolues(corps, source.parent)
    relatif = source.relative_to(RACINE).as_posix()
    pied = f'<p class="genere">Version PDF de <code>{html.escape(relatif)}</code>, générée le {date.today():%d/%m/%Y}.</p>'
    return (
        "<!doctype html><html lang=\"fr\"><head><meta charset=\"utf-8\">"
        f"<title>{html.escape(titre)}</title><meta name=\"author\" content=\"Ahmed Ben Arfa\">"
        f"<style>{FEUILLE_DE_STYLE}</style></head><body>{corps}{pied}</body></html>"
    )


def imprimer(navigateur: Path, page_html: Path, pdf: Path, profil: Path) -> None:
    commande = [
        str(navigateur), "--headless=new", "--disable-gpu", "--no-first-run",
        "--no-pdf-header-footer", f"--user-data-dir={profil}",
        f"--print-to-pdf={pdf}", page_html.as_uri(),
    ]
    subprocess.run(commande, check=True, capture_output=True, timeout=120)
    if not pdf.exists() or pdf.stat().st_size == 0:
        sys.exit(f"Échec de l'impression : {pdf}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("fichiers", nargs="*", help="fichiers Markdown à convertir (par défaut : toute la documentation)")
    args = parser.parse_args()

    sources = [Path(f).resolve() for f in args.fichiers] or [RACINE / s for s in SOURCES]
    navigateur = trouver_navigateur()
    SORTIE.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for source in sources:
            page = tmp / (source.stem + ".html")
            page.write_text(vers_html(source), encoding="utf-8")
            pdf = SORTIE / (source.stem + ".pdf")
            imprimer(navigateur, page, pdf, tmp / "profil")
            print(f"{source.relative_to(RACINE).as_posix()} -> {pdf.relative_to(RACINE).as_posix()} ({pdf.stat().st_size // 1024} Ko)")


if __name__ == "__main__":
    main()
