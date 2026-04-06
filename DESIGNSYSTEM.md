# Design System — Decidiamoci

> Guida stilistica per lo sviluppo dell'interfaccia. Tutti i componenti seguono queste regole.
> Ultimo aggiornamento: 2026-04-06.

---

## Fondamenta

| Proprietà | Valore |
|-----------|--------|
| **CSS Framework** | Tailwind CSS v4 + DaisyUI 5 |
| **Temi** | `nord` (light, default), `night` (dark, `--prefersdark`) |
| **Font** | **Sora** (Google Fonts) — tutti i pesi da 300 a 800 |
| **Border radius** | `0` ovunque (`border-radius: 0 !important` globale) |
| **Icone** | Font Awesome 6 (`fa-solid fa-*`, `fa-regular fa-*`, `fa-brands fa-*`) |
| **Colori** | Solo token DaisyUI: `primary`, `secondary`, `accent`, `info`, `success`, `warning`, `error`, `base-100/200/300`, `base-content` |

### CSS — `app/assets/tailwind/application.css`

```css
@import url('https://fonts.googleapis.com/css2?family=Sora:wght@300;400;500;600;700;800&display=swap');
@import "tailwindcss";
@plugin "daisyui" {
  themes: nord --default, night --prefersdark;
}

* {
  font-family: 'Sora', sans-serif;
  border-radius: 0 !important;
}
```

**Regola fondamentale:** ZERO classi CSS custom. Solo utility Tailwind + componenti DaisyUI. L'unico CSS custom è per Trix editor e override globali (checkbox, radio).

---

## Layout

### Struttura pagina (drawer layout)

Tutte le pagine (guest e loggato) usano il **drawer layout** DaisyUI:

```html
<div class="drawer lg:drawer-open">
  <input id="sidebar-drawer" type="checkbox" class="drawer-toggle" />

  <!-- Drawer content (navbar + pagina) -->
  <div class="drawer-content flex flex-col">
    <!-- Navbar (sticky top) -->
    <nav class="navbar bg-base-100 border-b-2 border-base-content/15 px-4 sticky top-0 z-30 min-h-16">
      ...
    </nav>

    <!-- Contenuto pagina -->
    <div class="max-w-[1400px] mx-auto px-4 lg:px-8 py-6 lg:py-8 w-full">
      <%= yield %>
    </div>

    <!-- Footer -->
  </div>

  <!-- Sidebar -->
  <div class="drawer-side is-drawer-close:overflow-visible z-40">
    <label for="sidebar-drawer" class="drawer-overlay"></label>
    <!-- Sidebar content -->
  </div>
</div>
```

### Sidebar

- Larghezza aperta: `is-drawer-open:w-64`
- Larghezza chiusa: `is-drawer-close:w-[4.5rem]`
- Bordo: `border-r-2 border-base-content/15`
- Sfondo: `bg-base-100`
- Voci attive: `bg-primary text-primary-content font-semibold`
- Voci inattive: `text-base-content/60 hover:bg-base-200 hover:text-base-content`
- Tooltip quando chiusa: `is-drawer-close:tooltip is-drawer-close:tooltip-right`
- Icone: `w-6 text-center text-lg`
- Sezioni: etichetta `text-[9px] font-bold text-base-content/30 uppercase tracking-widest mb-2 px-3`

### Navbar

- Sfondo: `bg-base-100 border-b-2 border-base-content/15`
- Sticky: `sticky top-0 z-30`
- Search: `input input-bordered w-full pl-10 h-10 text-sm` con icona FA assoluta
- Theme toggle: `swap swap-rotate btn btn-ghost btn-circle` con SVG sun/moon
- Notifiche: `dropdown dropdown-end` con `indicator-item badge badge-error badge-xs`
- User dropdown: avatar con iniziali + nome + ruolo

---

## Componenti

### Card (contenitore standard)

```html
<div class="bg-base-100 border-2 border-base-content/15">
  <!-- contenuto -->
</div>
```

**MAI usare:** `shadow-xl`, `shadow-lg`, `rounded-2xl`, `rounded-lg`. Il border-radius è 0 globalmente.

