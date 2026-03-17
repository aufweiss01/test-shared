# -*- coding: utf-8 -*-
#!/usr/bin/env python3
"""
Terminologiepruefung: Prueft DITA-Dateien auf verbotene Begriffe
aus TBX-Terminologiedatenbanken.

Verwendung:
    python3 check_terminology.py \
        --dita   <datei.dita> [datei2.dita ...] \
        --tbx    <termbase.tbx> [termbase2.tbx ...] \
        --lang   <de-DE>         (Standard: de-DE) \
        --summary                (GitHub Job Summary ausgeben)

Rueckgabewert:
    0 - keine Verstoesse gefunden
    1 - mindestens ein Verstoss gefunden

Speicherort: .github/scripts/check_terminology.py

HINWEIS ZUR SPRACHPRUEFUNG:
    Aktuell wird die Sprache fest als Argument uebergeben (Standard: de-DE).
    TODO: Sprache aus xml:lang-Attribut des Topics auslesen,
    sobald die Sprachkennung zuverlaessig im Prolog gefuehrt wird.
"""

import xml.etree.ElementTree as ET
import sys
import os
import argparse

XML_LANG = '{http://www.w3.org/XML/1998/namespace}lang'


def lade_verbotene_begriffe(tbx_dateien, sprache):
    """Liest deprecatedTerm-Eintraege aus TBX-Dateien fuer die angegebene Sprache."""
    verboten = []
    for tbx_datei in tbx_dateien:
        if not os.path.isfile(tbx_datei):
            continue
        try:
            tree = ET.parse(tbx_datei)
            root = tree.getroot()
            for lang_sec in root.findall('.//langSec'):
                if lang_sec.get(XML_LANG) == sprache:
                    for term_sec in lang_sec.findall('termSec'):
                        term_note = term_sec.find('termNote[@type="termType"]')
                        term = term_sec.find('term')
                        if (term_note is not None and
                                term_note.text == 'deprecatedTerm' and
                                term is not None and
                                term.text):
                            verboten.append(term.text.strip())
        except ET.ParseError as e:
            print('TBX-Parse-Fehler in ' + tbx_datei + ': ' + str(e),
                  file=sys.stderr)
    return verboten


def pruefe_dita_datei(dita_datei, verbotene_begriffe):
    """Prueft eine DITA-Datei auf verbotene Begriffe im Textinhalt."""
    try:
        tree = ET.parse(dita_datei)
        root = tree.getroot()
        text = ' '.join(root.itertext())
        gefunden = [b for b in verbotene_begriffe if b in text]
        return gefunden
    except ET.ParseError as e:
        print('DITA-Parse-Fehler in ' + dita_datei + ': ' + str(e),
              file=sys.stderr)
        return []


def main():
    parser = argparse.ArgumentParser(
        description='Terminologiepruefung fuer DITA-Dateien gegen TBX-Datenbanken')
    parser.add_argument('--dita',    nargs='+', required=True,
                        help='DITA-Dateien zum Pruefen')
    parser.add_argument('--tbx',     nargs='+', required=True,
                        help='TBX-Terminologiedatenbanken')
    parser.add_argument('--lang',    default='de-DE',
                        help='Sprache der zu pruefenden Begriffe (Standard: de-DE)')
    parser.add_argument('--summary', action='store_true',
                        help='GitHub Job Summary ausgeben')
    args = parser.parse_args()

    verbotene_begriffe = lade_verbotene_begriffe(args.tbx, args.lang)

    if not verbotene_begriffe:
        print('Keine verbotenen Begriffe in TBX-Dateien gefunden '
              '(Sprache: ' + args.lang + ').')
        return 0

    verstoesse_gesamt = 0
    summary_zeilen = []

    for dita_datei in args.dita:
        if not dita_datei.endswith('.dita'):
            continue
        if not os.path.isfile(dita_datei):
            continue

        gefunden = pruefe_dita_datei(dita_datei, verbotene_begriffe)

        if gefunden:
            print('')
            print('Warnung: ' + dita_datei)
            for begriff in gefunden:
                print('   -> Verbotener Begriff: "' + begriff + '"')
                print('      Bitte Vorzugsbenennung aus Terminologiedatenbank verwenden.')
            summary_zeilen.append(
                '| `' + dita_datei + '` | ⚠️ ' + ', '.join(gefunden) + ' |')
            verstoesse_gesamt += 1
        else:
            print('OK: ' + dita_datei)
            summary_zeilen.append('| `' + dita_datei + '` | ✅ OK |')

    # GitHub Job Summary
    if args.summary:
        summary_datei = os.environ.get('GITHUB_STEP_SUMMARY', '')
        if summary_datei:
            with open(summary_datei, 'a', encoding='utf-8') as f:
                f.write('\n## Terminologiepruefung\n\n')
                f.write('| Datei | Ergebnis |\n')
                f.write('|-------|----------|\n')
                for zeile in summary_zeilen:
                    f.write(zeile + '\n')
                if verstoesse_gesamt > 0:
                    f.write('\n> Warnung: **' + str(verstoesse_gesamt) +
                            ' Datei(en) mit verbotenen Begriffen.**\n')
                else:
                    f.write('\n> OK: **Keine verbotenen Begriffe gefunden.**\n')

    if verstoesse_gesamt > 0:
        print('')
        print('Warnung: Terminologiepruefung: ' + str(verstoesse_gesamt) +
              ' Datei(en) mit verbotenen Begriffen.')
        print('Verstoesse sind Warnungen - kein Merge-Block.')
        return 1

    print('')
    print('OK: Terminologiepruefung erfolgreich.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
