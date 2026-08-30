---
target: "G10 administration and operational tools baseline"
total_score: 6
max_score: 40
na_heuristics:
p0_count: 3
p1_count: 7
timestamp: 2026-08-30T16-06-20Z
slug: app-views-admin
---
# G10 baseline — amministrazione e strumenti operativi

Method: dual-agent (A: visual/browser · B: technical/security). Detector intentionally deferred to the final G10 gate.

## Design Health Score

| # | Euristica | Score | Problema principale |
|---|---:|---:|---|
| 1 | Visibilità dello stato | 1 | Le superfici principali falliscono prima di mostrare stato o avanzamento. |
| 2 | Corrispondenza col mondo reale | 0 | Il pannello non è raggiungibile e le azioni legacy non spiegano conseguenze o destinatari. |
| 3 | Controllo e libertà | 1 | Mancano conferme e alcune mutazioni privilegiate avvengono via GET. |
| 4 | Coerenza e standard | 1 | Route, controller, layout e mount non rispettano contratti coerenti. |
| 5 | Prevenzione errori | 0 | Template ERB eseguibili, target utente fragili e route fantasma espongono effetti ad alto impatto. |
| 6 | Riconoscimento anziché memoria | 1 | Link morto Sidekiq e strumenti non raggiungibili impediscono orientamento. |
| 7 | Flessibilità ed efficienza | 0 | Admin, moderator, newsletter e RailsAdmin non completano alcun workflow. |
| 8 | Estetica e minimalismo | 1 | La sola UI visibile è la debug page Rails, con overflow mobile. |
| 9 | Recupero dagli errori | 1 | L'errore generico non riporta all'area amministrativa né conferma l'assenza di mutazioni. |
| 10 | Aiuto e documentazione | 0 | Nessun contesto su rischio, durata, destinatari o risultato delle operazioni. |
| **Totale conservativo** | | **6/40** | **Critical / gate FAIL** |

## Finding prioritari

- **P0:** `ManagerActions` mancante blocca eager load, panel e moderator; RailsAdmin e newsletter falliscono a runtime; le debug page development espongono sorgente, trace, route e ambiente.
- **P1:** route helper Sidekiq inesistente; moderator ereditato dal gate admin; unblock e impersonazione via GET; ERB persistito eseguibile in preview/invio newsletter; blocco utenti senza target/self/last-admin guard; route panel/newsletter senza action.
- **P2:** status 302/200 permissivi, receiver newsletter non allowlisted, ElFinder top-level senza CSRF e con GET write, CKEditor morto, landmark/H1 assenti, spec che accettano 500 e Haml RailsAdmin senza handler.

## Acceptance criteria

- `zeitwerk:check`, eager load e tutte le superfici amministrative retained devono caricare senza 500.
- Zero route G10 senza controller/action; rimuovere Sidekiq, CKEditor, ElFinder e impersonazione legacy se non più supportati.
- Mutazioni solo con verbi CSRF-safe, target e conseguenze esplicite, scope/guard deterministici e 303/422.
- Newsletter come markup sanitizzato non eseguibile, receiver allowlisted, conteggio destinatari e conferma esplicita.
- Un solo main/H1, target da 44 px, responsive mobile senza overflow ed empty/error state amministrativi.
- Spec exact-status e security regressions; detector riservato a un'unica esecuzione finale.

Questions skipped: l'utente ha autorizzato remediation completa e chiusura G10; gli endpoint legacy senza consumatori possono essere rimossi nell'ambito della pulizia richiesta.
