(function() {
    "use strict";

    // Adds website domain as CSS class to body element
    function addDomainClass() {
        try {
            // Get the current hostname
            const hostname = window.location.hostname;

            if (!hostname) return;

            // Remove 'www.' prefix if present
            const cleanHostname = hostname.replace(/^www\./, "");

            // Split by dots and process based on domain structure
            const parts = cleanHostname.split(".");
            let domainClass = "";

            if (parts.length >= 2) {
                if (parts.length === 2) {
                    // Simple domain like
                    domainClass = parts[0];
                } else {
                    // Subdomain like
                    domainClass = parts.slice(0, -1).join("-");
                }
            } else {
                // Edge case: single part domain (localhost, etc.)
                domainClass = parts[0];
            }

            // Sanitize the class name to be CSS-safe
            domainClass = domainClass
                .toLowerCase()
                .replace(/[^a-z0-9-]/g, "-") // Replace non-alphanumeric chars with hyphens
                .replace(/-+/g, "-") // Replace multiple hyphens with single hyphen
                .replace(/^-|-$/g, ""); // Remove leading/trailing hyphens

            // Only proceed if we have a valid class name
            if (domainClass && domainClass.length > 0) {
                const body = document.body;

                if (body) {
                    // Add the new domain class
                    if (!body.classList.contains(domainClass)) {
                        body.classList.add(domainClass);
                        console.log(`Added domain class: ${domainClass}`);
                    }
                }
            }
        } catch (error) {
            console.error("Error adding domain class:", error);
        }
    }

    // Run immediately if DOM is ready
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", addDomainClass);
    } else {
        addDomainClass();
    }

    // Also run on window load as fallback
    window.addEventListener("load", addDomainClass);

    // Handle SPA navigation and hash changes
    let lastUrl = location.href;

    // Use MutationObserver to detect URL changes in SPAs
    const observer = new MutationObserver(function() {
        if (location.href !== lastUrl) {
            lastUrl = location.href;
            setTimeout(addDomainClass, 100); // Small delay to ensure DOM is updated
        }
    });

    // Start observing
    observer.observe(document, {
        subtree: true,
        childList: true,
    });

    // Listen for popstate events (back/forward navigation)
    window.addEventListener("popstate", function() {
        setTimeout(addDomainClass, 100);
    });

    // Listen for hashchange events
    window.addEventListener("hashchange", addDomainClass);
})();
