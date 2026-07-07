// ==UserScript==
// @name         Domain As Class
// @namespace    https://taiwbi.ir/
// @version      1.1
// @description  Adds the main domain name and subdomains as classes to the html tag
// @match        http://*/*
// @match        https://*/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function () {
  "use strict";

  const hostname = window.location.hostname;
  const parts = hostname.split(".");

  if (parts.length >= 2) {
    // Extracts everything except the TLD (e.g., ['subdomain', 'wallhaven'])
    const domainClasses = parts.slice(0, -1);

    // Ensures it runs as soon as the HTML element is available
    const addClasses = () => {
      if (document.documentElement) {
        // Adds all extracted parts as individual classes
        document.documentElement.classList.add(...domainClasses);
      } else {
        requestAnimationFrame(addClasses);
      }
    };
    addClasses();
  }
})();
