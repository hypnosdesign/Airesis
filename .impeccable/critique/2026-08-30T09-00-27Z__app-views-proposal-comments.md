---
group: G04
iteration: baseline
mode: operate
score: 12
score_max: 40
p0: 6
p1: 5
gate: fail
viewports: 1440x900,390x844
timestamp: 2026-08-30T09-00-27Z
slug: app-views-proposal-comments
---
# Impeccable critique — G04 baseline

- Gruppo: G04 — Deliberazione, commenti, quorum e voto
- Modalità: operate
- Viewport: 1440×900 e 390×844
- Route rappresentative: 9/9 verificate
- Nielsen: **12/40**
- Gate: **FAIL** — P0=6, P1=5

## Assessment A — design e Nielsen

| Euristica | /4 |
|---|---:|
| Visibilità dello stato | 1 |
| Corrispondenza col mondo reale | 2 |
| Controllo e libertà | 1 |
| Coerenza e standard | 1 |
| Prevenzione errori | 1 |
| Riconoscimento anziché memoria | 2 |
| Flessibilità ed efficienza | 1 |
| Estetica e minimalismo | 2 |
| Diagnosi e recupero errori | 1 |
| Aiuto e documentazione | 0 |
| **Totale** | **12/40** |

## P0

1. La proposal di gruppo con commenti restituisce 500: `proposal_comments/_ranking_panel.html.erb` risolve `ranking_panel_others` nel namespace `proposals`.
2. Il pannello sostegno restituisce 500: `User::Groupable#scoped_groups` genera SQL senza parentesi finale.
3. Il voto standard espone tre anchor `href="#"` senza binding, input o stato semantico: la decisione primaria non è inviabile.
4. `/votation` espone `Unknown action`: la route punta a `VotationsController#show`, che non esiste; anche i fallback HTML la usano.
5. `proposal_lives#show` HTML restituisce 500 perché esiste solo il template Turbo Stream.
6. `/quorums/help` restituisce 404 perché il loader CanCan tenta di caricare un `BestQuorum` senza ID.

## P1

1. Revision history: solo H2, nessun contenuto utile, empty state, landmark o ritorno contestuale visibile.
2. Quorum mobile: `scrollWidth 561` su `clientWidth 375`, tabella e CTA tagliate.
3. Quorum runtime: `ReferenceError: QuorumsIndex is not defined`; toggle amministrativi privi di feedback affidabile.
4. Quorum accessibility: checkbox senza nome e target edit/delete circa 12–18 px.
5. Commenti: nessun `main`, menu ellissi senza nome, reply senza label, reaction da circa 20×28 px e gerarchia mobile fragile.

## P2

- Copy/localizzazione mista (`Votation`, `fa`, `modificato`, `1 giorno: 1 day`) e data quorum tecnica.
- Heading del voto con salti di livello e copy “Debate proceeding” durante la fase di voto.
- Route e template legacy espongono azioni REST senza implementazione reale.

## Assessment B — detector e browser

- Detector eseguito una sola volta; exit 2.
- Fallback regex perché mancavano `htmlparser2`, `css-select`, `css-tree` e `domutils`.
- Il comando ricevuto includeva anche il target finale `.`, quindi ha scansionato build, coverage, public assets e documentazione oltre ai sei target G04; 1.285 righe sono state troncate. Nessun rilancio è stato eseguito.
- Le evidenze browser sopra sono state confermate a entrambi i viewport; unico overflow orizzontale osservato sull'indice quorum mobile.
- Nessun form, voto, delete o toggle è stato azionato; nessun file o dato è stato modificato dalle critique.

## Punti positivi

- La proposal in voto ha una buona gerarchia generale, un `main`, H1 e target voto alti 44 px.
- Il quorum desktop raggruppa chiaramente dibattito e votazione.
- Le error page applicative sono responsive e offrono due vie di fuga.
- Focus globale e reduced motion del design system sono già presenti.

## Ordine di remediation

1. Ripristinare i sei flussi P0 e rimuovere le route fantasma.
2. Rendere il voto standard un form semantico con conferma e feedback.
3. Riparare storico e revisioni con fallback HTML e empty state.
4. Rendere quorum responsive, nominato e collegato a JavaScript effettivo.
5. Uniformare commenti, landmark, target, copy e localizzazione al linguaggio G03.
