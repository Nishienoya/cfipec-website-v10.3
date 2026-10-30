# Implementation Plan — Remove "For Workers" flow, feature JobOrders on the landing page

Target site (all files live here): `c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website`
Git repo root (for git only): `c:/WEBDEV/cfipec-website-v10.3`
Environment: Windows / PowerShell. This is a **static site — plain HTML/CSS/JS, NO build step, NO test framework, NO framework**. Verification is browser smoke-testing plus a PowerShell regression grep (there is no `npm`/build/test command to run).

Placeholder JobOrders URL used everywhere: `https://joborders.cfipec.org` (to be swapped later).

---

## Key finding from exploration: the nav source of truth is `menu.js`

`menu.js` is the **single** file that builds the header (main nav), the footer (sitemap), and resolves every `<a data-page="...">` link on every page. All HTML pages only contain empty `<header data-site-header>` / `<footer data-site-footer>` hosts plus `<script src="menu.js"></script>`. There is **no per-HTML nav duplication**. Therefore all nav / footer / signed-in-profile changes happen in `menu.js` only.

Relevant facts confirmed by reading the code:
- Pre-sign-in nav `MAIN` array includes a conditional `For Workers` item (shown only when `!SIGNED_IN`) and a `JOBORDERS` item whose dropdown points to `browseJobOrders` + `careerPathway` (both files that must be unlinked).
- `accountMenu()` (signed-in profile dropdown) renders a "My Worker Profile" section from `workerKeys = ["workerProfile","workerCv","workerCertification","careerPathway"]` plus an "Account" section (`accountProfile`, `accountSettings`, Log out).
- `renderFooter()` builds columns from `MAIN` + `MORE`, and a signed-in "Account" footer column that also lists the four worker links.
- `PAGES.browseJobOrders.file = "browse-joborders.html"`, so the `JOBORDERS` nav/footer entry currently links internally to a page that must be unlinked.
- Reachable pages with hardcoded worker-page links (found by grepping every HTML file): `index.html`, `iso-17024.html`, `country-template.html`. Every other reachable page has none. The six worker page files (`worker-certification.html`, `worker-cv.html`, `worker-profile.html`, `career-pathway.html`, `my-joborders.html`, `browse-joborders.html`) are kept on disk and left as-is.

---

## Design decisions (rationale)

1. **All nav/footer/profile edits go in `menu.js`.** It is the single source of truth; HTML files have no nav markup to edit. Confirmed by reading `menu.js`, `script.js`, and several page files.

2. **Repoint the `JOBORDERS` nav item to the external `https://joborders.cfipec.org` and remove its dropdown** (rather than delete the item). Requirement 4 forces removing all internal links to `browse-joborders.html`; requirement 1 only asks to remove "For Workers", so keeping the `JOBORDERS` item is compliant and preserves a sitewide JobOrders entry point (consistent with "the site routes workers to JobOrders"). Rejected alternative: delete the item entirely (removes more than the user asked).

3. **Remove "For Workers" from `MAIN`.** Requirement 1. This also removes the signed-out footer "For Workers" column automatically, since the footer is derived from `MAIN`.

4. **Signed-in profile menu: remove the entire "My Worker Profile" section** (`workerKeys`), leaving only Account Details / Settings / Log out. Requirement 2. No JobOrders link is added to the profile menu — the (always-visible) `JOBORDERS` external nav item already gives signed-in users a route to JobOrders, so adding one would be unrequested scope.

5. **Signed-in footer "Account" column: remove the four worker links.** Requirement 4 (footer must not link to worker pages). Keep Account Details / Settings / Log out.

6. **Homepage quick-links: remove only the "For Workers" card** (requirement 1, minimal change). Keep the "JOBORDERS" card and the "For Partners" card, and switch the row to a balanced 2-column grid via a new `cards--2` modifier (keeps the existing card the user may expect; no new content invented).

7. **Add one prominent JobOrders feature section to `index.html`** (requirement 3), placed high on the page (right after the quick-links). It reuses the existing `.about-grid` two-column layout + design tokens, with a new dark-gradient logo tile showing `JOBORDERS_logo_light.png`, a bullet list of what workers do in JobOrders (profile/CV, certification & career pathway, browse & apply to job orders), and a "Go to JOBORDERS ↗" external CTA. New CSS goes in `home.css` (already loaded by `index.html`) — **no new CSS file, no framework**.

8. **Repoint reachable pages' hardcoded worker CTAs to the external JobOrders URL** (`index.html`, `iso-17024.html`, `country-template.html`). The six unlinked worker page files stay on disk untouched, internal cross-links preserved, per "keep the page in the file but remain unlinked just in case."

