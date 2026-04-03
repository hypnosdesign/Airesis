window.Airesis = {
  i18n: {},
  scrollLock: function(element, event) {
    const d = event.originalEvent.wheelDelta || -event.originalEvent.detail;
    const dir = d > 0 ? 'up' : 'down';
    const stop = (dir === 'up' && element.scrollTop === 0) || (dir === 'down' && element.scrollTop === element.scrollHeight - element.offsetHeight);
    if (stop) {
      event.preventDefault();
    }
  },
  development: function() {
    return this.environment === 'development';
  },
  log: function(args) {
    if (Airesis.development()) {
      console.log(args);
    }
  },
  select2town: function(element) {
    element.select2({
      placeholder: Airesis.i18n.type_for_town,
      ajax: {
        url: '/municipalities',
        dataType: 'json',
        data: function(params) {
          return {
            q: params.term
          };
        },
        processResults: function(data, page) {
          return {
            results: data
          };
        },
        cache: true
      },
      escapeMarkup: function(m) {
        return m;
      }
    });
  },
  delay: (function() {
    let timer = 0;
    return function(callback, ms) {
      clearTimeout(timer);
      timer = setTimeout(callback, ms);
    };
  })()
};
