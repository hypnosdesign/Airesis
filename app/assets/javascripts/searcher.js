Airesis.Searcher = class Searcher {
  searchcache = {};

  constructor() {
    var search_f = $('#search_q');
    if (!(search_f.length > 0)) {
      return;
    }
    search_f.autocomplete({
      minLength: 1,
      source: (request, response) => {
        var term = request.term;
        if (term in this.searchcache) {
          response(this.searchcache[term]);
        }
        return $.getJSON('/searches', request, (data, status, xhr) => {
          this.searchcache[term] = data;
          return response(data);
        });
      },
      focus: function(event, ui) {
        return event.preventDefault();
      },
      select: function(event, ui) {
        window.location.href = ui.item.url;
        return event.preventDefault();
      }
    });
    search_f.data('uiAutocomplete')._renderMenu = function(ul, items) {
      var that = this;
      $.each(items, function(index, item) {
        if (item.type === 'Divider') {
          ul.append($('<li class=\'ui-autocomplete-category\'>' + item.value + '</li>'));
        } else {
          that._renderItemData(ul, item);
        }
      });
      return $(ul).addClass('f-dropdown').addClass('medium').css('z-index', 1005).css('width', '400px');
    };
    search_f.data('uiAutocomplete')._renderItem = function(ul, item) {
      var container_, desc_, el, image_, link_, text_;
      el = $('<li>');
      link_ = $('<a></a>');
      container_ = $('<div class="search_result_container"></div>');
      image_ = $('<div class="search_result_image"></div>');
      container_.append(image_);
      desc_ = $('<div class="search_result_description"></div>');
      desc_.append('<div class="search_result_title">' + item.label + '</div>');
      text_ = $('<div class="search_result_text">' + '</div>');
      if (item.type === 'Blog') {
        image_.append(item.image);
        text_.append('<a href="' + item.user_url + '">' + item.username + '</a>');
      } else if (item.type === 'Group') {
        text_.append('<div class="groupDescription"><img src="' + Airesis.assets.group_participants + '"><span class="count">' + item.participants_num + '</span></div>');
        text_.append('<div class="groupDescription"><img src="' + Airesis.assets.group_proposals + '"><span class="count">' + item.proposals_num + '</span></div>');
        image_.append('<img src="' + item.image + '"/>');
      } else {
        image_.append('<img src="' + item.image + '"/>');
      }
      desc_.append(text_);
      container_.append(desc_);
      container_.append('<div class="clearboth"></div>');
      link_.attr('href', item.url);
      link_.append(container_);
      el.append(link_);
      el.appendTo(ul);
      return el;
    };
    return search_f.on('keypress', function(e) {
      var code = e.keyCode ? e.keyCode : e.which;
      if (code === 13) {
        return false;
      }
    });
  }
};
