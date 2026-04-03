window.QuorumsIndex = {
  init: function() {
    $('[data-quorum-check]').on('click', function() {
      return QuorumsIndex.switchOption($(this), "/groups/" + QuorumsIndex.groupId + "/quorums/" + $(this).data('quorum-check') + "/change_status");
    });
    $('[data-change-default-anonimity]').on('click', function() {
      return QuorumsIndex.switchOption($(this), QuorumsIndex.changeDefaultAnonimityUrl);
    });
    $('[data-change-default-visible-outside]').on('click', function() {
      return QuorumsIndex.switchOption($(this), QuorumsIndex.changeDefaultVisibleOutsideUrl);
    });
    $('[data-change-default-secret-vote]').on('click', function() {
      return QuorumsIndex.switchOption($(this), QuorumsIndex.changeDefaultSecretVoteUrl);
    });
    return $('[data-change-default-advanced-options]').on('click', function() {
      return QuorumsIndex.switchOption($(this), QuorumsIndex.changeDefaultAdvancedOptionsUrl);
    });
  },
  switchOption: function(element, url) {
    var active = element.is(':checked');
    return $.ajax({
      data: {
        active: active
      },
      url: url,
      dataType: 'script',
      type: 'post'
    });
  }
};