9. **External links use `target="_blank" rel="noopener noreferrer"`, a visible `↗` cue** (already an in-site convention in `browse-joborders.html`'s "Open JOBORDERS Platform ↗"), and an `aria-label="… (opens in a new tab)"` for accessibility. JobOrders logo gets `alt="JOBORDERS logo"`.

---

## Files to change (summary)

| File | Change |
|------|--------|
| `menu.js` | Repoint JOBORDERS nav/footer to external; remove For Workers nav; remove dropdown; remove worker section from profile menu & footer; add external-link helpers |
| `index.html` | Repoint hero/quick-link/CTA JOBORDERS links external; remove For Workers card; add `cards--2`; insert JobOrders feature section |
| `home.css` | Add `.jo-feature-list`, `.jo-feature-logo` styles + `.cards--2` grid (with mobile override) |
| `iso-17024.html` | Repoint "My Certification" CTA to external JobOrders |
| `country-template.html` | Repoint "Learn About JOBORDERS" CTA to external JobOrders |

Files intentionally **NOT changed**: every other reachable page (`account-details.html`, `account-settings.html`, `coming-soon.html`, `contact.html`, `country-pages.html`, `country-partner-info.html`, `global-network.html`, `help.html`, `ipec-bureau.html`, `login.html`, `news.html`, `partner-application.html`, `privacy.html`, `recruitment-agencies.html`, `sign-up.html`, `terms.html`, `ticket.html`) — verified to contain no worker-page links; all CSS except `home.css` (`styles.css`, `layout.css`, `hero.css`, `pages.css`, `joborders.css`); and the six unlinked worker page files (kept on disk as-is).

---

## Implementation items (ordered by dependency)

- [ ] 1. **Edit `menu.js` — nav, footer, and signed-in profile menu (the source of truth).**
  Files: `c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website/menu.js`
  Exact changes:

  a) Add a constant for the external JobOrders URL (place it just above the `const PAGES = {` block, after `SITE_NAME`):
  ```js
  // External JOBORDERS platform — workers manage certification, CV, profile and job orders there.
  // Placeholder URL: swap for the real address once the platform is live.
  const JOBORDERS_URL = "https://joborders.cfipec.org";
  ```

  b) In `PAGES`, repoint `browseJobOrders` to the external URL:
  ```js
  browseJobOrders:     { title: "JOBORDERS",             file: JOBORDERS_URL },
  ```

  c) Replace the `MAIN` array (removes the `For Workers` item and the `JOBORDERS` dropdown):
  ```js
  const MAIN = [
    { label: "Home",             to: "home",            children: ["about", "visionMission", "howItWorks", "values"] },
    { label: "JOBORDERS",        to: "browseJobOrders", children: [] },
    { label: "Country Partners", to: "globalNetwork",   children: ["globalNetwork", "countryPages"] },
    { label: "For Partners",     to: "recruitmentAgencies", children: ["recruitmentAgencies", "countryPartnerInfo", "partnerApplication"] }
  ];
  ```
  Also delete the now-inaccurate comment line above `MAIN` that reads `// "For Workers" is hidden after login – those pages live in the profile avatar dropdown instead.` (replace it with: `// "For Workers" moved to the JOBORDERS platform; worker pages are unlinked but kept on disk.`).

  d) Add two external-link helpers near the other helpers (e.g. just after `function esc(s) {...}`):
  ```js
  function isExternal(u) { return /^https?:\/\//i.test(String(u)); }
  function extAttrs(u) { return isExternal(u) ? ' target="_blank" rel="noopener noreferrer"' : ""; }
  ```

  e) Update `navItem()` so the top-level link is external-aware (the `JOBORDERS` item now has `children: []`, so this is the branch it hits):
  ```js
  function navItem(item) {
    const active = isHere(item);
    const href = url(item.to);
    const ext = isExternal(href);
    const cue = ext ? ' <span aria-hidden="true">↗</span>' : "";
    const aria = ext ? ' aria-label="' + esc(item.label) + ' (opens in a new tab)"' : "";
    const label = '<a class="nav-link' + (active ? " active" : "") + '"' + aria + ' href="' + href + '"' +
      (active ? ' aria-current="page"' : "") + extAttrs(href) + ">" + esc(item.label) + cue + "</a>";
    if (!item.children.length) return "<li>" + label + "</li>";
  // … rest unchanged
  ```

  f) Update `renderFooter()` so a no-children group's heading link is external-aware, and remove worker links from the signed-in Account column. The no-children branch becomes:
  ```js
      if (!g.children.length) {
        const h = url(g.to);
        const ext = isExternal(h);
        const cue = ext ? ' <span aria-hidden="true">↗</span>' : "";
        const aria = ext ? ' aria-label="' + esc(g.label) + ' (opens in a new tab)"' : "";
        return '<div class="footer-col"><h3><a href="' + h + '"' + aria + extAttrs(h) + ">" + esc(g.label) + cue + "</a></h3></div>";
      }
  ```
  The signed-in "Account" footer column becomes (worker links removed):
  ```js
      const items = SIGNED_IN
        ? "<li>" + link("accountProfile") + "</li><li>" + link("accountSettings") + '</li><li><a href="index.html" data-logout>Log out</a></li>'
        : "<li>" + link("signUp") + "</li><li>" + link("login") + "</li>";
  ```

  g) Replace `accountMenu()` to remove the "My Worker Profile" section entirely (keep the avatar, the "Account" section, and Log out):
  ```js
  function accountMenu() {
    if (!SHOW_ACCOUNT || !SIGNED_IN) return "";
    const accountKeys = ["accountProfile", "accountSettings"];
    const active = accountKeys.some((k) => fileOf(k) === here);

    const avatarSvg =
      '<svg class="avatar-icon" viewBox="0 0 36 36" aria-hidden="true" focusable="false">' +
        '<circle cx="18" cy="18" r="18" fill="var(--color-primary)"/>' +
        '<circle cx="18" cy="14" r="6" fill="#fff"/>' +
        '<path d="M6 32c0-6.627 5.373-12 12-12s12 5.373 12 12" fill="#fff"/>' +
      '</svg>';

    const accountItems = accountKeys.map((k) => "<li>" + link(k) + "</li>").join("");

    return '<li class="has-sub has-account">' +
      '<button class="nav-avatar' + (active ? " active" : "") + '" type="button" aria-expanded="false" aria-label="My account menu">' +
        avatarSvg +
      "</button>" +
      '<div class="submenu submenu--right profile-menu">' +
        '<p class="profile-menu__section-label">Account</p>' +
        '<ul>' + accountItems + '<li><a href="index.html" data-logout>Log out</a></li></ul>' +
      '</div>' +
    '</li>';
  }
  ```
  Leave the `link()` helper and the `data-page` resolver in `onReady()` untouched.

  Verify: open `index.html` (signed-out) in a browser — the nav shows Home / JOBORDERS / Country Partners / For Partners / More and **no "For Workers"**; the `JOBORDERS` item links to `https://joborders.cfipec.org` and opens a new tab. Then open `index.html?demo=signedin` — the avatar dropdown shows only "Account Details / Settings / Log out" (no "My Worker Profile" section), and the footer "Account" column shows the same three items (no worker links). The footer "JOBORDERS" heading links externally.

