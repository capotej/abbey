# frozen_string_literal: true

require "rails/generators"
require "rails/generators/named_base"

module Abbey
  module Generators
    # Scaffold a new drop-in theme under app/themes/<name>/.
    #
    #   rails g abbey:theme aurora
    #     # full skeleton: theme.rb + assets/tailwind.css + a minimal
    #     # layout that renders through the shared chrome partial.
    #
    #   rails g abbey:theme aurora --minimal
    #     # bare minimum: theme.rb + assets/tailwind.css + 3-line layout.
    #     # Use case: pure recolor on top of Abbey's default chrome.
    #
    #   rails g abbey:theme aurora --from=retro
    #     # clones an existing theme's structure as the starting point.
    #     # Use case: a serious visual override that wants to start from
    #     # something more substantial than the bare skeleton.
    class ThemeGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      desc "Scaffold a new Abbey drop-in theme under app/themes/<name>/"

      class_option :minimal, type: :boolean, default: false,
                   desc: "Only generate theme.rb + assets/tailwind.css + a 3-line layout (pure recolor)"
      class_option :from,    type: :string,  default: nil,
                   desc: "Clone an existing theme as the starting point (e.g. --from=retro)"

      def validate_name
        return if file_name.match?(/\A[a-z][a-z0-9_]*\z/)

        raise Thor::Error,
              "Theme name must be lowercase, start with a letter, and contain only " \
              "letters, digits, and underscores (got: #{file_name.inspect})."
      end

      def validate_destination
        if File.exist?(File.join(destination_root, theme_path("theme.rb")))
          raise Thor::Error, "A theme already exists at #{theme_path('')}"
        end
      end

      def create_manifest
        template "theme.rb.tt", theme_path("theme.rb")
      end

      def create_tailwind_entry
        template "tailwind.css.tt", theme_path("assets/tailwind.css")
      end

      def create_layout
        template "layouts/application.html.erb.tt", theme_path("views/layouts/application.html.erb")
      end

      def create_readme
        template "README.md.tt", theme_path("README.md")
      end

      def clone_from_source
        return unless options[:from].present?

        source_dir = Pathname.new(File.join(destination_root, "app/themes/#{options[:from]}"))
        # Fall back to repo-level path when the generator is invoked
        # against the real app (not a generator test): destination_root
        # is the cwd in that case, which is also Rails.root.
        source_dir = Rails.root.join("app/themes/#{options[:from]}") unless source_dir.directory?
        unless source_dir.directory?
          raise Thor::Error,
                "--from=#{options[:from]}: no theme found at app/themes/#{options[:from]}"
        end

        say_status :clone, "from #{options[:from]} (views/, assets/)"
        dest_views = File.join(destination_root, theme_path("views"))
        src_views  = source_dir.join("views")
        if src_views.directory?
          FileUtils.mkdir_p(dest_views)
          # Copy entry-by-entry so we merge into an existing dest (created
          # by create_layout) instead of nesting `views/views/` under it.
          Dir.children(src_views).each do |entry|
            FileUtils.cp_r(src_views.join(entry).to_s, File.join(dest_views, entry))
          end
        end
        copy_extra_assets_from(source_dir)
      end

      def scaffold_views
        return if options[:minimal] || options[:from].present?

        scaffold_view_files.each do |relative|
          template "views/#{relative}.tt", theme_path("views/#{relative}")
        end
      end

      def print_next_steps
        say ""
        say "Theme #{file_name.inspect} scaffolded.", :green
        say ""
        say "Next steps:"
        say "  1. Edit app/themes/#{file_name}/theme.rb (display_name, colors, fonts)."
        say "  2. Tweak app/themes/#{file_name}/assets/tailwind.css with your @theme tokens."
        say "  3. (optional) Customize app/themes/#{file_name}/views/ to override layouts/partials."
        say "  4. Boot the app with ABBEY_THEME=#{file_name} bin/dev"
      end

      private

      # Returns the theme's path RELATIVE to destination_root (which Thor
      # prefixes for us). Empty `rel` returns "app/themes/<name>".
      def theme_path(rel = "")
        File.join("app/themes", file_name, rel.to_s).chomp("/")
      end

      def copy_extra_assets_from(source_dir)
        assets_src = source_dir.join("assets")
        return unless assets_src.directory?

        dest_assets = File.join(destination_root, theme_path("assets"))
        FileUtils.mkdir_p(dest_assets)
        Dir.children(assets_src).each do |entry|
          next if entry == "tailwind.css"
          FileUtils.cp_r(assets_src.join(entry).to_s, File.join(dest_assets, entry))
        end
      end

      # `layouts/application.html.erb` is emitted by `create_layout`; the
      # rest of the view tree is scaffolded here.
      def scaffold_view_files
        %w[
          shared/_navigation.html.erb
          shared/_footer.html.erb
          shared/_admin_navigation.html.erb
          shared/_tags.html.erb
          blog/index.html.erb
          blog/show.html.erb
          blog/index_by_tag.html.erb
          pages/show.html.erb
          links/index.html.erb
          links/_link.html.erb
          papers/index.html.erb
          papers/_paper.html.erb
        ]
      end

      def theme_display_name
        file_name.titleize
      end

      def theme_html_class
        "theme-#{file_name}"
      end

      def theme_module_color
        "##{[ "0ea5e9", "ec4899", "10b981", "f59e0b", "8b5cf6" ].sample}"
      end
    end
  end
end
