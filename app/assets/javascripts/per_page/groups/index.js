window.GroupsIndex = {
  init: function() {
    GroupsIndex.everPushedSomething = false;
    GroupsIndex.initialUrl = location.href;
    this.initInterestBorder();
    $(window).bind('popstate', function(event) {
      var onloadPop = !GroupsIndex.everPushedSomething && location.href === GroupsIndex.initialUrl;
      GroupsIndex.everPushedSomething = true;
      if (onloadPop) {
        return;
      }
      $.getScript(addQueryParam(location.href, 'back', 'true'));
    });
    return this.initSwitchButtons();
  },
  checkCharacters: function() {
    if ($('#search').val().length > 2 || $('#interest_border').val() !== '') {
      return true;
    } else {
      alert(Airesis.i18n.groups.queryOrPlace);
      return false;
    }
  },
  initSwitchButtons: function() {
    $('#area').switchButton({
      checked: GroupsIndex.areaParam,
      on_label: $('<div class="switch_opt s_circle"></div>'),
      off_label: $('<div class="switch_opt s_circle"><div class="i_circle"></div></div>'),
      on_title: Airesis.i18n.groups.exactBorder,
      off_title: Airesis.i18n.groups.areaBorder
    });
    $('#and').switchButton({
      checked: GroupsIndex.andParam,
      on_label: $('<div class="switch_opt">&</div>'),
      off_label: $('<div class="switch_opt">||</div>'),
      on_title: Airesis.i18n.groups.allWords,
      off_title: Airesis.i18n.groups.oneWord
    });
    return $('.switch-button-label.on, .switch-button-label.off').qtip({
      prerender: true,
      position: {
        at: 'top center',
        my: 'bottom center',
        viewport: $(window),
        effect: false
      },
      style: {
        classes: 'qtip-dark'
      }
    });
  },
  initInterestBorder: function() {
    var input = $('#interest_border');
    return input.tokenInput("/interest_borders.json", {
      propertyToSearch: 'text',
      crossDomain: false,
      prePopulate: input.data("pre"),
      hintText: Airesis.i18n.interestBorders.hintText,
      noResultsText: Airesis.i18n.interestBorders.noResultsText,
      searchingText: Airesis.i18n.interestBorders.searchingText,
      preventDuplicates: true,
      tokenLimit: 1,
      allowTabOut: true
    });
  }
};