- [ ] 2. **Add the JobOrders feature CSS and the 2-card quick-links grid to `home.css`.**
  Files: `c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website/home.css`
  Append (at the end of the file, after the existing responsive block) — reuses `:root` tokens from `styles.css` and the visual language of `.media-frame`/`.about-grid`:
  ```css
  /* ---------- JobOrders feature (landing page) ---------- */
  .jo-feature-list { margin: 0 0 28px; padding: 0; display: grid; gap: 12px; }
  .jo-feature-list li { position: relative; padding-left: 30px; color: var(--color-text); }
  .jo-feature-list li::before {
    content: "";
    position: absolute; left: 0; top: 8px;
    width: 14px; height: 14px; border-radius: 50%;
    background: var(--color-accent);
    box-shadow: 0 0 0 4px rgba(0, 173, 239, 0.16);
  }
  .jo-feature-logo {
    position: relative;
    aspect-ratio: 4 / 3;
    border-radius: 22px;
    display: grid;
    place-items: center;
    padding: 48px;
    background: linear-gradient(135deg, var(--color-navy) 0%, var(--color-primary-dark) 55%, var(--color-primary) 100%);
    box-shadow: 0 24px 60px rgba(20, 40, 80, 0.22);
    overflow: hidden;
  }
  .jo-feature-logo img { max-width: 72%; max-height: 62%; width: auto; height: auto; object-fit: contain; }
  .jo-feature-logo::after {
    content: "";
    position: absolute;
    width: 280px; height: 280px;
    right: -60px; bottom: -60px;
    border-radius: 50%;
    background: var(--color-accent);
    opacity: 0.30;
    filter: blur(60px);
  }

  /* Quick-links: two-card layout (For Workers card removed) */
  .cards--2 { grid-template-columns: repeat(2, 1fr); }
  @media (max-width: 820px) { .cards--2 { grid-template-columns: 1fr; } }
  @media (max-width: 980px) { .jo-feature-logo { padding: 32px; } }
  ```
  Verify: nothing visible yet (CSS is consumed by index.html in the next step). Confirm `home.css` has no syntax errors by opening any page that loads it (e.g. `country-template.html`) — it still renders normally.

