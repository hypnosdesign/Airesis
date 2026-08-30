---
target: G05 groups, membership and invitations baseline
total_score: 13
max_score: 40
na_heuristics:
p0_count: 2
p1_count: 4
timestamp: 2026-08-30T10-21-19Z
slug: app-views-groups
---
Method: dual-agent (A: g05_baseline_design · B: g05_baseline_detector)

# Impeccable critique — G05 baseline

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|---|---:|---|
| 1 | Visibility of System Status | 1 | Listing filtrato senza stato leggibile; membri termina in 500. |
| 2 | Match System / Real World | 1 | Token geografico tecnico, lingua mista e descrizione chiamata Rules. |
| 3 | User Control and Freedom | 1 | Navigazione di gruppo invisibile e form senza uscita affidabile. |
| 4 | Consistency and Standards | 1 | Index/show moderni, edit/invito e membri ancora legacy o rotti. |
| 5 | Error Prevention | 2 | Required e conferme presenti, ma azioni mutanti perdono i metodi Turbo. |
| 6 | Recognition Rather Than Recall | 1 | Settings, membri, inviti, regole e adesione non sono raggiungibili dalla UI. |
| 7 | Flexibility and Efficiency | 0 | Gestione utenti e operazioni batch sono bloccate dal 500. |
| 8 | Aesthetic and Minimalist Design | 2 | Buona gerarchia su show/index, forte rumore nei form. |
| 9 | Error Recovery | 2 | Error page recuperabile ma senza ritorno contestuale al gruppo. |
| 10 | Help and Documentation | 2 | Aiuto parziale; formato inviti e permessi avanzati non sono spiegati nel punto giusto. |
| **Total** |  | **13/40** | **Poor** |

## Design Specificity Verdict

Il profilo gruppo usa informazioni civiche pertinenti — membri, proposte, eventi e attività — ma hero, icona e card sono ancora category-interchangeable. Missione, identità del gruppo e stato di membership non guidano la composizione.

Il detector è stato eseguito una sola volta ma il comando ricevuto includeva il target finale `.`: ha quindi scansionato build, coverage, documentazione e asset fingerprinted oltre ai tre alberi G05. Exit 2, fallback regex per i moduli mancanti `htmlparser2`, `css-select`, `css-tree` e `domutils`; il JSON è stato troncato e non consente un conteggio target affidabile. Nessun retry è stato eseguito. Il browser reale resta l'evidenza principale.

## Overall Impression

La scoperta e la home del gruppo sembrano promettenti, ma i percorsi operativi sono nascosti o bloccati. Il picco positivo della home viene cancellato dal 500 sui membri e da form di creazione/modifica non adatti al mobile.

## What's Working

- La home del gruppo offre una gerarchia immediata e statistiche specifiche al dominio.
- Sora, focus globale, drawer modale e molti pulsanti da 44 px danno una base condivisa coerente.
- Le azioni distruttive principali prevedono warning e conferme.

## Priority Issues

### P0 — Gestione membri bloccata

`/groups/ui-audit-civic-lab/group_participations` rende l'error page perché `endless_page.js` non esiste nella pipeline. Il flusso operativo principale non è utilizzabile. Rimuovere la dipendenza legacy, riparare markup e azioni e aggiungere regressioni che richiedano HTTP 200.

### P0 — Navigazione e azioni del gruppo invisibili

Il layout raccoglie Home, proposte, eventi, forum, membri e settings in `content_for :left_panel`, ma il layout generale non rende quel contenuto. Introdurre una navigazione secondaria responsive e azioni role-aware visibili nella home.

### P1 — Discovery fuorviante

`/groups` applica implicitamente `K-5` come match geografico esatto e nasconde il gruppo di Roma. Gli input misurano 24 px, i checkbox non hanno label visibile e non esiste reset. Usare default neutro, area umana, risultato count, reset e controlli da almeno 44 px.

### P1 — Overflow mobile su new/edit

A 390 px i documenti misurano rispettivamente 432 e 422 px. Trix, select e label vengono tagliati. Rendere contenitori e campi `min-width: 0`, full-width e confinare l'overflow alla toolbar.

### P1 — Permessi senza progressive disclosure

La creazione mostra insieme 11 checkbox, Default e Ok; l'anchor `href="#"-id="permessi"` è malformato e i comandi non hanno comportamento. Sostituire con `details`, fieldset/legend e controlli reali, eliminando placeholder.

### P1 — Landmark e heading mancanti

Cinque route sane su sei non hanno `main`; l'invito non ha H1. Rendere il layout G05 un landmark principale e dare a ogni pagina un H1 unico e contestuale.

## Additional Issues

- P2: invito senza nome gruppo, hint formato o cancel standalone affidabile.
- P2: descrizione presentata come Rules, vero regolamento irraggiungibile e lingua mista.
- P2: edit senza sezioni, cancel e danger zone distinta.
- P2: target form tra 24 e 40 px e avatar CSS senza equivalente testuale robusto.
- P3: identity band generica e invito troppo vuoto a desktop.

## Cognitive Load

Alto: 7/8 checklist falliscono. Il punto peggiore è il form nuovo gruppo con 11 permessi e due pseudo-comandi mostrati insieme; la navigazione assente richiede inoltre di ricordare o inventare URL.

## Emotional Journey

Il listing parte con un hero sicuro ma sembra vuoto per il filtro implicito. La home del gruppo è il picco, poi l'assenza di azioni e il 500 dei membri creano la valle principale. Edit e invito chiudono il percorso con superfici legacy, quindi il peak-end resta negativo.

## Persona Red Flags

- **Jordan:** non comprende `K-5`, non trova Membri/Invita/Settings e scambia la descrizione per regolamento.
- **Sam:** skip link verso un `div`, invito senza H1, controlli piccoli, avatar CSS, `<td>` dentro `<li>`, select con ID ripetuti e checkbox area senza label.
- **Casey:** overflow mobile, toolbar tagliate e permessi troppo densi prima dell'azione primaria.

## Minor Observations

- Zero errori o warning console sulle route renderizzate; il solo 500 è server-side per l'asset mancante.
- Nessuna immagine rotta nel browser.
- Il badge development Bullet è visibile ma non appartiene al prodotto.

## Questions to Consider

- Il gruppo deve comportarsi come una destinazione autonoma con navigazione propria?
- La home deve privilegiare “cosa sta succedendo” o “cosa posso fare ora”?
- I permessi avanzati devono essere obbligatori durante la creazione o vivere nella gestione successiva?

Questions skipped: l'utente ha già richiesto esplicitamente la remediation completa di G05 e la chiusura del gate, quindi priorità e perimetro sono già definiti.
