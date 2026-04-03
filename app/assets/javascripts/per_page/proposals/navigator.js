Airesis.ProposalNavigator = class ProposalNavigator {
  constructor() {
    this.navigators = $('.navigator');
    this.solution_navigators = this.navigators.find('.sol_nav');
    this.section_navigators = this.navigators.find('.sec_nav');
    this.solution_section_navigators = this.navigators.find('.sec_nav.sol');
    this.move_up_selector = '.move_up';
    this.move_down_selector = '.move_down';
    this.remove_selector = '.remove';
    $(document).on('click', '[data-scroll-to-section]', function() {
      return ProposalsEdit.scrollToSection(this);
    });
    this.solution_navigators.on('click', function(event) {
      if (this === event.target) {
        $(this).toggleClass('expanded');
        $(this).children('ul').toggle();
        var solution = new Airesis.SolutionContainer($(this).data('solution_id'));
        return solution.toggle(!solution.element.data('compressed'));
      }
    });
    $('[data-navigator-expand]').click(() => {
      return this.toggleSolutionNavigators(true);
    });
    $('[data-navigator-collapse]').click(() => {
      return this.toggleSolutionNavigators(false);
    });
    // sections navigator
    this.navigators.on('click', `.sec_nav:not(.sol) ${this.move_up_selector}`, (event) => {
      return this.moveUpSection($(event.currentTarget));
    });
    this.navigators.on('click', `.sec_nav:not(.sol) ${this.move_down_selector}`, (event) => {
      return this.moveDownSection($(event.currentTarget));
    });
    this.navigators.on('click', `.sec_nav:not(.sol) ${this.remove_selector}`, (event) => {
      return this.removeSection($(event.currentTarget));
    });
    // solution sections navigator
    this.navigators.on('click', `.sec_nav.sol ${this.move_up_selector}`, (event) => {
      return this.moveUpSection($(event.currentTarget));
    });
    this.navigators.on('click', `.sec_nav.sol ${this.move_down_selector}`, (event) => {
      return this.moveDownSection($(event.currentTarget));
    });
    this.navigators.on('click', `.sec_nav.sol ${this.remove_selector}`, (event) => {
      return this.removeSection($(event.currentTarget));
    });
    // solutions navigator
    this.navigators.on('click', ".sol_nav .sol.move_up", (event) => {
      return this.moveUpSolution($(event.currentTarget));
    });
    this.navigators.on('click', ".sol_nav .sol.move_down", (event) => {
      return this.moveDownSolution($(event.currentTarget));
    });
    this.navigators.on('click', ".sol_nav .sol.remove", (event) => {
      return this.removeSolution($(event.currentTarget).parent().data('solution_id'));
    });
  }

  collapsed_solution_navigators() {
    return this.solution_navigators.filter('.collapsed');
  }

  toggleSolutionNavigators(expand) {
    this.collapsed_solution_navigators().toggleClass('expanded', expand);
    this.collapsed_solution_navigators().children('ul').toggle(expand);
    return ProposalsEdit.toggleSolutions(!expand);
  }

  getSectionActionSubject(list_element) {
    var section_id = list_element.data('section_id');
    return new Airesis.SectionContainer(section_id);
  }

  getSolutionActionSubject(list_element) {
    var solution_id = list_element.data('solution_id');
    return new Airesis.SolutionContainer(solution_id);
  }

  moveDownNavigatorElement(list_element) {
    var list_element_ex = list_element.next();
    return list_element.before(list_element_ex);
  }

  moveUpNavigatorElement(list_element) {
    var list_element_ex = list_element.prev();
    return list_element.after(list_element_ex);
  }

  moveUpSection(section) {
    var list_element = section.parent();
    this.moveUpNavigatorElement(list_element);
    var to_move = this.getSectionActionSubject(list_element);
    return to_move.moveUp();
  }

  moveDownSection(section) {
    var list_element = section.parent();
    this.moveDownNavigatorElement(list_element);
    var to_move = this.getSectionActionSubject(list_element);
    return to_move.moveDown();
  }

  removeSection(section) {
    var list_element = section.parent();
    var to_remove = this.getSectionActionSubject(list_element);
    if (to_remove.remove()) {
      return list_element.remove();
    }
  }

  moveUpSolution(solution) {
    var list_element = solution.parent();
    this.moveUpNavigatorElement(list_element);
    var to_move = this.getSolutionActionSubject(list_element);
    return to_move.moveUp();
  }

  moveDownSolution(solution) {
    var list_element = solution.parent();
    this.moveDownNavigatorElement(list_element);
    var to_move = this.getSolutionActionSubject(list_element);
    return to_move.moveDown();
  }

  removeSolution(solutionId) {
    var toRemove = new Airesis.SolutionContainer(solutionId);
    if (toRemove.remove()) {
      return this.solution_navigators.filter(`[data-solution_id=${solutionId}]`).remove();
    }
  }

  addSectionNavigator(i, title) {
    var section_navigator = $(Mustache.render($('#section_navigator_template').html(), {
      i: i,
      title: title
    }));
    var nav_ = $('.navigator .sec_nav:not(.sol)').last();
    return nav_.after(section_navigator);
  }

  addSolutionSectionNavigator(solutionId, i, title) {
    var solution_section_navigator = $(Mustache.render($('#section_navigator_template').html(), {
      classes: 'sol',
      i: i,
      title: title
    }));
    var nav_ = $('.navigator li[data-solution_id=' + solutionId + ']');
    return nav_.find('.sub_navigator').append(solution_section_navigator);
  }

  addSolutionNavigator(solutionId) {
    var sections = [];
    var solution = new Airesis.SolutionContainer(solutionId);
    for (var section of solution.sections) {
      var sectionContainer = new Airesis.SectionContainer(section);
      sections.push({
        id: sectionContainer.id,
        title: sectionContainer.title,
        classes: 'sol'
      });
    }
    var solution_navigator = $(Mustache.render($('#solution_navigator_template').html(), {
      classes: 'sol',
      i: solutionId,
      title: '&nbsp;',
      sections: sections
    }, {
      'proposals/_section_navigator': $('#section_navigator_template').html()
    }));
    return $('.navigator.navsolutions').append(solution_navigator);
  }
};
