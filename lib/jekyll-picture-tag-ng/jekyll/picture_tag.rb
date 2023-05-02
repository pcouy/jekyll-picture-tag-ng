# frozen_string_literal: true

require_relative "static_file"
require_relative "picture_tag/pics_generator"

module Jekyll
  class Error < StandardError; end

  module PictureTag
    CONFIG = {
      "picture_versions" => {
        "s" => "400",
        "m" => "700"
      },
      "background_color" => "FFFFFF",
      "extra_convert_args" => [],
      "replace_convert_args" => false
    }.freeze
  end
end
