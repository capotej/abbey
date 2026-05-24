# frozen_string_literal: true

Abbey::Theme.register(:retro) do |t|
  t.display_name      = "Retro (Memphis / 8-bit / CRT)"
  t.html_class        = "theme-retro"
  t.body_class        = "min-h-screen flex flex-col font-sans bg-memphis-paper dark:bg-memphis-crt"
  t.markdown_renderer = :minimal
  t.theme_color_light = "#fff8ef"
  t.theme_color_dark  = "#0a0e1a"

  t.fonts = [
    "https://fonts.googleapis.com/css2?family=Press+Start+2P&family=VT323&family=Space+Grotesk:wght@400;500;600;700&display=swap"
  ]

  # Pixelated 4-square Memphis favicon.
  t.favicon_svg = <<~SVG.strip
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" shape-rendering="crispEdges">
      <rect width="16" height="16" fill="#ff3eb5"/>
      <rect x="2" y="2" width="12" height="12" fill="#ffd400"/>
      <rect x="4" y="4" width="8" height="8" fill="#00e5ff"/>
      <rect x="6" y="6" width="4" height="4" fill="#0d0d12"/>
    </svg>
  SVG
end
