// Mobile menu toggle
const toggle = document.querySelector(".nav-toggle");
const nav = document.getElementById("main-nav");

if (toggle && nav) {
  toggle.addEventListener("click", () => {
    const open = nav.classList.toggle("open");
    toggle.setAttribute("aria-expanded", String(open));
  });
}

// ---------- Prototype forms ----------
// <form data-proto>   → on submit: checks the fields, hides the form, shows the element with id "<form id>-done".
//                       Nothing is stored or sent.
// <form data-signin data-next="page.html"> → also sets the demo "signed in" flag, then goes to that page.
document.querySelectorAll("form[data-proto]").forEach(function (form) {
  form.addEventListener("submit", function (e) {
    e.preventDefault();
    if (form.hasAttribute("data-signin")) {
      try { sessionStorage.setItem("ipec-demo-signed-in", "1"); } catch (err) {}
      location.href = form.getAttribute("data-next") || "index.html";
      return;
    }
    var done = document.getElementById(form.id + "-done");
    if (done) { form.hidden = true; done.hidden = false; done.focus(); }
  });
});
