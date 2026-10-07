/*
  This lights up the right link in my top menu.
  As you scroll, the link for the section in the middle of the screen turns green.
*/
(function () {
  "use strict";

  var sections = Array.prototype.slice.call(document.querySelectorAll("section.block[id]"));
  var navlinks = Array.prototype.slice.call(document.querySelectorAll(".navlink"));

  function setActive(id) {
    navlinks.forEach(function (l) {
      l.classList.toggle("active", l.dataset.nav === id);
    });
  }

  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (e.isIntersecting) setActive(e.target.id);
      });
    }, { rootMargin: "-45% 0px -50% 0px", threshold: 0 });
    sections.forEach(function (s) { io.observe(s); });
  }
})();
