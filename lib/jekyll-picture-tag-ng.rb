# frozen_string_literal: true

require "jekyll"
require "kramdown"
require_relative "jekyll-picture-tag-ng/version"

module Jekyll
  # Override default static file to make some instance variables readable
  class StaticFile
    attr_reader :site, :dest, :dir, :name
  end

  module PictureTag
    CONFIG = {
      "picture_versions" => {
        "s" => "400",
        "m" => "700"
      },
      "background_color" => "FFFFFF"
    }.freeze

    class Error < StandardError; end

    # Class that holds generated variants of pictures
    class OutImageFile < StaticFile
      def initialize(site, orig_static_file, version, pictype)
        super(site, site.source, orig_static_file.dir, orig_static_file.name)
        @version = version
        @picture_dim = picture_versions[@version]
        @pictype = pictype
        @collection = nil
      end

      def config
        @config ||= CONFIG.merge(@site.config["picture_tag_ng"] || {})
      end

      def picture_versions
        config["picture_versions"]
      end

      def picture?
        extname =~ /(\.jpg|\.jpeg|\.webp)$/i
      end

      def destination(dest)
        output_dir = File.join("img", @version, @dir)
        output_basename = @site.in_dest_dir(@site.dest, File.join(output_dir, "#{basename}.#{@pictype}"))
        FileUtils.mkdir_p(File.dirname(output_dir))
        @destination ||= {}
        @destination[dest] ||= output_basename
      end

      def write(*args)
        Jekyll.logger.debug "write : #{args} Modified : #{modified?}"
        super(*args)
      end

      def popen_args(dest_path)
        args = ["convert", @path, "-resize", "#{@picture_dim}x>"]
        if @pictype == "jpg"
          args.concat ["-background", "##{@config["background_color"]}",
                       "-flatten", "-alpha", "off"]
        end
        args.push dest_path
      end

      def copy_file(dest_path)
        Jekyll.logger.debug "copy_file : #{path} -> #{dest_path}"
        p = IO.popen(popen_args(dest_path))
        p.close
        File.utime(self.class.mtimes[path], self.class.mtimes[path], dest_path)
      end
    end

    # Will generate the picture variants
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

Jekyll::Hooks.register :site, :after_init do |site|
  Kramdown::Converter::JEKYLL_SITE = site
end

module Kramdown
  module Parser
    # Override Kramdown parser
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

  module Converter
    # Override Kramdown HTML converter
    class Html
      def site_config
        @site_config ||= Jekyll::PictureTag::CONFIG.merge(JEKYLL_SITE.config["picture_tag_ng"] || {})
      end

      def picture_versions
        site_config["picture_versions"]
      end

      def convert_img(el, _indent)
        require "cgi"
        res = "<picture>"
        new_src = el.attr["src"]
        if File.extname(el.attr["src"]) =~ /(\.jpg|\.jpeg|\.webp)$/i
          picture_versions.each_with_index do |(version, geometry), index|
            src_base = File.join(
              "/img",
              version,
              File.dirname(el.attr["src"]).split("/").map do |x|
                x.gsub(" ", "%20")
              end.join("/"),
              File.basename(el.attr["src"], File.extname(el.attr["src"])).gsub(" ", "%20")
            )
            if index == picture_versions.size - 1
              media = ""
              new_src = "#{src_base}.jpg"
            else
              media = "media=\"(max-width: #{geometry}px)\""
            end
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
