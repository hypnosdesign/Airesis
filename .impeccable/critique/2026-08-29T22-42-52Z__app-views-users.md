---
group: G02
phase: baseline
score: 13
score_max: 40
p0: 0
p1: 4
timestamp: 2026-08-29T22-42-52Z
slug: app-views-users
---
# G02 baseline — Shell, dashboard, identità e notifiche

## Esito

Punteggio Nielsen: **13/40**. Gate non superato: **P0 0, P1 4**.

Due assessment indipendenti hanno coperto le route rappresentative a 1440×900 e 390×844. Il detector è stato eseguito una volta sui target dichiarati; `app/views/searches` non esiste e il detector non ha emesso finding.

## P1 confermati

1. Route primarie di profilo, preferenze e notifiche espongono eccezioni o pagine errore: `/users/:id/edit`, `/notifications`, `/users/alarm_preferences`, `/users/privacy_preferences`, `/statistics`, `/interest_borders`, `/municipalities`.
2. Il flusso notifiche collega la campanella a `/notifications`, che non ha `index`; `/alerts` marca automaticamente tutto come letto al caricamento anziché su azione esplicita.
3. Il profilo usa affordance pointer-only e dialog non nominati; la route convenzionale di modifica utente è rotta.
4. La shell autenticata non espone `main` o `aria-current`; preferenze e alert hanno heading incoerenti o mancanti.

## P2 principali

- `/users/statistics` rende percentuali `NaN` quando il denominatore è zero.
- Ricerca globale e campanella non hanno nomi accessibili affidabili.
- Autocomplete assente nei campi account; target secondari sotto 44 px.
- Dashboard iniziale molto lunga, piena di zeri/empty state e con lingua/brand non uniformi.
- `/searches`, `/interest_borders` e `/municipalities` sono endpoint di supporto JSON inclusi impropriamente come superfici HTML.

## Evidenze di copertura

Renderizzate: `/home`, `/users/1-administrator-administrator`, `/users/edit`, `/users/border_preferences`, `/users/statistics`, `/alerts`, `/school`, `/municipality`.

Route con eccezione o error page: `/users/1-administrator-administrator/edit`, `/users/alarm_preferences`, `/users/privacy_preferences`, `/notifications`, `/statistics`, `/interest_borders`, `/municipalities`.

`/searches` è stato bloccato dal client prima della richiesta; il controller è stato verificato come endpoint JSON. Nessun overflow orizzontale è stato rilevato sulle route renderizzate.
