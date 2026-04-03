(function() {
  window.Facebook = class Facebook {
    static load() {
      if ($('#fb-root').length === 0) {
        const initialRoot = $('<div>').attr('id', 'fb-root');
        $('body').prepend(initialRoot);
      }

      if ($('#facebook-jssdk').length === 0) {
        const facebookScript = document.createElement("script");
        facebookScript.id = 'facebook-jssdk';
        facebookScript.async = 1;
        facebookScript.src = `//connect.facebook.net/${Facebook.locale()}/sdk.js#xfbml=1&appId=${Facebook.appId()}&version=v2.0`;

        const firstScript = document.getElementsByTagName("script")[0];
        firstScript.parentNode.insertBefore(facebookScript, firstScript);
      }

      if (!Facebook.eventsBound) {
        Facebook.bindEvents();
      }
      Facebook.subscriptions();
    }

    static subscriptions() {}

    static bindEvents() {
      if (typeof Turbolinks !== 'undefined' && Turbolinks.supported) {
        $(document)
          .on('page:fetch', Facebook.saveRoot)
          .on('page:change', Facebook.restoreRoot)
          .on('page:load', function() {
            if (typeof FB !== 'undefined') {
              FB.XFBML.parse();
            }
          });
      }

      Facebook.eventsBound = true;
    }

    static saveRoot() {
      Facebook.rootElement = $('#fb-root').detach();
    }

    static restoreRoot() {
      if ($('#fb-root').length > 0) {
        $('#fb-root').replaceWith(Facebook.rootElement);
      } else {
        $('body').append(Facebook.rootElement);
      }
    }

    static appId() {
      return $('#fb-root').data('app-id');
    }

    static locale() {
      return $('#fb-root').data('locale');
    }
  };

  Facebook.rootElement = null;
  Facebook.eventsBound = false;

  window.fbAsyncInit = function() {
    FB.Event.subscribe('edge.create', function(href, widget) {
      const likeable_type = $(widget).data('likeable_type');
      const likeable_id = $(widget).data('likeable_id');
      if (likeable_type && likeable_id) {
        $.ajax({
          headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
          data: {
            'user_like[likeable_id]': likeable_id,
            'user_like[likeable_type]': likeable_type
          },
          url: $('#fb-root').data('user-like-url'),
          type: 'post'
        });
      }
    });

    FB.Event.subscribe('edge.remove', function(href, widget) {
      const likeable_type = $(widget).data('likeable_type');
      const likeable_id = $(widget).data('likeable_id');
      if (likeable_type && likeable_id) {
        $.ajax({
          headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
          data: {
            'user_like[likeable_id]': likeable_id,
            'user_like[likeable_type]': likeable_type
          },
          url: $('#fb-root').data('user-like-url') + '/' + likeable_id,
          type: 'delete'
        });
      }
    });
  };
})();
