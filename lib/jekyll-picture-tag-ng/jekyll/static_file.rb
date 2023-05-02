# frozen_string_literal: true

require "jekyll"

module Jekyll
  # Override default static file to make some instance variables readable
  class StaticFile
    attr_reader :site, :dest, :dir, :name
  end
end
