window.ParticipationRolesIndex = {
  init: function() {
    return $(document).on('click', '[data-action-abilitation]', function() {
      return $(this).closest('form').submit();
    });
  }
};
