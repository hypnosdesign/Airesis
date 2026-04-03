Airesis.ProposalVotationManager = class ProposalVotationManager {
  constructor() {
    this._initSolutionScrollAndTips();
    this._initSchulzeVoteButton();
    this._initVoteButton();
    this._initSortable();
  }

  _initVoteButton() {
    return $('.votebutton').on('click', function() {
      var message, type;
      type = $(this).data('vote-type');
      message = type === Airesis.i18n.proposals.vote.positive ? Airesis.i18n.proposals.vote.confirm_positive : type === Airesis.i18n.proposals.vote.neutral ? Airesis.i18n.proposals.vote.confirm_neutral : Airesis.i18n.proposals.vote.confirm_negative;
      if (confirm(message)) {
        $('#data_vote_type').val(type);
        $('.votebutton').fadeOut();
        $('.vote_panel form').fadeOut();
        $('.loading_vote').show();
        $('.vote_panel form').submit();
      }
      return false;
    });
  }

  _initSchulzeVoteButton() {
    return $('#schulze-submit').on('click', () => {
      var votestring = '';
      $('.vote-items').each(function(c_id, cont) {
        var items = $(cont).find('.vote-item');
        if (!items.length) {
          return true;
        }
        if (votestring !== '') {
          votestring += ';';
        }
        return items.each(function(item_id, item) {
          if (item_id !== 0) {
            votestring += ',';
          }
          return votestring += $(item).data('id');
        });
      });
      $('#data_votes').val(votestring);
      return true;
    });
  }

  _initSolutionScrollAndTips() {
    return $('.vote_solution_title').each(function() {
      $(this).on('click', function() {
        scrollToElement($('.solution_main[data-solution_id=' + $(this).parent().data('id') + ']'));
        return false;
      });
      return $(this).qtip({
        content: $('.proposal_content[data-id=' + $(this).parent().data('id') + ']').clone()
      });
    });
  }

  _initSortable() {
    return $('.vote-items').each((id, el) => {
      this._checkBoxSiblings($(el).parent());
      return this._initSortableBox(el);
    });
  }

  _checkBoxSiblings(to) {
    var box, next_box, prev_box;
    next_box = to.nextAll('.vote-items-external');
    prev_box = to.prevAll('.vote-items-external');
    if (next_box.length) {
      this._destroyBoxes(next_box);
    } else {
      box = this._buildBox();
      to.after(box);
      this._initSortableBox(box.find('.vote-items')[0]);
    }
    if (prev_box.length) {
      this._destroyBoxes(prev_box);
    } else {
      box = this._buildBox();
      to.before(box);
      this._initSortableBox(box.find('.vote-items')[0]);
    }
    return this._countBoxes();
  }

  _initSortableBox(el) {
    return Sortable.create(el, {
      group: 'vote',
      animation: 150,
      onAdd: (event) => {
        var to = $(event.to).parent();
        return this._checkBoxSiblings(to);
      }
    });
  }

  _buildBox() {
    var box, extBox;
    extBox = $('<div>').attr('class', 'vote-items-external');
    extBox.append('<span class="label primary">');
    box = $('<div>').attr('class', 'vote-items');
    extBox.append(box);
    return extBox;
  }

  _destroyBoxes(boxes) {
    var firstBox = true;
    return boxes.each(function(id, box) {
      var items = $(box).find('.vote-items').find('.vote-item');
      if (items.length) {
        return firstBox = true;
      } else {
        if (firstBox) {
          firstBox = false;
          return true;
        } else {
          return $(box).remove();
        }
      }
    });
  }

  _countBoxes() {
    var bottom, boxes, top;
    boxes = $('.vote-items-external');
    top = $(boxes.get(-1)).find('.label').html('-');
    boxes.splice(boxes.length - 1, 1);
    bottom = $(boxes.get(0)).find('.label').html('+');
    boxes.splice(0, 1);
    return boxes.each(function(id, box) {
      return $(box).find('.label').html(id + 1);
    });
  }
};
