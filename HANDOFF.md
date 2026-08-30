# Handoff operativo — Airesis

> Aggiornato il 2026-08-30. Questo è il punto di ripresa corrente.
> La prossima sessione deve leggere questo file prima di modificare il repository, senza chiedere all'utente di ricostruire il contesto.

## Stato in breve

- Repository: `/Users/mattia/Projects/Airesis_Site/airesis-develop`
- Branch: `main`; il programma UI/UX è chiuso e verificato fino a G10 compreso. G01 resta il solo gruppo non passato, bloccato dall'autorità legale mancante.
- Versione applicativa: 6.1.3
- Stack aggiornato localmente: Ruby 4.0.6, Bundler 4.0.19, Rails 8.1.3.1, PostgreSQL 18.6, Node.js 24.20.0 LTS e Yarn 4.18.0
- Remediation P0, refresh dello stack e inizializzazione PostgreSQL 18 sono consolidati e pubblicati su `origin/main`.
- La remediation P1 A1-A5 e il programma UI/UX G02-G10 sono completati e verificati; la rimozione della credenziale A1 resta inclusa nella history riscritta.
- Le modifiche G06-G10 e l'abilitazione ChromeDriver Linux ARM64 sono complete e verificate ma restano intenzionalmente non committate/non pubblicate in questo worktree.
- PostgreSQL 18 è ora inizializzato sul volume persistente `airesisDB18`; app e database sono attivi rispettivamente sulle porte host 3001 e 5434.
- Il volume sorgente PostgreSQL 17 è risultato vuoto: non esistevano dati applicativi storici da trasferire. Il database corrente contiene schema e seed ufficiali del progetto.
- I volumi legacy PostgreSQL 17/Yarn 1 e le immagini non più usate sono stati rimossi dopo backup, restore di prova e controlli di integrità.
- Audit applicativo e stato remediation: [`audit_sicurezza.md`](audit_sicurezza.md)

## Punto di ripresa — G10 chiuso, bonifica completata

