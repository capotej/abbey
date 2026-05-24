# frozen_string_literal: true

# Opt-in theming for Abbey.
#
# A theme is one self-contained folder under `app/themes/<name>/`:
#
#   app/themes/<name>/
#     theme.rb               # manifest — Abbey::Theme.register(:name) { |t| ... }
#     assets/                # CSS bundled with the theme (loaded via theme_stylesheets)
#       tailwind.css         # per-theme Tailwind build (Phase 2)
#       <name>-highlight.css # optional Rouge syntax theme
#     views/                 # ERB templates that override default views
#       layouts/             # while this theme is active
#       shared/
#       blog/ pages/ links/ papers/
#
# The active theme is selected via the `ABBEY_THEME` env var:
#
#   $ ABBEY_THEME=retro bin/dev
#
# (or `Rails.application.config.theme = "retro"` in an environment file).
# With no env var set, the implicit "default" theme renders the original
# Abbey look — no view overrides, no theme stylesheets.

require "abbey/theme"
require "markdown_render"
require "minimal_markdown_render"

# Honor the env var as the default; environments / other initializers may
# still override `Rails.application.config.theme`.
Rails.application.config.theme = ENV.fetch("ABBEY_THEME", "default")

# Populate the registry by loading every `app/themes/*/theme.rb` manifest.
Abbey::Theme.load_all!

# Register each theme's `assets/` folder with Propshaft so that
# `stylesheet_link_tag "themes/<name>/<file>"` resolves. This runs at
# boot so the load path is in place before the first request.
Abbey::Theme.registry.each_value do |theme|
  next unless theme.assets_path&.directory?

  Rails.application.config.assets.paths << theme.assets_path.to_s
end
