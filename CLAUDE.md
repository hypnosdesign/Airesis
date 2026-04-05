# CLAUDE.md — Airesis

> Analisi iniziale: 2026-03-31.
> Ultimo aggiornamento: 2026-04-05 — Rails 8.1.3 ✓, Ruby 3.4.4 ✓, Solid Queue ✓, APP_VERSION 6.0.0 ✓. Fasi 1–7 completate. Copertura test: ~80% ✓. Zero jQuery, zero .js.erb, 100% Hotwire (Turbo + Stimulus).
> Obiettivo: modernizzare l'app per renderla funzionante e manutenibile nel 2026.

---

## Cos'è questa app

**Airesis** è una piattaforma open source di e-democracy e partecipazione civica.
Permette a utenti e gruppi di creare proposte, votarle (sistema Schulze), discuterle via forum e blog, organizzare eventi, e gestire processi decisionali collettivi.

È un'app Rails monolitica con API v1, pannello admin, sistema di notifiche asincrono e supporto multilingua per oltre 20 locale.

Repo originale: https://github.com/coorasse/airesis (branch `develop`)

---

## Stack — stato attuale

| Componente     | Versione originale | Versione attuale | Target              |
|----------------|-------------------|-----------------|---------------------|
| Ruby           | 2.7.5 (EOL)       | **3.4.4** ✓     | 3.4.x               |
| Rails          | 6.0.3.1 (EOL)     | **8.1.3** ✓     | 8.1.x               |
| PostgreSQL     | qualsiasi         | 14-alpine ✓     | 14+                 |
| Redis          | qualsiasi         | **rimosso** ✓   | non necessario      |
| Sidekiq        | 6.1.2             | **rimosso** ✓   | Solid Queue (Rails 8 nativo) |
| Devise         | 4.7.1             | **5.0.3** ✓     | 5.x                 |
| CanCanCan      | 3.1.1             | **3.6.1** ✓     | 3.x                 |
| rails_admin    | 2.0.1             | **3.3.0** ✓     | 3.x                 |
| paper_trail    | 10.3.1            | **14.0.0** ✓    | 14.x                |
| Webpacker      | 5.1.1             | **rimosso** ✓   | jsbundling + esbuild  |
| jsbundling-rails | —               | **installato** ✓ | esbuild bundler      |
| Foundation CSS | 5.0               | **Foundation 5 + TailwindCSS** (ibrido) | solo Tailwind v4 + DaisyUI |
| Font Awesome   | 4.7               | **6.x** ✓       | font-awesome-sass    |
| Turbolinks     | 5.x               | **rimosso** ✓   | Turbo (Hotwire)      |
| jQuery         | jquery-rails       | **ancora attivo** | da rimuovere (Fase 4-R) |
| Sentry gem     | sentry-raven 3.x  | **sentry-rails 6.5** ✓ | sentry-rails  |

---

## Struttura del progetto

```
app/
  models/        # 117 modelli
  controllers/   # 73 controller (namespace: api/v1, admin/, frm/)
  workers/       # 37 ActiveJob workers (ex Sidekiq)
  cancan/        # abilities (Guest, Logged, Moderator, Admin)
  views/         # ERB (500+ file). Tutte con classi Tailwind/DaisyUI. Zero file Slim.
config/
  initializers/  # 43 file (aggiunti zeitwerk.rb, new_framework_defaults_6_1.rb)
  locales/       # 20+ lingue
spec/            # RSpec, ~7400 linee
```

### Namespace principali
- `Api::V1::` — API REST con token auth
- `Admin::` — pannello amministrativo (rails_admin + controller custom)
- `Frm::` — forum integrato (Topics, Posts, Forums, Categories)

### Modelli chiave
- `User` — 52 relazioni, Devise + OmniAuth (Facebook/Google/Twitter)
- `Proposal` — entità centrale, stati via `workflow` gem, voto Schulze
- `Group` — comunità con ruoli, eventi, blog, forum
- `Event` — incontri con partecipanti e commenti
- `Alert` / `Notification` — sistema notifiche (20+ ActiveJob worker)

---

## Autenticazione e autorizzazione

- **Devise 5** — registrazione, login, conferma email, password reset
- **OmniAuth** — Facebook, Google OAuth2, Twitter
- **simple_token_authentication** — token API
- **CanCanCan 3** — autorizzazione a ruoli (Guest < Logged < Moderator < Admin)
- **Rack::Attack** — rate limiting e blocco probe

---

## Job asincroni (Solid Queue)

Queue configurate in `config/queue.yml` (Solid Queue, Rails 8 nativo, no Redis):
- `high_priority` — alta priorità (AlertsWorker)
- `notifications` — notifiche (NotificationSender e subclassi)
- `default` — default (ProposalsWorker, EventsWorker)
- `low_priority` — bassa priorità (EmailsWorker, UpdateSitemap)
- `mailers` — email (ResqueMailer via deliver_later)

Avvio: `bundle exec rails solid_queue:start`

---

## Docker

Avvio sviluppo:
```bash
docker compose up
```

