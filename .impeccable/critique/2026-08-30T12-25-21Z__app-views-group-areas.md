---
target: "G06 governance groups: areas, roles, permissions final"
total_score: 33
max_score: 40
na_heuristics:
p0_count: 0
p1_count: 0
timestamp: 2026-08-30T12-25-21Z
slug: app-views-group-areas
---
# G06 finale — governance: aree, ruoli e permessi

## Esito

- Assessment A visuale: 33/40.
- Assessment B tecnico: 35/40.
- Sintesi conservativa: **33/40 — Good**.
- P0: 0. P1: 0. Gate: PASS (`>=33/40`, P0=0, P1=0).
- Detector finale eseguito una sola volta sul perimetro esatto: exit 0, JSON `[]`; non rilanciato dopo il follow-up visuale.

## Nielsen

| # | Euristica | Score | Evidenza |
|---|---:|---:|---|
| 1 | Visibilità dello stato | 3/4 | Salvataggi espliciti, flash contestuali e risposte Turbo/HTML coerenti. |
| 2 | Corrispondenza col mondo reale | 4/4 | Aree, ruoli, membri, default e permessi usano terminologia operativa chiara. |
| 3 | Controllo e libertà | 4/4 | Cancel deterministico, breadcrumb, conferme distruttive, Esc e focus restore. |
| 4 | Coerenza e standard | 3/4 | Pattern condivisi tra ruoli di gruppo e area; label e azioni uniformi. |
| 5 | Prevenzione errori | 4/4 | Scope server-side, outsider respinti e ruoli default protetti. |
| 6 | Riconoscimento anziché memoria | 3/4 | Nomi completi, badge default, conteggi e associazione univoca label/input. |
| 7 | Flessibilità ed efficienza | 3/4 | Disclosure per ruolo e salvataggio per matrice senza perdere il contesto. |
| 8 | Estetica e minimalismo | 3/4 | Gerarchia pulita, righe responsive e densità controllata. |
| 9 | Diagnosi e recupero errori | 3/4 | Errori 422 preservano i form in HTML e Turbo. |
| 10 | Aiuto e documentazione | 3/4 | Copy contestuale su default, permessi e azioni; help avanzato non presente. |
| **Totale conservativo** |  | **33/40** | **Good / gate PASS** |

## Correzioni concluse

- Route ridotte da 33 a 26, con 9 GET e nessuna action fantasma.
- Salvataggi espliciti per permessi di gruppo e area; ability allineata a `change_permissions`.
- Scope tenant-safe per like, membership, partecipazioni e ruoli di area.
- Ruoli predefiniti protetti lato ability, controller e UI.
- Error state 422 preservati per aree e ruoli in HTML/Turbo.
- Landmark, H1, document title, dialog nominati, focus/Esc/restore, target da 44 px e ID univoci.
- Booleani resi con un'unica label flex: zero sovrapposizioni a desktop e mobile; nomi ruolo completi e a capo.

## Evidenza

- Browser desktop e 390×844: un main/H1, title contestuale, zero duplicate ID, immagini rotte e overflow documentale.
- Follow-up: zero intersezioni checkbox/label; riga minima 44 px e testo lungo a 64 px senza invasione.
- Suite G06 combinata: 43 esempi, 0 failure; dopo l'ultimo fix visuale, 10 system spec Selenium, 0 failure.
- RuboCop mirato e build JavaScript verdi; `git diff --check` verde nel blocco.

Questions skipped: l'utente ha autorizzato la remediation completa e la chiusura G06; non restano decisioni di perimetro.
