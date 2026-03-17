# -*- coding: utf-8 -*-
#!/usr/bin/env python3
"""
SVRL-Parser: Extrahiert Fehler- und Warnmeldungen aus Saxon SVRL-Output.

Verwendung:
    python3 parse_svrl.py <svrl_datei> <modus>

    modus: 'fehler'    -> failed-assert Texte ausgeben
           'warnungen' -> successful-report Texte ausgeben

Speicherort: .github/scripts/parse_svrl.py
"""

import xml.etree.ElementTree as ET
import sys

NS = {'svrl': 'http://purl.oclc.org/dsdl/svrl'}


def parse_svrl(svrl_datei, modus):
    try:
        tree = ET.parse(svrl_datei)
        root = tree.getroot()

        if modus == 'fehler':
            elemente = root.findall('.//svrl:failed-assert/svrl:text', NS)
        elif modus == 'warnungen':
            elemente = root.findall('.//svrl:successful-report/svrl:text', NS)
        else:
            print('Unbekannter Modus: ' + modus, file=sys.stderr)
            sys.exit(1)

        for el in elemente:
            text = ' '.join((el.text or '').split())
            if text:
                print(text)

    except ET.ParseError as e:
        print('XML-Parse-Fehler: ' + str(e), file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print('Datei nicht gefunden: ' + svrl_datei, file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Verwendung: parse_svrl.py <svrl_datei> <fehler|warnungen>',
              file=sys.stderr)
        sys.exit(1)
    parse_svrl(sys.argv[1], sys.argv[2])
