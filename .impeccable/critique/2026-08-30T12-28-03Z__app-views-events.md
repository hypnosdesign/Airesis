---
target: G07 events and calendar baseline
total_score: 9
max_score: 40
na_heuristics:
p0_count: 2
p1_count: 6
timestamp: 2026-08-30T12-28-03Z
slug: app-views-events
---
# G07 baseline — eventi e calendario

## Esito

- Assessment A visuale: 9/40.
- Assessment B tecnico: 14/40.
- Sintesi conservativa: **9/40 — Critical**.
- P0: 2. P1: 6. Gate: FAIL (`>=33/40`, P0=0, P1=0).
- Detector eseguito una sola volta sul perimetro esatto: exit 0, JSON `[]`; i guasti Rails/Turbo, di layout e JavaScript non sono coperti dal detector.

## Nielsen

| # | Euristica | Score | Evidenza |
|---|---:|---:|---|
| 1 | Visibilità dello stato | 1/4 | Spinner permanente, errori e formati di risposta incoerenti. |
| 2 | Corrispondenza col mondo reale | 2/4 | Data/luogo leggibili, ma città Yes/No o ID e copy misto. |
| 3 | Controllo e libertà | 0/4 | Creazione senza Submit/Cancel; Cancel edit rompe JavaScript. |
| 4 | Coerenza e standard | 1/4 | Show moderno, form legacy, HTML/Turbo e partial divergenti. |
| 5 | Prevenzione errori | 1/4 | False affordance, delete rotto e scope contestuale incompleto. |
| 6 | Riconoscimento anziché memoria | 1/4 | RSVP, partecipanti e azioni admin non sono montati dal layout. |
| 7 | Flessibilità ed efficienza | 1/4 | Creazione bloccata e presenza non correggibile. |
| 8 | Estetica e minimalismo | 2/4 | Hero discreto, ma markup legacy, mappe vuote e toolbar mobile rumorosa. |
| 9 | Diagnosi e recupero errori | 0/4 | Commenti root impossibili; rami invalidi non preservano form/status. |
| 10 | Aiuto e documentazione | 0/4 | Nessun aiuto utile per città, date, presenza o recovery. |
| **Totale** |  | **9/40** | **Critical** |

## P0

1. `EventComment` richiede un parent, ma il form crea commenti root senza parent: il flusso principale non può persistere.
2. Il wizard non ha controlli Submit/Cancel e dipende dai global assenti `EventsEdit`/`EventsShow`.

## P1

1. Quattordici route pubblicate puntano ad action inesistenti (`event_comments#index/new/edit/show/update`, `events#list`).
2. RSVP, partecipanti, Edit e Delete sono in `content_for :left_panel`, non montato dal layout.
3. Delete perde `turbo_method`; Cancel edit cerca un dialog inesistente.
4. Create/update eventi e failure attendance/commenti non recuperano coerentemente HTML/Turbo con 422 e dati preservati.
5. Il calendario mobile sfora di 81 px e rende la settimana illeggibile.
6. `EventCommentsController` non autentica: guest può raggiungere codice che richiede `current_user`.

## Debito tecnico e cognitivo

- 42 route e 18 GET; 14 route fantasma duplicate tra top-level e gruppo.
- Partial commenti duplicate e divergenti; una usa `raw`/`sanitize: false`.
- Show e form usano JavaScript inline/globali mancanti; mappa vuota.
- Nessun main sulle route ispezionate; edit senza H1/title contestuale.
- Toolbar con troppe decisioni e form unico che eredita il carico di un wizard senza progressione.
- Spec permissive accettano 500 e salvano commenti con `validate: false`.

## Remediation concordata

Potare route fantasma e duplicate, rendere root comment validi, sostituire i global legacy, introdurre form evento completo con Submit/Cancel e recovery 422, montare RSVP/partecipanti/azioni, rendere il calendario mobile list-first, consolidare commenti e rafforzare test esatti e Selenium.

Questions skipped: l'utente ha autorizzato remediation completa e chiusura G07; non resta una decisione di priorità o perimetro.