### Card con padding

```html
<div class="bg-base-100 border-2 border-base-content/15 p-5">
  <!-- contenuto -->
</div>
```

### Card con header e body separati

```html
<div class="bg-base-100 border-2 border-base-content/15">
  <div class="p-4 border-b-2 border-base-content/15 flex items-center gap-3">
    <div class="bg-primary/10 text-primary w-8 h-8 flex items-center justify-center">
      <i class="fa-solid fa-file-lines"></i>
    </div>
    <h2 class="font-bold text-sm">Titolo sezione</h2>
  </div>
  <div class="p-4">
    <!-- contenuto -->
  </div>
</div>
```

### Hero banner

Usato come intestazione di ogni pagina principale:

```html
<div class="bg-primary text-primary-content p-6 lg:p-8 mb-6 border-2 border-base-content/15 relative overflow-hidden">
  <div class="relative z-10 max-w-xl">
    <p class="text-[11px] font-bold tracking-widest text-primary-content/50 uppercase mb-3">SOTTOTITOLO</p>
    <h1 class="text-2xl lg:text-3xl font-extrabold leading-tight mb-2">Titolo pagina</h1>
    <p class="text-primary-content/60 text-sm mb-5">Descrizione breve.</p>
    <a href="#" class="btn btn-secondary btn-sm font-bold gap-2">
      Azione <i class="fa-solid fa-arrow-right text-xs"></i>
    </a>
  </div>
  <i class="fa-solid fa-landmark absolute right-6 lg:right-12 top-1/2 -translate-y-1/2 text-[7rem] lg:text-[9rem] text-primary-content/[0.06] hidden md:block"></i>
</div>
```

- Sfondo: `bg-primary text-primary-content`
- Bordo: `border-2 border-base-content/15`
- Icona decorativa: FA icon `absolute`, dimensione `text-[7rem] lg:text-[9rem]`, opacità `text-primary-content/[0.06]`, nascosta su mobile `hidden md:block`

### Stats row

```html
<div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
  <div class="bg-base-100 p-4 flex items-center gap-4 border-2 border-base-content/15">
    <div class="w-12 h-12 bg-primary/10 flex items-center justify-center text-primary shrink-0">
      <i class="fa-solid fa-file-lines text-xl"></i>
    </div>
    <div>
      <p class="text-[11px] text-base-content/40 font-medium">Sottotitolo</p>
      <p class="font-bold text-lg leading-tight">12 Proposte</p>
    </div>
  </div>
  <!-- ripetere per ogni stat -->
</div>
```

- Icona: quadrato colorato `w-12 h-12 bg-{color}/10 text-{color}`
- Sottotitolo: `text-[11px] text-base-content/40 font-medium`
- Valore: `font-bold text-lg leading-tight`

### Section header (dentro card)

```html
<div class="flex items-center gap-3 mb-4">
  <div class="w-10 h-10 bg-primary/10 flex items-center justify-center text-primary shrink-0">
    <i class="fa-solid fa-pen text-lg"></i>
  </div>
  <div>
    <h2 class="font-bold text-lg leading-tight">Titolo sezione</h2>
    <p class="text-[11px] text-base-content/40">Descrizione breve della sezione.</p>
  </div>
</div>
```

Colori icona per tipo di sezione:
- Primary: `bg-primary/10 text-primary`
- Secondary: `bg-secondary/10 text-secondary`
- Accent: `bg-accent/10 text-accent`
- Info: `bg-info/10 text-info`
- Warning: `bg-warning/10 text-warning`
- Success: `bg-success/10 text-success`
- Error: `bg-error/10 text-error`

---

## Tipografia

| Uso | Classi |
|-----|--------|
| **Titolo pagina** (hero) | `text-2xl lg:text-3xl font-extrabold leading-tight` |
| **Titolo sezione** | `font-bold text-lg leading-tight` |
| **Titolo card** | `font-bold text-sm` o `font-bold leading-snug` |
| **Corpo** | `text-sm text-base-content/60` o `text-sm text-base-content/45` |
| **Metadata** | `text-[11px] text-base-content/40` |
| **Timestamp** | `text-[11px] text-primary font-medium` (se recente) o `text-[11px] text-base-content/35` |
| **Label sezione sidebar** | `text-[9px] font-bold text-base-content/30 uppercase tracking-widest` |
| **Label tabella header** | `text-[10px] font-bold text-base-content/30 uppercase tracking-wider` |
| **Link "vedi tutto"** | `text-xs text-primary font-bold hover:underline` |

