# frozen_string_literal: true

module Abbey
  # Registry of opt-in themes that Abbey can render under.
  #
  # A theme lives in a single self-contained folder under `app/themes/<name>/`
  # and declares its metadata in a `theme.rb` manifest:
  #
  #   # app/themes/retro/theme.rb
  #   Abbey::Theme.register(:retro) do |t|
  #     t.display_name      = "Retro (Memphis / 8-bit / CRT)"
  #     t.html_class        = "theme-retro"
  #     t.body_class        = "min-h-screen flex flex-col font-sans bg-memphis-paper dark:bg-memphis-crt"
  #     t.markdown_renderer = :minimal
  #     t.theme_color_light = "#fff8ef"
  #     t.theme_color_dark  = "#0a0e1a"
  #     t.fonts             = ["https://fonts.googleapis.com/css2?..."]
  #     t.favicon_svg       = "<svg ...>"
  #   end
  #
  # The registry exposes the active theme to:
  #   * `Theming` controller concern (view path prepending)
  #   * `ApplicationHelper#theme_stylesheets` (asset enumeration)
  #   * `Rendering#markdown_renderer` (renderer choice)
  #   * `_abbey_chrome.html.erb` partial (head/body chrome rendering)
  #
  # The "default" theme is implicit — no folder, no manifest, no overrides.
  # Calling `Abbey::Theme.active` when the configured theme name is "default"
  # (or unknown) returns a sentinel `DefaultTheme` instance whose accessors
  # return `nil`/sensible blanks, so callers can use the registry without
  # special-casing.
  class Theme
    THEMES_DIR = "app/themes"

    class << self
      def registry
        @registry ||= {}
      end

      def register(name)
        theme = new(name)
        yield theme if block_given?
        registry[name.to_sym] = theme
        theme
      end

      # Load every `app/themes/*/theme.rb` so manifests register themselves.
      # Uses Kernel#load (not require) so manifests are re-evaluated each
      # call — important for `reset!` + reload during tests and for code
      # reloading in development.
      def load_all!(root = Rails.root)
        Dir.glob(root.join(THEMES_DIR, "*", "theme.rb")).sort.each do |manifest|
          load manifest
        end
        registry
      end

      # The currently active theme, as configured via `ABBEY_THEME` env var
      # or `Rails.application.config.theme`. Returns the `default` sentinel
      # if the configured theme isn't registered.
      def active
        name = configured_name
        registry[name.to_sym] || DefaultTheme.instance
      end

      def active?
        !active.is_a?(DefaultTheme)
      end

      def configured_name
        ENV["ABBEY_THEME"].presence ||
          Rails.application.config.try(:theme).to_s.presence ||
          "default"
      end

      def reset!
        @registry = {}
      end

      # All folders under app/themes/ that have a theme.rb. Useful for
      # configuring Tailwind builds (Phase 2) and discovery.
      def discover(root = Rails.root)
        Dir.glob(root.join(THEMES_DIR, "*", "theme.rb")).sort.map do |manifest|
          Pathname.new(manifest).parent.basename.to_s.to_sym
        end
      end
    end

    attr_accessor :display_name, :html_class, :body_class, :theme_color_light,
                  :theme_color_dark, :fonts, :favicon_svg
    attr_reader   :name, :markdown_renderer_choice

    def initialize(name)
      @name                     = name.to_sym
      @display_name             = name.to_s.titleize
      @html_class               = "theme-#{name}"
      @body_class               = nil
      @markdown_renderer_choice = :default
      @theme_color_light        = nil
      @theme_color_dark         = nil
      @fonts                    = []
      @favicon_svg              = nil
    end

    # Accept either `:minimal` / `:default` or an actual renderer class.
    def markdown_renderer=(value)
      @markdown_renderer_choice = value
    end

    # Resolve to the actual renderer class. Themes pick a symbol; we map.
    def markdown_renderer
      case @markdown_renderer_choice
      when Class    then @markdown_renderer_choice
      when :minimal then MinimalMarkdownRender
      else               MarkdownRender
      end
    end

    # Filesystem layout helpers (paths relative to Rails.root).
    def root_path(root = Rails.root)
      root.join(THEMES_DIR, name.to_s)
    end

    def views_path(root = Rails.root)
      root_path(root).join("views")
    end

    def assets_path(root = Rails.root)
      root_path(root).join("assets")
    end

    # CSS files this theme contributes, returned as logical asset paths
    # (no extension) suitable for `stylesheet_link_tag`. Excludes
    # `tailwind.css` (the per-theme Tailwind build, loaded via a separate
    # mechanism in Phase 2).
    #
    # The theme's `assets/` folder is registered with Propshaft at boot,
    # so logical paths are the bare filename: `themes/retro/retro.css` on
    # disk resolves as `retro`. Themes namespace their assets via filename
    # (`retro.css`, `retro-highlight.css`) to avoid collisions.
    def stylesheets
      return [] unless assets_path.directory?

      Dir.children(assets_path)
        .select { |f| f.end_with?(".css") }
        .reject { |f| f == "tailwind.css" }
        .map    { |f| f.delete_suffix(".css") }
        .sort
    end

    def default?
      false
    end

    # Sentinel for the unthemed default look. Returned by `Theme.active`
    # when no named theme is configured (or the configured name isn't
    # registered). Lets callers use the same API for default + named themes.
    class DefaultTheme < Theme
      include Singleton

      def initialize
        super(:default)
        @display_name = "Default"
        @html_class   = nil
      end

      def markdown_renderer
        MarkdownRender
      end

      def views_path(_root = Rails.root) = nil
      def assets_path(_root = Rails.root) = nil
      def stylesheets = []
      def default?    = true
    end
  end
end