- [ ] 3. **Edit `index.html` — repoint JOBORDERS links, remove the For Workers card, and insert the JobOrders feature section.**
  Files: `c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website/index.html`
  Exact changes:

  a) Hero "Learn About JOBORDERS" button (line ~47) → external:
  ```html
  <a href="https://joborders.cfipec.org" class="btn btn-ghost" target="_blank" rel="noopener noreferrer" aria-label="Learn About JOBORDERS (opens in a new tab)">Learn About JOBORDERS <span aria-hidden="true">↗</span></a>
  ```

  b) Quick-links: change the container to `cards cards--2`, remove the entire "For Workers" card, and repoint the "JOBORDERS" card to external. The section becomes:
  ```html
    <section class="quick-links" id="explore">
      <div class="container cards cards--2">
        <a class="card reveal" style="--d: 0ms" href="https://joborders.cfipec.org" target="_blank" rel="noopener noreferrer" aria-label="JOBORDERS (opens in a new tab)">
          <h2>JOBORDERS <span aria-hidden="true">↗</span></h2>
          <p>Learn how to register, get certified, and apply for international employment opportunities.</p>
        </a>
        <a class="card reveal" style="--d: 240ms" href="coming-soon.html" data-page="recruitmentAgencies">
          <h2>For Partners</h2>
          <p>Recruitment agencies and country partners: join the network.</p>
        </a>
      </div>
    </section>
  ```
  (The middle "For Workers" card with `data-page="workerProfile"` is deleted; "For Partners" stays unchanged.)

  c) Insert the JobOrders feature section **immediately after** the `</section>` that closes the quick-links and **before** `<section class="section" id="about">`:
  ```html
    <!-- ===== JobOrders feature ===== -->
    <section class="section section--alt" id="joborders">
      <div class="container about-grid">
        <div class="about-text reveal">
          <p class="eyebrow" style="color: var(--color-primary)">JOBORDERS</p>
          <h2 class="section-title">The worker platform for certification, CV &amp; job orders</h2>
          <p>
            <em>JOBORDERS</em> is CFIPEC Global's dedicated platform where workers manage their entire
            journey &mdash; from building a profile and CV, to tracking certification and a career pathway,
            to browsing and applying to verified international job orders.
          </p>
          <ul class="jo-feature-list">
            <li>Build and manage your worker profile and CV</li>
            <li>Track certification and your career pathway</li>
            <li>Browse and apply to verified international job orders</li>
          </ul>
          <a class="btn btn-primary" href="https://joborders.cfipec.org" target="_blank" rel="noopener noreferrer" aria-label="Go to JOBORDERS (opens in a new tab)">Go to JOBORDERS <span aria-hidden="true">↗</span></a>
        </div>
        <div class="reveal" style="--d: 150ms">
          <div class="jo-feature-logo">
            <img src="assets/images/JOBORDERS_logo_light.png" alt="JOBORDERS logo" />
          </div>
        </div>
      </div>
    </section>
  ```

  d) CTA band "Learn About JOBORDERS" button (line ~206) → external:
  ```html
  <a class="btn btn-primary" href="https://joborders.cfipec.org" target="_blank" rel="noopener noreferrer" aria-label="Learn About JOBORDERS (opens in a new tab)">Learn About JOBORDERS <span aria-hidden="true">↗</span></a>
  ```
  (The "Become a Partner" button beside it stays unchanged.)

  Verify: open `index.html` in a browser. Confirm: the JobOrders feature section renders with the light logo on a dark gradient tile, a 3-item bullet list, and a "Go to JOBORDERS ↗" button that opens `https://joborders.cfipec.org` in a new tab; the quick-links row shows exactly 2 cards (JOBORDERS, For Partners) side by side on desktop and stacked on narrow widths; the hero and CTA "Learn About JOBORDERS" buttons open the external URL in a new tab.

