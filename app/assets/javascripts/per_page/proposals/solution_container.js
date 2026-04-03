Airesis.SolutionContainer = class SolutionContainer {
  static selector = '.solution_main';

  constructor(id) {
    if (id instanceof jQuery) {
      this.element = id;
      this.id = this.element.data('solution_id');
    } else {
      this.element = $(Airesis.SolutionContainer.selector).filter(`[data-solution_id='${id}']`);
      this.id = id;
    }
    this.destroyField = this.element.find("[data-solution-destroy]");
    this.seqField = this.element.find(`[name='proposal[solutions_attributes][${this.id}][seq]']`);
    this.titleField = this.element.find(`[name$='proposal[solutions_attributes][${this.id}][title]']`);
    this.sections = this.element.find(Airesis.SectionContainer.selector);
  }

  persisted() {
    return this.element.data('persisted');
  }

  moveUp() {
    var to_exchange = this.element.prevAll(Airesis.SolutionContainer.selector).first();
    this.element.after(to_exchange);
    return ProposalsEdit.updateSolutionSequences();
  }

  moveDown() {
    var to_exchange = this.element.nextAll(Airesis.SolutionContainer.selector).first();
    this.element.before(to_exchange);
    return ProposalsEdit.updateSolutionSequences();
  }

  remove() {
    if (confirm(Airesis.i18n.proposals.edit.removeSolutionConfirm)) {
      if (this.persisted()) {
        this.destroyField.val(1);
        this.element.fadeOut();
      } else {
        this.element.fadeOut(() => {
          return this.element.remove();
        });
      }
      this.element.nextUntil(null, Airesis.SolutionContainer.selector).each(function() {
        var sol_id = $(this).attr('data-solution_id');
        var seqel_ = $('[name^=\'proposal[solutions_attributes][' + sol_id + '][seq]\']');
        var seq_ = parseInt(seqel_.val());
        return $(this).find('.title_placeholder .num').html(seq_ - 1);
      });
      ProposalsEdit.fakeSolutionsCount--;
      ProposalsEdit.updateSolutionSequences();
      return true;
    } else {
      return false;
    }
  }

  setSeq(val) {
    return this.seqField.val(val);
  }

  isCompressed() {
    return this.element.data('compressed') === true;
  }

  toggle(compress) {
    if (this.element.is(':animated')) {
      return false;
    }
    if (compress) {
      return this.hide();
    } else {
      return this.show();
    }
  }

  show() {
    var duration = 500;
    var easing = 'swing';
    if (this.element.is(':animated')) {
      return false;
    }
    if (this.isCompressed()) {
      this.element.data('compressed', false);
      this.element.animate({
        'height': this.element.attr('data-height')
      }, duration, easing);
      return this.element.find('.sol_content').show();
    }
  }

  hide() {
    var duration = 500;
    var easing = 'swing';
    var toggleMinHeight = 100;
    if (this.element.is(':animated')) {
      return false;
    }
    if (!this.isCompressed()) {
      this.element.data('compressed', true);
      this.element.attr('data-height', this.element.height());
      this.element.find('.sol_content').hide();
      return this.element.animate({
        'height': toggleMinHeight
      }, duration, easing);
    }
  }
};