Servizi:
- `airesis` — app Rails (porta 3000). Nota: `NODE_OPTIONS=--openssl-legacy-provider` ancora nel docker-compose (legacy Webpack, da rimuovere in Fase 4-R)
- `db` — PostgreSQL 14 (porta 5433, user `postgres`, trust auth)
- `solid_queue` — Solid Queue worker (porta nessuna, DB-backed)

Comandi utili:
```bash
# Creare il database (prima volta)
docker compose run --rm airesis bundle exec rails db:create db:schema:load

# Migrazioni
docker compose run --rm airesis bundle exec rails db:migrate

# Compilare gli asset (necessario dopo ogni deploy o cambio JS/CSS)
docker compose run --rm -e RAILS_ENV=development -e NODE_OPTIONS=--openssl-legacy-provider airesis bundle exec rails assets:precompile

# Aggiornare gem e ricostruire l'immagine
docker compose run --rm airesis bundle update <gem>
docker compose build
```

---

## Variabili d'ambiente necessarie

Copiare `config/application.example.yml` → `config/application.yml` e compilare.
Il file è gestito da **Figaro** e caricato automaticamente.

Variabili minime per development (già in `config/application.yml`):
```bash
SECRET_KEY_BASE / DEVISE_SECRET_KEY
DATABASE_URL (override via docker-compose)
REDIS_URL (override via docker-compose)
MAILER_DEFAULT_HOST=localhost:3000
ADMIN_EMAIL / ADMIN_PASSWORD
```

Variabili aggiuntive per produzione:
```bash
SMTP_ADDRESS / SMTP_PORT / SMTP_USER / SMTP_PASSWORD
AWS_HOST / AWS_BUCKET / AWS_REGION / AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
SENTRY_DSN
RECAPTCHA_PUBLIC / RECAPTCHA_PRIVATE
FACEBOOK_APP_ID / FACEBOOK_APP_SECRET
GOOGLE_APP_ID / GOOGLE_APP_SECRET
TWITTER_APP_ID / TWITTER_APP_SECRET
FORCE_SSL=true
RAILS_LOG_TO_STDOUT=true
```

---

## Test

- Framework: **RSpec** + FactoryBot + Capybara + Selenium
- Copertura attuale: **~80.23%** (1498 esempi, 0 failure al 2026-04-04) — target 80% ✓ raggiunto
- Copertura minima configurata in SimpleCov: **70.0%**
- Run in Docker: `docker compose run --rm -e RAILS_ENV=test airesis bundle exec rspec`
- Escludi system spec (Selenium non disponibile nel container): `docker compose run --rm -e RAILS_ENV=test airesis bundle exec rspec --exclude-pattern "**/system/**/*_spec.rb"`
- CI: Travis CI (`.travis.yml`) + Semaphore (`.semaphore/`)

---

## Roadmap di refactoring

### Fase 1 — Ambiente funzionante ✅
1. ✅ Dockerfile corretto (Ruby 2.7.5, Node 18, Yarn, dipendenze sistema)
2. ✅ `docker-compose.yml` aggiornato a formato v3.8 (Postgres 14, Redis 7)
3. ✅ `config/application.yml` creato per development
4. ✅ Schema caricato (133 tabelle), app risponde HTTP 200

### Fase 2 — Upgrade Rails ✅
5. ✅ Rails 6.0 → **6.1.7.10**
   - `paper_trail` 10→14, `bullet` 6→8, `bootsnap` 1.4→1.23
   - `require 'logger'` in `config/boot.rb`, `bin/webpack`, `bin/webpack-dev-server`
   - `belongs_to :default_role` → `:default_participation_role` / `:default_area_role` (conflitto con `AR::Base.default_role` in Rails 6.1)
   - Named volume `node_modules` in docker-compose
6. ✅ Rails 6.1 → **7.0.10**
   - `devise` 4→5, `cancancan` 3.1→3.6, `rails_admin` 2→3, `simple_form` 5.0→5.4
   - `config/initializers/rails_admin.rb` wrappato in `config.to_prepare`
   - `config/initializers/zeitwerk.rb` — esclude `lib/rails_admin/` da Zeitwerk
   - `config.action_view.raise_on_missing_translations` → `config.i18n.raise_on_missing_translations`
   - `NODE_OPTIONS=--openssl-legacy-provider` per Webpack 4 + Node 18 + OpenSSL 3
7. ✅ Rails 7.0 → **7.1.6**
   - `config.load_defaults 7.1`
   - `I18n.t()` class-load-time in `user.rb` → lambda `-> { I18n.t() }` (Rails 7.1 triggers `raise_on_missing_translations` prima del runtime)
   - Aggiunta chiave mancante `activerecord.errors.messages.privacy` in `config/locales/activerecord.en-EU.yml`
   - `config/initializers/rails_admin.rb`: aggiunto `RailsAdmin.config { config.asset_source = :webpacker }` fuori da `to_prepare` (per il railtie check)
   - `rails_admin:install` → `asset_source = :webpacker`, crea `app/javascript/packs/rails_admin.js` e stylesheet
   - Stub Sprockets: `vendor/assets/javascripts/rails_admin/application.js` e `vendor/assets/stylesheets/rails_admin/application.css` per evitare che Sprockets compili il manifest della gem (i file `.js`/`.scss` rails_admin sono solo in `src/` per webpacker, non nel path Sprockets)
   - `paper_trail` 14.x: warning (non upgrade) — PaperTrail 15+ richiede Ruby ≥ 3.0, da aggiornare dopo upgrade Ruby
