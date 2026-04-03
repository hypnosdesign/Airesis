window.QuorumsDates = {
  init: function() {
    $('[data-start-votation]').on('dblclick', function() {
      return QuorumsDates.changeStart();
    });
    $('[name="proposal[votation][choise]"]').change(function() {
      if ($(this).val() === 'preset') {
        $('.choise_b .inner').css('opacity', 0.6);
        return $('.choise_a .inner').css('opacity', 1);
      } else {
        $('.choise_b .inner').css('opacity', 1);
        return $('.choise_a .inner').css('opacity', 0.6);
      }
    });
    $('.radiolabel').click(function() {
      return $('#' + $(this).attr('for')).click();
    });
    $('#proposal_votation_vote_period_id').select2({
      minimumResultsForSearch: -1,
      templateResult: formatPeriod,
      templateSelection: formatPeriod,
      escapeMarkup: function(m) {
        return m;
      }
    });
    $('#proposal_votation_vote_period_id').on("select2-focus", function(e) {
      return $('#proposal_votation_choise_preset').click();
    });
    $('#proposal_votation_end').fdatetimepicker();
    $('#proposal_votation_start').fdatetimepicker().on('hide', function(event) {
      var eventStartTime_ = event.date;
      $('#proposal_votation_end').fdatetimepicker("setStartDate", eventStartTime_);
      $('#proposal_votation_end').fdatetimepicker("setDate", addMinutes(eventStartTime_, 2880));
      showOnField($('#proposal_votation_end'), Airesis.i18n.datepicker.changed);
      return $('#proposal_votation_choise_new').click();
    });
    $('#choose_votation .cancel_action').click(function() {
      $('#start_preset').show();
      $('#start_choose').hide();
      return $('#proposal_votation_start_edited').val(null);
    });
    return $('#later').click(function() {
      var later_ = $('#proposal_votation_later');
      if (later_.val() === 'true') {
        $('#choose_votation .inner').show();
        later_.val('false');
      } else {
        $('#choose_votation .inner').hide();
        later_.val('true');
      }
      switchText($(this));
      return false;
    });
  },
  changeStart: function() {
    $('#start_preset').hide();
    $('#start_choose').show();
    return $('#proposal_votation_start_edited').val('true');
  }
};
