# Opt-in theme system for Abbey.
#
# A theme can override any view by placing a same-named file under
# `app/views/themes/<theme>/` (e.g. `app/views/themes/retro/blog/index.html.erb`
# wins over `app/views/blog/index.html.erb` when the theme is active).
#
# A theme can also ship its own stylesheets under
# `app/assets/stylesheets/themes/<theme>.css` (and optionally
# `themes/<theme>-highlight.css`) which the layout loads in addition to the
# default Tailwind build.
#
# Set the active theme with the ABBEY_THEME env var, or override here.
# Built-in themes: "default" (the original minimal look), "retro".

Rails.application.config.theme = ENV.fetch("ABBEY_THEME", "default")

# Themes listed here render markdown via the MinimalMarkdownRender (semantic
# HTML, no inline Tailwind classes) so they can style content entirely from
# a wrapper class scope. Default theme keeps the original utility-class
# renderer to preserve current behavior.
Rails.application.config.themes_using_minimal_renderer = %w[retro]
