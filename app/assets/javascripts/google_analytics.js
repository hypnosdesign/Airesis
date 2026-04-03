(function() {
  window.GoogleAnalytics = class GoogleAnalytics {
    static load() {
      if (Airesis.googleAnalyticsId === '') {
        return;
      }

      (function(i, s, o, g, r, a, m) {
        i["GoogleAnalyticsObject"] = r;
        i[r] = i[r] || function() {
          (i[r].q = i[r].q || []).push(arguments);
        };
        i[r].l = 1 * new Date();
        a = s.createElement(o);
        m = s.getElementsByTagName(o)[0];
        a.async = 1;
        a.src = g;
        m.parentNode.insertBefore(a, m);
      })(window, document, "script", "//www.google-analytics.com/analytics.js", "ga");

      if (typeof Turbolinks !== 'undefined' && Turbolinks.supported) {
        document.addEventListener("page:change", function() {
          GoogleAnalytics.trackPageview();
        }, true);
      } else {
        GoogleAnalytics.trackPageview();
      }
    }

    static trackPageview(url) {
      if (!GoogleAnalytics.isLocalRequest()) {
        if (url) {
          window.ga('send', 'pageview', window.location.pathname);
        } else {
          window.ga('create', Airesis.googleAnalyticsId, 'auto');
          window.ga('send', 'pageview');
        }
      }
    }

    static isLocalRequest() {
      return GoogleAnalytics.documentDomainIncludes("local");
    }

    static documentDomainIncludes(str) {
      return document.domain.indexOf(str) !== -1;
    }
  };
})();