---

## Bottoni

| Tipo | Classi |
|------|--------|
| **Primario** | `btn btn-primary font-bold` |
| **Outline** | `btn btn-outline font-bold` |
| **Piccolo** | `btn btn-primary btn-sm font-bold` |
| **Ghost** | `btn btn-ghost` |
| **Cerchio** | `btn btn-ghost btn-circle` |
| **Con icona** | `btn btn-primary btn-sm font-bold gap-2` + `<i class="fa-solid fa-*"></i>` |
| **Danger** | `btn btn-error font-bold` |
| **Full width** | aggiungere `w-full` |

---

## Badge

```html
<span class="badge badge-primary badge-sm font-bold">IN VOTAZIONE</span>
<span class="badge badge-warning badge-sm font-bold">IN DISCUSSIONE</span>
<span class="badge badge-success badge-sm font-bold">APPROVATA</span>
<span class="badge badge-error badge-sm font-bold">RESPINTA</span>
<span class="badge badge-secondary badge-sm font-bold">PROPOSTA</span>
<span class="badge badge-accent badge-sm font-bold">COMMENTO</span>
```

Testo badge sempre **UPPERCASE** e **font-bold**.

---

## Avatar

### Con iniziali (standard)

```html
<div class="avatar placeholder">
  <div class="bg-primary text-primary-content w-10">
    <span class="font-bold text-sm">MR</span>
  </div>
</div>
```

Dimensioni: `w-6` (mini), `w-8` (small), `w-10` (default), `w-11` (medium).

### Con stato online

```html
<div class="relative shrink-0">
  <div class="avatar placeholder">
    <div class="bg-secondary text-secondary-content w-8">
      <span class="text-[10px] font-bold">LB</span>
    </div>
  </div>
  <span class="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 bg-success border-2 border-base-100"></span>
</div>
```

---

## Form

### Struttura campo (fieldset pattern)

```html
<fieldset class="fieldset">
  <label class="fieldset-label font-medium">Nome campo</label>
  <input type="text" class="input input-bordered w-full" placeholder="Placeholder..." />
</fieldset>
```

### Tipi di input

| Tipo | Classi |
|------|--------|
| **Text/email/password** | `input input-bordered w-full` |
| **Textarea** | `textarea textarea-bordered w-full` |
| **Select** | `select select-bordered w-full` |
| **Checkbox** | Stilizzato globalmente via CSS (`checkbox checkbox-primary`) |
| **Radio** | Stilizzato globalmente via CSS (`radio radio-primary`) |
| **Errore** | Aggiungere `input-error`, `textarea-error`, `select-error` |

### Checkbox con label

```html
<label class="label cursor-pointer gap-2 justify-start">
  <input type="checkbox" class="checkbox checkbox-sm checkbox-primary" />
  <span class="label-text text-sm">Testo della checkbox</span>
</label>
```

### Errori validazione

```html
<p class="text-error text-xs mt-1">Messaggio di errore</p>
```

### Alert errori (blocco)

```html
<div role="alert" class="alert alert-error mb-4">
  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/>
  </svg>
  <span class="text-sm">Messaggio di errore</span>
</div>
```

### Form multi-sezione (stile proposal/new)

Ogni sezione del form è una card separata con section header:

```html
<form class="space-y-6">
  <!-- Sezione 1 -->
  <div class="bg-base-100 border-2 border-base-content/15 p-5 space-y-4">
    <div class="flex items-center gap-3 mb-2">
      <div class="w-10 h-10 bg-primary/10 flex items-center justify-center text-primary shrink-0">
        <i class="fa-solid fa-pen text-lg"></i>
      </div>
      <div>
        <h2 class="font-bold text-lg leading-tight">Titolo</h2>
        <p class="text-[11px] text-base-content/40">Descrizione.</p>
      </div>
    </div>
    <!-- fieldset qui -->
  </div>

  <!-- Sezione 2, 3... -->

  <!-- Actions -->
  <div class="flex items-center justify-end gap-3">
    <a href="#" class="btn btn-outline font-bold">Annulla</a>
    <button type="submit" class="btn btn-primary font-bold">Salva</button>
  </div>
</form>
```

