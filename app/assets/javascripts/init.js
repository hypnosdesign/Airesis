$(function() {
  const checkCharacters = function(field) {
    const button = $(this).nextAll('.search-by-text');
    if (field.val().length > 1) {
      button.removeAttr('disabled');
      return true;
    } else {
      button.attr('disabled', 'disabled');
      return false;
    }
  };

  $(document).foundation();
  new AiresisFormValidation($('form:not("[data-disable-form-validator]")'));
  Facebook.load();
  if (Airesis.environment === 'production') {
    GoogleAnalytics.load();
  }
  if (Airesis.environment === 'test') {
    $.fx.off = true;
  }
  // ajax requests
  $.ajaxPrefilter(function(options, originalOptions, jqXHR) {
    if (Airesis.i18n.l !== '') {
      options.data = $.param($.extend(originalOptions.data, { l: Airesis.i18n.l }));
    }
    return true;
  });
  //polling alerts
  if (Airesis.signed_in) {
    PrivatePub.subscribe('/notifications/' + Airesis.id, function(data, channel) {
      if (Airesis.resource_viewable) {
        //if I am in a page with a viewable object, sign it has view and then poll for alerts
        $.ajax({
          url: window.location,
          complete: poll_if_not_recent
        });
      } else {
        //otherwise, just poll for alerts
        poll_if_not_recent();
      }
    });
    poll();
  }
  //feedback configuration
  const feedback_options = Feedback({
    h2cPath: Airesis.i18n.feedback.h2cPath,
    url: '/send_feedback',
    label: Airesis.i18n.feedback.label,
    header: Airesis.i18n.feedback.header,
    nextLabel: Airesis.i18n.feedback.nextLabel,
    reviewLabel: Airesis.i18n.feedback.reviewLabel,
    sendLabel: Airesis.i18n.feedback.sendLabel,
    closeLabel: Airesis.i18n.feedback.closeLabel,
    messageSuccess: Airesis.i18n.feedback.messageSuccess,
    messageError: Airesis.i18n.feedback.messageError,
    appendTo: $('footer .feedback_space')[0],
    btnClass: 'feedbackBtn',
    pages: [
      new (window.Feedback.Form)([ {
        type: 'textarea',
        name: 'message',
        label: Airesis.i18n.feedback.describeProblem,
        required: true
      } ]),
      new (window.Feedback.Screenshot)({
        h2cPath: Airesis.i18n.feedback.h2cPath,
        blackoutButtonMessage: Airesis.i18n.feedback.blackoutButtonMessage,
        highlightButtonMessage: Airesis.i18n.feedback.highlightButtonMessage,
        highlightOrBlackout: Airesis.i18n.feedback.highlightOrBlackout}),
      new (window.Feedback.Review)()
    ]
  });
  //remove attributes for introjs from aside hidden menu. so they can work correctly
  $('aside [data-ijs]').removeAttr('data-ijs');

  $.fn.qtip.defaults = $.extend(true, {}, $.fn.qtip.defaults, { style: { classes: 'qtip-light qtip-shadow' } });

  Airesis.viewport = $('html, body');

  disegnaProgressBar();

  if ($('.sticky-anchor').length > 0) {
    $(window).scroll(sticky_relocate);
    sticky_relocate();
  }
  $('#menu-group .menu-activator').click(function() {
    const menu_ = $('#menu-left');
    if (menu_.attr('data-expshow') === 'true') {
      menu_.removeClass('small-show');
      menu_.attr('data-expshow', false);
    } else {
      menu_.addClass('small-show');
      menu_.attr('data-expshow', true);
    }
  });
  mybox_animate();

  // search in the website!
  new Airesis.Searcher();

  $('.submenu a div').qtip({
    position: {
      at: 'bottom center',
      my: 'top center'
    },
    show: {
      effect: false
    }
  });
  $('.cur.love').qtip({
    position: {
      at: 'bottom center',
      my: 'top center',
      viewport: $(window),
      adjust: {
        method: 'shift',
        x: 0,
        y: 0
      }
    },
    show: {
      effect: false,
      solo: true
    },
    style: { classes: 'qtip-light qtip-shadow qtip-cur' }
  });

  $('[data-qtip]').qtip({ style: { classes: 'qtip-light qtip-shadow' } });

  $(document).on('focus', '[data-datetimepicker]', function() {
    $(this).fdatetimepicker();
  });

  $('input[data-datepicker]').fdatetimepicker({ format: $.fn.fdatetimepicker.defaults.dateFormat });

  $(document).on('click', '[data-reveal-close]', function() {
    $('.reveal-modal:visible').foundation('reveal', 'close');
  });

  $(document).on('click', '[data-login]', function() {
    $('#login-panel').foundation('reveal', 'open');
  });

  $('.create_proposal').on('click', function() {
    const link = $(this);
    const create_proposal_ = $('<div class="dynamic_container reveal-modal large" data-reveal></div>');
    create_proposal_.append($(this).next('.choose_model').clone().show());
    $('.proposal_model_option', create_proposal_).click(function() {
      const url = $(this).data('url');
      window.location.href = url;
      const create_proposal_inner_ = $('.choose_model', create_proposal_);
      create_proposal_inner_.hide(500, function() {
        create_proposal_inner_.remove();
        create_proposal_.append($('#loading-fragment').clone());
      });
    });

    airesis_reveal(create_proposal_);
    return false;
  });
  $.fn.tagcloud.defaults = {
    size: {
      start: 12,
      end: 24,
      unit: 'pt'
    },
    color: {
      start: '#fff',
      end: '#fff'
    }
  };

  $('[data-tag-cloud] a').tagcloud();

  // proposals index, search by text field
  $('.search-by-text').on('click', function() {
    const field = $(this).prevAll('.field-by-text');
    const condition = $(this).prevAll('.condition-for-text:checked');
    if (checkCharacters(field)) {
      let loc_ = addQueryParam(location.href, 'search', field.val());
      if (condition.length > 0) {
        loc_ = addQueryParam(loc_, 'or', condition.val());
      } else {
        loc_ = addQueryParam(loc_, 'or', '');
      }
      window.location = loc_;
    }
    return false;
  });
  //initialize textntags when needed
  $(document).on('focus', '[data-textntags]', function() {
    if ($(this).data('textntags') !== 1) {
      $(this).textntags({
        triggers: { '@': { uniqueTags: false } },
        onDataRequest: function(mode, query, triggerChar, callback) {
          const data = ProposalsShow.nicknames;
          query = query.toLowerCase();
          const found = _.filter(data, function(item) {
            return item.name.toLowerCase().indexOf(query) > -1;
          });
          callback.call(this, found);
        }
      });
      $(this).data('textntags', 1);
      $(this).focus();
    }
  });

  //executes page specific js
  const page = $('body').data('page');
  execute_page_js(page);

  //select fdatetimepicker mode in according to All day checkbox
  $(document).on('change', '#event_all_day', function() {
    if ($(this).is(':checked')) {
      fdatetimepicker_only_date($('#event_starttime'), $("#event_endtime"));
    } else {
      fdatetimepicker_date_and_time($('#event_starttime'), $("#event_endtime"));
    }
  });
});