8. ✅ Ruby 2.7.5 → **3.2.8**
   - `FROM ruby:3.2.8` in Dockerfile
   - `pg` 1.2.3 → 1.6.3 (Ruby 3.2: `rb_cData` conflict con la nuova classe `Data`)
   - `paper_trail` 14 → 17 (richiede Ruby ≥ 3.0; aggiunto `gem 'paper_trail', '>= 15'`)
   - `gem 'matrix'` aggiunto: rimossa da stdlib Ruby 3.1, richiesta da `vote-schulze`
   - `binding_of_caller` 0.8→1.0, `better_errors` 2.7→2.10, `byebug` 11→13, `pry-byebug` 3.9→3.12, `rack-mini-profiler` 2→4
   - `pry` 0.13→0.16, `pry-rails` 0.3.9→0.3.11 (`Object#=~` rimosso in Ruby 3.x)
   - `friendly_id` 5.3→5.6 (`has_many` con 3 argomenti non più supportato in AR 7.1)
   - Psych 5.0 (Ruby 3.1+) disabilita YAML aliases: patch in `config/boot.rb` per compatibilità con Webpacker 5.x e altri gem. Rimuovere in Fase 3 con Webpacker.
   - Workflow gem aggiornamento: usare `docker create / docker cp / docker rm` per estrarre Gemfile.lock aggiornato dall'immagine dopo ogni build
9. ✅ Sostituire `sentry-raven` con `sentry-ruby` + `sentry-rails`
   - `sentry-raven` rimosso dal gruppo `:production`; aggiunti `sentry-ruby 6.5.0` + `sentry-rails 6.5.0`
   - `config/initializers/sentry.rb`: `Raven.configure` → `Sentry.init` con `send_default_pii: false` e `breadcrumbs_logger`
   - `app/controllers/application_controller.rb`: `Raven.capture_exception` → `Sentry.with_scope` + `Sentry.capture_exception`

### Fase 3 — Gem deprecate
10. ✅ Migrare **Paperclip** → Active Storage
    - Aggiunti `has_one_attached` ai modelli `User`, `Group`, `SentFeedback`, `Image`, `Ckeditor::Picture`, `Ckeditor::AttachmentFile`.
    - Eseguite migrazioni per le tabelle Active Storage.
    - Aggiunta gemma `active_storage_validations`.
11. ✅ Rimuovere **coffee-rails**, convertire `.coffee` in ES6+
    - Convertiti 36 file `.coffee` in `.js`.
    - Rimosso `coffee-rails` dal Gemfile.
12. ✅ Sostituire **Webpacker** con `jsbundling-rails` + `esbuild`
    - Rimosso `webpacker` dal Gemfile e `package.json`.
    - Aggiunta gemma `jsbundling-rails`.
    - Configurato `esbuild` come bundler JS.
    - Spostati entry point da `app/javascript/packs/` a `app/javascript/`.
    - Aggiornati layout e RailsAdmin per usare il nuovo sistema.
    - Rimossi file di configurazione Webpacker.



### Fase 4 — Frontend ✅
13. ✅ Foundation 5 → TailwindCSS + DaisyUI
    - Installato `tailwindcss-rails` (Tailwind v4) + DaisyUI 5.x come plugin.
    - DaisyUI build: `@plugin "daisyui"` in `app/assets/tailwind/application.css`.
    - Stile neobrutalista: `--radius-*: 0rem`, `--border: 2px`, ombre solide `.shadow-brutal`.
    - **TUTTE le view convertite a ERB + DaisyUI** (0 file Slim, ~500 file ERB).
    - gem `slim-rails` rimossa dal Gemfile.
    - **Ancora attive:** gem `foundation-rails ~> 5.0` (CSS importato da `application.css.scss`), `jquery-rails` (327 file JS legacy via Sprockets).
14. 🔄 Adottare Hotwire (Turbo + Stimulus) — rimuovere jQuery + Turbolinks
    - Turbolinks rimosso, `turbo-rails` importato in `application.js` e funzionante.
    - Stimulus controller attivi: `theme` (dark/light toggle), `flash` (DaisyUI toast, sostituisce toastr.js).
    - **toastr.js sostituito** — flash messages ora DaisyUI toast + Stimulus, zero jQuery.
    - **Pendente:** `jquery-rails` gem ancora attiva. 327 file JS legacy (57.892 LOC) via Sprockets. Plugin jQuery rimanenti: qtip, fdatetimepicker, switchbutton, tokeninput, fullcalendar, jqplot, steps, textntags, intro.js. `private_pub` (Faye) ancora attivo.
15. ✅ Aggiornare Font Awesome 4.7 → 6.x
    - Sostituito `font-awesome-rails` con `font-awesome-sass`.
    - Eseguita migrazione batch di oltre 100 icone nelle view.
