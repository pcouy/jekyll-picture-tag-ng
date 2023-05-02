# frozen_string_literal: true

require "kramdown"

module Kramdown
  module Parser
    # Override Kramdown parser to add `loading="lazy"` to images
    class Kramdown
      def add_link(el, href, title, alt_text = nil, ial = nil)
        el.options[:ial] = ial
        update_attr_with_ial(el.attr, ial) if ial
        if el.type == :a
          el.attr["href"] = href
        else
          el.attr["src"] = href
          el.attr["alt"] = alt_text
          el.attr["loading"] = el.attr["loading"] || "lazy"
          el.children.clear
        end
        el.attr["title"] = title if title
        @tree.children << el
      end

      require "kramdown/parser/kramdown"
    end
  end
end
