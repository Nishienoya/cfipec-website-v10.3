// =========================================================
// menu.js – the ONE place that defines the site menu.
// It builds the header (menu), the footer (sitemap) and the
// links on every page, so you never edit menus page by page.
//
// HOW TO EDIT
//  • Rename a menu item ........ change its "title" in PAGES below
//  • Add / remove a menu item .. edit the MAIN / MORE lists below
//  • A page you have built ..... set its  file: "your-page.html"
//    (file: null shows the "Coming soon" page instead)
//  • Hide Sign up / Login ....... set SHOW_ACCOUNT = false
//  • Preview signed-in menus .... add  ?demo=signedin  to any page address
//                                 (and ?demo=signedout to go back).
//                                 Prototype only: once real login exists,
//                                 replace readSignedIn() below with the real check.
//  • Logo ....................... see LOGO_HTML below (dark and light versions)
// =========================================================
(function () {
  "use strict";

  // ---------- Settings ----------
  const SHOW_ACCOUNT = true; // false = removes Sign up / Login from header and footer

  // Signed-in state. PROTOTYPE: a demo flag kept for this browser tab only.
  // Swap this function for the real session check when the backend exists.
  function readSignedIn() {
    try {
      const demo = new URLSearchParams(location.search).get("demo");
      if (demo === "signedin") sessionStorage.setItem("ipec-demo-signed-in", "1");
      if (demo === "signedout") sessionStorage.removeItem("ipec-demo-signed-in");
      return sessionStorage.getItem("ipec-demo-signed-in") === "1";
    } catch (e) { return false; }   // storage blocked → treat as signed out
  }
  const SIGNED_IN = readSignedIn();
  // lets any page show/hide parts with  data-only="in"  or  data-only="out"  (see layout.css)
  document.documentElement.classList.add(SIGNED_IN ? "is-signed-in" : "is-signed-out");

  // Two versions of the logo: dark lettering for light backgrounds, light lettering for dark ones (layout.css picks which to show)
  const LOGO_HTML =
    '<img class="logo-dark" src="assets/images/CFIPEC_GLOBAL_logo.png" alt="CFIPEC Global" width="72" height="64">' +
    '<img class="logo-light" src="assets/images/CFIPEC_GLOBAL_logo_light.png" alt="" width="75" height="64">';

  const SITE_NAME = "CFIPEC Global";

  // External JOBORDERS platform — workers manage certification, CV, profile and job orders there.
  // Placeholder URL: swap for the real address once the platform is live.
  const JOBORDERS_URL = "https://joborders.cfipec.org";

  // ---------- Every page on the site ----------
  // file: null  → opens "Coming soon" (coming-soon.html) until you build the page
  const PAGES = {
    // Home (these are sections on the Home page)
    home:                { title: "Home",                  file: "index.html" },
    about:               { title: "About",                 file: "index.html#about" },
    visionMission:       { title: "Vision & Mission",      file: "index.html#vision-mission" },
    howItWorks:          { title: "How It Works",          file: "index.html#how-it-works" },
    values:              { title: "Our Values",            file: "index.html#values" },

    // JOBORDERS
    browseJobOrders:     { title: "JOBORDERS",             file: JOBORDERS_URL },
    myJobOrders:         { title: "My JOBORDERS",          file: "my-joborders.html" },

    // Country Partners
    globalNetwork:       { title: "Global Network",        file: "global-network.html" },
    countryPages:        { title: "Country Pages",         file: "country-pages.html" },

    // For Workers
    workerProfile:       { title: "My Profile",               file: "worker-profile.html" },
    workerCv:            { title: "My CV",                    file: "worker-cv.html" },
    workerCertification: { title: "My Certification",         file: "worker-certification.html" },
    careerPathway:       { title: "Career Pathway",        file: "career-pathway.html" },

    // For Partners
    recruitmentAgencies: { title: "Recruitment Agencies",  file: "recruitment-agencies.html" },
    countryPartnerInfo:  { title: "Become a Country Partner",      file: "country-partner-info.html" },
    partnerApplication:  { title: "Partner Application",   file: "partner-application.html" },

    // Certification
    ipecBureau:          { title: "IPEC Bureau",           file: "ipec-bureau.html" },
    iso17024:            { title: "ISO/IEC 17024 Pathway", file: "iso-17024.html" },

    // News & Insights
    news:                { title: "News & Insights",       file: "news.html" },

    // Support
    help:                { title: "Help",                  file: "help.html" },
    contact:             { title: "Contact",               file: "contact.html" },
    ticket:              { title: "Submit a Ticket",       file: "ticket.html" },

    // Account
    signUp:              { title: "Sign Up",               file: "sign-up.html" },
    login:               { title: "Login",                 file: "login.html" },
    accountProfile:      { title: "Account Details",               file: "account-details.html" },
    accountSettings:     { title: "Settings",              file: "account-settings.html" },

    // Legal
    privacy:             { title: "Privacy Policy",        file: "privacy.html" },
    terms:               { title: "Terms of Use",          file: "terms.html" }
  };

  // ---------- The menu ----------
  // label = text shown, to = page opened when the label is clicked, children = dropdown items
  // "For Workers" moved to the JOBORDERS platform; worker pages are unlinked but kept on disk.
  const MAIN = [
    { label: "Home",             to: "home",            children: ["about", "visionMission", "howItWorks", "values"] },
    { label: "JOBORDERS",        to: "browseJobOrders", children: [] },
    { label: "Country Partners", to: "globalNetwork",   children: ["globalNetwork", "countryPages"] },
    { label: "For Partners",     to: "recruitmentAgencies", children: ["recruitmentAgencies", "countryPartnerInfo", "partnerApplication"] }
  ];

  // Items inside the "More" menu
  const MORE = [
    { label: "Certification",   to: "ipecBureau", children: ["ipecBureau", "iso17024"] },
    { label: "News & Insights", to: "news",       children: [] },
    { label: "Support",         to: "help",       children: ["help", "contact", "ticket"] },
    { label: "Legal",           to: "privacy",    children: ["privacy", "terms"] }
  ];

  // ---------- Helpers ----------
  function esc(s) {
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
  }

  function isExternal(u) { return /^https?:\/\//i.test(String(u)); }
  function extAttrs(u) { return isExternal(u) ? ' target="_blank" rel="noopener noreferrer"' : ""; }

  function url(key) {
    const p = PAGES[key];
    if (!p) return "coming-soon.html";
    return p.file || "coming-soon.html?page=" + encodeURIComponent(p.title);
  }

  function link(key, cls) {
    return '<a href="' + url(key) + '"' + (cls ? ' class="' + cls + '"' : "") + ">" + esc(PAGES[key].title) + "</a>";
  }

  // Which page file are we on?  (used to highlight the current menu item)
  const here = (location.pathname.split("/").pop() || "index.html").toLowerCase();
  function fileOf(key) {
    const f = PAGES[key] && PAGES[key].file;
    return f ? f.split("#")[0].toLowerCase() : null;
  }
  function isHere(item) {
    // a page can also claim a menu section with  <body data-section="globalNetwork">
    const claimed = document.body && document.body.getAttribute("data-section") === item.to;
    return claimed || [item.to].concat(item.children || []).some((k) => fileOf(k) === here);
  }

  // ---------- Header ----------
  function navItem(item) {
    const active = isHere(item);
    const href = url(item.to);
    const ext = isExternal(href);
    const cue = ext ? ' <span aria-hidden="true">↗</span>' : "";
    const aria = ext ? ' aria-label="' + esc(item.label) + ' (opens in a new tab)"' : "";
    const label = '<a class="nav-link' + (active ? " active" : "") + '"' + aria + ' href="' + href + '"' +
      (active ? ' aria-current="page"' : "") + extAttrs(href) + ">" + esc(item.label) + cue + "</a>";
    if (!item.children.length) return "<li>" + label + "</li>";
    // The little arrow button is only shown in the phone/tablet menu (layout.css),
    // where there is no hover. On desktop the dropdown opens on hover or keyboard focus.
    return '<li class="has-sub">' + label +
      '<button class="sub-toggle" type="button" aria-expanded="false" aria-label="Show ' + esc(item.label) + ' submenu"></button>' +
      '<ul class="submenu">' + item.children.map((k) => "<li>" + link(k) + "</li>").join("") + "</ul></li>";
  }

  function moreItem() {
    const groups = MORE.map((g) => {
      const head = '<a class="mega-title" href="' + url(g.to) + '">' + esc(g.label) + "</a>";
      const kids = g.children.length
        ? "<ul>" + g.children.map((k) => "<li>" + link(k) + "</li>").join("") + "</ul>"
        : "";
      return '<div class="mega-group">' + head + kids + "</div>";
    }).join("");
    const active = MORE.some(isHere);
    return '<li class="has-sub has-mega">' +
      '<button class="nav-link nav-more' + (active ? " active" : "") + '" type="button" aria-expanded="false">More</button>' +
      '<div class="submenu mega">' + groups + "</div></li>";
  }

  // Signed out: Login + Sign Up buttons (desktop bar). Signed in: handled by accountMenu().
  function accountButtons() {
    if (!SHOW_ACCOUNT || SIGNED_IN) return "";
    return '<div class="nav-account">' +
      '<a class="btn btn-outline btn-sm" href="' + url("login") + '">' + esc(PAGES.login.title) + "</a>" +
      '<a class="btn btn-primary btn-sm" href="' + url("signUp") + '">' + esc(PAGES.signUp.title) + "</a>" +
      "</div>";
  }

  // Signed in: a profile-avatar dropdown at the end of the menu
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

  function renderHeader() {
    const host = document.querySelector("[data-site-header]");
    if (!host) return;
    host.innerHTML =
      '<a class="skip-link" href="#main">Skip to content</a>' +
      '<div class="container header-inner">' +
        '<a href="index.html" class="brand" aria-label="' + esc(SITE_NAME) + ' home">' + LOGO_HTML + "</a>" +
        '<button class="nav-toggle" aria-label="Toggle menu" aria-expanded="false" aria-controls="main-nav">' +
          "<span></span><span></span><span></span></button>" +
        '<nav id="main-nav" class="site-nav" aria-label="Main">' +
          '<ul class="nav-list">' + MAIN.map(navItem).join("") + moreItem() + accountMenu() + "</ul>" +
          accountButtons() +
        "</nav>" +
      "</div>";
    wireMenu(host);
  }

  // ---------- Dropdown behaviour ----------
  function wireMenu(host) {
    const nav = host.querySelector("#main-nav");
    const toggle = host.querySelector(".nav-toggle");

    function closeAll(except) {
      nav.querySelectorAll(".has-sub.open-sub").forEach((li) => {
        if (li === except) return;
        li.classList.remove("open-sub");
        const b = li.querySelector(":scope > button");
        if (b) b.setAttribute("aria-expanded", "false");
      });
    }

    nav.addEventListener("click", (e) => {
      const btn = e.target.closest("li.has-sub > button");
      if (btn) {
        const li = btn.parentElement;
        const open = !li.classList.contains("open-sub");
        closeAll(li);
        li.classList.toggle("open-sub", open);
        btn.setAttribute("aria-expanded", String(open));
        return;
      }
      if (e.target.closest("a")) {
        // follow the link: tidy up (also closes the phone menu for in-page links)
        closeAll();
        nav.classList.remove("open");
        toggle.setAttribute("aria-expanded", "false");
      }
    });

    document.addEventListener("click", (e) => { if (!e.target.closest(".site-nav")) closeAll(); });
    document.addEventListener("keydown", (e) => {
      if (e.key !== "Escape") return;
      const active = document.activeElement;
      const li = active && active.closest ? active.closest(".has-sub") : null;
      closeAll();
      if (li && nav.contains(li)) {
        // keep focus on the menu item but hide its panel until the pointer/focus leaves
        li.classList.add("dismissed");
        const top = li.querySelector(":scope > .nav-link");
        if (top) top.focus();
        const clear = () => {
          li.classList.remove("dismissed");
          li.removeEventListener("mouseleave", clear);
          li.removeEventListener("focusout", clear);
        };
        li.addEventListener("mouseleave", clear);
        li.addEventListener("focusout", clear);
      }
    });
  }

  // ---------- Footer ----------
  function renderFooter() {
    const host = document.querySelector("[data-site-footer]");
    if (!host) return;

    const groups = MAIN.concat(MORE.filter((g) => g.label !== "Legal"));
    const cols = groups.map((g) => {
      if (!g.children.length) {
        const h = url(g.to);
        const ext = isExternal(h);
        const cue = ext ? ' <span aria-hidden="true">↗</span>' : "";
        const aria = ext ? ' aria-label="' + esc(g.label) + ' (opens in a new tab)"' : "";
        return '<div class="footer-col"><h3><a href="' + h + '"' + aria + extAttrs(h) + ">" + esc(g.label) + cue + "</a></h3></div>";
      }
      return '<div class="footer-col"><h3>' + esc(g.label) + "</h3><ul>" +
        g.children.map((k) => "<li>" + link(k) + "</li>").join("") + "</ul></div>";
    });
    if (SHOW_ACCOUNT) {
      const items = SIGNED_IN
        ? "<li>" + link("accountProfile") + "</li><li>" + link("accountSettings") + '</li><li><a href="index.html" data-logout>Log out</a></li>'
        : "<li>" + link("signUp") + "</li><li>" + link("login") + "</li>";
      cols.push('<div class="footer-col"><h3>Account</h3><ul>' + items + "</ul></div>");
    }

    host.innerHTML =
      '<div class="container footer-top">' +
        '<div class="footer-brand"><img class="footer-logo" src="assets/images/CFIPEC_GLOBAL_logo_light.png" alt="' + esc(SITE_NAME) + '" width="94" height="80">' +
        '<address class="footer-address">' +
          '91-3 Amber Business Plaza 1,<br>' +
          'Jalan Jelawat 1,<br>' +
          '56000 Kuala Lumpur, Malaysia.<br>' +
          '<a href="mailto:cfipec2020@gmail.com">cfipec2020@gmail.com</a>' +
        '</address>' +
      "</div>" +
        '<div class="footer-cols">' + cols.join("") + "</div>" +
      "</div>" +
      '<div class="footer-bottom"><div class="container footer-inner">' +
        "<p>&copy; " + new Date().getFullYear() + " " + esc(SITE_NAME) + ". All rights reserved.</p>" +
        '<p class="footer-legal">' + link("privacy") + link("terms") + "</p>" +
      "</div></div>";
  }

  // ---------- Run ----------
  renderHeader(); // runs immediately so the menu appears with the page

  function onReady() {
    renderFooter();
    // Any link written as <a data-page="browseJobOrders"> gets its address from PAGES above
    document.querySelectorAll("[data-page]").forEach((a) => a.setAttribute("href", url(a.getAttribute("data-page"))));
  }
  // Log out (prototype): forget the demo flag, then the link carries on to the Home page
  document.addEventListener("click", (e) => {
    if (e.target.closest("[data-logout]")) { try { sessionStorage.removeItem("ipec-demo-signed-in"); } catch (err) {} }
  });

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", onReady);
  else onReady();
})();
