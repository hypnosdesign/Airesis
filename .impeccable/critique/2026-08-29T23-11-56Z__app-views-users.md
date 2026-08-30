---
group: G02
phase: post_fix_iteration_2
score: 29
score_max: 40
p0: 0
p1: 4
timestamp: 2026-08-29T23-11-56Z
slug: app-views-users
---
# G02 — iterazione 2 post-fix

## Esito

Punteggio Nielsen: **29/40**. Gate non superato: **P0 0, P1 4**.

Il detector post-fix ha restituito JSON puro `[]` su tutti i sette target, senza fallback o target mancanti. Tutte le superfici HTML hanno reso senza error page, con un solo `main` e un solo H1, zero `NaN` e nessun overflow desktop/mobile.

## P1 da correggere

1. Il menu locale delle preferenze è costruito via `content_for :left_panel` ma non viene renderizzato: le sottosezioni non sono scopribili dalla UI.
2. I toggle della matrice notifiche hanno nomi ripetuti “Alerts/Emails” senza il nome dell’attività della riga.
3. Il drawer mobile non trasferisce affidabilmente il focus all’apertura e gli auditor non rilevano lo sfondo come inert; trap, Esc e restore passano.
4. Contrasto insufficiente su overline/testi attenuati e azione distruttiva; un dialog profilo non chiude in modo affidabile con Esc nella verifica tecnica.

## Miglioramenti confermati

- Route precedentemente rotte corrette o normalizzate; `/notifications` reindirizza a `/alerts`.
- Dashboard first-run, search e notifiche vuote chiare e specifiche.
- GET `/alerts` non marca più automaticamente le notifiche; l’azione è un POST esplicito.
- Ricerca e campanella nominate; autocomplete account corretto; `aria-current` globale presente.
- Endpoint JSON verificati come supporto, non come superfici visuali.
