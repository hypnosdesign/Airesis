# CLAUDE.md — Airesis

> Analisi iniziale: 2026-03-31.
> Ultimo aggiornamento: 2026-04-03 — Fasi 1–3, 5 completate. Fase 4 (frontend) parziale: Tailwind/DaisyUI installati, layout convertito, ma jQuery+Foundation ancora attivi. Copertura test: 70.0% ✓.
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
| Ruby           | 2.7.5 (EOL)       | **3.2.8** ✓     | 3.2.x               |
| Rails          | 6.0.3.1 (EOL)     | **7.1.6** ✓     | 7.1.x               |
| PostgreSQL     | qualsiasi         | 14-alpine ✓     | 14+                 |
| Redis          | qualsiasi         | 7-alpine ✓      | 7.x                 |
| Sidekiq        | 6.1.2             | 6.1.x           | 7.x                 |
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
  workers/       # 39 Sidekiq worker
  cancan/        # abilities (Guest, Logged, Moderator, Admin)
  views/         # Slim (517 file). ~108 con Tailwind/DaisyUI, ~95 ancora con classi Foundation
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
- `Alert` / `Notification` — sistema notifiche (20+ worker Sidekiq)

---

## Autenticazione e autorizzazione

- **Devise 5** — registrazione, login, conferma email, password reset
- **OmniAuth** — Facebook, Google OAuth2, Twitter
- **simple_token_authentication** — token API
- **CanCanCan 3** — autorizzazione a ruoli (Guest < Logged < Moderator < Admin)
- **Rack::Attack** — rate limiting e blocco probe

---

## Job asincroni (Sidekiq)

Code configurate in `config/sidekiq.yml`:
- `high_priority` — 5 concorrenti
- `notifications` — 3 concorrenti
- `default` — 2 concorrenti
- `low_priority` — 1 concorrente
- `mailers` — 1 concorrente

---

## Docker

Avvio sviluppo:
```bash
docker compose up
```

Servizi:
- `airesis` — app Rails (porta 3000). Nota: `NODE_OPTIONS=--openssl-legacy-provider` ancora nel docker-compose (legacy Webpack, da rimuovere in Fase 4-R)
- `db` — PostgreSQL 14 (porta 5433, user `postgres`, trust auth)
- `redis` — Redis 7
- `sidekiq` — worker Sidekiq

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
- Copertura attuale: **~70.0%** (1103 esempi, 0 failure al 2026-04-03) — target 70% ✓ raggiunto
- Copertura minima configurata in SimpleCov: **70.0%**
- Run in Docker: `docker compose run --rm -e BUNDLE_APP_CONFIG=/usr/src/app/.bundle airesis bundle exec rspec`
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



### Fase 4 — Frontend (parziale)
13. 🔄 Foundation 5 → TailwindCSS + DaisyUI
    - Installato `tailwindcss-rails` (Tailwind v4) + DaisyUI 5.x come plugin.
    - DaisyUI build: `@plugin "daisyui"` in `app/assets/tailwind/application.css` (file usato dalla gem).
    - Stile neobrutalista: `--radius-*: 0rem`, `--border: 2px`, ombre solide `.shadow-brutal`.
    - **Tutti i layout ERB** (34 file, 0 Slim): _general, _top_menu, _footer, _login_panel, _head, _header, _favicons, _languages (→ DaisyUI tabs+dialog), _personal_menu, _page_title, _portlet, _tutorials, application, open_space, groups, users, admin, landing, newsletter.
    - **56 view ERB** con DaisyUI: Batch 1 (auth+home), Batch 2 (proposals), Batch 3 (groups+events).
    - **460 view Slim** rimanenti: funzionano via compatibility layer CSS. Da convertire progressivamente.
    - **Pendente:** gem `foundation-rails ~> 5.0` ancora attiva. `foundation_and_overrides.scss` ancora importato.
14. 🔄 Adottare Hotwire (Turbo + Stimulus) — rimuovere jQuery + Turbolinks
    - Turbolinks rimosso, `turbo-rails` importato in `application.js` e funzionante.
    - Stimulus controller attivi: `theme` (dark/light toggle), `flash` (DaisyUI toast, sostituisce toastr.js).
    - **toastr.js sostituito** — flash messages ora DaisyUI toast + Stimulus, zero jQuery.
    - **Pendente:** `jquery-rails` gem ancora attiva. 327 file JS legacy (57.892 LOC) via Sprockets. Plugin jQuery rimanenti: qtip, fdatetimepicker, switchbutton, tokeninput, fullcalendar, jqplot, steps, textntags, intro.js. `private_pub` (Faye) ancora attivo.
