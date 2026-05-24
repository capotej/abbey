module ApplicationHelper
  # Override Propshaft's `:app` bulk inclusion so that stylesheets which
  # live under `app/themes/<name>/assets/` (registered with the asset
  # pipeline at boot) are NOT auto-included with the rest of the app
  # bundle. They belong to optional themes and are loaded separately via
  # #theme_stylesheets only when their theme is active. This keeps the
  # default theme byte-for-byte unchanged regardless of how many themes
  # the project ships.
  def app_stylesheets_paths
    super.reject { |path| path.to_s.start_with?("themes/") }
  end

  # Returns the logical names of every stylesheet the active theme ships
  # under `app/themes/<name>/assets/`, suitable for `stylesheet_link_tag`.
  # The default theme contributes nothing extra.
  #
  # Resolution order:
  #   1. Read the active theme manifest's `stylesheets` (filesystem scan).
  #   2. Filter via the asset pipeline so missing files don't 500.
  #   3. Fall back to the legacy `themes/<name>` / `themes/<name>-highlight`
  #      pair if the manifest yielded nothing (back-compat for older code
  #      paths that haven't moved to the consolidated folder).
  def theme_stylesheets
    theme = Abbey::Theme.active
    return [] if theme.default?

    candidates = theme.stylesheets
    candidates = [
      "themes/#{theme.name}",
      "themes/#{theme.name}-highlight"
    ] if candidates.empty?

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
