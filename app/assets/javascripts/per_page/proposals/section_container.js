Airesis.SectionContainer = class SectionContainer {
  static selector = '.section_container';

  constructor(param) {
    if (param instanceof HTMLElement) {
      this.element = $(param);
    } else if (param instanceof jQuery) {
      this.element = param;
    } else {
      this.element = $(Airesis.SectionContainer.selector).filter(`[data-section_id=${param}]`);
    }
    this.id = this.element.data('section_id');
    this.seqField = this.element.find("[data-section-seq]");
    this.titleField = this.element.find("[name$='[title]']");
    this.title = this.titleField.val();
    this.destroyField = this.element.find("[data-section-destroy]");
    this.editor = this.element.find("textarea[name$='[content_dirty]']");
  }

  persisted() {
    return this.element.data('persisted');
  }

  destroyCkEditor() {
    return CKEDITOR.instances[this.editor.attr('id')].destroy();
  }

  initCkEditor() {
    var editor_ = CKEDITOR.replace(this.editor.attr('id'), {
      'toolbar': 'proposal',
      'language': Airesis.i18n.locale,
      'customConfig': Airesis.assets.ckeditor.config_lite
    });
    return this.addEditorEvents(editor_);
  }

  addEditorEvents(editor_) {
    editor_.on('lite:init', function(event) {
      var lite = event.data.lite;
      lite.toggleShow(true); // TODO
      return lite.setUserInfo({
        id: Airesis.id,
        name: Airesis.fullName
      });
    });
    editor_.on('lite:showHide', function(event) {});
  }

  exchange(toExchange, action) {
    var toExchangeContainer = new Airesis.SectionContainer(toExchange);
    toExchangeContainer.destroyCkEditor();
    this.destroyCkEditor();
    action.apply();
    this.initCkEditor();
    toExchangeContainer.initCkEditor();
    return ProposalsEdit.updateSequences();
  }

  moveUp() {
    var toExchange = this.element.prevAll(Airesis.SectionContainer.selector).first();
    return this.exchange(toExchange, () => {
      return this.element.after(toExchange);
    });
  }

  moveDown() {
    var toExchange = this.element.nextAll(Airesis.SectionContainer.selector).first();
    return this.exchange(toExchange, () => {
      return this.element.before(toExchange);
    });
  }

  remove() {
    if (confirm(Airesis.i18n.proposals.edit.removeSectionConfirm)) {
      if (this.persisted()) {
        this.destroyField.val(1);
        this.element.fadeOut();
      } else {
        this.element.fadeOut(() => {
          return this.element.remove();
        });
      }
      ProposalsEdit.updateSequences();
      return true;
    } else {
      return false;
    }
  }

  setSeq(val) {
    return this.seqField.val(val);
  }
};
