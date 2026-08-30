# Impeccable critique — G03 finale

- Timestamp: 2026-08-30T00:42:19Z
- Gruppo: G03 — Proposte: scoperta, creazione e lettura
- Modalità: operate
- Viewport: 1440×900 e 390×844
- Route core: 8/8 verificate; JSON, banner, test banner e tab list verificati separatamente
- Detector finale: esecuzione deterministica unica sui sei target, exit 0, JSON valido `[]`, nessun fallback
- Nielsen: **37/40**
- Gate: **PASS** — P0=0, P1=0; il detector finale non rileva neppure P2

## Assessment A — design, Nielsen e journey

| Euristica | /4 |
|---|---:|
| Visibilità dello stato | 4 |
| Corrispondenza col mondo reale | 4 |
| Controllo e libertà | 4 |
| Coerenza e standard | 4 |
| Prevenzione errori | 3 |
| Riconoscimento anziché memoria | 4 |
| Flessibilità ed efficienza | 4 |
| Estetica e minimalismo | 4 |
| Diagnosi e recupero errori | 3 |
| Aiuto e documentazione | 3 |
| **Totale** | **37/40** |

### Evidenze decisive

- Listing pubblico e di gruppo: card responsive, empty state utile, navigazione degli stati e ordinamento semantici. Tutti i sort restano sugli index corretti; dopo `Higher rank` rimangono shell, un `main`, H1, title e `aria-current="page"`.
- Il sort attivo misura **5,04:1** e ogni anchor è alto **44 px**; nessun overflow a 390 px.
- Creazione e lettura: campi core nominati, heading e copy coerenti, stato localizzato, commento con label persistente e flash inline.
- Editing: 12 editor Trix collegati ai rispettivi hidden input, toolbar nominate con roving tabindex, Home/End/frecce, target 44×44 px e scrollbar orizzontale visibile. Le 12 sezioni usano progressive disclosure, con Expand/Collapse all e barra azioni mobile sticky alta 70 px.
- L'etichetta della soluzione viene risolta per tipo e non serializza più l'hash I18n.
- Drawer filtri: dialog nominato, focus iniziale, background inert, trap, Esc e restore corretti.
- Banner: endpoint responsive, test page completa e banner interamente azionabile verso la proposta; nessun caricamento di HTML come script.
- `/proposal_categories.json`: 200, JSON valido e sole chiavi `id` e `description`.

## Assessment B — detector e runtime

- P0=0, P1=0, P2=0.
- Detector eseguito esattamente una volta sui sei source target G03: exit 0, JSON `[]`, nessun fallback o falso positivo. `app/views/proposal_presentations` è assente perché non esiste una superficie view per l'unica azione `destroy` rimasta.
- Otto route core e supporti HTML: 200 a desktop/mobile, nessun overflow o errore runtime applicativo.
- Public/group sort: href index, contesto preservato al click, contrasto 5,04:1 e hit-area 44 px.
- Commento pubblico/gruppo con label associata; banner con link nominato all'esatta proposta.

## Storia delle iterazioni

- Baseline: **15/40**, P0=0, P1=6.
- Iterazione 2: **29/40**, P1 su label soluzione e toolbar Trix; il detector rileva inoltre test banner non funzionante.
- Iterazione 3: **33/40**, soglia numerica raggiunta ma gate fallito per i link sort verso la partial e contrasto attivo 3,31:1.
- Iterazione 4: **37/40**, P0=0, P1=0 — gate superato.

## Verifiche tecniche

- `107 examples, 0 failures` sulle spec helper/request G03.
- Build esbuild e Tailwind verdi.
- `git diff --check` pulito.
- Nessun form inviato o dato modificato durante le critique; viewport ripristinata, schede audit chiuse e `/events/new` riattivata.
