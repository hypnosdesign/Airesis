# Airesis - The Social Network for E-Democracy

The first open source web application for eDemocracy.

Airesis is a platform for participatory democracy that allows citizens, groups, and organizations to create proposals, discuss them in forums and blogs, organize events, and make collective decisions using the Schulze voting method.

> **Current version: 6.0.0** — Rails 8.1.3 · Ruby 3.4.4 · Tailwind v4 + DaisyUI 5 · Hotwire (Turbo + Stimulus)
>
> This is a fork of the original [Airesis](https://github.com/airesis/airesis) project by Alessandro Rodi ([coorasse/airesis](https://github.com/coorasse/airesis)). The original project has been inactive since 2022 and is no longer deployed in production. The modernization effort (v4 → v6) is carried out by **Mattia Piano**.

---

## Modernization changelog (v4 → v6)

This project underwent a comprehensive modernization starting from a legacy Rails 6.0 / Ruby 2.7 codebase. Below is a summary of every phase, so that new contributors can understand the current state and the decisions behind it.

### Phase 1 — Working environment (v4 baseline)

- Fixed Dockerfile (Ruby 2.7.5, Node 18, Yarn, system dependencies)
- Updated `docker-compose.yml` to v3.8 format (PostgreSQL 14, Redis 7)
- Created `config/application.yml` for development
- Loaded database schema (133 tables), verified HTTP 200 response

### Phase 2 — Rails upgrade (6.0 → 7.1)

| Step | Upgrade | Key changes |
|------|---------|-------------|
| 1 | Rails 6.0 → **6.1** | `paper_trail` 10→14, `bullet` 6→8, `bootsnap` 1.4→1.23. Renamed `default_role` to avoid AR conflict. |
| 2 | Rails 6.1 → **7.0** | `devise` 4→5, `cancancan` 3.1→3.6, `rails_admin` 2→3, `simple_form` 5.0→5.4. Zeitwerk exclusions for `lib/rails_admin/`. |
| 3 | Rails 7.0 → **7.1** | `load_defaults 7.1`. Lazy `I18n.t()` in models. Added missing locale keys. Sprockets stubs for rails_admin. |
| 4 | Ruby 2.7.5 → **3.2.8** | `pg` 1.2→1.6, `paper_trail` 14→17, added `matrix` gem. Updated debuggers and dev tools. |
| 5 | Sentry migration | Replaced `sentry-raven` with `sentry-ruby` + `sentry-rails` 6.5. |

### Phase 3 — Deprecated gems

| Gem removed | Replaced with |
|-------------|---------------|
| **Paperclip** | Active Storage (`has_one_attached`) + `active_storage_validations` |
| **coffee-rails** | 36 `.coffee` files converted to ES6+ |
| **Webpacker 5.x** | `jsbundling-rails` + esbuild |

### Phase 4 — Frontend modernization

- **Tailwind v4 + DaisyUI 5** installed as primary CSS framework
- **All 500+ views** converted from Slim/Foundation to ERB + Tailwind/DaisyUI classes
- `slim-rails` gem removed (zero `.slim` files remaining)
- **Font Awesome** 4.7 → 6.x (`font-awesome-sass`)
- **Turbolinks** removed, replaced by **Turbo** (Hotwire)
- **Stimulus controllers**: `theme` (dark/light), `flash` (toast), `modal`, `countdown`, `infinite_scroll`, `toggle`, `autosubmit`

### Phase 4-R — Frontend remediation (legacy cleanup)

- Discovered that the layout did not load legacy Sprockets JS — 349 JS files and Foundation CSS were dead code
- **Removed**: 349 legacy JS files (57,892 LOC), 39 legacy CSS/SCSS files
- **Gems disabled**: `foundation-rails`, `jquery-rails`, `private_pub`, `select2-rails`, `mustache-js-rails`, `uri-js-rails`, `uglifier`
- Asset pipeline consolidated: Sprockets for images only, esbuild for JS, Tailwind for CSS

### Phase 5 — Code quality

- **`User` model refactored** into 7 concerns: `Authenticatable`, `Proposable`, `Groupable`, `Socializable`, `Forumable`, `Notificationable`, `Profileable` (from 700+ lines to ~100 core lines)
- **Test coverage**: 32% → **80%** (1498 examples, 0 failures)
  - Added request specs for 12+ controllers with zero coverage
  - Added model, helper, and mailer specs
  - SimpleCov minimum set to 80%

### Phase 6 — Stack upgrade (7.1 → 8.1, Ruby 3.4)

| Step | Upgrade | Key changes |
|------|---------|-------------|
| 1 | Rails 7.1 → **7.2** | `enable_reloading` config, positional `enum` syntax, removed `check_pending!` |
| 2 | Rails 7.2 → **8.1.3** | Removed `simple_token_authentication` → `has_secure_token` (Rails native). `render text:` → `render plain:`, `render nothing:` → `head :ok`. |
| 3 | Ruby 3.2 → **3.4.4** | Bundler 2.5.23. `matrix` gem still required. |
| 4 | Sidekiq + Redis → **Solid Queue + Solid Cable** | 37 Sidekiq workers converted to ActiveJob. Redis service removed. DB-backed queues. |

### Phase 7 — Hotwire completion (v6.0.0)

- **136 `.js.erb` → 0**: all converted to `.turbo_stream.erb` (109 templates)
- **jQuery eliminated**: `jquery_shim.js` removed, 45 views converted to vanilla JS
- **rails-ujs removed**: `remote: true` / `method:` → Turbo data attributes (85 files)
- **Action Cable**: Warden/Devise connection, real-time ProposalComment broadcasts
- **`private_pub` (Faye)** fully replaced by Action Cable + Turbo Streams

### Version history

| Version | Milestone |
|---------|-----------|
| 4.x | Original codebase (Rails 6.0, Ruby 2.7, jQuery, Foundation 5, Slim, Sidekiq) |
| 5.0.0 | Rails 8.1.3, Ruby 3.4.4, 80% test coverage, Solid Queue |
| **6.0.0** | Zero jQuery, zero `.js.erb`, 100% Hotwire, Action Cable, 7 Stimulus controllers |

---

## Stack

| Component | Version |
|-----------|---------|
| Ruby | 3.4.4 |
| Rails | 8.1.3 |
| PostgreSQL | 14+ |
| Job queue | Solid Queue (DB-backed, no Redis) |
| WebSocket | Action Cable + Solid Cable |
| CSS | Tailwind v4 + DaisyUI 5 |
| JS bundler | esbuild (`jsbundling-rails`) |
| JS framework | Hotwire (Turbo + Stimulus) |
| Auth | Devise 5 + OmniAuth |
| Authorization | CanCanCan 3 |
| Voting | Schulze method (`vote-schulze`) |
| Search | `pg_search` |
| Pagination | Pagy |
| Forms | SimpleForm (DaisyUI wrapper) |
| Admin | rails_admin 3 |
| Icons | Font Awesome 6 (`font-awesome-sass`) |
| Monitoring | Sentry (`sentry-rails` 6.5) |

---

## Installation and Setup

### Requirements

- PostgreSQL 14+ with `hstore` extension enabled
- Node.js 18+ and Yarn (for JS bundling)

### Docker (recommended)

```bash
# First time setup
cp config/application.example.yml config/application.yml
docker compose up
docker compose run --rm airesis bundle exec rails db:create db:schema:load
```

```bash
# Day-to-day development
docker compose up
```

Services:
- `airesis` — Rails app (port 3000)
- `db` — PostgreSQL 14 (port 5433)
- `solid_queue` — background job worker

### Useful commands

```bash
# Run migrations
docker compose run --rm airesis bundle exec rails db:migrate

# Compile assets
docker compose run --rm airesis bundle exec rails assets:precompile

# Run tests
docker compose run --rm -e RAILS_ENV=test airesis bundle exec rspec

# Run tests excluding system specs (no Selenium in container)
docker compose run --rm -e RAILS_ENV=test airesis bundle exec rspec --exclude-pattern "**/system/**/*_spec.rb"
```

### Local installation

```bash
git clone https://github.com/hypnosdesign/Airesis.git
cd airesis
bundle install
cp config/application.example.yml config/application.yml
# Edit config/application.yml with your values
bundle exec rails db:setup
bundle exec rails s
```

In a separate terminal, start Solid Queue:
```bash
bundle exec rails solid_queue:start
```

### Seeding test data

```bash
bundle exec rake airesis:seed:more:public_proposals[10]    # 10 fake proposals + users
bundle exec rake airesis:seed:more:votable_proposals[5]     # 5 proposals in voting phase
bundle exec rake airesis:seed:more:clear_proposals          # destroy all proposals
```

See `spec/factories` for additional factory definitions.

## Environment variables

See `config/application.example.yml` for a detailed explanation. Managed via [Figaro](https://github.com/laserlemon/figaro).

## I18n

Translations are managed in a separate gem: [airesis_i18n](https://github.com/airesis/airesis_i18n).

## Authors

- **Mattia Piano** — current maintainer (fork, modernization v4 → v6)
- **Alessandro Rodi** (coorasse@gmail.com) — original author

## License

AGPL — see [LICENSE](LICENSE) for details.
