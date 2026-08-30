---
target: G10 administration and operational tools final
total_score: 37
max_score: 40
na_heuristics:
p0_count: 0
p1_count: 0
timestamp: 2026-08-30T16-52-00Z
slug: app-views-admin
---
# G10 finale — amministrazione e strumenti operativi

Method: dual-agent (A: visual/browser · B: technical/security), follow-up indipendenti e detector CLI eseguito una sola volta sul target finale con exit 0 e JSON `[]`.

## Design Health Score

| # | Euristica | Score | Evidenza finale |
|---|---:|---:|---|
| 1 | Visibilità dello stato | 4 | Panel, newsletter e operazioni privilegiate espongono stato, conteggi e feedback conclusivo. |
| 2 | Corrispondenza col mondo reale | 4 | Le azioni dichiarano destinatari, conseguenze e durata attesa con linguaggio operativo. |
| 3 | Controllo e libertà | 4 | Mutazioni POST/PATCH, conferme esplicite, redirect 303 e separazione admin/moderator. |
| 4 | Coerenza e standard | 4 | Layout, route, RailsAdmin e newsletter condividono landmark, titoli e contratti Rails coerenti. |
| 5 | Prevenzione errori | 4 | Scope e guard deterministici, receiver allowlisted, markup sanitizzato e invii retryable per destinatario. |
| 6 | Riconoscimento anziché memoria | 4 | Navigazione amministrativa, titoli, hint e contesto rendono ogni workflow riconoscibile. |
| 7 | Flessibilità ed efficienza | 3 | I workflow sono completi e batch; le operazioni intenzionalmente privilegiate restano conservative. |
| 8 | Estetica e minimalismo | 3 | Gerarchia compatta e responsive, senza decorazione gratuita; RailsAdmin mantiene parte del linguaggio visivo proprio. |
| 9 | Recupero dagli errori | 4 | Errori 422, retry limitati, discard di record rimossi e nessuna mutazione implicita via GET. |
| 10 | Aiuto e documentazione | 3 | I rischi principali sono spiegati nel contesto; la documentazione operativa estesa resta nell'handoff. |
| **Totale conservativo** | | **37/40** | **PASS** |

## Design-specificity verdict

PASS. La superficie adotta deliberatamente una modalità `operate`: densità controllata, gerarchia funzionale, target interattivi da almeno 44 px, nessuna animazione coreografica e colore riservato a stato, focus, pericolo e azione primaria. Tipografia Sora, misura di lettura e ruoli semantici restano coerenti con le altre superfici.

## Finding prioritari

- **P0: 0 · P1: 0 · P2: 0 · P3: 0.** Tutti i finding delle due assessment finali e dei follow-up risultano chiusi.
- Newsletter: delivery atomica per destinatario, deduplica, retry polinomiale limitato, conteggio accodato e preview sanitizzata.
- Cleanup notifiche: job batch da 500, retention assoluta a sei mesi, unread recenti preservate e matrice di regressione completa.
- Route: 22 endpoint G10, 8 GET, zero action gap; ElFinder, CKEditor view e alias amministrativi morti rimossi.
- RailsAdmin: mount e asset Sprockets reali, title nel `head`, landmark `main`, tema responsive e precompile production verificato.

## Persona red flags

Nessuno. Le azioni distruttive o ad alto impatto richiedono intenzione esplicita; i destinatari newsletter e gli utenti amministrati sono identificabili prima della conferma.

## Osservazioni minori

- Il logo della preview locale usa l'host configurato dall'ambiente di sviluppo; non è un difetto della configurazione production.
- La scelta di non applicare un effetto “overdrive” è intenzionale: una superficie amministrativa trae qualità da prevedibilità, velocità e assenza di spettacolarizzazione.

Questions skipped: G10 è chiuso e l'utente ha chiesto di fermarsi al termine del programma con riepilogo.
