window.ProposalsIndex = {
  init: function() {
    $('[name="time[start_w]"],[name="time[end_w]"]').fdatetimepicker({
      format: $.fn.fdatetimepicker.defaults.dateFormat
    });
    $('.creation_date').each(function() {
      var selected_, text;
      if (ProposalsIndex.timeFilter != null) {
        selected_ = $(this).find('.hidden_menu a[data-type=' + ProposalsIndex.timeFilter.type + ']');
        if (ProposalsIndex.timeFilter.type === 'f') {
          text = ProposalsIndex.timeFilter.start_w + ' - ' + ProposalsIndex.timeFilter.end_w;
        } else {
          text = selected_.text();
        }
      } else {
        selected_ = $(this).find('.hidden_menu a[data-type=w]');
        text = selected_.text();
      }
      $(this).find('.hidden_link b').text(text);
      return selected_.addClass('checked');
    });
    $('html').click(function() {
      $('.hidden_menu').hide();
      return $('.hidden_link.visible').removeClass('visible');
    });
    $('.hidden_link').click(function(event) {
      $(this).addClass('visible');
      $(this).next().show().position({
        my: "right top",
        at: "right bottom",
        of: $(this)
      });
      return event.stopPropagation();
    });
    var input = $('.interest_borders');
    return input.select2({
      placeholder: Airesis.i18n.interestBorders.hintText,
      allowClear: true,
      ajax: {
        url: '/interest_borders',
        dataType: 'json',
        delay: 250,
        data: function(params) {
          return {
            q: params.term,
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
      escapeMarkup: function(markup) {
        return markup;
      },
      minimumInputLength: 1
    }).on("change", function(e) {
      return $(this).closest('form').submit();
    });
  }
};
