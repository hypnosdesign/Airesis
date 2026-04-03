# Gemini Context — Airesis

This project is a modernizing open-source e-democracy platform. It is a monolithic Ruby on Rails application designed for civic participation, collective decision-making (Schulze method voting), and community management.

## Project Overview

*   **Purpose:** Enable citizens and groups to create proposals, vote, discuss via forums/blogs, and organize events.
*   **Architecture:** Rails Monolith with a REST API (v1), integrated forum system (`Frm::`), and a robust background job system (Sidekiq).
*   **Primary Technologies:**
    *   **Backend:** Ruby 3.2.8, Rails 7.1.6
    *   **Database:** PostgreSQL 14 (using `hstore` and `pg_search`)
    *   **Cache/Jobs:** Redis 7, Sidekiq 6.1 (multi-queue setup)
    *   **Auth:** Devise 5 (with OmniAuth for Facebook, Google, Twitter) + CanCanCan 3 for authorization.
    *   **Frontend:** Slim (100% of templates), TailwindCSS v4, Hotwire (Turbo & Stimulus), FontAwesome 6 (CDN).
    *   **Asset Pipeline:** Sprockets 4 (for legacy) + `jsbundling-rails` (esbuild, for modern).
    *   **Other:** `active_storage` (uploads), `paper_trail` (auditing), `friendly_id` (slugs), `geocoder`, `ckeditor`.

## Building and Running

### Development with Docker (Preferred)

1.  **Start Services:**
    ```bash
    docker compose up
    ```
2.  **Initial Setup:**
    ```bash
    docker compose run --rm airesis bundle exec rails db:create db:schema:load
    ```
3.  **Migrations:**
    ```bash
    docker compose run --rm airesis bundle exec rails db:migrate
    ```
4.  **JS Build:** (Required for JS changes)
    ```bash
    docker compose run --rm airesis yarn build
    ```
5.  **Tailwind Build:** (Required for Tailwind CSS changes)
    ```bash
    docker compose run --rm airesis bundle exec rails tailwindcss:build
    ```
6.  **Asset Precompilation:**
    ```bash
    docker compose run --rm -e RAILS_ENV=development -e NODE_OPTIONS=--openssl-legacy-provider airesis bundle exec rails assets:precompile
    ```

## Development Conventions

*   **Authorization:** Always use **CanCanCan** (`can?`, `authorize!`).
*   **Jobs:** Use **Sidekiq** directly for background tasks (configured in `config/sidekiq.yml`).
*   **Views:** Use **Slim** (`.slim`) exclusively. All ERB files have been migrated.
*   **Styling:** Build all new features using **TailwindCSS/DaisyUI**. The legacy Foundation CSS code is completely deprecated and MUST be refactored out.
*   **JS:** Use **Stimulus** for all interactivity (`app/javascript/controllers`). DO NOT write new jQuery code.
*   **I18n:** UI strings must use `I18n.t()`. 

## The "Real" Application State & Technical Debt (Current 2026 Status)

While Fases 1-5 have successfully upgraded the infrastructure (Ruby 3.2, Rails 7.1, Hotwire, esbuild, Tailwind CSS initialized, Slim refactored, Paperclip to ActiveStorage migrated), **the application suffers from a massive "hybrid state" in the frontend.**

### 🚨 Critical Frontend Architecture Debt:
- **Stimulus is empty:** While configured, there are almost zero real Stimulus controllers active in `app/javascript/controllers`.
- **Legacy Code Rules the Client:** The overwhelming majority of the application's interactivity and style is still dictated by monolithic legacy files sitting in `app/assets/javascripts` (e.g. `democracy.js`, `foundation-patch.js`) and `app/assets/stylesheets` (huge 70KB Foundation overrides, fullcalendar, jQuery-UI).
- **The True Strategy:** The primary development focus MUST be purely executional: picking a view, removing Foundation classes, re-implementing it in TailwindCSS/DaisyUI, and moving any jQuery interactivity into well-scoped Stimulus Controllers.

### Active Roadmap:
1.  **Increase Test Coverage (from ~63.7% to >70%):** Write robust RSpec and System Tests to guarantee that removing legacy views and javascript won't break features like Schulze voting.
2.  **Frontend Bonification:** Page-by-page rewrite using exclusively DaisyUI / TailwindCSS and Stimulus. Absolute destruction of `app/assets/javascripts` and `foundation`.
3.  **Future Upgrades (Post Refactor):** Upgrade to Rails 8.0/Ruby 3.4, and evaluate replacing Sidekiq/Redis with `Solid Queue` / `Solid Cache` to simplify the Docker infrastructure.
