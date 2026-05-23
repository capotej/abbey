module ApplicationHelper
  # Override Propshaft's `:app` bulk inclusion so that stylesheets which
  # live under `app/assets/stylesheets/themes/` are NOT auto-included.
  # Those files belong to optional themes and are loaded separately via
  # #theme_stylesheets only when their theme is active. This keeps the
  # default theme byte-for-byte unchanged regardless of how many themes
  # the project ships.
  def app_stylesheets_paths
    super.reject { |path| path.to_s.start_with?("themes/") }
  end

  # Returns the names of any extra stylesheets that the active theme ships
  # under `app/assets/stylesheets/themes/`. The default theme contributes
  # nothing extra; other themes load `themes/<name>.css` and (if present)
  # `themes/<name>-highlight.css`.
  def theme_stylesheets
    return [] unless theme_active?

    candidates = [
      "themes/#{current_theme}",
      "themes/#{current_theme}-highlight"
    ]
    candidates.select { |name| theme_stylesheet_exists?(name) }
  end

  private

  def theme_stylesheet_exists?(logical_name)
    Rails.application.assets&.load_path&.find("#{logical_name}.css").present? ||
      Rails.root.join("app/assets/stylesheets/#{logical_name}.css").exist?
  rescue StandardError
    Rails.root.join("app/assets/stylesheets/#{logical_name}.css").exist?
  end
end
