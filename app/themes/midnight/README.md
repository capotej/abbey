# Midnight

Abbey's reference **drop-in sample theme** — a minimal recolor that demonstrates the "30-second theme" pattern.

```sh
ABBEY_THEME=midnight bin/dev
```

## What it shows

* **The minimum viable theme**: ~80 lines total across `theme.rb` + `assets/tailwind.css` + the 3-line `application.html.erb` layout shell.
* **Zero view overrides**: inherits Abbey's default chrome, navigation, footer, blog index, blog post, page, links, papers — all of it.
* **Single-color palette + accent**: deep slate background, warm amber for links and quote borders.
* **Web fonts**: Inter for body, JetBrains Mono for code — loaded via the manifest's `t.fonts` array, with Google Fonts preconnect tags emitted automatically by the chrome partial.
* **Inline SVG favicon**: a tiny crescent moon, declared inline in `theme.rb` (no precompiled binary assets to ship).
* **Custom prose styling**: overrides Tailwind Typography's CSS variables (`--tw-prose-*`) so markdown content renders correctly on the dark background.

## Folder layout

```
app/themes/midnight/
  theme.rb               # 30 lines — manifest
  assets/tailwind.css    # 50 lines — palette + a few component classes
  views/layouts/application.html.erb  # 3 lines — chrome shell
  README.md
```

## How to fork this for your own theme

```sh
bin/rails g abbey:theme yourname --from=midnight
```

That'll clone this entire structure as a starting point. Then edit `theme.rb` (display_name, colors, fonts) and the `@theme` block in `assets/tailwind.css`. You're done.

For the authoring guide, see [`docs/THEMES.md`](../../../docs/THEMES.md). For the full manifest API reference, see [`docs/THEMES_API.md`](../../../docs/THEMES_API.md).
