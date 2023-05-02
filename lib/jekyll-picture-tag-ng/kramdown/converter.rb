# frozen_string_literal: true

require "kramdown"
require_relative "../jekyll/picture_tag"

module Kramdown
  module Converter
    # Override Kramdown HTML converter to output picture tags
    class Html
      def site_config
        @site_config ||= Jekyll::PictureTag::CONFIG.merge(JEKYLL_SITE.config["picture_tag_ng"] || {})
      end

      def picture_versions
        site_config["picture_versions"]
      end

      def _get_default_pic_version
        largest_version = ""
        largest_size = 0
        picture_versions.each do |version, geometry|
          size = if geometry.is_a?(Integer)
                   geometry
                 elsif geometry["default"]
                   999_999_999
                 else
                   geometry["out_size"]
                 end
          if size > largest_size
            largest_version = version
            largest_size = size
          end
        end
        largest_version
      end

      def default_pic_version
        @default_pic_version ||= _get_default_pic_version
      end

      def media_attribute(version)
        geometry = picture_versions[version]
        if geometry.is_a?(Hash)
          if geometry["media"].is_a?(String)
            "media=\"#{geometry["media"]}\""
          elsif geometry["media"].is_a?(Integer)
            "media=\"(max-width: #{geometry["media"]}px)\""
          else
            "media=\"(max-width: #{geometry["out_size"]}px)\""
          end
        else
          "media=\"(max-width: #{geometry}px)\""
        end
      end

      def convert_img(el, _indent)
        require "cgi"
        res = "<picture>"
        new_src = el.attr["src"]
        if File.extname(el.attr["src"]) =~ /(\.jpg|\.jpeg|\.webp)$/i &&
           el.attr["src"] !~ %r{^https?://}
          picture_versions.each do |version, _geometry|
            src_base = File.join(
              "/img",
              version,
              File.dirname(el.attr["src"]).split("/").map do |x|
                x.gsub(" ", "%20")
              end.join("/"),
              File.basename(el.attr["src"], File.extname(el.attr["src"])).gsub(" ", "%20")
            )
            media = media_attribute(version)
            new_src = "#{src_base}.jpg" if version == default_pic_version
            res += "<source #{media} srcset=\"#{src_base}.webp\" type=\"image/webp\">"
            res += "<source #{media} srcset=\"#{src_base}.jpg\" type=\"image/jpeg\">"
          end
        end
        el.attr["src"] = new_src
        res += "<img#{html_attributes(el.attr)}>"
        res += "</picture>"
      end
    end
  end
end