- [ ] 4. **Edit `iso-17024.html` — repoint the "My Certification" CTA to JobOrders.**
  Files: `c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website/iso-17024.html`
  Change the CTA actions (line ~79) from:
  ```html
  <div class="cta-actions"><a class="btn btn-primary" href="coming-soon.html" data-page="workerCertification">My Certification</a><a class="btn btn-ghost" href="coming-soon.html" data-page="ipecBureau">About the IPEC Bureau</a></div>
  ```
  to:
  ```html
  <div class="cta-actions"><a class="btn btn-primary" href="https://joborders.cfipec.org" target="_blank" rel="noopener noreferrer" aria-label="Go to JOBORDERS (opens in a new tab)">Go to JOBORDERS <span aria-hidden="true">↗</span></a><a class="btn btn-ghost" href="coming-soon.html" data-page="ipecBureau">About the IPEC Bureau</a></div>
  ```
  (Removes the `data-page="workerCertification"` link to `worker-certification.html`; "About the IPEC Bureau" stays.)
  Verify: open `iso-17024.html`; the CTA's first button is "Go to JOBORDERS ↗" opening the external URL; "About the IPEC Bureau" still works.

- [ ] 5. **Edit `country-template.html` — repoint the "Learn About JOBORDERS" CTA to JobOrders.**
  Files: `c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website/country-template.html`
  Change the CTA actions (line ~72) from:
  ```html
  <div class="cta-actions"><a class="btn btn-primary" href="browse-joborders.html">Learn About JOBORDERS</a><a class="btn btn-ghost" href="country-pages.html">Back to Country Pages</a></div>
  ```
  to:
  ```html
  <div class="cta-actions"><a class="btn btn-primary" href="https://joborders.cfipec.org" target="_blank" rel="noopener noreferrer" aria-label="Learn About JOBORDERS (opens in a new tab)">Learn About JOBORDERS <span aria-hidden="true">↗</span></a><a class="btn btn-ghost" href="country-pages.html">Back to Country Pages</a></div>
  ```
  ("Back to Country Pages" stays.)
  Verify: open `country-pages.html`, click a country card to reach `country-template.html`; the CTA's first button opens the external JobOrders URL; "Back to Country Pages" still works.

---

## Final verification (after all 5 items)

This static site has no build/test command. Do both checks:

1. **Functional smoke test (browser):**
   - Open `index.html`: nav has no "For Workers"; "JOBORDERS" nav item opens `https://joborders.cfipec.org` in a new tab; the JobOrders feature section is visible with the logo and external CTA; quick-links shows 2 cards.
   - Open `index.html?demo=signedin`: the avatar dropdown lists only Account Details / Settings / Log out (no "My Worker Profile"); the footer "Account" column lists the same three (no worker links); the footer "JOBORDERS" heading links externally.
   - Open `iso-17024.html` and `country-template.html` (via `country-pages.html`): their JOBORDERS CTAs open the external URL.

2. **Regression grep (PowerShell) — confirms no reachable page still links to the six worker pages, and `menu.js` has no For Workers nav / worker profile section:**
   ```powershell
   $site = "c:/WEBDEV/cfipec-website-v10.3/cfipec-website-v10.3/cfipec-website"
   $workerPages = @('worker-certification.html','worker-cv.html','worker-profile.html','career-pathway.html','my-joborders.html','browse-joborders.html')
   "Reachable HTML still linking to worker pages (expect none):"
   Get-ChildItem $site -Filter *.html | Where-Object { $workerPages -notcontains $_.Name } |
     Select-String -Pattern ($workerPages -join '|') | Select-Object FileName, LineNumber, Line
   "menu.js For Workers / workerKeys references (expect none):"
   Select-String -Path "$site/menu.js" -Pattern 'For Workers','workerKeys','workerItems'
   ```
   Expected: both sections print nothing (no matches). The six worker page files themselves are excluded from the first check (they remain on disk, untouched, by design).

---

## Notes / gaps resolved by assumption

- **"For Workers" nav scope:** Only the pre-sign-in "For Workers" nav item is removed (req 1). The existing `JOBORDERS` nav item is repointed externally rather than deleted, because req 4 requires removing its internal link to `browse-joborders.html` and req 1 does not ask to remove `JOBORDERS`. If the product later prefers no JOBORDERS nav item at all, remove that one `MAIN` entry — but that is not what the user asked.
- **Profile menu:** Only worker buttons are removed (req 2); no JobOrders link is added there (the nav `JOBORDERS` external link already covers signed-in users). Adding one would be unrequested scope.
- **Unlinked worker files:** `browse-joborders.html`, `my-joborders.html`, `worker-certification.html`, `worker-cv.html`, `worker-profile.html`, `career-pathway.html` stay on disk with their internal cross-links intact (unreachable, "just in case"). They are intentionally not edited.
- **External link styling:** No new CSS framework. The `↗` cue is plain inline text (an existing in-site convention); external `target`/`rel`/`aria-label` are attributes only. The only new CSS is the homepage JobOrders feature + `cards--2`, added to the already-loaded `home.css`.
