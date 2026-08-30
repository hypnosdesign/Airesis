# Impeccable critique — G03 baseline

- Timestamp: 2026-08-29T23:58:01Z
- Gruppo: G03 — Proposte: scoperta, creazione e lettura
- Modalità: operate
- Viewport: 1440×900 e 390×844
- Route core: 8/8 verificate; supporti raggiungibili verificati separatamente
- Detector: esecuzione deterministica unica, exit 0, parser nativo, output `[]`
- Nielsen: **15/40**
- Gate: **FAIL** — P0=0, P1=6

## Assessment A — design, Nielsen e journey

| Euristica | /4 |
|---|---:|
| Visibilità dello stato | 2 |
| Corrispondenza col mondo reale | 2 |
| Controllo e libertà | 1 |
| Coerenza e standard | 1 |
| Prevenzione errori | 2 |
| Riconoscimento anziché memoria | 2 |
| Flessibilità ed efficienza | 1 |
| Design essenziale | 2 |
| Diagnosi e recupero errori | 1 |
| Aiuto e documentazione | 1 |
| **Totale** | **15/40** |

### P1

1. `/groups/ui-audit-civic-lab/proposals` restituisce 500: `CGI::escapeHTML` riceve un `ActionText::RichText` in `app/views/proposals/index.html.erb:3`.
2. Le due pagine edit non consentono di modificare il corpo: i textarea sono `visibility:hidden`, nessun editor li sostituisce e il JavaScript legacy è stato rimosso.
3. Il listing pubblico è visivamente collassato: immagini fuori scala, titolo/stato sovrapposti e metriche concatenate rendono le card indistinguibili, soprattutto su mobile.
4. Titolo, territorio, tag, contenuto, commento e campi edit core sono privi di nome accessibile.
5. Il drawer filtri non aggiorna lo stato ARIA, non isola il background, non gestisce focus/Esc/restore e il pulsante di chiusura non ha nome.
6. Testi informativi con `text-primary-content/60` e `text-base-content/40` misurano rispettivamente circa 3,00:1 e 2,14–2,16:1; il titolo soluzione è circa 3,50:1.

### P2

- Il flash mobile copre temporaneamente hero, badge e titolo.
- I link di navigazione usano semantica tab incompleta; sono più corretti come navigazione con pagina corrente.
- Manca il landmark `main` e lo show salta da H1 a H3.
- Copy inglese e italiana sono mescolate nelle superfici principali.
- Empty/loading/error sono poco informativi; varianti legacy secondarie hanno dimensioni fisse.
- `/banner` e `/test_banner` rispondono 403 prima dell'autorizzazione esplicita dell'action; `/tab_list` è correttamente un frammento.

Carico cognitivo alto nella scoperta e critico nell'editing. Red flag principali: screen reader senza nomi dei campi, tastiera esclusa dal drawer, listing mobile non scansionabile e urgenza temporale dell'edit senza editor funzionante.

## Assessment B — detector e runtime

- Confermati il 500 del listing di gruppo e il drawer rotto.
- `/proposal_categories.json` restituisce 406 dopo `ArgumentError: unknown keyword: :order` da `ProposalCategory.all(order: 'id desc')`.
- Confermati i nomi accessibili mancanti su new, show ed edit.
- Le sette pagine HTML funzionanti non espongono `<main>`/`role="main"`.
- `/banner` e `/test_banner` restituiscono 403; `/tab_list` rende senza overflow.
- Nessun overflow documentale o errore di contrasto ulteriore sulle pagine funzionanti.

Nessun form inviato e nessun dato/file modificato dai due assessment. La scheda audit è stata chiusa e la route originaria `/events/new` ripristinata.
