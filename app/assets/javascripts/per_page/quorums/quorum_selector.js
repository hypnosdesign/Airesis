Airesis.QuorumSelector = class QuorumSelector {
  constructor() {
    var quorum_ = $('#proposal_quorum_id');
    quorum_.select2({
      minimumResultsForSearch: -1,
      templateResult: formatQuorum,
      templateSelection: formatQuorumSelection,
      escapeMarkup: function(m) {
        return m;
      }
    });
    quorum_.on('change', function(e) {
      var choose_vote, end_, exlanation_, field, id_, minutes_, now_, selected_, timefixed_, upperend_, votation_end_;
      field = $(e.currentTarget);
      field.closest('form').formValidation('revalidateField', field);
      selected_ = quorum_.find('option:selected');
      exlanation_ = selected_.data('explanation');
      timefixed_ = selected_.data('time_fixed');
      minutes_ = selected_.data('minutes');
      id_ = selected_.val();
      if (exlanation_) {
        $('#quorum_explanation').html(exlanation_).show();
      } else {
        $('#quorum_explanation').hide();
      }
      choose_vote = $('#choose_votation');
      if (timefixed_) {
        return $.ajax({
          url: Airesis.paths.quorums.dates,
          data: {
            id: id_,
            group_id: Airesis.groupId
          },
          success: function() {
            var end_field, min_votation_end_, start_field;
            choose_vote.show();
            now_ = new Date();
            end_ = addMinutes(now_, parseInt(minutes_) + Airesis.debateVoteDifference);
            //votation start time
            upperend_ = upperMinutes(end_, 5);
            //votation end time
            min_votation_end_ = addMinutes(upperend_, 10);
            votation_end_ = addMinutes(upperend_, 2880);
            start_field = $('#proposal_votation_start');
            end_field = $('#proposal_votation_end');
            choose_vote.find('.start_vot').html(Airesis.i18n.proposals.debate.end + ' (' + dateToString(upperend_) + ')');
            start_field.fdatetimepicker('setStartDate', upperend_);
            start_field.fdatetimepicker('setDate', upperend_);
            end_field.fdatetimepicker('setStartDate', min_votation_end_);
            return end_field.fdatetimepicker('setDate', votation_end_);
          }
        });
      } else {
        return choose_vote.hide();
      }
    });
  }
};