- **G10 ha superato il gate Impeccable a 37/40**, P0/P1/P2/P3 tutti a zero. Baseline: `.impeccable/critique/2026-08-30T16-06-20Z__app-views-admin.md`; finale: `.impeccable/critique/2026-08-30T16-52-00Z__app-views-admin.md`.
- Le assessment indipendenti finali hanno dato 39/40 visuale e 37/40 tecnico conservativo. Il detector G10 è stato eseguito esattamente una volta, exit 0 e JSON `[]`, e non è stato rilanciato nei follow-up.
- G10 ha ripristinato boot e strumenti operativi eliminando il riferimento legacy a `ManagerActions`; admin e moderator hanno gate separati, target utente deterministici, guard per self/ultimo admin e mutazioni soltanto POST/PATCH con 303/422.
- Newsletter: CRUD, preview e publish sono completi; markup sanitizzato senza ERB eseguibile, receiver allowlisted, conferma e conteggio destinatari, batch deduplicati e un job retryable per destinatario.
- Cleanup notifiche: enqueue dal panel, batch da 500, retention assoluta a sei mesi, unread recenti preservate, read oltre un mese rimosse senza doppio conteggio e matrice di regressione completa.
- RailsAdmin è montato a `/admin/data`, usa asset Sprockets reali e precompilabili, `<title>` nel `head`, landmark `main`, H1 e tema responsive con target da almeno 44 px. Rimossi dashboard Haml, login-as e stub vendor obsoleti.
- ElFinder top-level e le view controller CKEditor morte sono stati rimossi; la route inventory G10 è scesa da 33/13 GET a **22/8 GET**, senza action gap. L'inventario live complessivo è **403 route controller = 360 UI assegnate + 43 tecniche escluse**, senza route non assegnate.
- I pass cross-surface `animate`, `typeset` e `colorize` sono verdi: riduzione movimento globale, tipografia Sora coerente, misure di lettura controllate e colori semantici DaisyUI. Nessun effetto `overdrive` è stato applicato: per una superficie amministrativa la scelta intenzionale è prevedibilità, velocità e assenza di spettacolarizzazione.
- ChromeDriver Linux ARM64 è disponibile nel container tramite `chromium`/`chromium-driver`; ambiente `aarch64` verificato con Chromium e ChromeDriver 151.0.7922.173. Le system spec Selenium usano i binari espliciti e il vecchio blocco Selenium Manager è chiuso.
- Verifica finale sul diff: **332 esempi, 0 failure, 1 pending noto** (`ResqueMailer#invite`, setup legacy con arità errata); suite amministrativa/job finale **33 esempi, 0 failure**; RuboCop **106 file, 0 offense**; 150 ERB compilati; 5 YAML parsati; esbuild, Tailwind, `zeitwerk:check`, precompile production e `git diff --check` verdi.
- Sicurezza dipendenze: `bundle outdated --strict` riporta “Bundle up to date”; `bundle-audit` nessuna vulnerabilità; `yarn npm audit --all --recursive` nessun advisory. Brakeman termina senza errori di parsing e riporta 21 warning legacy separati (1 command injection, 9 XSS, 3 file access, 8 SQL injection).
- La bonifica finale ha sostituito il database development con il baseline PostgreSQL 18 verificato: conteggi identici al manifest per tutte le tabelle, `ui_audit_rows=0`, 1 utente seed, 0 gruppi e 0 proposte. `pg_amcheck` ha verificato 835/835 relazioni e 2.844 pagine; migrazioni allineate e smoke HTTP 200 su `/` e su `/landing` dopo il redirect canonico.
- Prima della bonifica è stato salvato il dump recuperabile ignorato da Git `tmp/database_backups/2026-08-30-pre-ui-cleanup/airesis-development.pre-ui-cleanup.dump`, SHA-256 `eb3133106f185b0357ef946381846a87d079b0c4564224c7c4bf2a31352b36b5`. Il database di transizione e i dump temporanei nel container sono stati rimossi.
- `public/assets` è output generato/ignorato, rigenerato con gli asset correnti e privo di dati applicativi.
- Prossimo passo funzionale possibile: G01 richiede testi e identità approvati dal titolare; resta `blocked_pending_legal_authority` e non va sbloccato inventando contenuti. In alternativa il worktree è pronto per review e per un eventuale commit/push soltanto su richiesta esplicita.

## Blocco appena completato — remediation P1 A1-A4

### A1 — credenziali Facebook storiche

- Rimossa da `config/initializers/omniauth.rb` la vecchia configurazione commentata con app ID e secret hard-coded.
- `config/initializers/devise.rb` continua a caricare le credenziali soltanto da `FACEBOOK_APP_ID` e `FACEBOOK_APP_SECRET`; una regressione impedisce di reintrodurre credenziali letterali nel vecchio initializer.
- Senza esporne i valori, è stato verificato che app ID e secret presenti nella configurazione locale sono entrambi diversi dai valori storici.
- L'utente ha confermato che la vecchia credenziale non esiste più su Meta.
- Bonificata tutta la history raggiungibile: riscritti con push atomico forzato `main`, `claude/refine-dashboard-design-6gaR1`, `v6.0.0` e `v6.1.0`. Nuovi riferimenti: `cfb2695`, `49292c4`, `616ffe9` e `719d1a9`.
- Un clone mirror fresco da GitHub non contiene né app ID né secret storici in nessuno dei 5.664 oggetti; anche il fetch diretto del vecchio commit non è più disponibile dal server.
- Il bundle di sicurezza e il clone temporaneo usati per il confronto sono stati eliminati definitivamente; reflog scaduti e garbage collection locale completata, con il vecchio commit non più presente nell'object database locale.
- I cloni esistenti devono riallinearsi alla nuova history senza ri-pubblicare vecchi branch o tag, altrimenti la credenziale revocata potrebbe essere reintrodotta nella cronologia raggiungibile.

