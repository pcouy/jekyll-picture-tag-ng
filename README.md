# Jekyll Picture Tag NG

This plugin will automatically generate variants of your pictures on build, and change the Kramdown rendering to use the variants with HTML picture tags when including pictures from markdown. Developed for and used on [Crocodile Couture](https://crocodile-couture.fr)

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add jekyll-picture-tag-ng

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install jekyll-picture-tag-ng

Additionally, you will need [ImageMagick](https://imagemagick.org/) installed on the system you're using to build your website in order to generate the picture variations. On Debian/Ubuntu systems, you can execute:

    $ sudo apt-get install imagemagick

After installing, update your `_config.yml` to include the plugin :

```yaml
plugins:   [other-plugins, jekyll-picture-tag-ng]
```

or

```yaml
plugins:
  - other-plugins
  - jekyll-picture-tag-ng
```

### Using with GitHub Pages

If you're using GitHub Pages to deploy your site, you'll need to use a custom action to be able to use this plugin and install ImageMagick. You can create such GitHub action by browsing to

```
https://github.com/{YOUR/REPO}/new/main?filename=.github%2Fworkflows%2Fjekyll.yml&workflow_template=pages%2Fjekyll
```

You will need to add the following lines as a step for the build job of your GitHub action (before the `jekyll build` command) :

```yaml
- name: Install imagemagick
  run: sudo apt-get update && sudo apt-get install imagemagick
```

After adding the custom action to your repository, you'll need to update the repository settings on GitHub : go to the "Pages" section and change the "Source" setting from "Deploy from a branch" to "GitHub Actions".

## Usage

By installing the plugin and activating it, `jekyll build` and `jekyll serve` commands will perform an additional step to generate several versions of your `jpeg` and `webp` files : for each of these files in the source directory, and each version defined, a file will be output in the `img/{version}` directory of the rendered website.

When using the default markdown syntax for including pictures (`![Alt text](PICTURE_URL)`) with the Kramdown renderer, `<picture>` tags with appropriate `<source>` children tags will be output.

When working locally, you can use the `--incremental` option to prevent Jekyll from re-generating all the pictures (which can take a long time) when re-launching the `jekyll serve` command. This is useful when developing a plugin or tweaking the `_config.yml` file (which both require you to frequently re-launch the `jekyll serve` command). However, be careful about using this option when changing the plugin's output image formats : the plugin will skip generating the new output formats in `--incremental` mode for pictures that were previously generated for the old output formats.

### Configuration

Configuration is done in the `_config.yml` of your website, under the `picture_tag_ng` variable :

```yaml
picture_tag_ng:
  parallel: false
  threads: 16
  background_color: FFFFFF
  picture_versions:
    m: 700
    s: 400
```

The example above is equivalent to the defaults.

- `background_color` is the color used to replace transparency when converting from `webp` to `jpeg`
- `picture_versions` maps version names to target widths in pixels. The default configuration above produces output files 700px wide in `img/m/` and 400px wide in `img/s/`.
- `parallel` is a boolean indicating if you want to generate the output files in parallel threads. With a website that has a lot of large pictures, I get ~30% speed improvements when generating the site locally.
- `threads` is the number of concurrent threads for generating the website (only used if `parallel` is `true`)

## Development

After cloning the repo, you can run the following commands in a local Jekyll website's folder to start hacking on the code of `jekyll-picture-tag-ng` (you'll need to replace the path in the second command) :

    $ bundle remove jekyll-picture-tag-ng # if you previously used jekyll-picture-tag-ng from rubygems
    $ bundle add --path /absolute/or/relative/path/to/your/local/jekyll-picture-tag-ng/repo jekyll-picture-tag-ng
    $ bundle exec jekyll serve # Re-run this when you want to test changes to your local jekyll-picture-tag-ng

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [the Rubygems repository](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pcouy/jekyll-picture-tag-ng.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
