# Audit di Sicurezza — airesis-develop (Rails 8.1.3)

**Data:** 2026-08-07
**Metodo:** 5 agenti `explore` in parallelo (auth/Devise/OAuth, autorizzazione CanCanCan/admin, injection/XSS/upload, API v1/rate limiting, secrets/gem/Docker) + verifica manuale incrociata dei finding critici (tutti confermati sul codice). Nessuna modifica apportata.
**Stack:** Rails 8.1.3, Ruby 3.4.4, PostgreSQL 17, Devise 5 + OmniAuth (FB/Google/Twitter), CanCanCan 3.6, rails_admin 3, Rack::Attack, Solid Queue, Hotwire, Tailwind v4 + DaisyUI. HEAD `0692178`, worktree con ~260 modifiche locali non committate.

## 1. Sintesi esecutiva

Base di partenza **buona**: gem aggiornate, `config/application.yml` mai committato, CORS fail-closed, admin/RailsAdmin doppiamente protetti, API token timing-safe, path traversal su documents bloccato, password hash bcrypt con stretches 10.

Esito: **3 CRITICHE, ~8 ALTE, ~15 MEDIE, ~12 BASSE/INFO.**

### Stato remediation P0/P1 — 2026-08-29

I tre finding P0 sono stati corretti, verificati e pubblicati su `origin/main`:

- **C1 risolto:** il login API non registra più email o password fornite; il log contiene soltanto ID utente (quando noto) e IP della richiesta.
- **C2 risolto:** `UsersController#update` applica `authorize! :update, @user`; CanCanCan consente l'update esclusivamente sul proprio profilo. Aggiunta regressione che prova il tentativo di cambio nome, email e password di un altro utente.
- **C3 risolto per il trasporto TLS:** Facebook OAuth usa `verify: true`; PayPal rifiuta endpoint non HTTPS e usa `OpenSSL::SSL::VERIFY_PEER`. La validazione applicativa di destinatario, importi e identificativo transazione resta una difesa P1/P2 da aggiungere quando saranno definiti i valori PayPal attesi.
- **Hardening aggiuntivo:** la source Bundler è stata portata da HTTP a HTTPS.

Verifiche eseguite: 70 spec di regressione mirate, 0 failure; RuboCop sui 12 file Ruby coinvolti, 0 offense. La suite non-system estesa esegue 1516 esempi ma conserva 15 failure preesistenti (helper/view obsolete e cache Rack::Attack condivisa tra test) e due file non caricabili già segnalati nell'audit (`ManagerActions` mancante e spec Resque obsoleta).

I finding A1-A4 del primo blocco P1 sono corretti nel worktree e non ancora committati:

- **A1 risolto:** rimossa la configurazione Facebook commentata con credenziali hard-coded; la configurazione effettiva usa esclusivamente `FACEBOOK_APP_ID` e `FACEBOOK_APP_SECRET` da ambiente. L'utente ha confermato che la vecchia credenziale non esiste più su Meta. `main`, il branch remoto aggiuntivo e i due tag sono stati riscritti e pubblicati atomicamente; un clone mirror fresco non contiene i valori storici e il vecchio commit non è più recuperabile dal server Git.
- **A2 risolto:** `group_image_tag` genera ora l'elemento `img` con il tag builder Rails, che esegue escaping degli attributi.
- **A3 risolto:** il model `Taggable` non produce più HTML; le view usano un helper basato su `safe_join` e `link_to`, senza `raw`.
- **A4 risolto:** `/tokens` è limitato per IP e per email normalizzata; il token viene generato soltanto dopo la verifica della password.

Verifiche P1: 57 spec mirate e di integrazione, 0 failure. Brakeman non segnala più i due XSS A2/A3; il report completo conserva finding estranei a questo blocco e un errore di parsing su una view legacy.

## 2. Punti di forza verificati

