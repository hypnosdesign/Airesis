window.UsersShow = {
  init: function() {
    $('[data-participation-tooltip]').each(function() {
      return $(this).qtip({
        content: $(this).next('[data-participation-tooltip-text]'),
        position: {
          viewport: $('#main-copy')
        }
      });
    });
    return $('#participation_table').dataTable({
      'bPaginate': false,
      'bFilter': false,
      'bSearchable': false,
      'bInfo': false,
      'aaSorting': [[2, 'desc']],
      'aoColumns': [null, null, {
        'iDataSort': 3
      }, {
        'bVisible': false
      }, null]
    });
  }
};
