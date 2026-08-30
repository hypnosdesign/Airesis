---
group: G04
iteration: final
mode: operate
score: 38
score_max: 40
p0: 0
p1: 0
gate: pass
viewports: 1736x980,1440x900,375x844,375x812
timestamp: 2026-08-30T09-44-03Z
slug: app-views-proposal-comments
---
# Impeccable critique — G04 finale

- Gruppo: G04 — Deliberazione, commenti, quorum e voto
- Modalità: operate
- Baseline: **12/40**, P0=6, P1=5
- Finale: **38/40**, P0=0, P1=0, P2=0
- Gate: **PASS**

## Assessment A — design e Nielsen

| Euristica | /4 |
|---|---:|
| Visibilità dello stato | 4 |
| Corrispondenza col mondo reale | 3 |
| Controllo e libertà | 4 |
| Coerenza e standard | 4 |
| Prevenzione errori | 4 |
| Riconoscimento anziché memoria | 4 |
| Flessibilità ed efficienza | 3 |
| Estetica e minimalismo | 4 |
| Diagnosi e recupero errori | 4 |
| Aiuto e documentazione | 4 |
| **Totale** | **38/40** |

Nove superfici rappresentative sono state verificate a desktop e mobile: proposta di gruppo, commenti, revisioni, proposal life, supporto, quorum gruppo, guida quorum, proposta in voto e legacy `/votation`. Tutte conservano un solo `main`, H1 e orientamento contestuale; non sono emersi 500/Oops, `href="#"`, overflow orizzontali o errori applicativi in console.

`GET /votation` risponde 301 verso `/public`, che presenta H1 “Public space” e un percorso utile. La proposal life HTML conduce alla cronologia revisioni. Il supporto usa un fallback asset pipeline valido 256×256, senza immagini rotte. Commenti, revisioni, supporti, quorum e voto hanno controlli nominati, target di almeno 44 px, stati e conferme coerenti.

Il voto standard e quello Schulze sono form semantici reali. Sono stati verificati senza submit lo stato delle radio, l'action del form, la selezione della cronologia e il dialog report. Nessuna azione mutante è stata eseguita dalle critique.

## Assessment B — detector e review del codice

Comando finale eseguito esattamente una volta:

```text
node /Users/mattia/.agents/skills/impeccable/scripts/detect.mjs --json app/views/proposal_comments app/views/proposal_revisions app/views/proposal_lives app/views/proposal_supports app/views/quorums app/views/votations
```

- Exit status: 0
- JSON completo: `[]`
- Detector: P0=0, P1=0, findings=0

La review del codice successiva ha individuato un P1 non rilevabile staticamente: la gestione “noise” dipendeva solo dal drag-and-drop. Il delta aggiunge pulsanti nativi da tastiera, label visibile e accessibile aggiornata, target 44 px e live region; il drag resta un progressive enhancement e `collectIds` serializza lo stato di entrambe le liste. La review read-only del delta ha confermato P0=0/P1=0 senza rilanciare il detector.

## Correzioni principali

- Riparati i 500 su commenti, supporti, proposal life e guida quorum.
- Potate route REST e template senza implementazione; inventario G04 ridotto da 125 a 36 route.
- Ricostruiti thread/reply, storico revisioni, supporto, indice/form/guida quorum e pannelli voto.
- Aggiunti controller Stimulus dedicati a report, ranking Schulze, history revisioni e form quorum.
- Resi accessibili report dialog, gestione noise, ranking, toggle quorum, radio/checkbox e azioni distruttive.
- Eliminato l'overflow mobile del quorum tramite card dedicate e stacking del page title.

## Verifiche

- Request/model spec mirate: **35 esempi, 0 failure**.
- Build esbuild e Tailwind: verdi.
- `git diff --check`: pulito.
- La system spec Selenium del voto è bloccata prima della visita dall'assenza di ChromeDriver Linux ARM64 in Selenium Manager; i flussi equivalenti sono stati verificati in Chrome reale.

## Residui

- P3: lieve incoerenza temporale nel copy del pannello dibattito; non blocca comprensione, azione o gate.
- Il detector copre i sei alberi indicati ma non può valutare comportamento Stimulus, contrasto runtime o partial dipendenti esterne; tali aspetti sono stati compensati dalla review e dal browser reale.
