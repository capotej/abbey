# Prepends the active theme's view directory to the lookup path so that
# `app/views/themes/<theme>/foo/bar.html.erb` overrides
# `app/views/foo/bar.html.erb` (including layouts) when a non-default theme
# is active. The default theme is a no-op.
module Theming
  extend ActiveSupport::Concern

  included do
    before_action :prepend_theme_view_path
    helper_method :current_theme, :theme_active?
  end

  private

  def current_theme
    Rails.application.config.theme.to_s.presence || "default"
  end

  def theme_active?
    current_theme != "default"
  end

  def prepend_theme_view_path
    return unless theme_active?

    theme_root = Rails.root.join("app/views/themes", current_theme)
    return unless theme_root.exist?

    prepend_view_path theme_root.to_s
  end
end
