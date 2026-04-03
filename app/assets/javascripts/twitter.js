(function() {
  let twttr_events_bound = false;

  const loadTwitterSDK = function() {
    $.getScript("//platform.twitter.com/widgets.js");
  };

  const renderTweetButtons = function() {
    $('.twitter-share-button').each(function() {
      const button = $(this);
      if (!button.data('url')) {
        button.attr('data-url', document.location.href);
      }
      if (!button.data('text')) {
        button.attr('data-text', document.title);
      }
    });
    if (typeof twttr !== 'undefined') {
      twttr.widgets.load();
    }
  };

  const bindTwitterEventHandlers = function() {
    $(document).on('page:load', renderTweetButtons);
    twttr_events_bound = true;
  };

  $(function() {
    loadTwitterSDK();
    if (!twttr_events_bound) {
      bindTwitterEventHandlers();
    }
  });
})();
