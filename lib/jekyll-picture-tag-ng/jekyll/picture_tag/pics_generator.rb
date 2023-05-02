# frozen_string_literal: true

require_relative "out_image_file"

module Jekyll
  module PictureTag
    # Adds `OutImageFile` instances to the site's static files
    class PicsGenerator < Generator
      safe true
      priority :lowest

      def generate(site)
        @config ||= CONFIG.merge(site.config["picture_tag_ng"] || {})
        @picture_versions = @config["picture_versions"]
        new_statics = []
        site.static_files.filter { |f| f.extname =~ /(\.jpg|\.jpeg|\.webp)$/i }.each do |f|
          @config["picture_versions"].each do |v, _s|
            img_f = OutImageFile.new(site, f, v, "jpg")
            new_statics << img_f
            img_f = OutImageFile.new(site, f, v, "webp")
            new_statics << img_f
          end
        end

        new_statics.each { |f| site.static_files << f }
      end
    end
  end
end
