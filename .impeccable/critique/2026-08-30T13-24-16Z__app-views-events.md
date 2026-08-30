---
target: "G07 events and calendar final"
total_score: 35
max_score: 40
na_heuristics:
p0_count: 0
p1_count: 0
timestamp: 2026-08-30T13-24-16Z
slug: app-views-events
---
# G07 finale — eventi e calendario

## Esito

- Assessment A visuale/browser: 35/40.
- Assessment B tecnico: 36/40.
- Sintesi conservativa: **35/40 — Excellent**.
- P0: 0. P1: 0. P2: 0. Gate: PASS (`>=33/40`, P0=0, P1=0).
- Detector eseguito esattamente una volta sul perimetro finale: exit 0 e JSON `[]`; non è stato rilanciato durante i follow-up.

## Nielsen

| # | Euristica | Score | Evidenza |
|---|---:|---:|---|
| 1 | Visibilità dello stato | 3/4 | Vista calendario, conteggi, RSVP, flash e failure 422 rendono esplicito lo stato corrente. |
| 2 | Corrispondenza col mondo reale | 4/4 | Meeting, voting window, data, luogo, presenza e discussione usano termini coerenti e localizzati. |
| 3 | Controllo e libertà | 4/4 | Submit/Cancel, Edit/Delete, correzione RSVP e navigazione calendario sono operabili e autorizzati. |
| 4 | Coerenza e standard | 3/4 | Pattern Rails/Turbo e componenti DaisyUI uniformi; resta solo lieve clipping mitigato nella rail gruppo. |
| 5 | Prevenzione errori | 4/4 | Scope proposta, transizione WAIT_DATE, limiti DB, date e matrice editable sono validati server-side. |
| 6 | Riconoscimento anziché memoria | 4/4 | Dettagli pratici precedono partecipanti e discussione nel DOM e nell'ordine visivo/focus. |
| 7 | Flessibilità ed efficienza | 3/4 | Calendario list-first mobile, viste multiple desktop e azioni contestuali senza false affordance. |
| 8 | Estetica e minimalismo | 4/4 | Griglia desktop compatta, mobile senza overflow, toolbar leggibile e gerarchia chiara. |
| 9 | Diagnosi e recupero errori | 3/4 | Form e valori sono preservati su 422 in HTML/Turbo; messaggi restano sintetici. |
| 10 | Aiuto e documentazione | 3/4 | Help contestuale per calendario, date, luogo, RSVP e navigazione gruppo. |
| **Totale conservativo** |  | **35/40** | **Excellent / gate PASS** |

## Correzioni concluse

- Route ridotte da 42 a 26, con 8 GET e nessuna action fantasma.
- Creazione/modifica evento atomica, con form completo, recovery 422 e redirect 303 coerenti.
- Proposte confinate al gruppo e autorizzate; collegamento tramite `Proposal#set_votation_date`, solo da `WAIT_DATE` a `WAIT`, con evento votation futuro.
- Commenti root, like e RSVP autenticati, scoped e validati; limiti UI/modello/database allineati.
- Calendario list-first su mobile, toolbar localizzata/contrastata con target da 44 px, CTA reale e drag permesso soltanto per eventi aggiornabili non-votation.
- Dettagli pratici, RSVP, mappa, partecipanti e discussione hanno ordine DOM, visivo e di focus coerente; layout desktop senza vuoti e mobile senza overflow.
- Leaflet usa target zoom da 44 px; città selezionabile in modo asincrono e coordinate opzionali.

## Evidenza

- Browser reale desktop e 390×844: un `main`/H1, zero overflow, toolbar e profili da 44 px, focus monotono e console applicativa pulita.
- Chromium 151.0.7922.173 e ChromeDriver 151.0.7922.173 installati nel container Linux `aarch64`; i system test Selenium non dipendono più da Selenium Manager.
- Suite combinata G06+G07: **87 esempi, 0 failure**, incluse le regressioni Selenium per form, RSVP, commenti, calendario e voto proposta.
- RuboCop mirato senza offense; build esbuild/Tailwind e precompile asset verdi; `git diff --check` pulito.

Baseline: `.impeccable/critique/2026-08-30T12-28-03Z__app-views-events.md` (**9/40**). Trend conservativo: **9 → 35**.

Questions skipped: l'utente ha autorizzato remediation completa e chiusura G07; non restano decisioni di perimetro.