| Area | Riferimento |
|---|---|
| `config/application.yml` mai committato (gitignored, verificato con git log/ls-files) | `.gitignore:12` |
| `SECRET_KEY_BASE`/`DEVISE_SECRET_KEY` solo da ENV, nessun fallback | `config/initializers/secret_key_base.rb`, `devise.rb:4` |
| CORS fail-closed (allowlist; vuoto = blocco totale; il claim CLAUDE.md "aperto a *" è obsoleto) | `config/application.rb:74-82` |
| RailsAdmin protetto due volte (route constraint + warden + CanCan, solo `user.admin?`) | `config/initializers/rails_admin.rb:13-19`, `app/cancan/abilities/rails_admin.rb` |
| Admin namespace con `before_action :admin_required` | `app/controllers/admin/application_controller.rb:5` |
| API token con `ActiveSupport::SecurityUtils.secure_compare` (timing-safe) | `app/controllers/api/v1/application_controller.rb:20-22` |
| Path traversal su `documents#view` bloccato (cleanpath + prefisso) | `app/controllers/documents_controller.rb:23-27` |
| Open redirect OAuth bloccato (`uri.host == request.host`) | `app/controllers/users/omniauth_callbacks_controller.rb:34-41` |
| Active Storage con `active_storage_validations` (magic bytes) + limiti dimensione | `app/models/user.rb:51-52`, `group.rb:113-114`, `constants.rb:35-37` |
| Rack::Attack con throttle (login, registrazione, API, admin panel, password reset) | `config/initializers/rack_attack.rb` |
| Cookie SameSite=Lax, serializer `:json`, HttpOnly default; `skip_session_storage` | `config/load_defaults 8.1` |
| Versione gem chiave tutte aggiornate (devise 5.0.3, cancancan 3.6.1, omniauth 2.1.4, rack 3.2.6, sanitize 7.0.0, nokogiri 1.19.2) | `Gemfile.lock` |
| Nessun `.pem`/`.key`/`master.key` tracciato; nessuna chiave AWS/GitHub/OpenAI hardcoded | verificato |

## 3. Findings

### CRITICHE (verificate direttamente sul codice)

**C1 — Password in chiaro nei log**
- `app/controllers/tokens_controller.rb:33`
- `logger.info("User #{email} failed signin, password \"#{password}\" is invalid")` scrive la password di ogni login fallito su `POST /tokens`. Bypassa `config.filter_parameters` (che filtra solo i parametri HTTP). Chiunque legga i log (lograge/STDOUT, Sentry breadcrumbs, aggregatori) recupera password valide.
- Fix: rimuovere la password dal log; loggare solo email + IP.

**C2 — Account takeover via IDOR su `UsersController#update`**
- `app/controllers/users_controller.rb:181-208` (`update`), `:275-277` (`load_user`), `:259-263` (`user_params`)
- Nessun `load_and_authorize_resource`/`authorize!`/verifica `@user == current_user`. `before_action :load_user` fa `User.find(params[:id])`; `user_params` permette `:password`, `:password_confirmation`, `:email`. `@user.update` (non `update_with_password`) non richiede `current_password`. Qualsiasi utente autenticato: `PATCH /users/:id_vittima` → cambia password/email di chiunque. **Account takeover totale.**
- Fix: `authorize! :update, @user` (o usare `current_user`), regola CanCan `can :update, User, id: user.id`.

**C3 — TLS disabilitato su Facebook OAuth e PayPal IPN**
- `config/initializers/devise.rb:31` (`client_options: { ssl: { verify: false, ... } }`) e `app/controllers/users/facebook_controller.rb:4`
- `app/controllers/sys_payment_notifications_controller.rb:26` (`http.verify_mode = OpenSSL::SSL::VERIFY_NONE`)
- MITM sulla rete può intercettare token OAuth Facebook e rispondere "VERIFIED" alle validazioni IPN PayPal (notifiche di pagamento false). Inoltre `Object.const_defined?(params[:atype])` è un pattern fragile.
- Fix: `verify: true`/`VERIFY_PEER` con CA bundle; validare il payload PayPal (txn_id, receiver_email, importi).

### ALTE

**A1 — Credenziali Facebook reali committate — RISOLTO**
- `config/initializers/omniauth.rb:2` — app ID e secret reali erano presenti in un commento dal commit iniziale e restano recuperabili dalla storia Git remota.
- Fix: ruotare il secret, rimuovere la riga, aggiungere secret-scanning in CI.

**A2 — Stored XSS via `group.name` — RISOLTO NEL WORKTREE**
- `lib/image_helper.rb:8-9` — HTML costruito a mano `<img ... alt="#{group.name}">` + `.html_safe`, usato in liste gruppi/portlet/email/mustache. `Group` non restringe i caratteri del nome (`app/models/group.rb:44`). Nome `"><script>...` → XSS per tutti i visitatori. CSP con `'unsafe-inline'` non mitiga.
- Fix: `content_tag`/`image_tag`/`CGI.escapeHTML`.

**A3 — Stored XSS via tag — RISOLTO NEL WORKTREE**
- `app/models/concerns/taggable.rb:46-48` (`tags_with_links` senza escaping) + `raw` in `blog_posts/show.html.erb:55`, `_blog_post.html.erb:42`, `_group_blog_post.html.erb:50`. `Tag#escape_text` non rimuove `< > "`.
- Fix: allowlist caratteri tag o `h()`/`sanitize`; rimuovere `raw`.

