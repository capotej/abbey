# frozen_string_literal: true

# Prepends the active theme's view directory to Rails' lookup path so that
# `app/themes/<theme>/views/<scope>/<name>.html.erb` overrides
# `app/views/<scope>/<name>.html.erb` (including layouts) while the theme
# is active. The default theme is a no-op.
module Theming
  extend ActiveSupport::Concern

  included do
    before_action :prepend_theme_view_path
    helper_method :current_theme, :theme_active?, :active_theme
  end

  private

  # Returns the active `Abbey::Theme` instance (or its DefaultTheme sentinel
  # when no named theme is configured). Always non-nil.
  def active_theme
    Abbey::Theme.active
  end

  # Backward-compat string accessor used by older view helpers.
  def current_theme
    active_theme.name.to_s
  end

  def theme_active?
    !active_theme.default?
  end

  def prepend_theme_view_path
    theme = active_theme
    return if theme.default?

    views = theme.views_path
    return unless views&.directory?

    prepend_view_path views.to_s
  end
end
