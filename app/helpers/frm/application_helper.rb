module Frm
  module ApplicationHelper
    include FormattingHelper
    # processes text with installed markup formatter
    def forem_format(text, *_options)
      text
    end

    def forem_quote(text)
      as_quoted_text(text)
    end

    def forem_pages_widget(pagy)
      pagy_nav(pagy) if pagy.pages > 1
    end
  end
end
