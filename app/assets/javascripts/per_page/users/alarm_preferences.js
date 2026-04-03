window.UsersAlarmPreferences = {
  init: function() {
    $('[data-change-notification-block]').on('click', function() {
      return UsersAlarmPreferences.change_notification_block(this);
    });
    $('[data-change-email-notification-block]').on('click', function() {
      return UsersAlarmPreferences.change_email_notification_block(this);
    });
    return $('[data-change-email-block]').on('click', function() {
      return UsersAlarmPreferences.change_email_block(this);
    });
  },
  change_notification_block: function(el) {
    var block_ = !el.checked;
    $.ajax({
      url: "/notifications/change_notification_block",
      dataType: 'script',
      data: {
        id: el.value,
        block: block_
      },
      type: 'post'
    });
    if (el.checked) {
      return $('#block_email_' + el.value).removeAttr("disabled").removeAttr("title");
    } else {
      return $('#block_email_' + el.value).attr("disabled", true).attr("title", "Devi attivare la notifica per ricevere l'email");
    }
  },
  change_email_notification_block: function(el) {
    var block_ = !el.checked;
    return $.ajax({
      url: "/notifications/change_email_notification_block",
      dataType: 'script',
      data: {
        id: el.value,
        block: block_
      },
      type: 'post'
    });
  },
  change_email_block: function(el) {
    var block_ = !el.checked;
    return $.ajax({
      url: "/notifications/change_email_block",
      dataType: 'script',
      data: {
        block: block_
      },
      type: 'post'
    });
  }
};