### A2/A3 — stored XSS

- `ImageHelper#group_image_tag` usa ora il tag builder Rails; `group.name` viene escaped nell'attributo `alt`.
- La costruzione HTML è stata rimossa da `Taggable`: il nuovo `tag_links_for` usa `safe_join`, `link_to` e route Rails.
- Le tre view blog non usano più `raw` né `tags_with_links`.
- Le regressioni costruiscono payload con chiusura dell'attributo e tag `script`, poi verificano il DOM prodotto e l'assenza di nodi eseguibili.

### A4 — emissione token e rate limiting

- `TokensController#create` normalizza l'email, verifica prima la password e chiama `ensure_authentication_token!` solo per credenziali valide.
- Rack::Attack limita `POST /tokens` a 5 richieste/20 secondi per IP e 5 richieste/minuto per email normalizzata, anche per body JSON e IP distribuiti.
- Le spec provano sia il `429` per IP/email sia l'assenza di scritture del token dopo una password errata.

### Verifiche del blocco

- Suite P1 + integrazione blog/tag: **57 esempi, 0 failure** con `NO_COVERAGE=1` (la soglia SimpleCov globale non è significativa su una selezione mirata).
- Brakeman 8.0.6: i finding A2/A3 non sono più presenti. La verifica finale post-G10 non ha errori di parsing e conserva 21 warning legacy separati, inventariati nel punto di ripresa.
- RuboCop sui file Ruby toccati: nessuna nuova offense; resta il warning preesistente per l'argomento `vars` inutilizzato in `ApplicationHelper#pagy_nav`.
- `git diff --check`: pulito.
- Container applicativo riavviato per ricaricare l'initializer Rack::Attack; smoke test finale: HTTP 200 su `http://localhost:3001/`.

## Blocco precedente — inizializzazione PostgreSQL 18 e cleanup

### Sorgente e destinazione

- `airesis-develop_airesisDB`, creato per PostgreSQL 17, occupava 0 byte e non conteneva `PG_VERSION` né file del cluster.
- Non risultano dump `.sql`, `.dump` o `.backup` nel progetto Airesis né un PostgreSQL Airesis in ascolto sull'host.
- Non è quindi avvenuto un trasferimento di contenuti utente: PostgreSQL 18 ha creato `airesis-development` dal `db/schema.rb` corrente e ha caricato i seed del progetto.
- Dati seed principali: 1 utente amministratore locale, 247 Paesi, 551 regioni, 10.362 province e 75.118 comuni; gruppi e proposte sono vuoti.
- È stato creato anche `airesis-test` per le regressioni.

### Backup e prova di restore

- Backup persistente ignorato da Git: `tmp/database_backups/2026-08-29-pg18/airesis-development.pg18.dump`.
- SHA-256 dump: `59308acb846fc77c62203927947302c9130194fa0d47357d735005c6ab974f21`.
- Nella stessa directory sono presenti `globals.sql`, `SHA256SUMS`, query e manifest dei conteggi.
- Il dump custom è stato ripristinato con `--exit-on-error` nel database temporaneo `airesis_integrity_restore_20260829`.
- Hash dello schema originale/ripristinato: identico (`710eb70907d54b837136632d003a84d9d0e86e81c75390e5b719f0de06ba3a3e`).
- Hash dei dati originali/ripristinati: identico (`d9bd0dbc5eab5f38410820dd99f11464e534ff4bcc89070e8b536063d1cae75e`).
- Conteggi identici per tutte le 149 tabelle pubbliche; 149/149 constraint check/FK validati.
- `pg_amcheck`: 835 relazioni e 2.811 pagine controllate senza errori.
- Il database temporaneo e l'estensione `amcheck` aggiunta per il controllo sono stati rimossi dopo la verifica.

### Verifiche applicative e pulizia

