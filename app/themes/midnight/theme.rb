# frozen_string_literal: true

# Midnight — Abbey's sample minimal recolor theme.
#
# Demonstrates the "30-second recolor" pattern: ~80 lines total across
# theme.rb + assets/tailwind.css + layout shell. No view overrides;
# inherits Abbey's default chrome and templates.
#
# Activate with: ABBEY_THEME=midnight bin/dev
Abbey::Theme.register(:midnight) do |t|
  t.display_name      = "Midnight"
  t.html_class        = "theme-midnight"
  t.body_class        = "min-h-screen flex flex-col bg-midnight-bg text-midnight-fg"
  t.main_class        = "container mx-auto px-4 py-10 max-w-3xl flex-1"
  t.markdown_renderer = :minimal
  t.theme_color_light = "#0f172a"
  t.theme_color_dark  = "#020617"

  t.fonts = [
    "https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&family=Inter:wght@400;500;700&display=swap"
  ]

  t.favicon_svg = <<~SVG.strip
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
      <rect width="16" height="16" fill="#0f172a"/>
      <circle cx="11" cy="5" r="3" fill="#fef3c7"/>
      <circle cx="13" cy="5" r="3" fill="#0f172a"/>
    </svg>
  SVG
end
