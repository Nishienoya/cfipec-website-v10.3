# Remove the For Workers nav flow and feature JobOrders on the landing page

The change retires the in-site "For Workers" flow in favor of the standalone JOBORDERS platform. The signed-out top nav drops its "For Workers" entry and points the JOBORDERS item at `https://joborders.cfipec.org`; the signed-in profile avatar menu drops its "My Worker Profile" group (profile, CV, certification, career pathway), and the footer's signed-in account column drops the same links. The landing page gains a dedicated JobOrders feature section and its quick-links row is reduced from three cards to two. The worker page HTML files stay on disk, unlinked. Because the menu is centralized in `menu.js`, deleting the "For Workers" MAIN entry propagates to every page without per-page edits, and every external link is consistently given `target="_blank"`, `rel="noopener noreferrer"`, an "(opens in a new tab)" aria-label, and a visually-hidden ↗ cue.

Watch for:
- The recorded verification is stale and contradicts the final code: `_verify_out.txt` reports the new JobOrders landing feature as absent, and the required `verify.txt` was never written. (confirmed)
- The external-link aria-label on the quick-links JOBORDERS card overrides the card's accessible name, dropping its descriptive sentence from what screen readers announce. (confirmed)

**Verdict**: NEEDS_CHANGES

## High-level view

Nav centralization makes the removal consistent. `menu.js` is the single source for the header, footer, and `data-page` link resolution on every page, so deleting the "For Workers" MAIN entry and clearing the worker keys from the profile dropdown and the footer's account column removes the worker flow site-wide without touching each HTML page. The JOBORDERS nav item is now a leaf with no dropdown, pointing at the external platform.

The landing-page JobOrders feature reuses existing design tokens rather than introducing new ones. A new `section--alt` block (`#joborders`) uses the same `about-grid`, `eyebrow`, `section-title`, and `reveal` classes as the About section, with a feature list and the light JOBORDERS logo on a gradient panel. `home.css` adds only vanilla rules for the list bullets, the logo panel, and a two-card quick-links grid with one breakpoint — no framework or build change.

External links are handled from one code path. A small `isExternal`/`extAttrs` pair in `menu.js` stamps `target="_blank" rel="noopener noreferrer"` and an "(opens in a new tab)" aria-label onto any https href, so the nav, footer, and the landing-page buttons all behave the same way and resist tab-nabbing and referrer leakage.

Verification evidence is the gating gap. The task required serve + DOM inspect + grep recorded in `verify.txt`; that file does not exist. The closest artifact, `_verify_out.txt`, was captured mid-implementation — its "present" markers for the new feature all read False while the removal markers correctly read gone — so it does not corroborate the final state, and it contains no DOM-inspect step.

<details>
<summary>Issues (2)</summary>

1. **Stale/invalid verification evidence** — `_verify_out.txt` reports the new JobOrders landing feature as absent (`id="joborders"`, `joborders.cfipec.org`, `cards--2`, `JOBORDERS_logo_light.png`, `const JOBORDERS_URL`, `function isExternal` all False), contradicting the final code; the required `verify.txt` is missing and there is no DOM-inspect step. Re-run serve + DOM inspect + grep against the final files and record valid, passing evidence in `verify.txt`. (blocking, confirmed)
2. **Card aria-label drops its description** — the JOBORDERS quick-link card's `aria-label="JOBORDERS (opens in a new tab)"` overrides the accessible name, so "Learn how to register, get certified, and apply for international employment opportunities." is no longer announced. Drop the aria-label on the card and use a visually-hidden "(opens in a new tab)" span, or fold the description into the aria-label. (non-blocking, confirmed)

</details>

<details>
<summary>Details</summary>

### Nav and profile menu: worker flow retired

The "For Workers" MAIN entry was a conditional spread — `...(!SIGNED_IN ? [{ label: "For Workers", ... }] : [])` — so it only ever appeared for signed-out visitors. Removing the spread entirely takes it out of both states, which matches the intent ("the navigation bar before signing in"). Because every page renders its header from `MAIN.map(navItem)`, this single edit is what makes the removal consistent across all pages; there is no per-HTML nav to drift out of sync. The JOBORDERS entry lost its dropdown (`children: []`), so it is now a direct external link rather than a hub for `browseJobOrders`/`careerPathway`.

The signed-in profile dropdown previously had two groups — "My Worker Profile" (profile, CV, certification, career pathway) and "Account" (details, settings, log out). The worker group, its divider, its `workerKeys`/`workerItems` locals, and the `active`-state check that included worker keys are all gone; the menu now shows only the Account group, and the footer's signed-in account column was mirrored to match. The `PAGES` dictionary still contains the worker/career/myJobOrders entries and their `.html` files, but nothing in `MAIN`, `MORE`, `accountMenu()`, or the footer references those keys anymore, so no link is generated to them from any reachable page. (confirmed)