- Nessuna migrazione Rails pendente.
- Suite P0 sul database persistente PostgreSQL 18: **70 esempi, 0 failure**.
- Installazione Yarn immutabile e build esbuild completate dopo la pulizia.
- Smoke test applicativo: HTTP 200 con 23.663 byte su `http://localhost:3001/`.
- Rimossi i volumi `airesis-develop_airesisDB` e `airesis-develop_node_modules`.
- Rimossi i tag immagine non referenziati `postgres:17-alpine` e `ruby:4.0.6` (la vecchia base Trixie fallita; l'immagine applicativa usa Bookworm).
- La cartella host `node_modules` ridondante è stata spostata nel Cestino come `/Users/mattia/.Trash/node_modules` ed è recuperabile finché il Cestino non viene svuotato.
- Nessun volume, container, immagine o cache MrWolf è stato modificato; non è stato eseguito alcun prune globale.
- Per evitare conflitti con servizi locali, Compose espone Airesis su `${AIRESIS_WEB_PORT:-3001}` e PostgreSQL su `${AIRESIS_POSTGRES_PORT:-5434}`.

## Blocco precedente — refresh completo agosto 2026

### Runtime e servizi

- `.ruby-version` e immagine Docker portati a Ruby 4.0.6.
- Rails portato da 8.1.3 a 8.1.3.1.
- Aggiunta esplicita di `resolv` 0.7.2 per le correzioni di sicurezza pubblicate ad agosto 2026.
- Bundler portato a 4.0.19.
- PostgreSQL portato da 17 a 18.6 usando `postgres:18.6-alpine`.
- Node.js portato da 18 a 24.20.0 LTS; rimosso `--openssl-legacy-provider`.
- Yarn Classic sostituito da Yarn 4.18.0 tramite Corepack; il progetto usa `nodeLinker: node-modules`.
- Mailpit fissato a 1.30.0.
- Il Dockerfile resta su Debian Bookworm perché l'app usa ancora `wkhtmltopdf`, non disponibile nell'immagine Ruby basata su Trixie.

### Gemme Ruby

- Eseguito un aggiornamento completo del bundle. Tutte le dipendenze dirette risultano alla release più recente compatibile.
- Il lockfile include entrambe le piattaforme Docker `aarch64-linux` e `x86_64-linux`.
- Aggiornamenti principali: Pagy 43.6.2, Workflow 3.1.1, Puma 8.0.2, RSpec Rails 8.0.4, Sentry 6.7.0, Solid Cable 4.0.2, Solid Queue 1.7.0 e SimpleCov 1.1.1.
- Aggiunti `bundler-audit` 0.9.3 e Brakeman 8.0.6 agli strumenti di sviluppo/test.
- Rimossi componenti senza punti d'uso: `thin`, `codeclimate-test-reporter`, `crowdin-api`, la relativa dipendenza diretta `rubyzip`, `rails_12factor` e `sdoc`.
- L'integrazione Crowdin non aveva codice eseguibile nel repository; le sue variabili obsolete sono state rimosse da `config/application.example.yml`.
- Il passaggio Pagy 9 → 43 ha richiesto la nuova API `Pagy::Method`, `pagy(:offset, ..., limit:)` e l'adeguamento della navigazione DaisyUI.
- L'initializer WickedPDF usa ora `WickedPdf.configure`.

Residui transitive intenzionali da non aggiornare isolatamente:

- `celluloid` 0.16, `listen` 2.10 e `timers` 4.0 sono vincolate da `mailman` 0.7.3, ancora usato da `Procfile`, initializer e task ricorrenti per la posta in ingresso;
- `marcel` 1.2 è vincolata da Active Storage 8.1;
- `diff-lcs` 1.6 è vincolata dalla serie RSpec 3.

Sostituire `mailman` o `wkhtmltopdf` è un intervento architetturale separato: entrambi hanno punti d'uso attivi e non possono essere rimossi come semplice pulizia del bundle.

### Dipendenze JavaScript

- Portate alle release correnti compatibili Sentry Browser 10.72.0, ApexCharts 7.0.0, DaisyUI 5.7.22, Sass 1.103.1, Trix 2.1.19 ed esbuild 0.28.2.
- FullCalendar resta coerentemente sulla serie 6.1.21: il solo core 7 è disponibile, ma i plugin ufficiali usati dall'app sono ancora 6.1.21 e dichiarano peer dependency sul core 6.
- Forzate release transitive corrette: Turbo 8.0.23, DOMPurify 3.4.14 e Immutable 5.1.9.
- Lockfile migrato al formato Yarn 4 e deduplicato.
- `yarn npm audit --all --recursive`: nessun advisory.

## Verifiche eseguite sullo stack aggiornato

- Build finale dell'immagine `airesis-develop-airesis`: completata.
- Bootstrap applicazione: Rails 8.1.3.1 e Pagy 43.6.2 caricati correttamente.
- Runtime verificati dall'immagine: Ruby 4.0.6, Bundler 4.0.19, Rails 8.1.3.1, Node 24.20.0, npm 11.19.0 e Yarn 4.18.0.
- Server verificato nel container isolato: PostgreSQL 18.6.
- `rails db:prepare` su PostgreSQL 18.6 temporaneo: completato.
- Build esbuild con Yarn 4 e le dipendenze aggiornate: completata.
- `yarn install --immutable`: completato durante la build Docker.
- Suite P0 mirata: **70 esempi, 0 failure**.
- Suite estesa non-system, esclusi i due file non caricabili: **1516 esempi, 14 failure, 2 pending**. Non sono emerse regressioni legate all'upgrade.
- `bundle-audit check --update`: nessuna vulnerabilità nota nel bundle.
- Audit npm/Yarn: nessun advisory dopo gli override transitive.
- `bundle outdated --only-explicit`: nessuna gemma diretta aggiornabile.
- `git diff --check`: pulito.

RuboCop 1.90 sui 27 file Ruby modificati segnala quattro offense preesistenti, tutte fuori dalle righe di questo upgrade: due suggerimenti `params.expect`, uno spazio doppio e l'argomento legacy `vars` del wrapper `pagy_nav`.

Il controllo Brakeman corrente, successivo alla remediation P1, è riportato nel blocco iniziale di questo handoff; i warning residui appartengono a filoni di sicurezza separati.

L'unico warning di compatibilità osservato al boot proviene da RailsAdmin 3.3.0 e riguarda stringhe che Ruby renderà frozen in futuro; non impedisce l'avvio su Ruby 4.0.6.

## Stato corrente delle verifiche

- Tutte le spec Ruby modificate o aggiunte dal programma attivo sono state eseguite insieme: **332 esempi, 0 failure, 1 pending**.
- Il solo pending è `ResqueMailer#invite`: il setup legacy passa due argomenti a un'interfaccia che ne accetta uno. Non riguarda i flussi newsletter G10, coperti separatamente e verdi.
- `Admin::PanelController` carica correttamente e `zeitwerk:check` è verde; il vecchio blocco `ManagerActions` non esiste più.
- La vecchia suite globale da 1.516 esempi non è stata rieseguita integralmente in questo blocco; i suoi 14 failure storici non descrivono lo stato del diff G06-G10 e non vanno usati come regressioni correnti.
- Il file legacy `spec/lib/resque/failure/notifier2_spec.rb` continua a richiedere un'implementazione già eliminata ed è fuori dal perimetro del diff corrente.

## Remediation P0 preservata

Le correzioni precedenti sono presenti nel baseline committato e riscritto `cfb2695`:

- `TokensController` non registra più credenziali nei login API falliti;
- `UsersController#update` autorizza l'utente e impedisce l'IDOR/account takeover;
- OAuth Facebook usa TLS peer verification;
- PayPal IPN richiede HTTPS e `VERIFY_PEER`;
- sorgente Rubygems su HTTPS;
- relative regressioni in request, controller, config e ability spec.

Resta separata la validazione semantica dell'IPN PayPal: destinatario, valuta/importo e unicità di `txn_id` richiedono i valori attesi dell'applicazione.

## Volumi e risorse locali

- Compose usa `airesisDB18` montato su `/var/lib/postgresql`, come richiesto dall'immagine ufficiale PostgreSQL 18.
- Compose usa `node_modulesYarn4`; il vecchio volume Yarn 1 è stato rimosso.
- Le sole risorse Docker Airesis persistenti rimaste sono `airesisDB18` e `node_modulesYarn4`.
- `airesis-develop-db-1` e `airesis-develop-airesis-1` sono attivi; usare `docker compose stop` per arrestarli senza eliminare i volumi.
- Il PostgreSQL 18 temporaneo usato per test, `airesis-ruby4-pg18-test`, era senza porte, su tmpfs ed è stato arrestato/rimosso.
- Il PostgreSQL di MrWolf sulla porta 5433 non è stato toccato.

## Worktree da preservare

Non usare restore/reset/clean. Il worktree contiene l'intero blocco G06-G10 e ChromeDriver ARM64 non committato: va preservato integralmente. Le fixture `[UI AUDIT]` sono già state bonificate dal database locale e non devono essere ricreate salvo un nuovo audit esplicito. Non eseguire commit o push senza una nuova richiesta esplicita. La history già pubblicata comprende:

- autenticazione token: `app/controllers/tokens_controller.rb`, `config/initializers/rack_attack.rb` e `spec/requests/tokens_controller_spec.rb`;
- escaping immagini/tag: `lib/image_helper.rb`, `app/helpers/application_helper.rb`, `app/models/concerns/taggable.rb`, le tre view blog e le relative spec;
- credenziali Facebook: regressione in `spec/config/omniauth_security_spec.rb`; l'initializer bonificato è già nel baseline riscritto;
- stato operativo: `audit_sicurezza.md` e questo `HANDOFF.md`.
- programma UI/UX pubblicato: stato fino a G05; nel worktree sono presenti coverage, snapshot e implementazione completa G06-G10, incluse system spec Selenium ARM64;
- regressioni G01: request spec di `HomeController`/`GroupsController` e spec helper per il contatto pubblico configurato.

`.claude/settings.local.json` e `meta.json` restano materiale locale e non devono essere aggiunti al repository.

## Programma UI/UX — stato consolidato

- Obiettivo richiesto: critique Impeccable, applicazione dei rilievi e nuova critique fino ad almeno 33/40 per ogni gruppo; chiusura con `animate`, `typeset`, `colorize` e `overdrive`.
- Inventario persistente: `.impeccable/ui-ux-coverage.yml`.
- Copertura corrente: 10 gruppi, 360 route UI assegnate e 43 endpoint tecnici non visuali esclusi esplicitamente; inventario live riconciliato **403/403** dopo la potatura finale G10.
- Autorizzazione sub-agent Impeccable ricevuta dall'utente; ogni iterazione critique usa due assessment indipendenti e read-only, A design/Nielsen e B detector/browser.
- G01 — pubblico, accesso e onboarding: baseline **17/40**, iterazione 3 **28/40**, iterazione 4 **28/40**. Le correzioni successive hanno chiuso contrasto (6,20:1 misurato), drawer modale, nomi/focus dei dialog, target secondari, landmark, empty state e 404. Il detector dell'iterazione 4 ha restituito `[]`, ma in fallback regex perché mancano `htmlparser2`, `css-select`, `css-tree` e `domutils`; il risultato è un undercount dichiarato.
- G01 resta `blocked_pending_legal_authority`: il gate 33/40 richiede zero P1, ma Privacy 2018, Termini solo italiani e consenso obbligatorio necessitano testo approvato, data effettiva, identità del titolare/operatore, contatto reale e provider di deployment. Il repository e la history non contengono una fonte più autorevole. Il vecchio `info@airesis.it` non viene più presentato come contatto corrente: è usato solo `APP_EMAIL_ADDRESS` se valido e non-placeholder, altrimenti l'interfaccia dichiara che il contatto non è configurato.
- Evidenza G01: build esbuild e Tailwind verdi; **73 request spec + 2 spec helper, 0 failure** con `NO_COVERAGE=1`; 13 route guest verificate a 1440×900 e 390×844 senza overflow, con redirect `/landing` e 404 reale. La suite helper più ampia ha un test preesistente dipendente dal cambio data a mezzanotte (`30.minutes.ago` cade nel giorno precedente).
- Snapshot persistiti: `.impeccable/critique/2026-08-29T20-41-55Z__app-views-devise.md`, `.impeccable/critique/2026-08-29T22-07-25Z__app-views-devise.md` e `.impeccable/critique/2026-08-29T22-21-39Z__app-views-devise.md`.
- G02 — shell, dashboard, identità e notifiche: **passed 33/40**, iterazione 4, P0/P1 zero. Baseline 13/40, iterazione 2 29/40, iterazione 3 31/40. Corrette route morte/rotte, notifiche con lettura esplicita, ricerca HTML/JSON, dashboard first-run, profilo e preferenze, statistiche senza `NaN`, navigazione locale, contrasto, dialog/drawer/popup, nomi accessibili, skip link e pagine archivio italiane dichiarate. Le 14 superfici HTML passano a desktop/mobile senza overflow, errori runtime, H1/main mancanti o traduzioni assenti; gli endpoint geografici sono JSON di supporto. Build esbuild/Tailwind verdi; **88 request spec, 0 failure, 1 pending noto** per fixture Alert. Il blocco infrastrutturale Selenium ARM descritto nello snapshot storico è ora risolto dall'installazione Chromium/ChromeDriver di G07; le specifiche G02 non sono state rilanciate in questo blocco.
- Snapshot G02: `.impeccable/critique/2026-08-29T22-42-52Z__app-views-users.md`, `2026-08-29T23-11-56Z__app-views-users.md`, `2026-08-29T23-34-22Z__app-views-users.md` e `2026-08-29T23-42-03Z__app-views-users.md`.
- G03 — proposte, scoperta, creazione e lettura: **passed 37/40**, iterazione 4, P0/P1 zero; il detector finale ha P2 zero. Baseline 15/40, iterazione 2 29/40, iterazione 3 33/40 ma gate fallito per il sort verso la partial. Listing, new, show, edit, JSON categorie, banner/test banner, Trix e drawer sono stati verificati a desktop/mobile. Build verdi; **107 spec helper/request, 0 failure**.
- Snapshot G03: `.impeccable/critique/2026-08-29T23-58-01Z__app-views-proposals.md` e `.impeccable/critique/2026-08-30T00-42-19Z__app-views-proposals.md`.
- G04 — deliberazione, commenti, quorum e voto: **passed 38/40**, iterazione 2, P0/P1/P2 zero. Baseline 12/40 con sei flussi bloccanti; route fantasma potate, voto standard/Schulze reso semantico e persistente, storico revisioni e supporti riparati, quorum responsive, commenti accessibili e noise manager operabile anche da tastiera. Nove superfici desktop/mobile senza overflow o errori runtime; detector finale `[]`; **35 request/model spec, 0 failure** e build verdi.
- Snapshot G04: `.impeccable/critique/2026-08-30T09-00-27Z__app-views-proposal-comments.md` e `.impeccable/critique/2026-08-30T09-44-03Z__app-views-proposal-comments.md`.
- G05 — gruppi, profilo e membership: **passed 33/40**, iterazione 2, P0/P1 zero. Baseline 13/40 con membri in 500 e navigazione/azioni invisibili; ricostruiti listing, profilo, form, gestione membri, inviti e permessi, ristrette le operazioni batch al gruppo autorizzato e potate 21 route morte. Sette superfici desktop/mobile senza overflow o errori runtime; detector finale `[]`; **111 request/model/helper spec, 0 failure**, RuboCop e build verdi.
- Snapshot G05: `.impeccable/critique/2026-08-30T10-21-19Z__app-views-groups.md` e `.impeccable/critique/2026-08-30T11-08-47Z__app-views-groups.md`.
- G06 — governance aree, ruoli e permessi: **passed 33/40**, iterazione 2, P0/P1 zero. Route 26/9 GET; scope tenant-safe, default protetti, form/errori Turbo e accessibilità verificati. Snapshot baseline/finale: `.impeccable/critique/2026-08-30T11-41-07Z__app-views-group-areas.md` e `.impeccable/critique/2026-08-30T12-25-21Z__app-views-group-areas.md`.
- G07 — eventi e calendario: **passed 35/40**, iterazione 2, P0/P1/P2 zero. Route 26/8 GET; creazione atomica, voting state machine, commenti/RSVP, calendario responsive e mappa verificati con browser reale e Selenium ARM64. Snapshot baseline/finale: `.impeccable/critique/2026-08-30T12-28-03Z__app-views-events.md` e `.impeccable/critique/2026-08-30T13-24-16Z__app-views-events.md`.
- G08 — blog, tag, documenti e contenuti: **passed 38/40**, iterazione 3, P0/P1/P2 zero. Route 39/20 GET; blog/post/commenti, tag, document lifecycle, hardening path/MIME, delete mobile e skip link verificati con browser reale e Selenium ARM64. Snapshot baseline/finale: `.impeccable/critique/2026-08-30T13-58-52Z__app-views-blogs.md` e `.impeccable/critique/2026-08-30T15-04-24Z__app-views-blogs.md`.
- G09 — forum e moderazione: **passed 36/40**, iterazione 3, P0/P1/P2 zero. Route 47/20 GET; workflow persistito, moderazione e associazioni tenant-scoped, verbi sicuri, Trix, layout responsive e target da 44 px verificati con browser reale e Selenium ARM64. Snapshot baseline/finale: `.impeccable/critique/2026-08-30T15-11-34Z__app-views-frm.md` e `.impeccable/critique/2026-08-30T15-59-16Z__app-views-frm.md`.
- G10 — amministrazione e strumenti operativi: **passed 37/40**, iterazione 3, P0/P1/P2/P3 zero. Route 22/8 GET; gate admin/moderator, newsletter, cleanup notifiche, RailsAdmin, asset production e operazioni privilegiate verificati. Snapshot baseline/finale: `.impeccable/critique/2026-08-30T16-06-20Z__app-views-admin.md` e `.impeccable/critique/2026-08-30T16-52-00Z__app-views-admin.md`.
- Prossimo passo operativo: ottenere dal titolare l'autorità e i contenuti legali necessari a G01, oppure review/commit del worktree su richiesta esplicita. Non esiste un G11 pianificato.

Il finding sicurezza A5 sulla moderazione forum è chiuso in G09 con scope per forum, allowlist, parametri stretti e regressioni cross-tenant/distruttive.

## Vincoli per la ripresa

- Non fare ulteriori commit, push, merge, deploy, migrazioni o modifiche a servizi esterni senza richiesta esplicita.
- Conservare insieme le correzioni P0 e il refresh stack appena completato.
- Se viene recuperato un dump storico, ripristinarlo prima in un database temporaneo e confrontarlo con manifest e vincoli prima di sostituire `airesis-development`.
- Usare test mirati durante l'implementazione e mantenere come baseline corrente la suite sul diff da 332 esempi descritta sopra.
- Aggiornare questo handoff al termine del prossimo blocco, sostituendo il punto di ripresa invece di accumulare note contraddittorie.
