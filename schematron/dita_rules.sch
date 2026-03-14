<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">

  <sch:title>DITA Metadaten-Validierung – Kernmodell v1.1</sch:title>

  <!--
    Speicherort: shared/schematron/dita_rules.sch
    Stand:       2026-03-14  |  Version: 1.0

    ZWECK
    =====
    Prüft Pflichtfelder, Wertelisten und Abhängigkeiten im DITA-Prolog.
    Wird ausgeführt:
      - lokal per Pre-commit Hook
      - serverseitig per GitHub Actions (AP 3)

    WERTELISTEN
    ===========
    Alle erlaubten Werte sind als Variablen am Anfang dieser Datei
    definiert. Kundenspezifische Anpassungen nur hier vornehmen –
    nicht in einzelnen Regeln unten.

    PROJEKTSPEZIFISCHE ANPASSUNG
    =============================
    Diese Datei liegt im Shared-Repo und gilt für alle Projekte
    dieses Kunden. Bei Bedarf die Variablen im Abschnitt
    "KONFIGURATION – WERTELISTEN" anpassen.

    TODO: Wenn oXygen als Haupt-Editor eingeführt wird, prüfen ob
    die Wertelisten stattdessen aus einer Subject Scheme Map per
    doc() ausgelesen werden können (eine einzige Pflegestelle).
  -->

  <!-- ============================================================
       KONFIGURATION – WERTELISTEN
       Alle Anpassungen pro Kunde / Projekt hier vornehmen.
       ============================================================ -->

  <!-- audience/@type -->
  <sch:let name="audience-type-values"
           value="('user', 'servicepersonnel', 'administrator')"/>

  <!-- audience/@job -->
  <sch:let name="audience-job-values"
           value="('operating', 'maintaining', 'installing',
                   'programming', 'troubleshooting', 'other')"/>

  <!-- audience/@experiencelevel -->
  <sch:let name="audience-experiencelevel-values"
           value="('novice', 'general', 'expert')"/>

  <!-- othermeta[@name='lifecycle-stage'] -->
  <sch:let name="lifecycle-stage-values"
           value="('installation', 'commissioning', 'operation',
                   'maintenance', 'decommissioning')"/>

  <!-- othermeta[@name='status'] -->
  <sch:let name="status-values"
           value="('draft', 'in-review', 'approved',
                   'outdated', 'deprecated')"/>

  <!-- othermeta[@name='translation-status'] -->
  <sch:let name="translation-status-values"
           value="('translation-requested', 'in-translation',
                   'translation-review', 'translation-approved',
                   'outdated')"/>

  <!-- prodinfo/prodname
       Erlaubte Produktnamen als direkte Werte (kein keyref möglich).
       Bei neuem Projekt: Werte hier ergänzen oder ersetzen. -->
  <sch:let name="prodname-values"
           value="('Optiscope X200', 'Optiscope A800')"/>

  <!-- @product (DITAVAL-Filterattribut)
       Erlaubte Werte für das product-Attribut an beliebigen Elementen.
       Bei neuem Projekt: Werte hier ergänzen oder ersetzen. -->
  <sch:let name="product-values"
           value="('optiscope_x200', 'optiscope_a800')"/>


  <!-- ============================================================
       REGEL 1: Pflichtfelder im Topic-Prolog
       Jedes Topic muss 'status' und 'audience' enthalten.
       ============================================================ -->
  <sch:pattern id="pflichtfelder">
    <sch:title>Pflichtfelder im Topic-Prolog</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]/prolog/metadata">

      <sch:assert test="othermeta[@name='status']"
                  role="error">
        FEHLER: Pflichtfeld fehlt – &lt;othermeta name="status"&gt; muss im Prolog vorhanden sein.
        Standardwert beim Anlegen: content="draft"
      </sch:assert>

      <sch:assert test="audience"
                  role="error">
        FEHLER: Pflichtfeld fehlt – &lt;audience&gt; muss im Prolog vorhanden sein.
      </sch:assert>

    </sch:rule>
  </sch:pattern>


  <!-- ============================================================
       REGEL 2: Werteliste audience/@type
       ============================================================ -->
  <sch:pattern id="audience-type">
    <sch:title>Erlaubte Werte für audience/@type</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]//audience[@type]">

      <sch:assert test="@type = $audience-type-values"
                  role="error">
        FEHLER: Ungültiger Wert für audience/@type: "<sch:value-of select="@type"/>".
        Erlaubte Werte: <sch:value-of select="string-join($audience-type-values, ', ')"/>
      </sch:assert>

    </sch:rule>
  </sch:pattern>


  <!-- ============================================================
       REGEL 3: Werteliste audience/@job
       ============================================================ -->
  <sch:pattern id="audience-job">
    <sch:title>Erlaubte Werte für audience/@job</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]//audience[@job]">

      <sch:assert test="@job = $audience-job-values"
                  role="error">
        FEHLER: Ungültiger Wert für audience/@job: "<sch:value-of select="@job"/>".
        Erlaubte Werte: <sch:value-of select="string-join($audience-job-values, ', ')"/>
      </sch:assert>

    </sch:rule>
  </sch:pattern>


  <!-- ============================================================
       REGEL 4: Werteliste audience/@experiencelevel
       ============================================================ -->
  <sch:pattern id="audience-experiencelevel">
    <sch:title>Erlaubte Werte für audience/@experiencelevel</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]//audience[@experiencelevel]">

      <sch:assert test="@experiencelevel = $audience-experiencelevel-values"
                  role="error">
        FEHLER: Ungültiger Wert für audience/@experiencelevel: "<sch:value-of select="@experiencelevel"/>".
        Erlaubte Werte: <sch:value-of select="string-join($audience-experiencelevel-values, ', ')"/>
      </sch:assert>

    </sch:rule>
  </sch:pattern>


  <!-- ============================================================
       REGEL 5: Werteliste lifecycle-stage
       Mehrfachwerte sind leerzeichen-getrennt möglich,
       z.B. content="installation commissioning".
       Jeder Einzelwert wird separat geprüft.
       ============================================================ -->
  <sch:pattern id="lifecycle-stage">
    <sch:title>Erlaubte Werte für lifecycle-stage</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]
                        //othermeta[@name='lifecycle-stage'][@content != '']">

      <sch:let name="einzelwerte"
               value="tokenize(normalize-space(@content), '\s+')"/>

      <sch:assert test="every $wert in $einzelwerte
                        satisfies $wert = $lifecycle-stage-values"
                  role="error">
        FEHLER: Ungültiger Wert in lifecycle-stage: "<sch:value-of select="@content"/>".
        Erlaubte Werte: <sch:value-of select="string-join($lifecycle-stage-values, ', ')"/>
        Mehrfachwerte leerzeichen-getrennt möglich, z.B. "installation commissioning".
      </sch:assert>

    </sch:rule>
  </sch:pattern>


  <!-- ============================================================
       REGEL 6: Werteliste status
       ============================================================ -->
  <sch:pattern id="status-werte">
    <sch:title>Erlaubte Werte für status</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]
                        //othermeta[@name='status']">

      <sch:assert test="@content = $status-values"
                  role="error">
        FEHLER: Ungültiger Wert für status: "<sch:value-of select="@content"/>".
        Erlaubte Werte: <sch:value-of select="string-join($status-values, ', ')"/>
      </sch:assert>

    </sch:rule>
  </sch:pattern>


  <!-- ============================================================
       REGEL 7: Werteliste translation-status
       ============================================================ -->
  <sch:pattern id="translation-status-werte">
    <sch:title>Erlaubte Werte für translation-status</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]
                        //othermeta[@name='translation-status']">

      <sch:assert test="@content = $translation-status-values"
                  role="error">
        FEHLER: Ungültiger Wert für translation-status: "<sch:value-of select="@content"/>".
        Erlaubte Werte: <sch:value-of select="string-join($translation-status-values, ', ')"/>
      </sch:assert>

    </sch:rule>
  </sch:pattern>


  <!-- ============================================================
       REGEL 8: translation-status nur in translations/
       Das Feld darf nie im Ausgangsmodul unter docs/ stehen.
       Geprüft wird anhand des Dateipfads (@xtrf).
       ============================================================ -->
  <sch:pattern id="translation-status-pfad">
    <sch:title>translation-status nur in translations/</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]
                        //othermeta[@name='translation-status']">

      <sch:assert test="contains(base-uri(.), '/translations/')"
                  role="error">
        FEHLER: &lt;othermeta name="translation-status"&gt; darf nur in
        translations/[lang]/ stehen – nie im Ausgangsmodul unter docs/.
        Gefunden in: <sch:value-of select="base-uri(.)"/>
      </sch:assert>

    </sch:rule>
  </sch:pattern>


  <!-- ============================================================
       REGEL 9: Abhängigkeit translation-status → status=approved
       Ein übersetztes Topic darf translation-status nur dann
       enthalten, wenn das zugehörige Ausgangsmodul approved ist.

       HINWEIS: Diese Regel setzt voraus, dass das Ausgangsmodul
       unter dem gleichen relativen Pfad in docs/ liegt wie das
       übersetzte Topic in translations/[lang]/.
       Beispiel:
         Ausgangsmodul: docs/tasks/t_beispiel.dita
         Übersetzung:   translations/en-GB/tasks/t_beispiel.dita
       ============================================================ -->
  <sch:pattern id="translation-bedingt-approved">
    <sch:title>translation-status setzt status=approved im Ausgangsmodul voraus</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]
                        //othermeta[@name='translation-status']
                        [@content = ('translation-requested',
                                     'in-translation',
                                     'translation-review',
                                     'translation-approved')]">

      <!-- Pfad des Ausgangsmoduls rekonstruieren:
           .../translations/en-GB/tasks/t_beispiel.dita
           →  .../docs/tasks/t_beispiel.dita                -->
      <sch:let name="aktueller-pfad"  value="base-uri(.)"/>
      <sch:let name="ausgangs-pfad"
               value="replace($aktueller-pfad,
                               '/translations/[^/]+/',
                               '/docs/')"/>
      <sch:let name="ausgangs-status"
               value="if (doc-available($ausgangs-pfad))
                      then doc($ausgangs-pfad)
                           //*[contains(@class,' topic/topic ')]
                           //othermeta[@name='status']/@content
                      else 'DATEI_NICHT_GEFUNDEN'"/>

      <sch:assert test="$ausgangs-status = 'approved'"
                  role="error">
        FEHLER: translation-status ist gesetzt, aber das Ausgangsmodul
        hat nicht den Status "approved".
        Ausgangsmodul: <sch:value-of select="$ausgangs-pfad"/>
        Status dort:   <sch:value-of select="$ausgangs-status"/>
        Übersetzung darf erst beginnen, wenn status="approved" gesetzt ist.
      </sch:assert>

    </sch:rule>
  </sch:pattern>


  <!-- ============================================================
       REGEL 10: Werteliste prodname
       <prodname> muss einen definierten Produktnamen enthalten.
       Notwendig weil keyref auf <prodname> nicht DTD-konform ist
       und der Wert daher nicht automatisch validiert wird.
       ============================================================ -->
  <sch:pattern id="prodname-werte">
    <sch:title>Erlaubte Werte für prodname</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]
                        //prodinfo/prodname">

      <sch:assert test="normalize-space(.) = $prodname-values"
                  role="error">
        FEHLER: Ungültiger Produktname in &lt;prodname&gt;: "<sch:value-of select="normalize-space(.)"/>".
        Erlaubte Werte: <sch:value-of select="string-join($prodname-values, ', ')"/>
        Neuen Produktnamen in der Variablen $prodname-values am Anfang dieser Datei eintragen.
      </sch:assert>

    </sch:rule>
  </sch:pattern>


  <!-- ============================================================
       REGEL 11: Werteliste @product (DITAVAL-Filterattribut)
       Das product-Attribut darf nur definierte Werte enthalten.
       Mehrfachwerte sind leerzeichen-getrennt möglich,
       z.B. product="optiscope_x200 optiscope_a800".
       Jeder Einzelwert wird separat geprüft.
       ============================================================ -->
  <sch:pattern id="product-attribut-werte">
    <sch:title>Erlaubte Werte für @product (DITAVAL)</sch:title>

    <sch:rule context="*[contains(@class, ' topic/topic ')]
                        //*[@product and @product != '']">

      <sch:let name="einzelwerte"
               value="tokenize(normalize-space(@product), '\s+')"/>

      <sch:assert test="every $wert in $einzelwerte
                        satisfies $wert = $product-values"
                  role="error">
        FEHLER: Ungültiger Wert im product-Attribut: "<sch:value-of select="@product"/>".
        Erlaubte Werte: <sch:value-of select="string-join($product-values, ', ')"/>
        Neuen Wert in der Variablen $product-values am Anfang dieser Datei eintragen.
      </sch:assert>

    </sch:rule>
  </sch:pattern>

</sch:schema>