### Landing-page JobOrders feature

The new `#joborders` section sits between quick-links and About and reuses the About section's exact class scaffold (`section section--alt` + `container about-grid` + `about-text reveal`), so it inherits the existing two-column responsive layout and reveal animation without new grid code. The logo uses the `_light` variant on a dark gradient panel (`.jo-feature-logo`), consistent with the site's convention of light logos on dark backgrounds. `home.css` is the only stylesheet touched, and the additions are plain CSS against existing custom properties (`--color-accent`, `--color-navy`, `--color-primary-dark`, `--color-primary`, `--color-text`) plus an `aspect-ratio: 4/3` panel and a blurred accent blob — no framework, no build step. The quick-links grid gained a `.cards--2` modifier collapsing to one column at 820px, matching the existing responsive breakpoints. (confirmed)

### External link handling and accessibility

`isExternal(u)` / `extAttrs(u)` centralize the new-tab behavior, so the nav link, the footer heading link, and all landing-page buttons get identical `target`/`rel`/`aria-label`/`↗` treatment from one code path rather than per-call duplication that could drift. (confirmed)

The rough edge is the quick-links JOBORDERS card. An `aria-label` is set on a link that wraps an `<h2>` plus a descriptive `<p>`; per ARIA, a present `aria-label` replaces the accessible name derived from the element's contents, so the descriptive sentence — the card's main explanatory text — is dropped from the announcement and replaced with just "JOBORDERS (opens in a new tab)". The original internal card had no `aria-label`, so its accessible name included the full description; this is a small regression in information for screen-reader users on that one card. The short-text links (nav, hero, CTA, feature CTA, footer) are unaffected because they had no description to lose. (confirmed)

### Verification evidence

I confirmed the feature is present by reading `index.html` and `menu.js` directly, so the stale log is not hiding a missing feature — it is simply out of date. But the task gated on recorded verification, and what was recorded does not validate this state. `_verify_out.txt` was produced by `_verify_all.ps1`, which serves the site over an HttpListener and then regex-matches the response bodies; it has no DOM-inspect step, and its output reads False for every affirmative marker of the new feature (`id="joborders"`, `joborders.cfipec.org`, `cards--2`, `JOBORDERS_logo_light.png`, `const JOBORDERS_URL`, `function isExternal`) while correctly reading the removal markers as gone. That pattern — removals present, additions absent — means the log was captured after the deletions but before the JobOrders feature was added, and was never re-run against the final files. The named deliverable, `verify.txt`, does not exist. Until verification is re-run against the final files (serve + DOM inspect + grep) and the passing result is recorded in `verify.txt`, the change is not validated. (confirmed)

### Out of scope: residual links inside the orphaned pages

The check for remaining worker-page hrefs turns up matches, but only inside the worker pages that were deliberately kept on disk and unlinked: `browse-joborders.html` still links to `career-pathway.html` and `worker-certification.html`, `career-pathway.html` links back to `browse-joborders.html`, `my-joborders.html` links to `browse-joborders.html`, `worker-certification.html` carries a `data-page="careerPathway"`, and each gated worker page has a self-referential `?demo=signedin` preview link. None of these pages is reachable from the nav or from any linked page, none was modified by this change, and the task's "nav or linked pages" check therefore passes; these are pre-existing internal links on unlinked pages, out of scope per the review's diff-only rule. They only matter if those pages are ever re-linked, at which point the cross-links would reintroduce the old local flow and should be repointed at the JOBORDERS platform then. (informational, out of scope)

</details>

<details>
<summary>File map</summary>

- `menu.js` — removed the "For Workers" MAIN entry; externalized the JOBORDERS nav item (`JOBORDERS_URL`); dropped the worker group from the signed-in profile dropdown and footer; added `isExternal`/`extAttrs` to stamp new-tab attributes on external hrefs.
- `index.html` — hero and CTA "Learn About JOBORDERS" buttons repointed at the external platform; quick-links reduced to two cards (For Workers card removed, JOBORDERS card externalized); new `#joborders` feature section added with eyebrow, headline, feature list, CTA, and JOBORDERS logo.
- `home.css` — vanilla styles for `.jo-feature-list` (bulleted feature list), `.jo-feature-logo` (gradient logo panel with blurred accent), and `.cards--2` (two-column quick-links with an 820px collapse).
- `country-template.html` — country page CTA "Learn About JOBORDERS" repointed at the external platform.
- `iso-17024.html` — CTA changed from "My Certification" → coming-soon to "Go to JOBORDERS" → external platform.

Worker files kept on disk, unlinked: `worker-profile.html`, `worker-cv.html`, `worker-certification.html`, `career-pathway.html`, `my-joborders.html`, `browse-joborders.html`.

Full diff: `git diff` (unstaged working tree against `HEAD`).

</details>
