/*
  My contact form.
  When you press Send, I post your inquiry to /api/contact and show the result
  under the button. If my API can't be reached, I ask you to email me instead.
*/
(function () {
  "use strict";

  var cfg = window.CV_CONFIG;
  var form = document.getElementById("contactForm");
  var status = document.getElementById("formStatus");
  if (!form || !status || !window.fetch) return;

  var button = form.querySelector(".form-submit");

  function setStatus(kind, text) {
    status.className = "form-status" + (kind ? " " + kind : "");
    status.textContent = text;
  }

  form.addEventListener("submit", function (e) {
    e.preventDefault();

    var payload = {
      name: form.elements.name.value.trim(),
      email: form.elements.email.value.trim(),
      company: form.elements.company.value.trim(),
      phone: form.elements.phone.value.trim(),
      reason: form.elements.reason.value,
      message: form.elements.message.value.trim(),
      website: form.elements.website.value
    };

    // A quick check in the browser. My API checks everything again, and that is the check that counts.
    if (!payload.name || !payload.message || !form.elements.email.checkValidity() || !payload.email) {
      setStatus("error", cfg.messages.invalid);
      return;
    }

    button.disabled = true;
    setStatus("", cfg.messages.sending);

    fetch(cfg.apiBase + "/contact", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    })
      .then(function (res) {
        if (res.status === 400) {
          setStatus("error", cfg.messages.invalid);
          return;
        }
        if (!res.ok) throw new Error("HTTP " + res.status);
        form.reset();
        setStatus("success", cfg.messages.sent);
      })
      .catch(function () {
        setStatus("error", cfg.messages.failed);
      })
      .then(function () {
        button.disabled = false;
      });
  });
})();