**A4 — Brute force illimitato su `/tokens` — RISOLTO NEL WORKTREE**
- `app/controllers/tokens_controller.rb:1-48`; `config/initializers/rack_attack.rb:17-39`
- Rack::Attack non copre `/tokens` (solo `/users/sign_in` e `/api/`). Inoltre `@user.ensure_authentication_token!` (`:28`) esegue write DB prima del check password.
- Fix: throttle dedicato su `/tokens` (per-IP e per-email), verificare password prima di rigenerare token.

**A5 — Moderazione forum: IDOR cross-group + dispatch metodo arbitrario**
- `app/models/frm/post.rb:85-91` (`send("#{moderation[:moderation_option]}!")`), `app/models/frm/topic.rb:88-90`, `app/controllers/frm/moderation_controller.rb:13,21`
- Post trovati per ID globale senza scope al forum/gruppo; `moderation_option` da params non whitelistato (`destroy!`, `update!`...).
- Fix: scoping `forum.posts.where(id: ...)` + whitelist `%w[approve spam]`.

**A6 — `config.hosts` assente in produzione (Host header injection)**
- `config/environments/production.rb` — in Rails 8.1 il default fuori da development è `[]` → `ActionDispatch::HostAuthorization` disabilitato → poisoning dei link (password reset, OAuth `full_host`).
- Fix: `config.hosts = ["airesis.it", ".airesis.it", IPAddr...]`.

**A7 — `force_ssl` condizionale a ENV**
- `config/environments/production.rb:28` — se `FORCE_SSL` manca in prod, HTTP puro senza HSTS.
- Fix: `config.force_ssl = true` fisso + `ssl_options` HSTS.

**A8 — CSP attiva ma con `'unsafe-inline'` su script-src**
- `config/initializers/content_security_policy.rb:11` — `script_src :self, :unsafe_inline, ...` annulla la difesa anti-XSS; `connect_src :https` troppo largo (`:14`); manca `frame-ancestors`.
- Fix: nonce per Stimulus/Turbo, stringere connect_src, aggiungere `frame_ancestors :self`.

### MEDIE (selezione)

- **Sanitizer globale con `iframe` + `style` permessi** — `config/application.rb:49-54` → UI-redress/phishing iniettabile nel contenuto proposte (iframe a schermo pieno).
- **SSRF incompleto su `avatar_url=`** — `app/models/user.rb:80-91`: blocca schema/host ma non IP privati/metadata (`169.254.169.254`), redirect, DNS rebinding; nessun limite di dimensione prima dell'attach.
- **`admin/users#unblock` è GET (CSRF)** — `config/routes.rb:426`, `admin/users_controller.rb:22-34`.
- **Skip CSRF globale su tutte le richieste JSON** — `app/controllers/application_controller.rb:39`; combinabile con form `.json` per CSRF su endpoint mutanti.
- **Login CSRF** — `app/controllers/sessions_controller.rb:2` (`skip_before_action :verify_authenticity_token, only: :create`); aggravato da `remember_me` di default in `home/index.html.erb:117`.
- **Token API senza scadenza/rotazione** — `app/models/user.rb:18,175-187`; non invalidato al cambio password/logout web; bypass di `blocked` e `confirmable` via token (`api/v1/application_controller.rb:16-24`, `tokens_controller.rb:19-35`).
- **Mass assignment su `SearchProposal`** — `app/controllers/search_proposals_controller.rb:3` (`new(params[:search_proposal])`, campi DB + `per_page` illimitato). *Latente: nessuna route mappata*.
- **`users#index` dump utenti senza `.limit()`** — `users_controller.rb:58-66`: `q` vuoto → `LIKE '%%'` → tutti gli utenti (id+nome) via JSON.
- **Input search non clampati** — `proposals_controller.rb:540`, `searches_controller.rb:6`, `tags_controller.rb:35`, `interest_borders_controller.rb:5` (fix 6.1.2 applicato solo a `users#index`).
- **Rack::Attack su `memory_store` per-processo** — `config/puma.rb:28` (2 worker), nessun cache store condiviso in `production.rb` → throttle aggirabili distribuendo su worker.
- **PostgreSQL `trust` auth** — `docker-compose.yml:38`; porta 5433 esposta sull'host.
- **Container come root** — `Dockerfile` senza `USER`; volume host `.:/usr/src/app` montato.
- **`login_as` (impersonazione) su GET** — `lib/rails_login_as.rb` (`http_methods [:get]`, `sign_in ... bypass: true`), senza audit trail.
- **Email enumeration** — `validators/uniqueness_controller.rb:9-11,21-23` (endpoint pubblico) e reset password Devise (messaggi differenziati).
- **`SESSION_DAYS` codice morto** — `config/initializers/constants.rb:39`: la costante non è referenziata; nessun timeoutable → sessioni senza scadenza reale oltre il cookie remember.
- **Password policy debole** — `devise.rb:22` (`6..128`), nessun `:lockable`.
- **Admin::PanelController/ManagerController rotti** — `app/controllers/admin/panel_controller.rb:3`, `manager_controller.rb:3` (`include ManagerActions` di modulo eliminato) → 500/NameError.

