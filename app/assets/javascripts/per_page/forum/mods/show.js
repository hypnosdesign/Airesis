window.ModsShow = {
  init: function() {
    return $("#frm_user_id").select2({
      ajax: {
        url: ModsShow.autocompleteUrl,
        dataType: 'json',
        data: function(params) {
          return {
            term: params.term,
            l: Airesis.i18n.locale,
            pp: 'disable'
          };
        },
        processResults: function(data, page) {
          return {
            results: data
          };
        },
        cache: true
      },
      templateResult: ModsShow.format,
      templateSelection: ModsShow.format
    });
  },
  format: function(state) {
    if (!state.id) {
      return state.text;
    }
    return $('<span>' + state.image_path + state.identifier + '</span>');
  }
};

window.MembersAdd = window.ModsShow;
