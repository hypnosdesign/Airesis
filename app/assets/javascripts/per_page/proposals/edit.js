window.ProposalsEdit = {
  integrated_contributes: [],
  safe_exit: false,
  currentPage: 0,
  currentView: 3,
  contributes: [],
  checkActive: false,
  ckedstoogle_: {},
  init: function() {
    var end_field, input, start_field, suggestion_right_;
    ProposalsEdit.integrated_contributes = [];
    this.safe_exit = false;
    window.onbeforeunload = this.check_before_exit;
    $(document).on('keyup', '.solution_main h3 .tit1 .tit2 input', function() {
      var id_ = $(this).closest('.solution_main').attr('data-solution_id');
      var title = !!$(this).val() ? $(this).val() : '&nbsp;';
      $('.navigator li[data-solution_id=' + id_ + '] span.sol_title').html(title);
    });
    $(document).on('keyup', 'input.edit_label', function() {
      var id_ = $(this).closest('.section_container').attr('data-section_id');
      $('.navigator li[data-section_id=' + id_ + '] a.sec_title').text($(this).val());
    });
    $('#menu-left, #centerpanelextended').addClass('editing');
    $('#proposal_proposal_category_id').select2({
      minimumResultsForSearch: -1,
      templateResult: formatCategory,
      templateSelection: formatCategory,
      escapeMarkup: function(m) {
        return m;
      }
    });
    start_field = $('#proposal_vote_starts_at');
    end_field = $('#proposal_vote_ends_at');
    start_field.fdatetimepicker($.fn.fdatetimepicker.dates[Airesis.i18n.locale]).on('hide', function(event) {
      var eventStartTime_ = event.date;
      end_field.fdatetimepicker('setStartDate', eventStartTime_);
      end_field.fdatetimepicker('setDate', addMinutes(eventStartTime_, 2880));
    });
    end_field.fdatetimepicker($.fn.fdatetimepicker.dates[Airesis.i18n.locale]);
    start_field.fdatetimepicker('setStartDate', ProposalsEdit.voteStartsAt);
    end_field.fdatetimepicker('setStartDate', ProposalsEdit.voteEndsAt);
    input = $('#proposal_interest_borders_tkn');
    input.tokenInput('/interest_borders.json', {
      propertyToSearch: 'text',
      crossDomain: false,
      prePopulate: input.data('pre'),
      hintText: Airesis.i18n.interestBorders.hintText,
      noResultsText: Airesis.i18n.interestBorders.noResultsText,
      searchingText: Airesis.i18n.interestBorders.searchingText,
      preventDuplicates: true
    });
    input = $('#proposal_tags_list');
    if (input) {
      input.tokenInput('/tags.json', {
        theme: 'facebook',
        crossDomain: false,
        prePopulate: ProposalsEdit.tags,
        allowFreeTagging: true,
        minChars: 3,
        hintText: Airesis.i18n.tags.hintText,
        searchingText: Airesis.i18n.tags.searchingText,
        preventDuplicates: true,
        allowTabOut: true,
        tokenValue: 'name'
      });
    }
    $('[data-add-section]').on('click', () => {
      this.addSection();
      return false;
    });
    $(document).on('click', '[data-add-solution-section]', (event) => {
      var solutionId = $(event.currentTarget).data('solution_id');
      this.addSolutionSection(solutionId);
      return false;
    });
    $('[data-add-solution]').on('click', () => {
      this.addSolution();
      return false;
    });
    $(document).on('click', '[data-remove-solution]', (event) => {
      var solutionId = $(event.currentTarget).data('solution_id');
      this.navigator.removeSolution(solutionId);
      return false;
    });
    $(Airesis.SectionContainer.selector).each(function() {
      var container = new Airesis.SectionContainer(this);
      return container.initCkEditor();
    });
    for (var name in CKEDITOR.instances) {
      ProposalsEdit.ckedstoogle_[name] = {
        first: true
      };
      var editor = CKEDITOR.instances[name];
      ProposalsEdit.addEditorEvents(editor);
    }
    $('[data-clean-fields=true]').on('click', (event) => {
      this.updateSolutionSequences();
      this.fillCleanFields();
      return this.setSubaction(event);
    });
    suggestion_right_ = $('.suggestion_right');
    fitRightMenu(suggestion_right_);
    suggestion_right_.bind('mousewheel DOMMouseScroll', function(e) {
      if (matchMedia(Foundation.media_queries['medium']).matches) {
        return Airesis.scrollLock(suggestion_right_, e);
      }
    });
    this.fetchContributes();
    $(document).on('click', '[data-integrate-contribute]', function() {
      return ProposalsEdit.integrate_contribute(this);
    });
    $(document).on('click', '[data-close-edit-right-section]', () => {
      this.hideContributes();
      return false;
    });
    $(document).on('click', '[data-update-and-exit-proposal]', function() {
      return ProposalsEdit.updateProposal();
    });
    $(document).on('click', '[data-update-proposal]', function() {
      return ProposalsEdit.updateAndContinueProposal();
    });
    return this.navigator = new Airesis.ProposalNavigator();
  },
  addEditorEvents: function(editor_) {
    editor_.on('lite:init', function(event) {
      ProposalsEdit.ckedstoogle_[event.editor.name]['first'] = false;
      var lite = event.data.lite;
      ProposalsEdit.ckedstoogle_[event.editor.name]['editor'] = lite;
      lite.toggleShow(ProposalsEdit.ckedstoogle_[event.editor.name]['state']);
      return lite.setUserInfo({
        id: Airesis.id,
        name: Airesis.fullName
      });
    });
    editor_.on('lite:showHide', function(event) {
      if (!ProposalsEdit.ckedstoogle_[event.editor.name]['first']) {
        ProposalsEdit.ckedstoogle_[event.editor.name]['state'] = event.data.show;
      }
    });
  },
  addEditor: function(id) {
    CKEDITOR.remove(CKEDITOR.instances[id]);
    var editor_ = CKEDITOR.replace(id, {
      'toolbar': 'proposal',
      'language': Airesis.i18n.locale,
      'customConfig': Airesis.assets.ckeditor.config_lite
    });
    ProposalsEdit.ckedstoogle_[id] = {
      first: true
    };
    ProposalsEdit.addEditorEvents(editor_);
  },
  setSubaction: function(event) {
    return $('[name="subaction"]').val($(event.target).data('type'));
  },
  fillCleanFields: function() {
    var integrated_ = $('#proposal_integrated_contributes_ids_list').val();
    if (ProposalsEdit.contributesCount > 0) {
      if (integrated_ === '') {
        if (!confirm(Airesis.i18n.proposals.edit.updateConfirm)) {
          return false;
        }
      }
    }
    try {
      var id;
      for (id in CKEDITOR.instances) {
        var editor = CKEDITOR.instances[id];
        var textarea_ = $('#' + id);
        var clean = ProposalsEdit.getCleanContent(id);
        var name_ = textarea_.attr('name').replace('_dirty', '').replace(/\[/g, '\\[').replace(/\]/g, '\\]');
        var target = $('[name=' + name_ + ']');
        target.val(clean);
      }
    } catch (err) {
      console.error(err);
      console.error('error in parsing ' + name_);
      return false;
    }
    $('.update2').attr('disabled', 'disabled');
    ProposalsEdit.safe_exit = true;
    return true;
  },
  integrate_contribute: function(el) {
    var id = $(el).data('integrate-contribute');
    var comment_ = $('#comment' + id);
    var inside_ = comment_.find('.proposal_comment');
    if ($(el).is(':checked')) {
      ProposalsEdit.integrated_contributes.push(id);
      comment_.fadeTo(400, 0.3);
      inside_.attr('data-height', inside_.outerHeight());
      inside_.css('overflow', 'hidden');
      inside_.animate({
        height: '52px'
      }, 400);
      comment_.find('[id^=reply]').each(function() {
        $(this).attr('data-height', $(this).outerHeight());
        $(this).css('overflow', 'hidden');
        return $(this).animate({
          height: '0px'
        }, 400);
      });
    } else {
      ProposalsEdit.integrated_contributes.splice(ProposalsEdit.integrated_contributes.indexOf(id), 1);
      comment_.fadeTo(400, 1);
      inside_.animate({
        height: inside_.attr('data-height')
      }, 400, 'swing', function() {
        return inside_.css('overflow', 'auto');
      });
      comment_.find('[id^=reply]').each(function() {
        return $(this).animate({
          height: $(this).attr('data-height')
        }, 400, 'swing', function() {
          return $(this).css('overflow', 'auto');
        });
      });
    }
    $('#proposal_integrated_contributes_ids_list').val(ProposalsEdit.integrated_contributes);
  },
  fetchContributes: function() {
    ProposalsEdit.currentPage++;
    return $.ajax({
      url: ProposalsEdit.contributesUrl,
      data: {
        disable_limit: true,
        page: ProposalsEdit.currentPage,
        view: ProposalsEdit.currentView,
        contributes: ProposalsEdit.contributes,
        all: true
      },
      type: 'get',
      dataType: 'script',
      complete: function() {
        return $('#loading_contributes').hide();
      }
    });
  },
  hideContributes: function() {
    var right_ = $('.suggestion_right');
    if (right_.hasClass('contributes_shown')) {
      right_.removeClass('contributes_shown');
      right_.hide();
      $('#centerpanelextended').removeClass('contributes_shown');
      $('#menu-left').removeClass('contributes_shown');
    } else {
      right_.addClass('contributes_shown');
      right_.show();
      $('#centerpanelextended').addClass('contributes_shown');
      $('#menu-left').addClass('contributes_shown');
    }
    var contributesButton = $('.contributes:visible');
    switchText(contributesButton);
    return false;
  },
  updateProposal: function() {
    if ($('.update2').attr('disabled') !== 'disabled') {
      $("form input:submit[data-type='save']").click();
    }
    return false;
  },
  updateAndContinueProposal: function() {
    if ($('.update3').attr('disabled') !== 'disabled') {
      $('form input:submit[data-type=\'continue\']').click();
    }
    return false;
  },
  scrollToSection: function(el) {
    scrollToElement($('.section_container[data-section_id=' + $(el).parent().parent().attr('data-section_id') + ']'));
    return false;
  },
  toggleSolutions: function(compress) {
    $('.solution_main').each(function() {
      var solution = new Airesis.SolutionContainer($(this));
      return solution.toggle(compress);
    });
    return false;
  },
  check_before_exit: function() {
    if (!ProposalsEdit.safe_exit) {
      return 'Tutte le modifiche alla proposta andranno perse.';
    }
  },
  getCleanContent: function(editor_id) {
    var editor = CKEDITOR.instances[editor_id];
    return editor.plugins.lite.findPlugin(editor)._tracker.getCleanContent();
  },
  calculateDataId: function(i, j) {
    return ((i + 1) * 100) + j;
  },
  updateSequences: function() {
    return $('.sections_column, .solutions_column').each(function() {
      var i = 0;
      return $(this).find(Airesis.SectionContainer.selector).each(function() {
        var section = new Airesis.SectionContainer($(this));
        return section.setSeq(i++);
      });
    });
  },
  updateSolutionSequences: function() {
    var i = 0;
    return $('.solution_main').each(function() {
      var solution = new Airesis.SolutionContainer($(this));
      return solution.setSeq(i++);
    });
  },
  addSection: function() {
    var title = Airesis.i18n.proposals.edit.paragraph + ' ' + (ProposalsEdit.sectionsCount + 1);
    var sectionId = ProposalsEdit.sectionsCount;
    var section = $(Mustache.render($('#section_template').html(), {
      section: {
        id: sectionId,
        seq: sectionId + 1,
        removeSection: Airesis.i18n.proposals.edit.removeSection,
        title: title,
        paragraphId: '',
        content: '',
        contentDirty: '',
        persisted: false
      }
    }));
    $('.sections_column').append(section);
    section.fadeIn();
    new Airesis.SectionContainer(section).initCkEditor();
    this.navigator.addSectionNavigator(sectionId, title);
    ProposalsEdit.sectionsCount += 1;
  },
  addSolutionSection: function(solutionId) {
    var sectionId = ProposalsEdit.numSolutionSections[solutionId];
    var title = Airesis.i18n.proposals.edit.paragraph + ' ' + (sectionId + 1);
    var dataId = ProposalsEdit.calculateDataId(parseInt(solutionId), sectionId);
    var solutionSection = $(Mustache.render($('#solution_section_template').html(), {
      section: {
        idx: sectionId,
        data_id: dataId,
        seq: sectionId + 1,
        removeSection: Airesis.i18n.proposals.edit.removeSection,
        title: title,
        paragraphId: '',
        content: '',
        contentDirty: '',
        persisted: false
      },
      solution: {
        id: solutionId
      }
    }));
    $(".solutions_column[data-solution_id=" + solutionId + "]").append(solutionSection);
    $(".solution_main[data-solution_id=" + solutionId + "]").css('height', '');
    solutionSection.fadeIn();
    new Airesis.SectionContainer(solutionSection).initCkEditor();
    this.navigator.addSolutionSectionNavigator(solutionId, dataId, title);
    return ProposalsEdit.numSolutionSections[solutionId] += 1;
  },
  addSolution: function() {
    jQuery.each(ProposalsEdit.mustacheSections, function(idx, section) {
      section['solution']['id'] = ProposalsEdit.solutionsCount;
      return section['section']['data_id'] = ProposalsEdit.calculateDataId(ProposalsEdit.solutionsCount, section['section']['idx']);
    });
    var options = {
      solution: {
        id: ProposalsEdit.solutionsCount,
        seq: ProposalsEdit.fakeSolutionsCount,
        persisted: true,
        title_placeholder: Airesis.i18n.proposals.edit.titlePlaceholder,
        solution_title: Airesis.i18n.proposals.edit.solutionTitle,
        title: '',
        removeSolution: Airesis.i18n.proposals.edit.removeSolution,
        addParagraph: Airesis.i18n.proposals.edit.addParagraph,
        sections: ProposalsEdit.mustacheSections
      }
    };
    var solution = $(Mustache.render($('#solution_template').html(), options, {
      'proposals/_solution_section': $('#solution_section_template').html()
    }));
    solution.find('.title_placeholder .num').html(ProposalsEdit.fakeSolutionsCount + 1);
    $("[data-hook='new-solution']").before(solution);
    solution.fadeIn();
    solution.find(Airesis.SectionContainer.selector).each(function(idx, section) {
      return new Airesis.SectionContainer(section).initCkEditor();
    });
    this.navigator.addSolutionNavigator(ProposalsEdit.solutionsCount);
    ProposalsEdit.numSolutionSections[ProposalsEdit.solutionsCount] = solution.find('.section_container').length;
    ProposalsEdit.solutionsCount++;
    return ProposalsEdit.fakeSolutionsCount++;
  },
  geocode_panel: function() {}
};

window.ProposalsUpdate = window.ProposalsEdit;