### BASSE / INFO

- `users#autocomplete` fuori scope (partecipanti di gruppi arbitrari) — `users_controller.rb:232-239`
- `ProposalLivesController#show` senza autorizzazione sulla proposta — `proposal_lives_controller.rb:4-24`
- `ProposalNicknamesController#update` IDOR — `proposal_nicknames_controller.rb:10-31`
- `UserLikesController#destroy` senza ownership — `user_likes_controller.rb:14-18`
- Guest `show` su gruppi privati — `app/cancan/abilities/guest.rb:30`
- Flash `raw` — `app/views/layouts/_flash.html.erb:14` e announcement `:23`
- `solution.title_with_seq.html_safe` nel PDF (wkhtmltopdf con JS abilitato) — `app/views/proposals/show.pdf.erb:146`
- Reply-by-email senza SPF/DKIM — `app/workers/elaborate_emails.rb:1-19`
- Feedback: content-type dichiarato senza magic bytes — `home_controller.rb:72-77`
- wkhtmltopdf da apt (CVE binario pre-0.12.6) — `Dockerfile:11`
- figaro EOL; `Gemfile:1` source `http://`; gem git su branch non pinnate
- `curl | bash` per Node in Dockerfile; `NODE_OPTIONS=--openssl-legacy-provider`
- Route catch-all `get '/:id'` — `config/routes.rb:437`
- NewRelic `capture_params: true` / `record_sql: raw` — `config/newrelic.yml:11,15`
- `REST_AUTH_SITE_KEY` hardcoded (dead code) — `config/initializers/site_keys.rb:18`
- OAuth token provider in chiaro nel DB (`authentications.token`) e in sessione cookie (`session['devise.omniauth_data']`)

## 4. Falsi positivi esclusi

- **"CORS aperto a *" in CLAUDE.md:561** — obsoleto: `application.rb:74-82` è allowlist fail-closed (verificato sul sorgente rack-cors 3.0.0).
- **SQL injection** — nessuna reale: le interpolazioni nei worker usano valori costanti/DB; ricerca ordinata con whitelist; `find_by_sql` parametrizzato.
- **`bundle audit`** non eseguibile (Ruby locale 2.6, lockfile 3.4/aarch64): analisi versioni manuale — tutte le gem chiave risultano sicure/aggiornate.
- **`validators/uniqueness`** — `constantize` su simboli fissi, non su input.
- **`params.to_unsafe_h`** — usato solo per redirect/URL, non per assegnazione a modelli.
- **elFinder upload** — scritture disabilitate (`@can_manage = false`).
- **`test.rb` `filter_parameters = []`** — solo ambiente test.

## 5. Priorità di remediation

1. **P0** — C1 password nei log; C2 IDOR `users#update`; C3 TLS Facebook/PayPal.
2. **P1** — A1-A4 risolti; resta A5 moderazione forum whitelist.
3. **P2** — A6 `config.hosts`; A7 `force_ssl`; A8 CSP nonce; sanitizer iframe; token API scadenza/rotazione + check blocked; CSRF JSON; cache Rack::Attack condivisa; `admin/unblock` POST.
4. **P3** — password policy + lockable; scadenza sessioni; NewRelic capture_params; wkhtmltopdf; Docker hardening (trust auth, non-root); paginazione/limit su search e users index.

## 6. Limiti dell'audit

- Analisi statica, non penetration test. Non verificati: valori reali delle env di produzione, `FORCE_SSL` effettivo, configurazione NewRelic, versione wkhtmltopdf installata, comportamento a runtime (es. `banned?` in `sessions_controller.rb:11`, pannello admin M1).
- Worktree locale con ~260 modifiche non committate: la valutazione riflette lo stato su disco, non necessariamente `origin/main`.
