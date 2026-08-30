---
target: G08 blog, tags, documents, and content baseline
total_score: 14
max_score: 40
na_heuristics:
p0_count: 2
p1_count: 3
timestamp: 2026-08-30T13-58-52Z
slug: app-views-blogs
---
Method: dual-agent (A: g07_final_visual_critique · B: g06_final_detector_critique)

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|---|---:|---|
| 1 | Visibility of system status | 1 | Core pages fail; document archive exposes no loading, empty, or failure state. |
| 2 | Match system / real world | 2 | Editorial terms are understandable, but status choices and legacy labels need interpretation. |
| 3 | User control and freedom | 2 | Cancel and safe exits exist; primary operations remain unavailable. |
| 4 | Consistency and standards | 1 | Legacy editorial surfaces diverge from the current application shell. |
| 5 | Error prevention | 2 | Required fields exist, but publication is the unexplained default and status is not validated. |
| 6 | Recognition rather than recall | 1 | Unnamed controls, empty indexes, and an unnamed overflow menu conceal meaning. |
| 7 | Flexibility and efficiency | 2 | Search and rich-text editing exist, but discovery and reading are blocked. |
| 8 | Aesthetic and minimalist design | 1 | Weak hierarchy, dead space, and unfinished components dominate. |
| 9 | Error recovery | 1 | Generic failure pages provide no contextual diagnosis or retry. |
| 10 | Help and documentation | 1 | Status and document workflows lack contextual guidance. |
| **Total** | | **14/40** | **Poor** |

## Design Specificity Verdict

The surfaces resemble generic legacy CMS scaffolding. The civic content is product-specific, but discovery, tag navigation, authorship, and document handling do not yet express traceable community decision-making. The current announcement and global error shell are more coherent with the modern product language.

The deterministic detector was intentionally deferred to the post-fix gate by the active Impeccable session directive. Independent source and browser evidence instead found runtime, route, authorization, and accessibility failures.

## Overall Impression

The content model has useful foundations, but the public reading path fails at runtime and the document archive looks operational while exposing an empty integration mount. Restoring trustworthy task completion is the single largest opportunity.

## What's Working

- No page-level horizontal overflow was observed at desktop or mobile widths.
- Primary authoring controls and the announcement dismissal meet the 44 px interaction floor.
- Destructive actions generally request confirmation, and document serving applies authorization plus clean-path checks.

## Priority Issues

1. **P0 — Blog and article routes return HTTP 500.** `blogs/show` and `blog_posts/show` require the removed `endless_page.js` asset. Replace the dependency with a working, progressively enhanced pagination contract and prevent 500 from being accepted by request specs.
2. **P0 — The document archive is operationally blank.** `#elfinder` renders no actions, content, loading, empty, or error feedback. Provide a resilient initialization and fallback state.
3. **P1 — Published routes exceed implemented behavior.** Blog comments, tags, and documents expose unsupported CRUD actions; top-level and group variants of blog posts enter code that assumes a blog. Constrain the route surface and make every retained path explicit.
4. **P1 — Deferred anonymous comments are saved after login without an explicit second authorization check.** Re-authorize the recovered create operation before persistence and clear invalid session state.
5. **P1 — Discovery and semantic foundations are incomplete.** Blog and tag indexes do not reliably reveal available content; pages lack consistent H1/main hierarchy; tab semantics are non-functional; overflow menus have no accessible name.
6. **P2 — Recovery and validation contracts are weak.** Invalid submissions do not consistently return 422, publication status is not constrained, and permissive specs accept 500.
7. **P2 — Authoring creates excess cognitive load.** Fourteen rich-text controls overflow mobile without a cue, while publication visibility and group distribution are not explained.

## Persona Red Flags

- **Jordan:** cannot interpret the unlabeled search checkbox or publication visibility and meets a generic server error before reading a post.
- **Sam:** encounters missing main/H1 structure, incomplete tab semantics, an unnamed overflow control, and weak editor focus indication.
- **Casey:** must horizontally discover a large editor toolbar and use multiple secondary targets below 44 px.

## Minor Observations

- `html_input` likely prevents comment textarea options from being applied.
- Document quota progress lacks an accessible name and heading order jumps from H1 to H4.
- Hidden announcement cookies are not deduplicated or bounded.

## Questions to Consider

The user has already selected complete remediation through G10, so runtime trust, authorization, and semantic clarity take precedence over decorative changes.

Questions skipped: l'utente ha già autorizzato esplicitamente la remediation completa di G08–G10 e ha chiesto di procedere fino al gate.
