# frozen_string_literal: true

Abbey::Theme.register(:grimoire) do |t|
  t.display_name      = "Grimoire (Retro hacker dark fantasy)"
  t.html_class        = "theme-grimoire"
  t.body_class        = "min-h-screen flex flex-col bg-grim-parchment dark:bg-grim-void"
  t.markdown_renderer = :minimal
  t.theme_color_light = "#ebd9b3"
  t.theme_color_dark  = "#07080d"

  t.fonts = [
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;700;800&family=IBM+Plex+Mono:wght@400;500;700&display=swap"
  ]

  # Pixel-runic favicon: pentagram-circle with an ember.
  t.favicon_svg = <<~SVG.strip
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
      <rect width="16" height="16" fill="#07080d"/>
      <circle cx="8" cy="9" r="5" fill="none" stroke="#c8a44d" stroke-width="1"/>
      <path d="M8 4 L9.5 8 L13 8 L10 10.2 L11 13.5 L8 11.5 L5 13.5 L6 10.2 L3 8 L6.5 8 Z" fill="none" stroke="#c8a44d" stroke-width="0.6"/>
      <circle cx="8" cy="9" r="1" fill="#f08029"/>
    </svg>
  SVG
end
