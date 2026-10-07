/*
  Settings my scripts share.

  apiBase is just "/api" with no domain. That works because CloudFront sends
  anything under /api/ to my API, so the page and the API are on one domain.

  I also keep the words my scripts show to visitors here, so I can change the
  wording in one place.
*/
window.CV_CONFIG = {
  apiBase: "/api",
  messages: {
    sending: "Sending...",
    sent: "Thanks! Your message is on its way to my inbox.",
    invalid: "Please check your name, email, phone number and message.",
    failed: "That didn't go through. Please email me directly instead.",
    visits: "Visitor #{count} · counted by AWS Lambda + DynamoDB"
  }
};
