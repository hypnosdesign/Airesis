---
target: "G08 blogs, tags, documents, and content final"
total_score: 38
max_score: 40
na_heuristics:
p0_count: 0
p1_count: 0
timestamp: 2026-08-30T15-04-24Z
slug: app-views-blogs
---
# G08 finale — blog, tag, documenti e contenuti

## Esito

- Assessment A visuale/browser: 38/40.
- Assessment B tecnico dopo hardening: 39/40.
- Sintesi conservativa: **38/40 — Excellent**.
- P0: 0. P1: 0. P2: 0. Gate: PASS (`>=33/40`, P0=0, P1=0).
- Detector eseguito esattamente una volta in un solo processo sui sei source target: exit 0 e JSON `[]`; non è stato rilanciato dopo il follow-up tecnico.

## Nielsen

| # | Euristica | Score | Evidenza |
|---|---:|---:|---|
| 1 | Visibilità dello stato | 4/4 | Empty state, conteggi, storage, flash e failure 422 rendono esplicito lo stato corrente. |
| 2 | Corrispondenza col mondo reale | 4/4 | Blog, bozze, topic, discussione, visibilità e archivio documenti usano termini operativi chiari. |
| 3 | Controllo e libertà | 4/4 | Azioni owner visibili, cancel deterministico, conferma distruttiva progressiva e download esplicito. |
| 4 | Coerenza e standard | 4/4 | Page title, card, form, landmark e target touch seguono la shell moderna. |
| 5 | Prevenzione errori | 4/4 | Stati P/R/D validati, ri-autorizzazione commento, quota e path documenti protetti, conferme distruttive. |
| 6 | Riconoscimento anziché memoria | 4/4 | Ricerca etichettata, topic, archivio, attività e help dei tre stati sono visibili nel contesto. |
| 7 | Flessibilità ed efficienza | 3/4 | Directory, ricerca, tag, draft e accesso gruppo coprono percorsi diversi senza action fantasma. |
| 8 | Estetica e minimalismo | 3/4 | Gerarchia e densità sono controllate; restano solo due residui cosmetici P3 nel social/count copy. |
| 9 | Diagnosi e recupero errori | 4/4 | Form invalidi rendono 422, mutazioni riuscite 303 e i dati restano correggibili. |
| 10 | Aiuto e documentazione | 4/4 | Help editor, visibilità, gruppi, storage, upload ed empty state sono contestuali. |
| **Totale conservativo** |  | **38/40** | **Excellent / gate PASS** |

## Correzioni concluse

- Route G08 ridotte a 39, di cui 20 GET, senza azioni mancanti o CRUD fittizio.
- Rimossi gli asset/helper legacy che causavano 500 su blog e post autenticato; lettura guest/owner e commenti tornano operativi.
- Commento anonimo differito consumato e ri-autorizzato dopo login; create/destroy scoped con 422 HTML/Turbo e 303.
- Blog e post hanno stati validi, form espliciti, gestione owner nel main, pagination server-side e cancellazione mobile sicura.
- Tag e directory hanno landmark, H1, navigazione reale, topic attivi, empty state e copy leggibile.
- Archivio documenti nativo con upload, quota, listing, open/download/remove, GET senza write, controllo `realpath` dei symlink intermedi e contenuti attivi forzati in attachment.
- Skip link visibile al focus e trasferimento tastiera verificato fino a `main#main-content`; target primari e menu a 44 px.

## Evidenza

- Browser desktop e 390×844: un `main`/H1, zero overflow, pannello Delete interamente nel viewport e skip link 204×48 px.
- Chromium/ChromeDriver 151.0.7922.173 nel container Linux `aarch64`; Selenium esegue i flussi reali senza Selenium Manager.
- Suite G08 combinata: **72 esempi, 0 failure**, incluse request e system spec Selenium.
- RuboCop mirato: 19 file, 0 offense; build esbuild/Tailwind, YAML e `git diff --check` verdi.
- Route live: 39 totali, 20 GET e zero coppie controller/action mancanti.

Baseline: `.impeccable/critique/2026-08-30T13-58-52Z__app-views-blogs.md` (**14/40**). Trend conservativo: **14 → 38**.

Questions skipped: l'utente ha autorizzato remediation completa e chiusura G08; non restano decisioni di perimetro.
