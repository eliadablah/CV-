/*
  My FAQ chat box.
  It runs only in the browser and does not call my API. I wrote a list of
  answers below. The chat looks for keywords in your question and picks the
  answer that matches best.
*/
(function () {
  "use strict";

  /* ---- My answers. Each one has keywords that trigger it. ---- */
  var KB = [
    { id: "experience", keywords: ["experience","job","work","current","doing now","role"],
      a: "Right now I'm an IT Support Technician III at EZLynx (Applied Systems). I previously did contract work at Mercor evaluating AI model responses and a cloud engineering contract at Novrupt, and I'm actively working toward a full move into cloud/DevOps." },
    { id: "skills", keywords: ["skills","technologies","tech stack","tools","stack"],
      a: "My toolkit spans AWS and Azure, security fundamentals (OAuth, RBAC, IAM), DevOps tooling (CI/CD, Docker, Kubernetes, GitHub Actions, Jenkins, Terraform), and Python/PySpark, plus support tools like Freshdesk, Jira, and ServiceNow." },
    { id: "aws", keywords: ["aws","amazon","cloud platform"],
      a: "Yes — I hold the AWS Certified Cloud Practitioner and AWS Certified Solutions Architect – Associate certifications, and got hands-on AWS experience (Glue, S3, DynamoDB, Athena) during a cloud engineering contract at Novrupt." },
    { id: "education", keywords: ["education","degree","school","university","study","studied","college"],
      a: "B.S. in Information Technology & Business Administration from the University of Texas at Tyler (Dec 2025, 3.4 GPA), and currently in a DevOps & AI training program through UTrains." },
    { id: "certs", keywords: ["certifications","certified","certs","certificate"],
      a: "AWS Certified Solutions Architect – Associate, AWS Certified Cloud Practitioner, and Google Data Analytics Certification." },
    { id: "projects", keywords: ["projects","built","portfolio","github","dashboard"],
      a: "Three I'm proud of: this CV site, which I run on AWS for under $1 a month with Terraform, Docker and Lambda; a budget tracker that connects to bank accounts through Plaid; and the UTC Student Services Portal, a UTC project that we actually built and ran on a three-tier AWS network with a load balancer, auto scaling and a private MySQL database, all with Terraform. They are in the Projects section above." },
    { id: "looking", keywords: ["looking for","hire","opportunity","open to","position","roles","job search"],
      a: "I'm actively looking for Cloud Support, Junior Systems Administrator, and DevOps-track roles. If you think there's a fit, reach out — email or LinkedIn both work." },
    { id: "contact", keywords: ["contact","reach","email","connect","get in touch"],
      a: "Easiest way is email (elikadablah@gmail.com) or LinkedIn — both are linked at the top and bottom of this page." },
    { id: "why", keywords: ["why","transition","switch","career change","moving"],
      a: "I started in IT support and got hooked on the infrastructure side during a cloud engineering contract — since then I've been building toward cloud/DevOps through certifications, training, and personal projects." },
    { id: "location", keywords: ["location","based","relocate","remote","dallas","where"],
      a: "Based in Dallas, TX. For specifics on remote work or relocation, that's best asked directly — feel free to email." },
    { id: "salary", keywords: ["salary","compensation","pay","rate","comp"],
      a: "That's best discussed directly — reach out via email and we can talk specifics." },
    { id: "hello", keywords: ["hi","hello","hey","sup"],
      a: "Hi! I'm an automated FAQ bot trained on Elikem's resume — ask about his experience, skills, projects, or how to get in touch." }
  ];
  var FALLBACK = "That's a good one — I don't have a canned answer for that yet. Reach out directly at elikadablah@gmail.com or on LinkedIn and Elikem can answer himself.";

  var QUICK = [
    { label: "What's your experience?", id: "experience" },
    { label: "What are your skills?", id: "skills" },
    { label: "What are you looking for?", id: "looking" },
    { label: "How do I contact you?", id: "contact" }
  ];

  // I count how many keywords each answer shares with the question. Most matches wins.
  function findAnswer(text) {
    var t = text.toLowerCase();
    var best = null, bestScore = 0;
    KB.forEach(function (entry) {
      var score = 0;
      entry.keywords.forEach(function (kw) { if (t.indexOf(kw) !== -1) score++; });
      if (score > bestScore) { bestScore = score; best = entry; }
    });
    return best ? best.a : FALLBACK;
  }

  var chatBody = document.getElementById("chatBody");
  function addMsg(role, text) {
    var div = document.createElement("div");
    div.className = "msg " + role;
    div.textContent = text;
    chatBody.appendChild(div);
    chatBody.scrollTop = chatBody.scrollHeight;
  }
  function addQuickChips() {
    var wrap = document.createElement("div");
    wrap.className = "qchips";
    QUICK.forEach(function (q) {
      var btn = document.createElement("button");
      btn.className = "qchip";
      btn.type = "button";
      btn.textContent = q.label;
      btn.addEventListener("click", function () {
        addMsg("user", q.label);
        var entry = KB.filter(function (e) { return e.id === q.id; })[0];
        setTimeout(function () { addMsg("bot", entry ? entry.a : FALLBACK); }, 260);
      });
      wrap.appendChild(btn);
    });
    chatBody.appendChild(wrap);
    chatBody.scrollTop = chatBody.scrollHeight;
  }

  var initialized = false;
  var toggle = document.getElementById("chatToggle");
  var panel = document.getElementById("chatPanel");
  toggle.addEventListener("click", function () {
    var open = panel.classList.toggle("open");
    toggle.classList.toggle("open", open);
    if (open && !initialized) {
      initialized = true;
      addMsg("bot", "Hi! I'm an automated FAQ bot trained on Elikem's resume.");
      addMsg("bot", "Ask me anything about his experience, skills, or projects — or tap a question below.");
      addQuickChips();
    }
  });

  var input = document.getElementById("chatInput");
  var send = document.getElementById("chatSend");
  function submit() {
    var val = input.value.trim();
    if (!val) return;
    addMsg("user", val);
    input.value = "";
    setTimeout(function () { addMsg("bot", findAnswer(val)); }, 300);
  }
  send.addEventListener("click", submit);
  input.addEventListener("keydown", function (e) {
    if (e.key === "Enter") submit();
  });
})();
