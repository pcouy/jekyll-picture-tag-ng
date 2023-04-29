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
      "background_color" => "FFFFFF",
      "extra_convert_args" => [],
      "replace_convert_args" => false
    }.freeze

    class Error < StandardError; end

    # Class that holds generated variants of pictures
    class OutImageFile < StaticFile
      def initialize(site, orig_static_file, version, pictype)
        super(site, site.source, orig_static_file.dir, orig_static_file.name)
        @version = version
        @picture_dim = if picture_versions[@version].is_a?(Hash)
                         picture_versions[@version]["out_size"]
                       else
                         picture_versions[@version]
                       end
        @pictype = pictype
        @collection = nil
      end

      def config
        @config ||= CONFIG.merge(@site.config["picture_tag_ng"] || {})
      end

      def replace_args
        result = config["replace_convert_args"]
        if picture_versions[@version].is_a?(Hash) &&
           !picture_versions[@version]["replace_convert_args"].nil?
          result = picture_versions[@version]["replace_convert_args"]
        end
        result
      end

      def picture_versions
        config["picture_versions"]
      end

      def as_args(input)
        if input.nil?
          []
        elsif input.is_a?(Array)
          input.clone
        elsif input.is_a?(String)
          input.split(" ")
        else
          raise(
            TypeError,
            "[jekyll-picture-tag-ng] `extra_convert_args` must be an array or a string (#{input})"
          )
        end
      end

      def convert_args
        @convert_args ||= as_args(config["extra_convert_args"]).concat(
          picture_versions[@version].is_a?(Hash) &&
          picture_versions[@version]["extra_convert_args"] || []
        )
      end

      def pre_convert_args
        @pre_convert_args ||= as_args(config["pre_extra_convert_args"]).concat(
          picture_versions[@version].is_a?(Hash) &&
          picture_versions[@version]["pre_extra_convert_args"] || []
        )
      end

      def picture?
        extname =~ /(\.jpg|\.jpeg|\.webp)$/i
      end

      def destination(dest)
        output_dir = File.join("img", @version, @dir)
        output_basename = @site.in_dest_dir(
          @site.dest,
          File.join(output_dir, "#{basename}.#{@pictype}")
        )
        FileUtils.mkdir_p(File.dirname(output_dir))
        @destination ||= {}
        @destination[dest] ||= output_basename
      end

      def popen_args(dest_path)
        args = ["convert", @path]
        args.concat pre_convert_args
        args.concat ["-resize", "#{@picture_dim}x>"] unless replace_args
        if @pictype == "jpg"
          args.concat ["-background", "##{@config["background_color"]}",
                       "-flatten", "-alpha", "off"]
        end
        args.concat convert_args
        args.push dest_path
      end

      def copy_file(dest_path)
        Jekyll.logger.debug "copy_file : #{path} -> #{dest_path} (#{popen_args(dest_path)})"
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

module Jekyll
  # Override the write methid to paralellize it
  class Site
    alias_method "old_write", "write"

    def n_threads
      config["picture_tag_ng"]["threads"] || 8
    end

    def thread_pool
      @thread_pool ||= (0..n_threads).map do |i|
        Jekyll.logger.debug "Creating thread num #{i}"
        Thread.new do
          j = 0
          Kernel.loop do
            Jekyll.logger.debug "Doing task num. #{j}"
            j += 1
            task = next_task
            if task.nil?
              sleep 0.1
            elsif task.instance_of?(Proc)
              res = task.call
            end

            break if res == -1
          end
          Jekyll.logger.debug "Finishing thread num #{i}"
        end
      end
    end

    def reset_thread_pool
      @thread_pool = nil
    end

    def next_task
      @task_queue ||= []
      @task_queue.shift
    end

    def add_task(&task)
      @task_queue ||= []
      @task_queue.push(task)
    end

    def write
      if config["picture_tag_ng"]["parallel"]
        Jekyll.logger.info "Writing files in parallel"
        Jekyll::Commands::Doctor.conflicting_urls(self)
        each_site_file do |item|
          regenerator.regenerate?(item) && add_task { item.write(dest) }
        end
        thread_pool.each do
          add_task { -1 }
        end
        thread_pool.each(&:join)
        reset_thread_pool
        regenerator.write_metadata
        Jekyll::Hooks.trigger :site, :post_write, self
        nil
      else
        old_write
      end
    end
  end
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
