---
group: G02
phase: post_fix_iteration_4
score: 33
score_max: 40
p0: 0
p1: 0
timestamp: 2026-08-29T23-42-03Z
slug: app-views-users
---
# G02 — iterazione 4 post-fix

## Esito

Punteggio Impeccable: **33/40**. Gate superato: **P0 0, P1 0**.

| Categoria | Punteggio |
|---|---:|
| Gerarchia e chiarezza | 4/5 |
| Coerenza visiva | 4/5 |
| Specificità di prodotto | 4/5 |
| IA e carico cognitivo | 4/5 |
| Semantica e contrasto | 4/5 |
| Tastiera e focus | 4/5 |
| Responsive e target | 5/5 |
| Stati ed errori runtime | 4/5 |
| **Totale** | **33/40** |

## Evidenze del gate

- Drawer mobile: primo avvio da tastiera, focus iniziale, `inert`, trap, Esc e restore verificati dopo reload pulito.
- Dialog profilo e popover globali: nomi e stato ARIA sincronizzati; Esc nasconde realmente i pannelli e ripristina il trigger.
- Statistiche utente: quattro gruppi semantici con `dl/dt/dd`, data localizzata e nessun dato tecnico visibile.
- Sottosezioni impostazioni: navigazione visibile, attiva, focalizzabile e comprensibile su mobile.
- Contrasto minimo osservato sui testi G02: **5,04:1**; nessuna violazione testuale dipinta.
- Tutte le 14 superfici HTML hanno un solo H1 e `main`, nessun overflow desktop/mobile, `NaN`, traduzione mancante o errore runtime applicativo.
- `/school` e `/municipality` dichiarano nella lingua della shell che il contenuto storico è conservato solo in italiano e marcano il contenuto con `lang="it"`.

## Rifiniture successive alla valutazione

- Aggiunto bypass “Skip to main content”, verificato da tastiera con focus su `#main-content`.
- Reso più naturale il copy delle statistiche e corretti tre refusi meccanici nella pagina archivio scuola.

## Verifiche

- Build esbuild e Tailwind: verdi.
- Request spec G02: **88 esempi, 0 failure, 1 pending noto** per una fixture Alert non valida.
- System spec Selenium non eseguibile nel container Linux ARM per assenza di ChromeDriver supportato; i flussi interattivi sono stati verificati nella sessione Chrome reale autenticata.
