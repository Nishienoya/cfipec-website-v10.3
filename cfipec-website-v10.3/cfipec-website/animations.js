// =========================================================
// animations.js – scroll animations (works on any page)
//  1. Elements with class "reveal" fade up as they scroll into view
//  2. The glass header gets more solid after scrolling
//  3. The hero background drifts slower than the page, and the hero
//     text fades out as you scroll down (the hero "melts" into the page)
// =========================================================
(function () {
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // ---- 1. Reveal on scroll ----
  const items = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window && !reduceMotion) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          const el = entry.target;
          el.classList.add("is-visible");
          observer.unobserve(el);
          // When the fade is done, hand the element back to its normal styles
          // (so hover effects on cards stay quick and responsive)
          el.addEventListener("transitionend", function done(e) {
            if (e.propertyName !== "opacity") return;
            el.classList.remove("reveal", "is-visible");
            el.removeEventListener("transitionend", done);
          });
        });
      },
      { threshold: 0.15, rootMargin: "0px 0px -40px 0px" }
    );
    items.forEach((el) => observer.observe(el));
  } else {
    items.forEach((el) => el.classList.add("is-visible"));
  }

  // ---- 2 & 3. Header + hero scroll effects ----
  const header = document.querySelector(".site-header--glass");
  const hero = document.querySelector(".hero--media");
  const media = hero && hero.querySelector(".hero-media");
  const content = hero && hero.querySelector(".hero-inner");
  let ticking = false;

  function update() {
    const y = window.scrollY;

    if (header) header.classList.toggle("is-scrolled", y > 24);

    if (hero && !reduceMotion) {
      const h = hero.offsetHeight;
      if (y < h) {
        if (media) media.style.transform = "translate3d(0," + y * 0.15 + "px,0)";
        if (content) {
          const p = Math.min(y / (h * 0.6), 1); // 0 at top → 1 after 60% of the hero
          content.style.opacity = String(1 - p);
          content.style.transform = "translate3d(0," + -p * 40 + "px,0)";
        }
      }
    }
    ticking = false;
  }

  window.addEventListener(
    "scroll",
    function () {
      if (!ticking) {
        requestAnimationFrame(update);
        ticking = true;
      }
    },
    { passive: true }
  );
  update();
})();