---

## Tabelle

```html
<div class="overflow-x-auto">
  <table class="table table-sm">
    <thead>
      <tr class="border-base-content/10">
        <th class="text-[10px] font-bold text-base-content/30 uppercase tracking-wider">Colonna</th>
      </tr>
    </thead>
    <tbody>
      <tr class="border-base-content/5 hover:bg-base-200/50">
        <td>
          <div class="flex items-center gap-2.5">
            <div class="avatar placeholder">
              <div class="bg-primary text-primary-content w-8">
                <span class="text-[10px] font-bold">MR</span>
              </div>
            </div>
            <div>
              <p class="font-semibold text-sm">Nome</p>
              <p class="text-[11px] text-base-content/35">Metadata</p>
            </div>
          </div>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

---

## Dropdown (notifiche, user menu)

```html
<div class="dropdown dropdown-end">
  <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
    <!-- trigger -->
  </div>
  <div tabindex="0" class="dropdown-content z-[60] mt-3 w-80 bg-base-100 border-2 border-base-content/15">
    <!-- header -->
    <div class="px-4 py-3 border-b-2 border-base-content/10">
      <span class="font-bold text-sm">Titolo</span>
    </div>
    <!-- items -->
    <div class="max-h-72 overflow-y-auto">
      <!-- ... -->
    </div>
    <!-- footer -->
    <div class="px-4 py-2.5 border-t-2 border-base-content/10 text-center">
      <a href="#" class="text-xs text-primary font-bold hover:underline">Vedi tutto</a>
    </div>
  </div>
</div>
```

---

## Pagine auth (login, registrazione, password reset, conferma)

Layout **split** — form da un lato, illustrazione dall'altro:

```html
<main class="flex-1 flex items-center justify-center px-4 py-12">
  <div class="flex w-full max-w-5xl bg-base-100 shadow-xl overflow-hidden">

    <!-- Form -->
    <div class="flex-1 p-8 sm:p-12 lg:p-16">
      <h1 class="text-3xl font-extrabold mb-2">Titolo</h1>
      <p class="text-base-content/50 mb-8">Sottotitolo.</p>
      <!-- social buttons + divider + form -->
    </div>

    <!-- Illustrazione (nascosta su mobile) -->
    <div class="hidden lg:flex flex-1 bg-primary/10 items-center justify-center p-12">
      <div class="text-center">
        <svg class="w-48 h-48 mx-auto text-primary/40" ...></svg>
        <h2 class="text-2xl font-bold text-primary mt-6">Titolo</h2>
        <p class="text-base-content/50 mt-2 max-w-xs mx-auto">Descrizione.</p>
      </div>
    </div>

  </div>
</main>
```

- **Signup**: form a sinistra, illustrazione a destra
- **Signin**: illustrazione a sinistra, form a destra
- **Social buttons**: `btn btn-outline flex-1 gap-3 font-semibold` con SVG Google/Facebook
- **Divider**: `<div class="divider text-sm text-base-content/40">oppure con email</div>`

---

## Modal

```html
<dialog id="my_modal" class="modal">
  <div class="modal-box max-w-2xl max-h-[80vh]">
    <form method="dialog">
      <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">✕</button>
    </form>
    <h3 class="font-bold text-xl mb-4">Titolo</h3>
    <div class="overflow-y-auto max-h-[60vh] text-sm leading-relaxed">
      <!-- contenuto -->
    </div>
    <div class="modal-action">
      <form method="dialog">
        <button class="btn btn-primary">Chiudi</button>
      </form>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop"><button>close</button></form>
