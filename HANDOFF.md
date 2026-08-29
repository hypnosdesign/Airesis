# Handoff operativo — Airesis

> Aggiornato il 2026-08-29. Questo è il punto di ripresa corrente.
> La prossima sessione deve leggere questo file prima di modificare il repository, senza chiedere all'utente di ricostruire il contesto.

## Stato in breve

- Repository: `/Users/mattia/Projects/Airesis_Site/airesis-develop`
- Branch: `main`; HEAD di partenza del lavoro locale: `0692178`
- Versione applicativa: 6.1.3
- Stack aggiornato localmente: Ruby 4.0.6, Bundler 4.0.19, Rails 8.1.3.1, PostgreSQL 18.6, Node.js 24.20.0 LTS e Yarn 4.18.0
- Il worktree contiene sia la remediation P0 precedente sia il refresh completo dello stack di agosto 2026.
- Lo stato operativo consolidato comprende remediation P0, refresh dello stack e inizializzazione PostgreSQL 18; verificare `git log` e `git status` per l'identificativo del commit corrente.
- PostgreSQL 18 è ora inizializzato sul volume persistente `airesisDB18`; app e database sono attivi rispettivamente sulle porte host 3001 e 5434.
- Il volume sorgente PostgreSQL 17 è risultato vuoto: non esistevano dati applicativi storici da trasferire. Il database corrente contiene schema e seed ufficiali del progetto.
- I volumi legacy PostgreSQL 17/Yarn 1 e le immagini non più usate sono stati rimossi dopo backup, restore di prova e controlli di integrità.
- Audit applicativo e stato remediation: [`audit_sicurezza.md`](audit_sicurezza.md)

## Blocco appena completato — inizializzazione PostgreSQL 18 e cleanup

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

Brakeman 8.0.6 termina con 6 warning applicativi e un errore di parsing su una view legacy. I due XSS sui tag corrispondono al finding A3 già presente nell'audit; gli altri warning richiedono analisi nel filone sicurezza e non sono stati modificati implicitamente durante l'upgrade.

L'unico warning di compatibilità osservato al boot proviene da RailsAdmin 3.3.0 e riguarda stringhe che Ruby renderà frozen in futuro; non impedisce l'avvio su Ruby 4.0.6.

## Stato noto della suite estesa

Le 14 failure rimaste appartengono al debito già noto prima del refresh:

- aspettativa obsoleta in `StepsHelper`;
- `ProposalsHelper` privo di `reload_message` nel contesto dello spec;
- view spec eventi priva di `for_list`;
- flussi registrazione/sessione che ricevono `429` perché la cache Rack::Attack resta condivisa nella suite;
- errori successivi nei flussi auth dovuti agli utenti non creati dopo i `429`;
- aspettativa della coda job in `NotificationForumTopicCreate`.

Due file bloccano ancora il caricamento della suite completa:

- `spec/lib/resque/failure/notifier2_spec.rb` richiede il file eliminato `lib/resque/failure/notifier2`;
- `spec/requests/admin/panel_controller_spec.rb` carica `Admin::PanelController`, che include il modulo mancante `ManagerActions`.

Lo stesso `ManagerActions` blocca il `zeitwerk:check` completo. Questi guasti non sono stati ampliati implicitamente nel refresh dello stack.

## Remediation P0 preservata

Le correzioni precedenti sono ancora presenti sopra il worktree sporco:

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

Non usare restore/reset/clean. Oltre ai file runtime, Docker, Gemfile/lock, package/lock e alla migrazione Pagy, il worktree contiene ancora intenzionalmente:

- i controller, initializer, ability e test della remediation P0;
- `audit_sicurezza.md`;
- `spec/config/omniauth_security_spec.rb`;
- `spec/controllers/users/facebook_controller_spec.rb`;
- questo `HANDOFF.md` e `AGENTS.md`.

`.claude/settings.local.json` e `meta.json` restano materiale locale e non devono essere aggiunti al repository.

## Prossimo blocco consigliato — P1 sicurezza

Procedere in piccoli cambiamenti indipendenti, con una regressione per ogni fix:

1. rimuovere il secret Facebook storico commentato; rotazione e bonifica Git richiedono un'azione esterna;
2. correggere lo stored XSS via `group.name` in `lib/image_helper.rb`;
3. correggere lo stored XSS via tag in `app/models/concerns/taggable.rb` e relative view;
4. aggiungere throttle Rack::Attack a `/tokens` e spostare la generazione token dopo la verifica della password.

## Vincoli per la ripresa

- Non fare ulteriori commit, push, merge, deploy, migrazioni o modifiche a servizi esterni senza richiesta esplicita.
- Conservare insieme le correzioni P0 e il refresh stack appena completato.
- Se viene recuperato un dump storico, ripristinarlo prima in un database temporaneo e confrontarlo con manifest e vincoli prima di sostituire `airesis-development`.
- Usare test mirati durante l'implementazione; la suite estesa ha i guasti noti sopra.
- Aggiornare questo handoff al termine del prossimo blocco, sostituendo il punto di ripresa invece di accumulare note contraddittorie.
