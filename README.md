# kunde-xyz-shared

Shared Library fuer Kunde XYZ.
Wird in alle Produktrepos des Kunden als Git-Submodul eingebunden.

## Struktur
- warnings/ - Warnhinweise und Sicherheitshinweise (de-DE)
- notes/ - Standardhinweise (Tipps, Hinweise etc., de-DE)
- images/ - Kundenweit wiederverwendbare Bilder und Warnsymbole (sprachneutral)
- links/ - Kundenweit genutzte externe Links als Keys
- reuse/ - Wiederverwendbare Inhaltselemente und Variablen (de-DE)
- translations/ - Uebersetzungen der Inhalte (je Sprache: warnings, notes, reuse)

## Verwendung
Dieses Repository wird nicht direkt bearbeitet, sondern als
Git-Submodul in Produktrepos eingebunden (Ordner: shared/).
Aenderungen hier wirken sich auf alle eingebundenen Produktrepos aus.