16. ✅ Conversione view a ERB + DaisyUI (completata in Fase 4-R.1)
    - Convertiti TUTTI i file Slim (460+) a ERB con classi Tailwind/DaisyUI.
    - Zero file `.slim` in `app/views/`.

### Fase 5 — Qualità e manutenibilità
17. ✅ Refactoring `User` model in Concerns
    - Estratte associazioni e metodi in `User::Authenticatable`, `User::Proposable`, `User::Groupable`, `User::Socializable`, `User::Forumable`, `User::Notificationable`, `User::Profileable`.
    - Ridotto `app/models/user.rb` a circa 100 righe di codice core.
18. ✅ Uniformare template engine (tutti ERB + DaisyUI)
    - Completata in Fase 4-R.1: convertiti tutti i file Slim a ERB con Tailwind/DaisyUI.
19. ✅ Aumentare copertura test al 70%+
    - Stato al 2026-04-04: **80.23%** (1498 esempi, 0 failure) — target 80% raggiunto ✓
    - Aggiunte spec request per 12+ controller a zero copertura (area_roles, frm/admin/*, frm/moderation, proposal_supports, event_comments, blocked_proposal_alerts, group_invitation_emails, admin/newsletters, registrations)
    - Estese spec per home, blog_posts, proposals, groups, users, quorums controller
    - Aggiunte spec modelli: best_quorum_extra, user/authenticatable concern, proposal_vote, quorum, user concerns (profileable, proposable, socializable)
    - Aggiunte spec helper: proposals_helper
    - Aggiunte spec mailer: resque_mailer
    - Estesa copertura: quorums_controller (destroy, change_status, dates), groups_controller (JS/JSON format, partecipazioni), best_quorum (check_phase, close_vote_phase, explanation_pop, populate_vote)
    - SimpleCov minimum_coverage aggiornato da 32.9% a 70.0%, poi a 80.0%

### Fase 4-R — Remediation frontend ✅

> **Completata al 2026-04-04.** jQuery, Foundation, e tutto il JS/CSS legacy rimossi.

4-R.1. ✅ Convertire TUTTE le view da Slim/Foundation → ERB + Tailwind/DaisyUI
    - **COMPLETATA** — 500+ file convertiti, zero file `.slim` in `app/views/`.
    - Batch 1–3 (sessioni precedenti): auth, home, proposals, groups, events, layouts
    - Batch 4 (2026-04-04): admin (10), quorums (16), users (18), blogs (26), forum (57)
    - Batch 5 (2026-04-04): mailer (25), kaminari (7), blog_comments, event_comments, alerts + tutte le dir rimanenti (proposals 71, proposal_comments 31, groups 29, home 27, events 19, group_areas 16, steps 14, + 70 file sparsi)
    - gem `slim-rails` rimossa dal Gemfile
    - **Nota:** `foundation-rails` gem NON rimossa — il CSS Foundation è ancora importato in `application.css.scss`, `foundation_and_overrides.scss`, `groups.scss`, `proposal.css.scss`, `portlet.scss`, `landing/all.css`. La rimozione richiede riscrittura completa del CSS.

4-R.2–4. ✅ Rimuovere jQuery, Foundation, JS/CSS legacy
    - **Scoperta:** il layout `_head.html.erb` NON caricava il JS legacy Sprockets — solo esbuild era attivo. I 327 file JS e il CSS Foundation erano codice morto.
    - Rimossi 349 file JS legacy, 39 file CSS/SCSS legacy
    - Gem commentate: `foundation-rails`, `jquery-rails`, `private_pub`, `select2-rails`, `mustache-js-rails`, `uri-js-rails`, `uglifier`, `slim-rails`

4-R.5. ✅ Consolidare asset pipeline
    - Sprockets solo per: immagini, builds esbuild, CSS residuo (newsletters, PDF, notifications)
    - esbuild: tutto il JS (Turbo + Stimulus)
    - Tailwind v4 + DaisyUI: tutto il CSS

### Fase 6 — Upgrade stack (post remediation frontend) ⬜

> **Prerequisiti per iniziare:** copertura ≥ 70% ✓, Fase 4-R completata ✓ (jQuery/Foundation rimossi), copertura ≥ 80% (sblocca Rails 8.x)
> **Riferimento:** Rails 8.1.3 rilasciato 2026-03-24 (bugfix + security). Bug fix until Oct 2026. Rails 8.0 → security-only da maggio 2026.

**Naming:**
- Nome in codice: **Decidiamoci** (fork di Airesis, licenza AGPL v3)
- `APP_SHORT_NAME` / `APP_LONG_NAME` in `config/application.yml` (gitignored) e `config/application.example.yml`
- Footer: "Decidiamoci vX.X.X | fork di Airesis"
- Il modulo Ruby interno rimane `Airesis` e `window.Airesis` JS — troppi riferimenti, non rinominare finché non necessario
- Costante versione: `APP_VERSION` in `config/initializers/sentry.rb` (`AIRESIS_VERSION` mantenuto come alias)

**Versioning applicazione (Semantic Versioning):**
- Versione corrente: **6.0.0** (definita in `config/initializers/sentry.rb` come `APP_VERSION`)
- 5.0.0: Fasi 1–6 (Rails 8.1.3, Ruby 3.4.4, copertura 80%)
- 6.0.0: Fase 7 (Hotwire completo, zero jQuery, zero .js.erb, Action Cable, 7 Stimulus controllers)

20. ✅ Copertura test → 80% + bump versione **5.0.0**
    - Target intermedio prima dell'upgrade Rails 8.x
    - Priorità: percorsi critici (auth, proposte/voto Schulze, gruppi, API v1)
    - Non necessario il 100% — troppo costoso su 117 modelli / 73 controller
    - **Raggiunto al 2026-04-04: 80.23% (1498 esempi, 0 failure)**
    - SimpleCov minimum_coverage aggiornato a 80.0%
    - `APP_VERSION = '5.0.0'` aggiornato in `config/initializers/sentry.rb` ✓

21. ✅ Rails 7.1 → **7.2.3**
    - `config.load_defaults 7.2`
    - `config.cache_classes` → `config.enable_reloading`
    - `enum` keyword arguments → positional syntax (5 modelli)
    - Rimosso `ActiveRecord::Migration.check_pending!` (Rails 7.2 non lo supporta)
    - `simple_token_authentication` bloccante (actionpack < 8) — risolto in step 22

22. ✅ Rails 7.2 → **8.1.3** (saltato 8.0, direttamente a 8.1.3)
    - `simple_token_authentication` rimosso → `has_secure_token :authentication_token` (Rails native)
    - `authenticate_user_from_token!` custom in `Api::V1::ApplicationController` e `SessionsController`
    - `render text:` → `render plain:` (3 controller)
    - `render nothing: true` → `head :ok` (8 controller)
    - `.scoped` → `.all` (2 view ckeditor)
    - `ActiveSupport::Logger` → `Logger` (production.rb)
    - `config.load_defaults 8.0`
    - Dockerfile: rimosso `--without test` per abilitare gem di test nel container
    - Run tests: `docker compose run --rm -e RAILS_ENV=test airesis bundle exec rspec`
    - **Nota:** RAILS_ENV deve essere impostato esplicitamente — docker-compose.yml ha `RAILS_ENV=development`

23. ✅ Rails 8.1 → **8.1.x aggiornamenti minori**
    - `config.load_defaults 8.1` applicato ✓ (era stato fatto con il bump a 8.1.3)
    - Solid Cable installato (step 25) — adapter `:test` in test, `:async` in dev, `solid_cable` in prod
    - `private_pub` (Faye) ancora commentata — Action Cable è disponibile ma la migrazione delle 136 .js.erb è in Fase 7

24. ✅ Ruby 3.2.8 → **3.4.4**
    - FROM ruby:3.4.4 in Dockerfile, bundler 2.5.23
    - `vote-schulze` e `airesis_i18n` (gem su git): nessun constraint Ruby — compatibili ✓
    - `matrix` gem: ancora necessaria (non rientrata in stdlib Ruby 3.4)
    - rails_admin emette warning deprecazione Symbol#to_s frozen string — non bloccante
    - SimpleCov.maximum_coverage_drop 0 → 0.5 (Ruby 3.4 conta linee diversamente)

25. ✅ Rimuovere Sidekiq e Redis → Solid Queue + Solid Cable
    - 37 worker Sidekiq convertiti a ActiveJob (ApplicationJob)
    - `perform_async` → `perform_later`, `perform_in/at` → `set(wait:).perform_later`
    - `ResqueMailer.delay.method` → `method.deliver_later`
    - AlertJob/EmailJob: `scheduled_in_queue?` tramite SolidQueue::Job DB lookup
    - docker-compose.yml: servizio `redis` rimosso, `solid_queue` aggiunto
    - `alert.rb`: `email_job.sidekiq_job` → `email_job.scheduled_in_queue?`
    - `ApplicationJob`: `.jobs` e `.drain` per compatibilità test (Sidekiq fake mode → test adapter)
    - `spec/support/notifications.rb`: stub `scheduled_in_queue?` invece di `sidekiq_job`

### Fase 7 — UI/UX redesign moderno ✅

> **Completata al 2026-04-05.** Zero jQuery, zero .js.erb, 100% Hotwire.

26. ✅ Setup DaisyUI + Tailwind v4
    - **Completato in Fase 4-R** — Tailwind v4 + DaisyUI 5.x installati e attivi
    - `@plugin "daisyui"` in `app/assets/tailwind/application.css`
    - Tutte le 500+ view usano classi DaisyUI (card, btn, modal, badge, table, form, drawer, tabs...)
    - Tema neobrutalista: `--radius-*: 0rem`, `--border: 2px`, ombre `.shadow-brutal`
    - Stimulus controller `theme` (dark/light toggle) e `flash` (toast DaisyUI) attivi

27. ✅ Redesign componenti core
    - Kaminari pagination → DaisyUI join component
    - SimpleForm wrapper → DaisyUI con mapping automatico (input, textarea, select, boolean)
    - Foundation 5 CSS compatibility layer (~500 righe) rimosso
    - Foundation accordion → DaisyUI collapse
    - Foundation reveal-modal → `<dialog>` + modal_controller Stimulus
    - Layout, navbar, footer, flash già DaisyUI (completati in Fase 4-R)

28. ✅ Redesign pagine principali
    - Homepage pubblica — landing page completa Tailwind/DaisyUI (hero, features, testimonials)
    - Pagine proposte — index con tab DaisyUI, show con card e panel
    - Pagine gruppi — show con grid, portlet sidebar
    - Tutte le pagine principali già convertite in Fasi 4-R.1 e precedenti

29. ✅ Interattività moderna con Stimulus + Turbo
    - **136 .js.erb → 0**: tutti convertiti a `.turbo_stream.erb` (109 template)
    - **jQuery eliminato**: `jquery_shim.js` rimosso, 45 view HTML convertite a vanilla JS
    - **rails-ujs eliminato**: `remote: true` / `method:` / `confirm:` → Turbo data attributes (85 file)
    - **7 Stimulus controllers**: flash, theme, modal, countdown, infinite_scroll, toggle, autosubmit
    - **Action Cable**: connection Warden/Devise, ProposalComment broadcasts real-time
    - **`turbo_stream_from @proposal`** nella vista show per aggiornamenti WebSocket live
    - `private_pub` (Faye) sostituito da Action Cable + Turbo Streams

30. ✅ Bump versione **6.0.0**
    - `APP_VERSION = '6.0.0'` in `config/initializers/sentry.rb`
    - Rails 8.1.3 + Ruby 3.4.4 + Tailwind v4 + DaisyUI 5 + Hotwire completo

### Fase 8 — Feature future (possibili) ⬜

31. ⬜ **TipTap + editing collaborativo**
    - Sostituire Trix con TipTap (MIT, headless) per rich text editing avanzato
    - Toolbar custom DaisyUI tramite Stimulus controller
    - Collaborative editing real-time sulle proposte: **TipTap + Y.js (MIT) + Action Cable**
    - `y-prosemirror` come ponte tra Y.js e ProseMirror/TipTap
    - Presenza utenti (cursori colorati, chi sta editando)
    - Zero costi — tutto open source e self-hosted, nessun TipTap Cloud
    - **Prerequisiti:** CKEditor rimosso, ActionText + Trix funzionante come base

32. ⬜ **Admin globale — governance della piattaforma**
    - Attualmente l'Admin globale opera solo via RailsAdmin (CRUD DB diretto) — manca un'interfaccia di governance
    - Vista "tutti i gruppi" con azioni: sospendere, sciogliere, forzare elezioni, entrare come osservatore
    - Moderazione trasversale: operare dentro qualsiasi gruppo senza esserne membro
    - Gestione utenti avanzata: sospensioni temporanee, storico azioni, note admin
    - **Prerequisiti:** pannello admin attuale funzionante

33. ⬜ **Dashboard analytics** (priorità media)
    - Utenti attivi (DAU/MAU), nuove registrazioni, trend
    - Proposte create/mese, tasso di successo (accettate/respinte), tempo medio dibattito
    - Voti totali, partecipazione media per proposta
    - Gruppi più attivi, crescita membri
    - Grafici con Chartkick o simile (server-side, zero JS framework)

34. ⬜ **Configurazione app da UI** (priorità media)
    - Sostituire `config/application.yml` (ENV) con tabella `settings` in DB
    - UI admin per modificare: nome app, social network attivi, limiti upload, SMTP, feature toggle
    - Nessun deploy necessario per cambiare configurazione
    - Gem candidata: `rails-settings-cached` o custom con ActiveRecord

35. ⬜ **Audit log con UI** (priorità bassa)
    - PaperTrail già traccia le versioni dei modelli — manca solo l'interfaccia
    - Vista admin: chi ha modificato cosa, quando, diff prima/dopo
    - Filtri per utente, modello, data
    - Export CSV per compliance

36. ⬜ **Feature flags** (priorità bassa)
    - Attivare/disattivare funzionalità da UI admin senza deploy
    - Gem candidata: `flipper` (Rails native, supporta per-gruppo e per-utente)
    - Use case: disabilitare forum per un gruppo, abilitare Schulze solo per certi gruppi

37. ⬜ **Multi-tenant ibrido — piattaforma + organizzazioni** (priorità bassa)
    - **Due modalità di distribuzione:**
      - **SaaS hosted**: piattaforma pubblica + N organizzazioni private sulla stessa istanza
      - **Self-hosted**: organizzazione installa sul proprio server in single-org mode (punto 39)
    - **Modello ibrido (SaaS):**
      - L'utente si registra alla piattaforma → accede a open space, gruppi pubblici
      - L'utente viene invitato a un'organizzazione → accede al workspace privato isolato
      - Stesso account, N organizzazioni + piattaforma pubblica
      - Organization switcher nella navbar (stile Slack/Notion)
    - **Implementazione:**
      - Flag `organization: true` su Group per distinguere organizzazioni da gruppi normali
      - Scoping dati per organizzazione (proposte, forum, eventi interni non visibili fuori)
      - Billing separato per organizzazione (se SaaS a pagamento)
      - Gem candidata: `acts_as_tenant` o scoping custom con `Current.organization`
    - **Prerequisiti:** single-org mode (punto 39), feature flags (punto 36), admin globale (punto 32)

38. ⬜ **Excalidraw — lavagna collaborativa nelle proposte** (priorità media)
    - Integrare Excalidraw (MIT, React) come componente embeddabile nelle proposte
    - Utenti possono creare schemi, diagrammi, disegni a mano libera per spiegare le proposte
    - Salvataggio: JSON in DB (campo `excalidraw_data` su Proposal o come allegato Active Storage)
    - Rendering: embed read-only nella vista proposta, editing in modale/pagina dedicata
    - Collaborative editing real-time possibile via `@excalidraw/excalidraw` + Action Cable (stesso pattern di TipTap + Y.js)
    - Integrazione: Stimulus controller wrapper per montare il componente React in un elemento DOM
    - Export: PNG/SVG per condivisione esterna
    - **Prerequisiti:** esbuild configurato (già attivo), Action Cable funzionante (già attivo)

39. ⬜ **Single-org mode — versione leggera per organizzazioni** (priorità media)
    - Flag `SINGLE_ORG_MODE=true` in configurazione (o DB settings)
    - Un solo gruppo = l'organizzazione. Utenti auto-assegnati al join/invito
    - Disabilita: creazione gruppi, open space, landing pubblica, blog pubblici
    - Registrazione solo su invito admin (no registrazione pubblica)
    - Homepage → redirect diretto alla dashboard del gruppo unico
    - Sidebar e navbar semplificate (nascondi voci inutili)
    - Il modello dati non cambia — stessa codebase, due modalità
    - Implementazione: `before_action` nei controller + `if/unless` nelle view
    - Use case: aziende, enti, associazioni con server proprio
    - **Prerequisiti:** feature flags (punto 36) o semplice ENV var

40. ⬜ **Setup wizard — configurazione al primo avvio** (priorità media)
    - Pagina `/setup` al primo avvio (o rake task `rails airesis:setup`)
    - Scelta modalità piattaforma: `PLATFORM_MODE=public|organization|saas|school`
      - `public` — piattaforma aperta, multi-gruppo, registrazione pubblica
      - `organization` — singola organizzazione, solo inviti, server proprio
      - `saas` — piattaforma pubblica + organizzazioni private hosted
      - `school` — preset scolastico con classi, assemblee, ruoli predefiniti
    - Configurazione base: nome app, email admin, password admin, lingua default, territorio
    - Opzionale: logo, colori tema, SMTP, social auth keys
    - Salva in DB (`settings` table) — la modalità è fissa dopo il primo setup
    - Redirect automatico a `/setup` se DB vuoto (nessun User admin presente)
    - **Prerequisiti:** configurazione app da UI (punto 34), single-org mode (punto 39)

41. ⬜ **Preset School — versione per organizzazioni scolastiche** (priorità media)
    - Preset del setup wizard (`PLATFORM_MODE=school`), non un fork separato
    - **Mapping concetti:** organizzazione = istituto, gruppo = classe/consiglio, proposta = mozione, evento votazione = assemblea
    - **Ruoli preconfigurati:** Studente, Rappresentante, Docente, Dirigente (invece di ruoli custom)
    - **Classi come gruppi:** auto-create dall'admin, studenti assegnati per anno/sezione
    - **Template predefiniti:** assemblea d'istituto (ordine del giorno + votazione), elezione rappresentanti (Schulze)
    - **Registrazione controllata:** solo email istituzionali (`@scuola.edu.it`) o inviti da docente/dirigente
    - **Linguaggio adattato:** i18n dedicato — "proposta" → "mozione", "gruppo" → "classe", "portavoce" → "rappresentante"
    - **Privacy GDPR minori:** consenso genitoriale obbligatorio, dati minimi, niente social auth, niente tracking
    - **Prerequisiti:** single-org mode (punto 39), setup wizard (punto 40)

41. ⬜ **Gestione temi/branding da UI** (priorità bassa)
    - Admin sceglie colori, logo, nome dalla UI
    - Override CSS generato dinamicamente (CSS custom properties)
    - Ogni gruppo potrebbe avere il proprio branding (sub-theme)

---

## Debito tecnico residuo

### Sicurezza
- [x] ~~Ruby 2.7.5 EOL~~ — upgradato a 3.2.8
- [x] ~~`sentry-raven`~~ — migrato a `sentry-ruby` + `sentry-rails` 6.5.0

### Gem deprecate ancora presenti
- [x] ~~**Paperclip**~~ — migrato ad Active Storage
- [x] ~~**coffee-rails**~~ — convertiti tutti i `.coffee` in ES6+
- [x] ~~**Webpacker 5.x**~~ — sostituito con jsbundling-rails + esbuild
- [x] ~~**turbolinks**~~ — sostituito da Turbo (Hotwire)
- [x] ~~**jquery-rails**~~ — rimossa (gem commentata, JS legacy eliminato)
- [x] ~~**foundation-rails ~> 5.0**~~ — rimossa (gem commentata, CSS Foundation eliminato)

### Frontend (risolto)
- [x] ~~Dual asset pipeline~~ — JS legacy eliminato, solo esbuild per JS + Sprockets per immagini/CSS residuo
- [x] ~~`legacy/application.js`~~ — eliminato con tutti i 349 file JS legacy
- [x] ~~`init.js`~~ / ~~`democracy.js`~~ — eliminati
- [x] ~~`private_pub` (Faye WebSocket)~~ — gem commentata, sostituita da Action Cable + Turbo Streams
- [x] ~~136 `.js.erb` view templates~~ — tutti convertiti a `.turbo_stream.erb` (109 template) + vanilla JS. Zero `.js.erb` in app/views.
- [x] ~~jQuery / `jquery_shim.js`~~ — eliminato. Zero riferimenti `$()` nelle view.
- [x] ~~rails-ujs (`remote: true`, `method:`)~~ — convertito a Turbo data attributes.
- [x] ~~Foundation 5 CSS compatibility layer~~ — rimosso (~500 righe). Solo Tailwind v4 + DaisyUI.

### Qualità codice
- [ ] 95+ commenti TODO/FIXME nel codice
- [x] ~~`User` model con 52 relazioni~~ — refactoring in 7 Concerns completato
- [x] ~~Foundation CSS 5.0~~ — CSS Foundation eliminato, tutte le view usano Tailwind/DaisyUI
- [x] ~~Font Awesome 4.7~~ — migrato a 6.x (font-awesome-sass)
- [ ] `.rubocop_todo.yml` con ~15KB di violazioni ignorate
- [x] Copertura test 80%+ (corrente: ~80% — target 80% ✓)

---

## Convenzioni di sviluppo

- Template engine primario: **ERB** (`.erb`) — zero file Slim
- ORM: **ActiveRecord** con PostgreSQL
- Autorizzazione: sempre via **CanCanCan** (`can?` / `authorize!`)
- Job asincroni: sempre via **ActiveJob** (`perform_later`) — Solid Queue come adapter in production
- Ricerca full-text: **pg_search** (non LIKE)
- Paginazione: **pagy**
- Form: **simple_form** con wrapper Tailwind/DaisyUI
- Internazionalizzazione: ogni stringa UI deve passare per `I18n.t()`

---

## Note tecniche importanti

- **`rails app:update` è pericoloso** — sovrascrive file custom senza backup. Usare sempre `rails app:update` in modalità interattiva dentro il container, oppure applicare le modifiche manualmente. I file sovrascritti accidentalmente possono essere recuperati dal repo GitHub: `curl https://raw.githubusercontent.com/coorasse/airesis/develop/CONFIG_FILE`.
- **`lib/rails_admin/`** non segue le convenzioni Zeitwerk — è caricato esplicitamente nell'initializer ed escluso da `config/initializers/zeitwerk.rb`.
- **`default_role`** rinominato in `Group` → `default_participation_role` e in `GroupArea` → `default_area_role` (conflitto con `ActiveRecord::Base.default_role` introdotto in Rails 6.1).
- **Stub Sprockets per rails_admin** — `vendor/assets/javascripts/rails_admin/application.js` e `vendor/assets/stylesheets/rails_admin/application.css` sono stub vuoti. Sprockets 3.x scansiona tutti i logical paths quando verifica `precompiled_assets`; senza lo stub, troverebbe il manifest rails_admin della gem (`.js.erb`) che referenzia file solo in `src/` (webpacker). Lo stub ha priorità perché `vendor/assets` precede i gem paths in Sprockets. Se si rimuove webpacker in futuro, rimuovere anche questi stub.
- **PaperTrail 14 con Rails 7.1** — emette un warning di compatibilità ma funziona. PaperTrail 15+ richiede Ruby ≥ 3.0; aggiornare dopo upgrade Ruby.
- La gem `airesis_i18n` è su git — tenerla d'occhio durante l'upgrade Ruby.
- La gem `vote-schulze` è su git — verificare compatibilità Ruby 3.
- `private_pub.ru` usa WebSocket via Faye — valutare migrazione ad Action Cable.
- **Asset pipeline**: Sprockets solo per immagini, CSS residuo (newsletters, PDF) e stub rails_admin. esbuild per tutto il JS (Turbo+Stimulus). Tailwind v4 per il CSS principale. Il JS legacy (349 file jQuery+Foundation) è stato eliminato in Fase 4-R.
- **`app/assets/javascripts/init.js`** è il punto di ingresso JS legacy — esegue `$(document).foundation()`, inizializza 15+ plugin jQuery, configura `window.Airesis`. Ogni pagina lo carica. Non può essere rimosso senza sostituire ogni plugin con Stimulus controller equivalente.
- CORS è aperto a `*` per `/api/*` — restringere in produzione.
- `config/locales/` contiene file sia YAML che RB — non mischiare i formati.
