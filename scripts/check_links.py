#!/usr/bin/env python3
"""
check_links.py – Prüft externe Links in DITA-Dateien auf Erreichbarkeit.

Verwendung:
  python3 check_links.py --dita datei1.dita datei2.dita [--timeout 10] [--summary]

Rückgabewert:
  0 – Alle Links erreichbar (oder keine Links gefunden)
  0 – Auch bei defekten Links (Warnungen, kein Merge-Block)

Externe Links werden über das scope="external"-Attribut identifiziert.
"""

import argparse
import sys
import xml.etree.ElementTree as ET
import urllib.request
import urllib.error
import socket
from pathlib import Path


# ──────────────────────────────────────────────
# Argumente einlesen
# ──────────────────────────────────────────────

def parse_args():
    parser = argparse.ArgumentParser(
        description="Prüft externe Links in DITA-Dateien."
    )
    parser.add_argument(
        "--dita",
        nargs="+",
        required=True,
        help="Liste der zu prüfenden DITA-Dateien"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=10,
        help="Timeout in Sekunden pro Link (Standard: 10)"
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Zusammenfassung am Ende ausgeben"
    )
    return parser.parse_args()


# ──────────────────────────────────────────────
# Externe Links aus einer DITA-Datei extrahieren
# ──────────────────────────────────────────────

def extract_external_links(filepath):
    """
    Liest eine DITA-Datei und gibt alle externen Links zurück.
    Externe Links sind xref- oder link-Elemente mit scope="external"
    sowie href-Attribute, die mit http:// oder https:// beginnen.
    Gibt eine Liste von (url, zeile) zurück.
    """
    links = []

    try:
        tree = ET.parse(filepath)
        root = tree.getroot()
    except ET.ParseError as e:
        print(f"⚠️  XML-Fehler in {filepath}: {e}")
        return links

    # Alle Elemente mit href durchsuchen
    for elem in root.iter():
        href = elem.get("href", "")
        scope = elem.get("scope", "")

        # Externe Links: scope="external" oder href beginnt mit http/https
        if href.startswith("http://") or href.startswith("https://"):
            links.append(href)
        elif scope == "external" and href:
            # Relative externe Links (scope=external ohne http) ignorieren –
            # diese sind selten und ohne Kontext nicht prüfbar
            if href.startswith("http") or href.startswith("https"):
                links.append(href)

    # Duplikate entfernen, Reihenfolge beibehalten
    seen = set()
    unique_links = []
    for link in links:
        if link not in seen:
            seen.add(link)
            unique_links.append(link)

    return unique_links


# ──────────────────────────────────────────────
# Einen Link prüfen
# ──────────────────────────────────────────────

def check_link(url, timeout):
    """
    Prüft ob eine URL erreichbar ist.
    Gibt (ok, statuscode_oder_fehler) zurück.
    """
    try:
        req = urllib.request.Request(
            url,
            headers={
                # Einige Server blockieren Anfragen ohne User-Agent
                "User-Agent": "Mozilla/5.0 (DITA Link Checker)"
            },
            method="HEAD"  # HEAD statt GET: schneller, kein Body nötig
        )
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return True, str(response.status)

    except urllib.error.HTTPError as e:
        # HTTP-Fehler (404, 403 etc.)
        # 403 Forbidden kann auch bedeuten, dass der Server HEAD blockiert –
        # deshalb bei 403 zusätzlich GET versuchen
        if e.code == 403:
            return check_link_get(url, timeout)
        return False, f"HTTP {e.code}"

    except urllib.error.URLError as e:
        return False, f"URL-Fehler: {e.reason}"

    except socket.timeout:
        return False, f"Timeout nach {timeout}s"

    except Exception as e:
        return False, f"Fehler: {e}"


def check_link_get(url, timeout):
    """Fallback: GET-Anfrage wenn HEAD blockiert wird (HTTP 403)."""
    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "Mozilla/5.0 (DITA Link Checker)"}
        )
        with urllib.request.urlopen(req, timeout=timeout) as response:
            return True, str(response.status)
    except urllib.error.HTTPError as e:
        return False, f"HTTP {e.code}"
    except Exception as e:
        return False, f"Fehler: {e}"


# ──────────────────────────────────────────────
# Hauptprogramm
# ──────────────────────────────────────────────

def main():
    args = parse_args()

    gesamt_links = 0
    defekte_links = 0
    dateien_mit_fehlern = []

    for dateipfad in args.dita:
        pfad = Path(dateipfad)
        if not pfad.exists():
            print(f"⚠️  Datei nicht gefunden: {dateipfad}")
            continue

        links = extract_external_links(pfad)

        if not links:
            continue

        datei_hat_fehler = False

        for url in links:
            gesamt_links += 1
            ok, info = check_link(url, args.timeout)

            if ok:
                # OK-Links nur ausgeben wenn explizit gewünscht
                # (hier nicht, um Ausgabe kompakt zu halten)
                pass
            else:
                print(f"⚠️  {dateipfad}")
                print(f"   → Defekter Link: {url}")
                print(f"   → Ursache: {info}")
                defekte_links += 1
                datei_hat_fehler = True

        if datei_hat_fehler:
            dateien_mit_fehlern.append(str(dateipfad))

    # Zusammenfassung
    if args.summary:
        print()
        print("── Link-Prüfung Zusammenfassung ──────────────────")
        print(f"   Geprüfte Links:  {gesamt_links}")
        print(f"   Defekte Links:   {defekte_links}")
        if dateien_mit_fehlern:
            print(f"   Betroffene Dateien:")
            for d in dateien_mit_fehlern:
                print(f"     - {d}")
        print("──────────────────────────────────────────────────")

    if defekte_links > 0:
        print()
        print("⚠️  Link-Prüfung: Defekte Links gefunden (siehe oben).")
        print("   Diese Warnungen blockieren den Merge nicht.")
    elif gesamt_links > 0:
        print(f"✅ Link-Prüfung: Alle {gesamt_links} Links erreichbar.")
    else:
        print("✅ Link-Prüfung: Keine externen Links gefunden.")

    # Immer exit 0 – defekte Links sind Warnungen, kein Merge-Block
    sys.exit(0)


if __name__ == "__main__":
    main()
