---
group: G01
phase: baseline
score: 17
score_max: 40
p0: 1
p1: 4
timestamp: 2026-08-29T20-41-55Z
slug: app-views-devise
---
# G01 — Pubblico, accesso e onboarding — baseline

Target primario: `app/views/devise`

Modalità: `persuade-operate`

## Metodo e isolamento

- Assessment A: review visuale/euristica indipendente su codice e live guest, desktop 1387×980 e mobile 390×844; nessun detector consultato.
- Assessment B: detector CLI JSON e browser evidence indipendente, desktop 1440×900 e mobile 390×844; nessun contatto con Assessment A.
- Campione comune: `/`, `/landing`, `/public`, `/edemocracy`, `/users/sign_in`, `/users/sign_up`, `/users/password/new`, `/privacy`.
- Assessment A ha inoltre verificato confirmation, press, terms, cookie policy e 404.
- L'overlay mutabile non era disponibile: il browser esponeva il DOM in sola lettura. Assessment B ha usato il fallback documentato DOM+screenshot.

## Specificità

Specificità medio-bassa. La root ha un tratto riconoscibile — palette Nord, bordi netti, ombre dure e iconografia civica — ma il linguaggio non prosegue in modo coerente nelle form Devise, nello spazio pubblico, nei documenti legali e negli errori. Brand e lingua cambiano lungo lo stesso viaggio.

## Punteggio Nielsen

| Euristica | Punteggio |
|---|---:|
| Visibilità dello stato | 2/4 |
| Sistema e mondo reale | 1/4 |
| Controllo e libertà | 2/4 |
| Coerenza e standard | 2/4 |
| Prevenzione degli errori | 2/4 |
| Riconoscimento anziché ricordo | 2/4 |
| Flessibilità ed efficienza | 2/4 |
| Estetica e minimalismo | 2/4 |
| Diagnosi e recupero dagli errori | 1/4 |
| Aiuto e documentazione | 1/4 |
| **Totale** | **17/40** |

## Carico cognitivo ed esperienza

Sei criteri su otto falliscono: focus, chunking, gerarchia sulle pagine informative, una cosa alla volta, scelta minima e progressive disclosure. Grouping e working memory superano grazie alle form auth e ai documenti legali in modale. Il viaggio parte con fiducia sulla root, introduce dubbio con lingua/brand incoerenti e dati pubblici tutti a zero, poi raggiunge una valle nel recupero mobile e termina male su errori generici.

## Punti di forza

1. La root presenta bene promessa, registrazione, tour e accesso.
2. Login e registrazione hanno gerarchia ordinata, alternative OAuth/email, errori e documenti legali contestuali.
3. La struttura responsive di base regge su auth e griglia pubblica.

## Backlog prioritario

1. **P0 — `/landing` inutilizzabile.** L'azione non ha template e rende l'errore interno. Renderizzare la landing reale anche su accesso diretto.
2. **P1 — lingua, brand e tono incoerenti.** Completare la locale attiva, scegliere Decidiamoci come brand pubblico e Airesis come attribuzione tecnica, uniformare terminologia/capitalizzazione.
3. **P1 — flusso mobile e accessibilità ostacolati.** Banner cookie sovrapposto, CTA password che deborda, righe login compresse, overflow privacy, zoom bloccato, provider/social icon-only e label non associate.
4. **P1 — esplorazione pubblica comunica vuoto.** Portare guida e CTA prima delle metriche/empty state e spiegare l'ambiente senza dati.
5. **P1 — contenuti e recupero non navigabili.** Correggere ancore, gerarchia e misura tipografica; aggiungere sommari; rendere gli errori specifici e offrire uscite sicure.

## Evidenza detector

Detector su 31 file G01: exit 2, un warning `overused-font` in `app/views/errors/422.html:10`. Il detector ha lavorato in fallback regex-only perché i parser HTML/CSS non erano installati: il singolo finding è un sottoconteggio. Nessun falso positivo dimostrato.

## Evidenza browser determinante

- `/landing`: 500, template HTML mancante.
- `lang` del layout generale contiene virgolette letterali per escaping errato.
- Input login, registrazione e password senza associazione programmatica alle label.
- CTA reset password: `scrollHeight=55` dentro 38px effettivi.
- Banner cookie mobile copre i campi login della root.
- OAuth/social della root mobile senza nome accessibile.
- `/privacy` mobile: 448px di contenuto su 375px di viewport per URL non spezzabili.
- `/edemocracy`: quattro `h1`, documento mobile di 16229px, ancore mancanti e typo `heref` nella locale.
- `/public` e auth mescolano italiano e inglese.

## Decisioni di sintesi

- `/landing` diventa alias della root, senza duplicare una campagna separata.
- Brand pubblico: Decidiamoci; attribuzione tecnica nel footer: basato su Airesis.
- La lingua segue integralmente la locale attiva; nessun fallback visibile in una seconda lingua.
- Il guest viene guidato all'esplorazione prima di chiedere la registrazione, preservando comunque una CTA primaria chiara.
- Tutti i cinque rilievi vengono applicati perché l'utente ha richiesto la copertura completa e l'iterazione fino a 33/40.
