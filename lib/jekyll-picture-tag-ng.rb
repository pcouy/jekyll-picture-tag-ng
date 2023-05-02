# frozen_string_literal: true

require_relative "jekyll-picture-tag-ng/version"
require_relative "jekyll-picture-tag-ng/jekyll"
require_relative "jekyll-picture-tag-ng/kramdown"

Jekyll::Hooks.register :site, :after_init do |site|
  Kramdown::Converter::JEKYLL_SITE = site
end
