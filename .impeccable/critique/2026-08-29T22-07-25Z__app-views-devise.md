---
group: G01
phase: iteration-3
score: 28
score_max: 40
p0: 0
p1: 3
timestamp: 2026-08-29T22-07-25Z
slug: app-views-devise
---
# G01 — Iteration 3 synthesis

Assessment A scored the public, authentication, legal, and error surface **28/40** on the Nielsen rubric. The 33/40 gate failed because three P1 findings remained.

## P1 findings

1. Secondary and inline primary-colour links measured 3.31–3.50:1 on the two observed Nord backgrounds.
2. The mobile navigation behaved mostly like a modal but did not synchronously place focus in the drawer or isolate the obscured page shell.
3. The mandatory legal consent remained unauthoritative: the privacy text dates from 20 June 2018, the terms are Italian-only in an English UI, and operator/controller/provider details require owner or legal approval.

Assessment B independently covered all 13 representative routes at 1440×900 and 390×844. It found no overflow, soft 404, heading, label, or accessible-name defects. Its single detector run returned two source findings in degraded regex mode because the HTML parser modules were unavailable; one concerned an authenticated-only submenu and one was a non-rendered Trix blockquote false positive.

## Applied after synthesis

- Added a dedicated high-contrast text-link token and verified the computed result at 6.20:1.
- Completed the drawer modal contract: synchronous close-button focus, inert and aria-hidden background, body scroll lock, focus trap, Escape close, and focus restoration.
- Replaced the unverified hard-coded contact address with a validated deployment contact; environments with no authoritative contact now state that clearly.

The legal-content P1 is intentionally unresolved pending authoritative operator information and approved current policy text.
