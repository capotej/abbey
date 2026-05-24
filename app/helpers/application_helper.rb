module ApplicationHelper
  # Override Propshaft's `:app` bulk inclusion so the per-theme assets
  # (tailwind-<name>.css and every file from app/themes/<name>/assets/)
  # are NOT auto-included with the rest of the app bundle. They belong
  # to optional themes and are loaded separately via #theme_stylesheets
  # only when their theme is active. This keeps the default theme bundle
  # byte-for-byte unchanged regardless of how many themes ship.
  def app_stylesheets_paths
    excluded = theme_excluded_logical_paths
    super.reject do |path|
      slug = path.to_s.delete_suffix(".css")
      slug.start_with?("themes/") || excluded.include?(slug)
    end
  end

  # Returns the logical names of every stylesheet the active theme ships,
  # suitable for `stylesheet_link_tag`. Always includes the per-theme
  # Tailwind bundle first (`tailwind-<name>`), then any extra CSS files
  # the theme contributes from its `assets/` folder. The default theme
  # contributes nothing extra.
  #
  # Resolution order:
  #   1. `tailwind-<active>` (compiled by `themes:tailwind:build`) so
  #      theme tokens land before component CSS that references them.
  #   2. Manifest-declared stylesheets (filesystem scan of assets/, with
  #      tailwind.css excluded since it's the compiler input, not output).
  #   3. Legacy `themes/<name>` / `themes/<name>-highlight` fallback for
  #      code paths that haven't moved to the consolidated folder.
  def theme_stylesheets
    theme = Abbey::Theme.active
    return [] if theme.default?

    sheets = []
    sheets << "tailwind-#{theme.name}" if theme_stylesheet_exists?("tailwind-#{theme.name}")

    candidates = theme.stylesheets
    candidates = [
      "themes/#{theme.name}",
      "themes/#{theme.name}-highlight"
    ] if candidates.empty?

    sheets.concat(candidates.select { |name| theme_stylesheet_exists?(name) })
  end

  # Whether dark mode is currently active on the request. The chrome
  # partial uses this to pick between the active theme's dark_html_class
  # and light_html_class.
  def dark_mode?
    cookies[:dark_mode] == "true"
  end

  # Build the `class="..."` value for the chrome partial's <html> element
  # by combining the active theme's always-on classes with its
  # dark/light variants based on the request's dark mode state.
  def chrome_html_class(theme = Abbey::Theme.active)
    parts = [
      theme.html_class,
      dark_mode? ? theme.dark_html_class : theme.light_html_class
    ]
    parts.compact.reject(&:blank?).join(" ").presence
  end

  private

  def theme_stylesheet_exists?(logical_name)
    Rails.application.assets&.load_path&.find("#{logical_name}.css").present? ||
      Rails.root.join("app/assets/stylesheets/#{logical_name}.css").exist?
  rescue StandardError
    Rails.root.join("app/assets/stylesheets/#{logical_name}.css").exist?
  end

  # Every logical asset path contributed by any registered theme. Used
  # by `app_stylesheets_paths` to exclude theme assets from the default
  # bundle without hard-coding any theme name.
  def theme_excluded_logical_paths
    @_theme_excluded_logical_paths ||= Abbey::Theme.registry.flat_map do |name, theme|
      ["tailwind-#{name}"] + theme.stylesheets
    end.to_set
  end
end
