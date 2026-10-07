/*
  The visitor counter at the bottom of my page.
  The first time you open the page, I add 1 to the count.
  If you refresh, I only read the count, so one person isn't counted twice.
  If my API can't be reached, the counter just stays hidden.
*/
(function () {
  "use strict";

  var cfg = window.CV_CONFIG;
  var el = document.getElementById("visitCount");
  if (!el || !window.fetch) return;

  var SESSION_KEY = "cv-visit-counted";
  var counted = false;
  // Some private windows block browser storage, so I wrap it in try/catch to avoid a crash
  try { counted = sessionStorage.getItem(SESSION_KEY) === "1"; } catch (e) { /* not counted */ }

  fetch(cfg.apiBase + "/visits", { method: counted ? "GET" : "POST" })
    .then(function (res) {
      if (!res.ok) throw new Error("HTTP " + res.status);
      return res.json();
    })
    .then(function (data) {
      var count = Number(data.visits);
      if (!isFinite(count)) return;
      el.textContent = cfg.messages.visits.replace("{count}", count.toLocaleString());
      el.hidden = false;
      try { sessionStorage.setItem(SESSION_KEY, "1"); } catch (e) { /* counts again next load */ }
    })
    .catch(function () { /* counter stays hidden */ });
})();
