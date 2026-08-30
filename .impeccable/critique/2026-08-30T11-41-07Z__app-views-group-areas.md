---
target: "G06 governance groups: areas, roles, permissions baseline"
total_score: 11
max_score: 40
na_heuristics:
p0_count: 3
p1_count: 5
timestamp: 2026-08-30T11-41-07Z
slug: app-views-group-areas
---
# G06 baseline — governance: aree, ruoli e permessi

## Esito

- Assessment A visuale: 11/40.
- Assessment B tecnico: 12/40.
- Sintesi conservativa: **11/40 — Critical**.
- P0: 3. P1: 5. Gate: FAIL (`>=33/40`, P0=0, P1=0).
- Detector eseguito una sola volta sul perimetro esatto: JSON `[]`; browser e sorgente dimostrano problemi non intercettati staticamente.

## Nielsen

| # | Euristica | Score | Evidenza |
|---|---:|---:|---|
| 1 | Visibilità dello stato | 1/4 | I permessi sembrano modificabili ma non vengono salvati; operazioni async senza pending/error/rollback. |
| 2 | Corrispondenza col mondo reale | 2/4 | Concetti comprensibili, titoli e default role incoerenti. |
| 3 | Controllo e libertà | 1/4 | Cancel punta a `#`; recovery fragile. |
| 4 | Coerenza e standard | 1/4 | Area e gruppo usano pattern diversi; route e controller non concordano. |
| 5 | Prevenzione errori | 0/4 | Route morte, default eliminabile, scoping membership/like insufficiente. |
| 6 | Riconoscimento anziché memoria | 2/4 | Descrizioni utili, controlli centrali senza nomi accessibili e ID duplicati. |
| 7 | Flessibilità ed efficienza | 1/4 | Flusso principale senza persistenza affidabile. |
| 8 | Estetica e minimalismo | 1/4 | Parete di permessi, form duplicato e gerarchia debole. |
| 9 | Diagnosi e recupero errori | 0/4 | Debug page e update invalido in 500. |
| 10 | Aiuto e documentazione | 2/4 | Descrizioni presenti, conseguenze e default non spiegati. |
| **Totale** |  | **11/40** | **Critical** |

## Design specificity

La terminologia è propria di Airesis, ma la composizione è ancora intercambiabile: form DaisyUI grezzi, accordion generici e superfici piatte. La shell G05 resta coerente e il riepilogo permessi amministratore è l'eccezione positiva.

## Priority issues

### P0

1. Sette route delle 33 inventariate puntano ad azioni inesistenti (`area_roles#index/show/change`, `area_participations#update`, `participation_roles#show/change_default_role`).
2. I form dei permessi di partecipazione espongono 11 checkbox ma nessun submit né handler: il core flow non persiste.
3. Il cambio ruolo area usa `change_permissions`, mentre l'ability concede `change`; un amministratore di gruppo non globale può ricevere 403.

### P1

1. `UserLikesController#destroy` non limita la ricerca al current user.
2. L'aggiunta a un'area accetta utenti esterni al gruppo.
3. L'update invalido di GroupArea usa `format` fuori da `respond_to` e può produrre 500.
4. Delete area e operazioni async hanno conferma/errore/rollback inaffidabili.
5. Mancano landmark main, H1 contestuali e label; accordion senza nome, ID duplicati, select e target touch troppo piccoli.

## Debito cognitivo e responsive

Carico alto: 11 permessi in colonna, creazione e modifica sulla stessa pagina, ruolo aperto di default, azione distruttiva troppo prominente. Nessun overflow root a 1440x900 e 390x844, ma la pagina ruoli mobile raggiunge circa 1772 px e i breadcrumb si troncano.

## Persona red flags

- Novizia: non comprende default, conseguenze della cancellazione o se il salvataggio sia avvenuto.
- Tastiera/screen reader: main e H1 mancanti, controlli senza nome, ID duplicati.
- Mobile/stress: target da 20–24 px, scroll eccessivo e assenza di recovery di rete.

## Remediation concordata

Restringere le route, introdurre salvataggi espliciti, allineare ability/controller, proteggere i ruoli default, rendere membership e like tenant-safe, riparare gli error state, separare i form, raggruppare i permessi e portare landmark/label/target al craft floor.

Questions skipped: l'utente ha già autorizzato remediation completa e chiusura G06; non resta una decisione di priorità o perimetro.
