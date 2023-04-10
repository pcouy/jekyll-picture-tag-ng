# Jekyll Picture Tag NG

This plugin will automatically generate variants of your pictures on build, and change the Kramdown rendering to use the variants with HTML picture tags when including pictures from markdown. Developped for and used on [Crocodile Couture](https://crocodile-couture.fr)

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add jekyll-picture-tag-ng

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install jekyll-picture-tag-ng

Additionally, you will need [ImageMagick](https://imagemagick.org/) installed on the system you're using to build your website in order to generate the picture variations. On Debian/Ubuntu systems, you can execute:

    $ sudo apt-get install imagemagick

After installing, update your `_config.yml` to include the plugin :

```
plugins:   [other-plugins, jekyll-picture-tag-ng]
```

### Using with GitHub Pages

If you're using GitHub Pages to deploy your site, you'll need to use a custom action to be able to use this plugin and install ImageMagick. You can create such GitHub action by browsing to `https://github.com/{YOUR/REPO}/new/main?filename=.github%2Fworkflows%2Fjekyll.yml&workflow_template=pages%2Fjekyll`. You will need to add the following lines as a step for the build job of your GitHub action (before the `jekyll build` command) :

```
- name: Install imagemagick
  run: sudo apt-get update && sudo apt-get install imagemagick
```

After adding the custom action to your repository, you'll need to update the repository settings on GitHub : go to the "Pages" section and change the "Source" setting from "Deploy from a branch" to "GitHub Actions".

## Usage

By installing the plugin and activating it, `jekyll build` and `jekyll serve` commands will perform an additional step to generate several versions of your `jpeg` and `webp` files : for each of these files in the source directory, and each version defined, a file will be output in the `img/{version}` directory of the rendered website.

When using the default markdown syntax for including pictures (`![Alt text](PICTURE_URL)`) with the Kramdown renderer, `<picture>` tags with appropriate `<source>` children tags will be output.

When working locally, it is recommended to use the `--incremental` option which will prevent Jekyll from re-generating all the picture versions (can take quite some time) every time you save a file. However, there is a catch : when using `--incremental`, if you edit your configuration file to change the output formats and build again, your pages will not be updated with the appropriate `<source>` tags for the new versions.

### Configuration

Configuration is done in the `_config.yml` of your website, under the `picture_tag_ng` variable :

```yaml
picture_tag_ng:
  background_color: FFFFFF
  picture_versions:
    m: 700
    s: 400
```

The example above is equivalent to the defaults.

- `background_color` is the color used to replace transparency when converting from `webp` to `jpeg`
- `picture_versions` maps version names to target widths in pixels. The default configuration above produces output files 700px wide in `img/m/` and 400px wide in `img/s/`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pcouy/jekyll-picture-tag-ng.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
