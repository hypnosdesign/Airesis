---
group: G01
phase: iteration-4
score: 28
score_max: 40
p0: 0
p1: 3
timestamp: 2026-08-29T22-21-39Z
slug: app-views-devise
---
# G01 — Iteration 4 synthesis

Assessment A scored the 13-route public/auth/legal/error surface **28/40**. The gate failed with P0=0 and P1=3. Assessment B independently checked all representative routes at desktop and mobile widths and ran the detector once.

## Assessment evidence

- No horizontal overflow; every route has one H1 and a main landmark; `/landing` redirects to `/`; the missing route returns a real 404 with two recovery paths.
- Computed contrast in the Nord theme produced no live failure; the link token was independently measured at 6.20:1 on the auth background.
- The detector returned an empty JSON array with exit 0, but explicitly fell back to regex because the HTML/CSS parser modules were unavailable. This is an undercount, not proof of zero defects.
- Assessment B's claims that the Italian terms lacked `lang="it"` and that the five `/edemocracy` topic links lacked accessible names were disproved in rendered HTML: the terms wrapper has `lang="it"`, and every topic link contains translated visible text.

## P1 findings at scoring time

1. Mandatory legal consent is unauthoritative: the privacy policy dates from 2018 and contradicts the current build about analytics; terms are Italian-only; operator/controller, public contact, providers, retention and other deployment facts require owner/legal approval.
2. Registration and language dialogs lacked an accessible name and deterministic initial focus.
3. The mobile drawer contract was otherwise correct, but initial focus was unreliable before the panel became rendered.

## Applied after synthesis

- Added `aria-labelledby` and visible titles to consent/language dialogs, plus a reusable modal controller focus target and next-frame fallback.
- Made the language launcher a real button instead of `href="#"`.
- Made the drawer panel synchronously visible in the opening task before focusing Close; runtime verification now reports `active="Close navigation"` inside the dialog and restores `Open navigation` on close.
- Raised standalone auth recovery links, “More topics”, footer legal links and “Back to top” to the 44px craft floor.

Only the legal-authority P1 remains. It cannot be resolved by UI inference; the service owner or legal reviewer must supply and approve current authoritative content.
