---
target: G05 groups, membership and invitations final
total_score: 33
max_score: 40
na_heuristics:
p0_count: 0
p1_count: 0
timestamp: 2026-08-30T11-08-47Z
slug: app-views-groups
---
Method: dual-agent (A: g05_final_design_critique · B: g05_final_detector_critique)

# Impeccable critique — G05 final

## Design Health Score

| # | Heuristic | Score | Final evidence |
|---|---|---:|---|
| 1 | Visibility of System Status | 3 | Active navigation, membership states, inline validation and flash feedback are visible. |
| 2 | Match System / Real World | 4 | Community, membership, CSV and email copy use direct domain language. |
| 3 | User Control and Freedom | 3 | Cancel paths, Esc, focus restoration and destructive confirmations are present. |
| 4 | Consistency and Standards | 4 | Seven surfaces share navigation, landmarks, controls, terminology and responsive behavior. |
| 5 | Error Prevention | 3 | Required fields, scoped batch operations and confirmations prevent high-cost mistakes. |
| 6 | Recognition Rather Than Recall | 4 | Labels and hints are contextual; the active mobile navigation item is automatically revealed. |
| 7 | Flexibility and Efficiency | 3 | Search, advanced filters, CSV export, email and scoped bulk removal support administrators. |
| 8 | Aesthetic and Minimalist Design | 3 | Forms are sectioned, empty tag chrome is omitted and mobile cards retain readable proportions. |
| 9 | Error Recovery | 3 | Invalid HTML and Turbo submissions preserve the form surface and render actionable errors. |
| 10 | Help and Documentation | 3 | Rules dialog, permission list, editor affordance and recipient-format hints are available in context. |
| **Total** |  | **33/40** | **Gate passed** |

## Gate

- Final score: **33/40**.
- P0: **0**.
- P1: **0**.
- Both independent assessments converged on 33/40 after read-only delta checks.

## Remediation completed

- Removed the missing legacy `endless_page.js` dependency and rebuilt member management with semantic cards, filters, CSV export, accessible email dialog and scoped bulk operations.
- Added visible, responsive and role-aware group navigation; its active item is revealed on mobile.
- Rebuilt discovery, profile, creation, editing, invitations and permissions with one `main`, one H1, real controls, stable Turbo targets and responsive Trix containment.
- Restored valid Turbo recovery for invalid group and invitation submissions; both replace stable form containers and show errors/flash.
- Added stable membership panel targets so Accept/Reject streams refresh community and pending-request state.
- Fixed contrast, mobile group-card proportions, wrapped role CTA, mixed terminology, invitation copy and empty tag chrome.
- Stopped `Group.look` from mutating request parameters; advanced filters are initially collapsed while match-all remains the explicit default.
- Scoped role assignment, massive email and bulk removal to the authorized group and pruned unimplemented REST routes.

## Browser evidence

Seven current G05 surfaces were checked at desktop and 390×844: `/groups`, `/groups/new`, group show, edit, members, invite and permissions. Each rendered one `main` and one H1, with no application 500/Oops page, horizontal page overflow, placeholder `href="#"` or broken image. Rules and email dialogs had accessible names, initial focus, Esc close and trigger focus restoration. The active mobile navigation item was fully visible on members, edit and permissions.

The invalid invitation and group Turbo flows displayed field errors plus flash without a valid persistence. Membership stream targets were verified against exactly one matching wrapper each; no valid Accept/Reject action was submitted during the final review.

## Detector

The final detector was executed exactly once with:

```text
node /Users/mattia/.agents/skills/impeccable/scripts/detect.mjs --json app/views/groups app/views/group_participations app/views/group_invitations
```

- Exit: `0`.
- JSON: `[]`.
- No degraded warning was emitted by the command.
- Limitation: ERB is inspected source-level and the unavailable HTML parser modules make `[]` an undercount; runtime Turbo targets and responsive behavior were therefore verified separately in the browser and request specs.

## Verification

- 111 targeted request/model/helper examples passed with zero failures.
- RuboCop passed on all touched Ruby and spec files.
- esbuild and Tailwind builds passed.
- Locale and coverage YAML parsed successfully; `git diff --check` passed.
- Selenium system specs remain blocked by Selenium Manager lacking ChromeDriver for Linux ARM64; the corresponding surfaces and interactions were covered in real Chrome.

## Residual observations

- An invalid invitation is rejected with a visible error but the deliberately invalid value is normalized away; this is minor and does not block recovery.
- G06 governance surfaces remain explicitly outside this assessment.

Questions skipped: the user already defined the G05 scope, gate and stop condition; no product decision remains before G06.