</dialog>
```

Apertura: `document.getElementById('my_modal').showModal()`

---

## Notifiche / Eventi nella sidebar destra

### Evento prossimo

```html
<a href="#" class="flex items-center gap-3 p-3 bg-base-200/60 border-2 border-base-content/10 hover:border-primary transition-colors">
  <div class="w-11 h-11 bg-primary text-primary-content flex flex-col items-center justify-center shrink-0 text-center leading-none">
    <span class="text-[9px] font-bold">APR</span>
    <span class="text-base font-extrabold">06</span>
  </div>
  <div class="min-w-0">
    <p class="font-bold text-sm leading-tight">Nome evento</p>
    <p class="text-[11px] text-base-content/40"><i class="fa-regular fa-clock mr-1"></i>18:00 — Luogo</p>
  </div>
</a>
```

### Gruppo nella sidebar

```html
<a href="#" class="flex items-center gap-3 p-2.5 hover:bg-base-200 transition-colors">
  <div class="w-9 h-9 bg-primary/10 flex items-center justify-center text-primary shrink-0">
    <i class="fa-solid fa-tree text-sm"></i>
  </div>
  <div class="min-w-0 flex-1">
    <p class="font-bold text-sm leading-tight">Nome gruppo</p>
    <p class="text-[11px] text-base-content/35">24 membri</p>
  </div>
  <span class="w-2 h-2 bg-success shrink-0"></span>
</a>
```

---

## Proposal card

```html
<div class="card bg-base-100 border-2 border-base-content/15">
  <div class="card-body p-5 gap-3">
    <div class="flex items-center justify-between">
      <span class="badge badge-primary badge-sm font-bold">IN VOTAZIONE</span>
      <span class="text-[11px] text-base-content/35"><i class="fa-regular fa-clock mr-1"></i>2gg</span>
    </div>
    <h3 class="font-bold leading-snug">Titolo proposta</h3>
    <p class="text-sm text-base-content/45 leading-relaxed">Descrizione breve.</p>
    <div class="flex items-center justify-between mt-auto pt-2">
      <div class="flex items-center gap-2">
        <!-- avatar -->
        <span class="text-xs font-medium">Nome autore</span>
      </div>
      <span class="text-xs text-base-content/35"><i class="fa-solid fa-check-to-slot mr-1"></i>18 voti</span>
    </div>
  </div>
  <div class="border-t-2 border-base-content/10 px-5 py-3">
    <a href="#" class="btn btn-primary btn-sm w-full font-bold gap-2">
      <i class="fa-solid fa-check-to-slot"></i> Vota
    </a>
  </div>
</div>
```

---

## Cosa NON fare

- **MAI** `rounded-*` — il border-radius è 0 globalmente
- **MAI** `shadow-xl`, `shadow-lg`, `shadow-md` sulle card — usare `border-2 border-base-content/15`
- **MAI** colori hardcoded (`#000`, `#fff`, `rgb(...)`) — solo token DaisyUI
- **MAI** classi CSS custom — solo utility Tailwind + componenti DaisyUI
- **MAI** font diversi da Sora
- **MAI** icone diverse da Font Awesome 6
- **MAI** `Inter`, `Roboto`, `Arial`, `system-ui` come font
- **MAI** temi DaisyUI diversi da `nord` e `night`
- **MAI** `@apply` nelle view — solo nel file `application.css` per override globali
- **MAI** inline `style=""` — solo utility classes

---

## File di riferimento

| File | Descrizione |
|------|-------------|
| `app/assets/tailwind/application.css` | CSS principale (Tailwind + DaisyUI + override globali + Trix theme) |
| `config/initializers/simple_form_daisyui.rb` | Wrapper SimpleForm per DaisyUI |
| `app/views/layouts/_general.html.erb` | Layout principale (drawer) |
| `app/views/layouts/_sidebar.html.erb` | Sidebar navigazione |
| `app/views/layouts/_top_menu.html.erb` | Navbar |
| `docs/code_examples/daisyUI/dashboard.html` | Template di riferimento dashboard |
| `docs/code_examples/daisyUI/signup.html` | Template di riferimento registrazione |
| `docs/code_examples/daisyUI/signin.html` | Template di riferimento login |
