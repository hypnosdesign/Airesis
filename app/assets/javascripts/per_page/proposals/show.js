window.ProposalsShow = {
  voting: false,
  abandoned: false,
  contributesUrl: '',
  rightlistUrl: '',
  clicked: null,
  contributes: [],
  nicknames: [],
  checkActive: false,
  currentView: 3,
  currentPage: 0,
  proposalId: null,
  openShare: false,
  contributeMaxLength: 0,
  times: {},
  firstCheck: false,
  init: function() {
    this.currentView = Airesis.signed_in ? 1 : 3;
    $('[data-scroll-to="vote_panel"]').on('click', function() {
      return ProposalsShow.scroll_to_vote_panel();
    });
    $(document).on('click', '[data-cancel-edit-comment]', function() {
      ProposalsShow.cancel_edit_comment($(this).data('cancel-edit-comment'));
      return false;
    });
    $(document).on('click', '[data-edit-contribute]', function() {
      ProposalsShow.edit_contribute($(this).data('edit-contribute'));
      return false;
    });
    $(document).on('click', '[data-history-contribute]', function() {
      ProposalsShow.history_contribute($(this).data('history-contribute'));
      return false;
    });
    $(document).on('click', '[data-report-contribute]', function() {
      ProposalsShow.report_contribute($(this).data('report-contribute'));
      return false;
    });
    $(document).on('click', '[data-close-section-id]', function() {
      ProposalsShow.close_right_contributes($('.contribute-button[data-section_id=' + $(this).data('close-section-id') + ']'));
      return false;
    });
    $(document).on('click', '[data-close-edit-right-section]', function() {
      hideContributes();
      return false;
    });
    $(document).on('ajax:beforeSend', '.vote_comment', function(n, xhr) {
      $(this).parent().find('.vote_comment').hide();
      return $(this).parent().find('.loading').show();
    });
    $(document).on('ajax:beforeSend', '.icon-sad-change', function(n, xhr) {
      var num = $(this).data('id');
      $(this).parent().find('.vote_comment').hide();
      $(this).parent().find('.loading').show();
      return $(".reply_textarea[data-id=" + num + "]").focus().attr('placeholder', Airesis.i18n.rankdown_reason).effect('highlight', {}, 3000);
    });
    $(document).ajaxError(function(e, XHR, options) {
      if (XHR.status === 401) {
        return window.location.replace(Airesis.new_user_session_path);
      }
    });
    if (this.voting) {
      new Airesis.ProposalVotationManager();
    } else {
      this.currentPage++;
      $.ajax({
        url: this.contributesUrl,
        dataType: 'script',
        data: {
          page: this.currentPage,
          view: this.currentView,
          contributes: this.contributes,
          comment_id: Airesis.show_comment_id //show contribute if requested
        },
        type: 'get',
        complete: function() {
          return $("#loading_contributes").hide();
        }
      });
    }
    if (this.voted) {
      if (matchMedia(Foundation.media_queries['medium']).matches) {
        $('.results-button')[0].click();
      }
    }
    $('img.cke_iframe').each(function() {
      var realelement = $(this).data('cke-realelement');
      $(this).after($(unescape(realelement)));
      return $(this).remove();
    });
    this.init_text_areas();
    this.init_contributes_button();
    this.init_countdowns();
    this.initVotePeriodSelect();
    if (this.abandoned) {
      new Airesis.QuorumSelector();
    }
    //open the contribute if it's a link from an email
    if (Airesis.show_section_id) {
      $(".contribute-button[data-section_id=" + Airesis.show_section_id + "]").trigger('click', [Airesis.show_comment_id]);
    }
    if (this.openShare !== '') {
      return $('#promote_proposal').click();
    }
  },
  init_text_areas: function() {
    return $('[data-contribute-area]').each(function() {
      if ($(this).attr('data-initialized') != 1) {
        $(this).textntags({
          triggers: {
            '@': {
              uniqueTags: false
            }
          },
          onDataRequest: function(mode, query, triggerChar, callback) {
            var data = ProposalsShow.nicknames;
            query = query.toLowerCase();
            var found = _.filter(data, function(item) {
              return item.name.toLowerCase().indexOf(query) > -1;
            });
            return callback.call(this, found);
          }
        });
        $(this).charCount({
          allowed: ProposalsShow.contributeMaxLength,
          warning: 100,
          counterText: Airesis.i18n.proposals.charactersLeft
        });
        return $(this).attr('data-initialized', 1);
      }
    });
  },
  scroll_to_vote_panel: function() {
    scrollToElement($(".vote_panel"));
    return false;
  },
  contribute: function(section_id) {
    $('#proposal_comment_section_id').val(section_id);
    Airesis.viewport.animate({
      scrollTop: $("#proposal_comment_content").offset().top - 150
    }, 2000, function() {
      $('#proposal_comment_content').focus();
      return $('#comment-form-comment').effect('highlight', {}, 3000);
    });
    Airesis.viewport.bind("scroll mousedown DOMMouseScroll mousewheel keyup", function(e) {
      if (matchMedia(Foundation.media_queries['medium']).matches && e.which > 0 || e.type === "mousedown" || e.type === "mousewheel") {
        return Airesis.viewport.stop().unbind('scroll mousedown DOMMouseScroll mousewheel keyup');
      }
    });
    return false;
  },
  edit_contribute: function(id) {
    close_all_dropdown();
    $.ajax({
      dataType: 'script',
      type: 'get',
      url: "/proposals/" + this.proposalId + "/proposal_comments/" + id + "/edit"
    });
    return false;
  },
  cancel_edit_comment: function(id) {
    if (confirm('Are you sure?')) {
      return $('.proposalComment[data-id=' + id + '] .edit_panel').fadeOut(function() {
        $(this).remove();
        return $('.proposalComment[data-id=' + id + '] .baloon-content').fadeIn();
      });
    }
  },
  history_contribute: function(id) {
    close_all_dropdown();
    $.ajax({
      dataType: 'script',
      type: 'get',
      url: "/proposals/" + this.proposalId + "/proposal_comments/" + id + "/history"
    });
    return false;
  },
  report_contribute: function(id) {
    $('#report_contribute_id').val(id);
    $('input[name=reason]').removeAttr('checked');
    $('#report_contribute').foundation('reveal', 'open');
    return close_all_dropdown();
  },
  checkScroll: function() {
    if (!this.voting) {
      if (nearBottomOfPage() && this.checkActive) {
        this.checkActive = false;
        this.currentPage++;
        return $.ajax({
          url: this.contributesUrl,
          dataType: 'script',
          data: {
            page: this.currentPage,
            view: this.currentView,
            contributes: this.contributes
          },
          type: 'get'
        });
      } else {
        return setTimeout("ProposalsShow.checkScroll()", 250);
      }
    }
  },
  open_right_contributes: function(_this, comment_id) {
    var section_id = _this.attr("data-section_id");
    _this.attr("data-status", 1);
    $('#suggest').show();
    _this.parent().find(".tria").show();
    _this.parent().addClass("sel");
    $('.text', _this).text(Airesis.i18n.proposals.closeContributes);
    hideLeftPanel();
    var fetched = $('.suggestion_right[data-section_id=' + section_id + ']');
    fitRightMenu(fetched);
    $('.suggestion_right[data-section_id=' + section_id + ']').fadeIn();
    _this.next().show();
    if (comment_id) {
      var comment_ = $('#comment' + comment_id + ' .proposal_comment');
      fetched.animate({
        scrollTop: comment_.offset().top - 100
      }, 2000);
      return comment_.effect('highlight', {}, 3000);
    }
  },
  close_right_contributes: function(_this) {
    var section_id = _this.attr("data-section_id");
    _this.attr("data-status", 2);
    $('.suggestion_right[data-section_id=' + section_id + ']').hide();
    _this.parent().find(".tria").hide();
    $('.text', _this).text(Airesis.i18n.proposals.showGiveContributes).append(" (" + _this.attr('data-unread_contributes_num') + "/" + _this.attr('data-contributes_num') + ")");
    $('#menu-left').removeClass('contributes_shown');
    $('#centerpanelextended').removeClass('contributes_shown');
    $('.suggestion_right[data-section_id=' + section_id + ']').removeClass('contributes_shown');
    return _this.next().hide();
  },
  reload_page: function() {
    toastr.options = {
      tapToDismiss: false,
      extendedTimeOut: 0,
      timeOut: 0
    };
    return toastr.info('<div>This page is outdate.<br/>Please reload the page.<br/><a href="" class="btn" style="color: #444">Reload</a></div>');
  },
  //0 - not fetched - closed
  //1 - fetched - open
  //2 - fetched - closed
  init_contributes_button: function() {
    return $(".contribute-button").click(function(event, comment_id) {
      var this_ = $(this);
      var section_id = this_.attr("data-section_id");
      var this_status = this_.attr("data-status");
      $(".contribute-button").each(function() {
        var his_status = $(this).attr("data-status");
        var his_section_id = $(this).attr("data-section_id");
        if (this_[0] !== this) { //for each right panel that is not the opened one
          if (his_status === '1') {
            $(this).attr("data-status", '2');
            $('.suggestion_right[data-section_id=' + his_section_id + ']').hide(); //hide it
            $(this).parent().find(".tria").hide();
            $('.text', this).text(Airesis.i18n.proposals.showGiveContributes).append(" (" + $(this).attr('data-unread_contributes_num') + "/" + $(this).attr('data-contributes_num') + ")");
            return $(this).next().hide(); //and hide what comes next...i don't know really...
          }
        }
      });
      $(".suggest .tria").hide();
      $(".suggest").removeClass("sel");
      if (this_status === '0') { //closed and never fetched
        $(this).attr("data-status", '1');
        $('#suggest').show();
        $(this).parent().find(".tria").show();
        $(this).parent().addClass("sel");
        $('.text', this).text(Airesis.i18n.proposals.closeContributes);
        hideLeftPanel();
        var fetched = $('<div data-section_id="' + section_id + '"class="suggestion_right"></div>');
        fetched.append('<div style="margin:auto;text-align:center;">' + Airesis.loadingImageTag + '<br/><b>' + Airesis.i18n.proposals.loadingContributes + '</b></div>');
        $('#centerpanelextended').append(fetched);
        fitRightMenu(fetched);
        $(this).next().show();
        $.ajax({
          url: ProposalsShow.rightListUrl,
          data: {
            comment_id: comment_id,
            section_id: section_id,
            disable_limit: true,
            view: Airesis.signed_in ? 1 : 3
          },
          type: 'get',
          dataType: 'script',
          complete: function() {
            return $(".loading", fetched).hide();
          },
          error: function(xhr, ajaxOptions, thrownError) {
            $(".loading", fetched).hide();
            if (xhr.status == '404') {
              return $(fetched).html(Airesis.i18n.proposals.errorLoadingParagraph);
            }
          }
        });
        $('.suggestion_right').bind('mousewheel DOMMouseScroll', function(e) {
          if (matchMedia(Foundation.media_queries['medium']).matches) {
            return Airesis.scrollLock(this, e);
          }
        });
        scrollToElement($(".proposal_main[data-section_id=" + section_id + "]"));
      } else if (this_status === '2') { //closed and fetched
        ProposalsShow.open_right_contributes($(this), comment_id);
        scrollToElement($(".proposal_main[data-section_id=" + section_id + "]"));
      } else { //status == 1  fetched and open
        if (comment_id != null) {
          var comment_ = $('#comment' + comment_id + ' .proposal_comment');
          section_id = $(this).attr("data-section_id");
          scrollToElement($(".proposal_main[data-section_id=" + section_id + "]"));
        } else {
          ProposalsShow.close_right_contributes($(this));
        }
      }
      return false;
    });
  },
  destroy_countdowns: function() {
    $('.date-creation').each(function() {
      return $(this).countdown('destroy');
    });
    $('.date-update').countdown('destroy');
    $('.end-debate').countdown('destroy');
    return $('.end-vote').countdown('destroy');
  },
  init_countdowns: function() {
    var creationDate = new Date(ProposalsShow.times.created_at * 1000);
    $('.date-creation').each(function() {
      return $(this).countdown($.extend({
        since: creationDate,
        significant: 1,
        format: 'YODHMS',
        layout: '{y<}{yn} {yl}{y>} {o<}{on} {ol}{o>} {d<}{dn} {dl}{d>} {h<}{hn} {hl}{h>} {m<}{mn} {ml}{m>}'
      }, $.countdown.regionalOptions[Airesis.i18n.locale]));
    });
    var updateDate = new Date(ProposalsShow.times.updated_at * 1000);
    $('.date-update').countdown($.extend({
      since: updateDate,
      significant: 1,
      format: 'YODHMS',
      layout: Airesis.i18n.countdown.layout2
    }, $.countdown.regionalOptions[Airesis.i18n.locale]));
    var endsDate = new Date(ProposalsShow.times.ends_at * 1000);
    $('.end-debate').countdown($.extend({
      until: endsDate,
      significant: 3,
      onExpiry: ProposalsShow.reload_page,
      description: ProposalsShow.times.descriptions.ends_at
    }, $.countdown.regionalOptions[Airesis.i18n.locale]));
    if (ProposalsShow.voting) {
      var endsVote = new Date(ProposalsShow.times.vote_ends_at * 1000);
      return $('.end-vote').countdown($.extend({
        until: endsVote,
        significant: 3,
        description: ProposalsShow.times.descriptions.vote_ends_at
      }, $.countdown.regionalOptions[Airesis.i18n.locale]));
    }
  },
  initVotePeriodSelect: function() {
    return $('#proposal_vote_period_id').select2({
      minimumResultsForSearch: -1,
      templateResult: formatPeriod,
      templateSelection: formatPeriod,
      escapeMarkup: function(m) {
        return m;
      }
    });
  }
};
