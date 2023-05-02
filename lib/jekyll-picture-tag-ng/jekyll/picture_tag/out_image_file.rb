# frozen_string_literal: true

module Jekyll
  module PictureTag
    # Class that holds generated variants of pictures.
    # Handles the call to the external program for image resizing (`convert`)
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

      def copy_file(dest_path)
        cmd = if config["backend"] == "libvips"
                vips_popen_args dest_path
              else
                imagemagick_popen_args dest_path
              end
        Jekyll.logger.debug "copy_file : #{path} -> #{dest_path} (#{cmd})"
        p = IO.popen(cmd, err: %i[child out])
        Jekyll.logger.debug "command_output :\n    #{p.readlines.join("    ")}"
        p.close
        File.utime(self.class.mtimes[path], self.class.mtimes[path], dest_path)
      end

      def imagemagick_popen_args(dest_path)
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

      def vips_popen_args(dest_path)
        args = ["vips", "thumbnail", @path]
        dest_path = dest_path.clone.concat "[background=#{rgb_bg_color}]" if @pictype == "jpg"
        args.push dest_path
        args.push @picture_dim.to_s
        args.concat ["--size", "down", "--height", "999999"]
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

      def rgb_bg_color
        hex = config["background_color"]
        @rgb_bg_color ||= "#{hex.slice(0, 2).to_i(16)} #{hex.slice(2, 2).to_i(16)} #{hex.slice(4, 2).to_i(16)}"
      end

      def picture?
        extname =~ /(\.jpg|\.jpeg|\.webp)$/i
      end

      def config
        @config ||= CONFIG.merge(@site.config["picture_tag_ng"] || {})
      end

      def picture_versions
        config["picture_versions"]
      end

      def replace_args
        if picture_versions[@version].is_a?(Hash) &&
           !picture_versions[@version]["replace_convert_args"].nil?
          picture_versions[@version]["replace_convert_args"]
        else
          config["replace_convert_args"]
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
    end
  end
end