15. ✅ Aggiornare Font Awesome 4.7 → 6.x
    - Sostituito `font-awesome-rails` con `font-awesome-sass`.
    - Eseguita migrazione batch di oltre 100 icone nelle view.
16. ✅ Conversione totale ERB → Slim
    - Convertiti tutti i 336 file `.html.erb` rimanenti in `.slim` tramite script automatizzato.
    - Aggiornati layout e partial principali.

### Fase 5 — Qualità e manutenibilità
17. ✅ Refactoring `User` model in Concerns
    - Estratte associazioni e metodi in `User::Authenticatable`, `User::Proposable`, `User::Groupable`, `User::Socializable`, `User::Forumable`, `User::Notificationable`, `User::Profileable`.
    - Ridotto `app/models/user.rb` a circa 100 righe di codice core.
18. ✅ Uniformare template engine (tutti Slim)
    - Convertiti tutti i 336 file ERB rimanenti in Slim.
19. ✅ Aumentare copertura test al 70%+
    - Stato al 2026-04-03: **70.0%** (1103 esempi, 0 failure) — target raggiunto
    - Aggiunte spec request per 12+ controller a zero copertura (area_roles, frm/admin/*, frm/moderation, proposal_supports, event_comments, blocked_proposal_alerts, group_invitation_emails, admin/newsletters, registrations)
    - Estese spec per home, blog_posts, proposals, groups, users, quorums controller
    - Aggiunte spec modelli: best_quorum_extra, user/authenticatable concern, proposal_vote, quorum, user concerns (profileable, proposable, socializable)
    - Aggiunte spec helper: proposals_helper
    - Aggiunte spec mailer: resque_mailer
    - Estesa copertura: quorums_controller (destroy, change_status, dates), groups_controller (JS/JSON format, partecipazioni), best_quorum (check_phase, close_vote_phase, explanation_pop, populate_vote)
    - SimpleCov minimum_coverage aggiornato da 32.9% a 70.0%

### Fase 4-R — Remediation frontend (completare migrazione) ⬜

> **Prerequisito:** Fase 5 completata (copertura ≥ 70% ✓).
> **Motivazione:** La Fase 4 ha installato Tailwind/DaisyUI e Hotwire ma non ha rimosso jQuery/Foundation. L'app è in stato ibrido: entrambi i sistemi sono caricati. Questo blocca l'upgrade Rails (Sprockets conflict) e il redesign UI (DaisyUI su Foundation non funziona). Serve completare la migrazione prima di procedere.

> **Approccio:** component-by-component, batch per batch. L'app resta funzionante durante la transizione perché entrambi i CSS sono caricati. Ogni batch è testabile indipendentemente.

> **Mapping Foundation → DaisyUI/Tailwind:**
> `.row` → `flex flex-wrap` | `.columns.large-6` → `w-full lg:w-1/2` | `.panel` → `card bg-base-200 p-4` | `.reveal-modal` → `dialog.modal` (DaisyUI) | `.button` → `btn` | `.button.small` → `btn btn-sm` | `.button.alert` → `btn btn-error` | `.alert-box` → `alert` | `.tabs-content` → `tabs` | `.f-dropdown` → `dropdown` | `.label` → `badge` | `.side-nav` → `menu`

4-R.1. 🔄 Convertire view da Foundation grid a Tailwind/DaisyUI (+ Slim → ERB)
    - ✅ **Batch 1** — Auth + Home: devise/sessions/new, registrations/new+edit, shared/_links+_social_links, home/index+intro
    - ✅ **Batch 2** — Proposals: index, show, new, edit, _show_proposal, _vote_panel, _comment, _comments, _report_contribute, _closest_proposals, _left_panel, _left_panel_index
    - ✅ **Batch 3** — Groups + Events: groups/index+show+_left_panel, events/show, layouts/groups+open_space
    - ✅ **Layout shell** — _general, _top_menu, _footer, _login_panel, application (tutti ERB + DaisyUI)
    - ✅ **Fix DaisyUI build** — `@plugin "daisyui"` nel file corretto (`app/assets/tailwind/application.css`)
    - ✅ **Stile neobrutalista** — `--radius-*: 0rem`, `--border: 2px`, ombre solide `.shadow-brutal`
    - ✅ **Fix render_error** — `application_controller.rb` template path senza suffisso
    - ⬜ **Batch 4** — Forum, Blog, Users, Admin, Quorums (~25 file)
    - ⬜ **Batch 5** — JS templates e mailer (~30 file)
    - ⬜ **Cleanup** — rimuovere `foundation-rails` gem quando tutte le view sono convertite
    - **Nota:** `slimrb -e` non è utilizzabile per conversioni bulk (escapa gli helper Rails). Conversione manuale batch per batch. I file Slim non convertiti funzionano grazie al compatibility layer CSS.

4-R.2. ⬜ Sostituire plugin jQuery con Stimulus controllers
    - Priorità (per accoppiamento):
      1. `toastr` → DaisyUI toast + Stimulus (flash messages, ogni pagina)
      2. `foundation-datetimepicker` → `<input type="datetime-local">` o Flatpickr + Stimulus
      3. `$.fn.qtip` → DaisyUI tooltip (CSS-only)
      4. `jquery.switchbutton` → DaisyUI toggle
      5. `jquery.steps` → Stimulus multi-step controller
      6. `jquery.tokeninput` → Stimulus autocomplete (tag/interest borders)
      7. `Feedback` widget → Stimulus controller
      8. `fullcalendar` → FullCalendar v6 (vanilla JS, no jQuery)
      9. `jquery.jqplot` → Chart.js o CSS semplice (bassa priorità, solo vote results)
      10. `underscore` → JS nativo (usato solo `_.filter`)

4-R.3. ⬜ Migrare init.js e democracy.js a ES6 + Stimulus
    - Convertire `init.js` in Stimulus controllers separati (search, datepicker, reveal-modal, textntags, tag-cloud, page-dispatcher)
    - Convertire `democracy.js` utility functions in modulo ES6
    - Convertire 28 file per-page JS (`per_page/`) in Stimulus controllers

4-R.4. ⬜ Rimuovere jquery-rails e Sprockets JS manifest
    - Rimuovere `jquery-rails` dal Gemfile
    - Rimuovere `legacy/application.js` Sprockets manifest
    - Tutto il JS passa solo da esbuild
    - Mantenere Sprockets solo per CSS

4-R.5. ⬜ Consolidare asset pipeline
    - Opzione A: mantenere Sprockets solo per CSS (più semplice)
    - Opzione B: migrare a Propshaft (default Rails 8, ma Sprockets 4.x funziona ancora)
    - Rimuovere gem `uglifier` (esbuild gestisce minification)
    - Rimuovere da `manifest.js` i riferimenti a `//= link_directory ../javascripts`

### Fase 6 — Upgrade stack (post remediation frontend) ⬜

> **Prerequisiti per iniziare:** copertura ≥ 70% ✓, Fase 4-R completata (jQuery/Foundation rimossi), copertura ≥ 80% (sblocca Rails 8.x)
> **Riferimento:** Rails 8.1.3 rilasciato 2026-03-24 (bugfix + security). Bug fix until Oct 2026. Rails 8.0 → security-only da maggio 2026.

**Naming:**
- Nome in codice: **Decidiamoci** (fork di Airesis, licenza AGPL v3)
- `APP_SHORT_NAME` / `APP_LONG_NAME` in `config/application.yml` (gitignored) e `config/application.example.yml`
- Footer: "Decidiamoci vX.X.X | fork di Airesis"
- Il modulo Ruby interno rimane `Airesis` e `window.Airesis` JS — troppi riferimenti, non rinominare finché non necessario
- Costante versione: `APP_VERSION` in `config/initializers/sentry.rb` (`AIRESIS_VERSION` mantenuto come alias)

**Versioning applicazione (Semantic Versioning):**
- Versione corrente: **4.8.7** (definita in `config/initializers/sentry.rb` come `APP_VERSION`)
- Fasi 1–5 completate (Rails 6→7.1, Ruby 2.7→3.2, Webpacker→esbuild, Foundation→Tailwind, Turbolinks→Hotwire, Paperclip→ActiveStorage, ERB→Slim) → bump a **5.0.0** al termine della copertura 80%
- Rails 8.x + Ruby 3.4 + UI redesign → bump a **6.0.0**

20. ⬜ Copertura test → 80% + bump versione **5.0.0**
    - Target intermedio prima dell'upgrade Rails 8.x
    - Priorità: percorsi critici (auth, proposte/voto Schulze, gruppi, API v1)
    - Non necessario il 100% — troppo costoso su 117 modelli / 73 controller
    - Al raggiungimento dell'80%: aggiornare `AIRESIS_VERSION = '5.0.0'`

21. ⬜ Rails 7.1 → **7.2**
    - Step minore, meno rischi
    - Verificare compatibilità: `rails_admin`, `simple_token_authentication`, `vote-schulze` (gem su git), `airesis_i18n` (gem su git)
    - Aggiornare `config.load_defaults 7.2`
    - Eseguire `rails app:update` interattivo nel container

22. ⬜ Rails 7.2 → **8.0**
    - Verificare `rails_admin` (supporto Rails 8 non garantito — potrebbe richiedere sostituzione)
    - Valutare migrazione da Sidekiq → **Solid Queue** (built-in Rails 8, elimina dipendenza Redis per i job)
    - Valutare migrazione da Redis cache → **Solid Cache**
    - `ActionController::Parameters` e altri breaking changes 8.0
    - Aggiornare `config.load_defaults 8.0`

23. ⬜ Rails 8.0 → **8.1.x** (target: 8.1.3+)
    - Step minore rispetto a 8.0
    - Aggiornare `config.load_defaults 8.1`
    - Valutare **Solid Cable** per WebSocket (sostituisce `private_pub.ru` via Faye)

24. ⬜ Ruby 3.2.8 → **3.4.x**
    - Può procedere in parallelo con Rails 7.2→8.x
    - Verificare `vote-schulze` (gem su git) e `airesis_i18n` (gem su git) con Ruby 3.4
    - `matrix` gem: verificare se rientra in stdlib o rimane necessaria
    - Aggiornare Dockerfile: `FROM ruby:3.4-alpine`

25. ⬜ Rimuovere Sidekiq e Redis (opzionale, post Rails 8)
    - Solo se migrazione a Solid Queue completata
    - Semplifica infrastruttura Docker (elimina servizio `redis` per i job)
    - Mantenere Redis se usato per altri scopi (cache, sessioni)

### Fase 7 — UI/UX redesign moderno ⬜

> **Prerequisito:** completate Fasi 5 e 6 (stack stabile su Rails 8.x + Ruby 3.4)
> **Nota architetturale:** l'app usa Hotwire/Turbo/Stimulus — NON React. Librerie React-only (shadcn/ui, Radix UI) non compatibili nativamente.

26. ⬜ Setup DaisyUI + Tailwind v4
    - **DaisyUI** — plugin Tailwind, zero JS overhead, componenti semantici
    - Evoluzione naturale: già su Tailwind v4, DaisyUI si aggiunge come plugin npm
    - Componenti core: button, card, modal, dropdown, navbar, badge, alert, table, form, drawer, tabs, avatar, tooltip
    - Theming tramite CSS variables (light/dark mode nativo, temi custom per branding Airesis)
    - Perfetta integrazione con Stimulus (DaisyUI non ha JS proprio — tutto JS gestito da Stimulus)
    - Setup: `npm install daisyui` + aggiungere plugin in `tailwind.config.js`

27. ⬜ Redesign componenti core
    - Layout principale (navbar, sidebar, footer)
    - Sistema tipografico e colori (design token Tailwind)
    - Form (simple_form + wrapper Tailwind/DaisyUI)
    - Tabelle e liste (proposte, gruppi, eventi)
    - Card e pannelli informativi
    - Modali e drawer (usare Turbo Frames + Stimulus)
    - Notifiche e alert in-app
    - Paginazione (kaminari template Tailwind)

28. ⬜ Redesign pagine principali
    - Homepage pubblica (landing, open space)
    - Dashboard utente autenticato
    - Pagine proposte (index, show, new/edit, vote)
    - Pagine gruppi (show, impostazioni, aree)
    - Forum (topics, posts)
    - Blog (index, show, editor)
    - Profilo utente e impostazioni
    - Pannello admin

29. ⬜ Interattività moderna con Stimulus + Turbo
    - Sostituire jQuery-dependent patterns con Stimulus controllers
    - Turbo Frames per aggiornamenti parziali (commenti, voti in real-time)
    - Turbo Streams per notifiche live
    - Valutare migrazione `private_pub.ru` → Action Cable + Turbo Streams

30. ⬜ Bump versione **6.0.0**
    - Al completamento del redesign UI + Rails 8.x + Ruby 3.4
    - Aggiornare `AIRESIS_VERSION = '6.0.0'`

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
- [ ] **jquery-rails** — ancora attiva, 786 selettori `$()`, 1.049 chiamate AJAX, 30+ plugin `$.fn` (Fase 4-R)
- [ ] **foundation-rails ~> 5.0** — ancora attiva, 95 view con classi Foundation, 23.551 righe CSS (Fase 4-R)

### Frontend ibrido (debito critico)
- [ ] Dual asset pipeline: Sprockets compila 327 file JS legacy + Foundation CSS; esbuild compila Turbo/Stimulus separatamente
- [ ] `app/assets/javascripts/legacy/application.js` — Sprockets manifest che carica jQuery, Foundation, 30+ plugin
- [ ] `init.js` — 130+ righe di setup jQuery globale, chiama `$(document).foundation()`
- [ ] `private_pub` (Faye WebSocket) — da migrare ad Action Cable + Turbo Streams

### Qualità codice
- [ ] 95+ commenti TODO/FIXME nel codice
- [x] ~~`User` model con 52 relazioni~~ — refactoring in 7 Concerns completato
- [ ] Foundation CSS 5.0 — parzialmente migrato (layout shell → Tailwind/DaisyUI, 95 view ancora Foundation)
- [x] ~~Font Awesome 4.7~~ — migrato a 6.x (font-awesome-sass)
- [ ] `.rubocop_todo.yml` con ~15KB di violazioni ignorate
- [ ] Copertura test < 80% (corrente: ~70.0% — target 70% ✓, prossimo 80% pre-Rails 8.x)

---

## Convenzioni di sviluppo

- Template engine primario: **Slim** (`.slim`)
- ORM: **ActiveRecord** con PostgreSQL
- Autorizzazione: sempre via **CanCanCan** (`can?` / `authorize!`)
- Job asincroni: sempre via **Sidekiq** (non `ActiveJob` diretto)
- Ricerca full-text: **pg_search** (non LIKE)
- Paginazione: **kaminari**
- Form: **simple_form** (wrapper ancora Foundation — da migrare a Tailwind/DaisyUI in Fase 4-R)
- Internazionalizzazione: ogni stringa UI deve passare per `I18n.t()`

---

## Note tecniche importanti

- **`rails app:update` è pericoloso** — sovrascrive file custom senza backup. Usare sempre `rails app:update` in modalità interattiva dentro il container, oppure applicare le modifiche manualmente. I file sovrascritti accidentalmente possono essere recuperati dal repo GitHub: `curl https://raw.githubusercontent.com/coorasse/airesis/develop/CONFIG_FILE`.
- **`lib/rails_admin/`** non segue le convenzioni Zeitwerk — è caricato esplicitamente nell'initializer ed escluso da `config/initializers/zeitwerk.rb`.
- **`bin/webpack` e `bin/webpack-dev-server`** richiedono `require 'logger'` prima di `require 'webpacker'` (workaround per bootsnap ≥ 1.10 + Rails 7).
- **`default_role`** rinominato in `Group` → `default_participation_role` e in `GroupArea` → `default_area_role` (conflitto con `ActiveRecord::Base.default_role` introdotto in Rails 6.1).
- **Stub Sprockets per rails_admin** — `vendor/assets/javascripts/rails_admin/application.js` e `vendor/assets/stylesheets/rails_admin/application.css` sono stub vuoti. Sprockets 3.x scansiona tutti i logical paths quando verifica `precompiled_assets`; senza lo stub, troverebbe il manifest rails_admin della gem (`.js.erb`) che referenzia file solo in `src/` (webpacker). Lo stub ha priorità perché `vendor/assets` precede i gem paths in Sprockets. Se si rimuove webpacker in futuro, rimuovere anche questi stub.
- **PaperTrail 14 con Rails 7.1** — emette un warning di compatibilità ma funziona. PaperTrail 15+ richiede Ruby ≥ 3.0; aggiornare dopo upgrade Ruby.
- La gem `airesis_i18n` è su git — tenerla d'occhio durante l'upgrade Ruby.
- La gem `vote-schulze` è su git — verificare compatibilità Ruby 3.
- `private_pub.ru` usa WebSocket via Faye — valutare migrazione ad Action Cable.
- **Dual asset pipeline (Sprockets + esbuild)** — entrambi attivi in parallelo. Sprockets compila `app/assets/javascripts/legacy/application.js` (327 file, jQuery+Foundation) + `application.css.scss` (Foundation CSS). esbuild compila `app/javascript/application.js` (Turbo+Stimulus). Il layout `_head.html.slim` carica entrambi. Rischio: handler eventi duplicati, CSS conflittuali, bloat. Da consolidare in Fase 4-R.
- **`app/assets/javascripts/init.js`** è il punto di ingresso JS legacy — esegue `$(document).foundation()`, inizializza 15+ plugin jQuery, configura `window.Airesis`. Ogni pagina lo carica. Non può essere rimosso senza sostituire ogni plugin con Stimulus controller equivalente.
- CORS è aperto a `*` per `/api/*` — restringere in produzione.
- `config/locales/` contiene file sia YAML che RB — non mischiare i formati.
