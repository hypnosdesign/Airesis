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
    *   **Asset Pipeline:** Sprockets 4 + `jsbundling-rails` (esbuild).
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
5.  **Tailwind Build:** (Required for CSS changes)
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
*   **Styling:** Use **TailwindCSS**. Foundation 5 is still present but deprecated.
*   **JS:** Use **Stimulus** for new interactive features. Legacy jQuery logic is being phased out.
*   **I18n:** UI strings must use `I18n.t()`. Note: Use `rescue` or check for existence when concatenating I18n arrays in layouts to avoid `TypeError`.

## Project Structure Highlights

*   `app/models/concerns/user/`: Modularized `User` logic (Authenticatable, Proposable, Groupable, etc.).
*   `app/javascript/`: JS entry points for esbuild.
*   `app/assets/builds/`: Compiled JS and CSS (Tailwind).
*   `app/assets/config/manifest.js`: Sprockets 4 manifest linking builds and legacy JS.
*   `app/workers/`: Sidekiq workers for async tasks.

## Roadmap & Technical Debt (Current 2026 Status)

*   **Completed:** 
    *   Upgraded stack: Ruby 3.2, Rails 7.1, Postgres 14, Redis 7, Sprockets 4.
    *   Migrated **Paperclip** to **Active Storage**.
    *   Removed **CoffeeScript** (converted to ES6+).
    *   Replaced **Webpacker** with **esbuild**.
    *   Implemented **TailwindCSS v4** and **Hotwire**.
    *   Migrated **100% of views from ERB to Slim**.
    *   Refactored **User model** into Concerns.
*   **Next Steps:**
    *   Increase test coverage (> 70%).
    *   Systematic TailwindCSS application to all UI components (removing Foundation).
    *   Migrate legacy jQuery logic to Stimulus controllers.

## Important Technical Notes

*   **Sprockets 4:** Uses `app/assets/config/manifest.js`. Note that `application.js` from `builds` conflicts with `javascripts/application.js`, so legacy main JS was moved to `javascripts/legacy/application.js`.
*   **User Model:** Extracted into 7 Concerns to manage complexity.
*   **FontAwesome 6:** Loaded via CDN in `_head.html.slim` for compatibility.
*   **Tests:** Run via `bundle exec rspec`. Coverage is around 33%.
