# Authoring Drop-in Themes for Abbey

Abbey ships with an opt-in theme system designed so that a community theme is **one self-contained folder** under `app/themes/<name>/`. Dropping the folder in and setting `ABBEY_THEME=<name>` is the entire install — zero edits to any central file. This guide walks through the concepts, the recommended workflow, and the gotchas you'll hit along the way.

If you're looking for the exhaustive manifest reference, see [`docs/THEMES_API.md`](THEMES_API.md).

## Table of contents

1. [Concepts](#concepts)
2. [Quick start (30-second recolor)](#quick-start-30-second-recolor)
3. [Folder layout](#folder-layout)
4. [The manifest (`theme.rb`)](#the-manifest-themerb)
5. [The Tailwind entry point (`assets/tailwind.css`)](#the-tailwind-entry-point-assetstailwindcss)
6. [Overriding views](#overriding-views)
7. [Picking a markdown renderer](#picking-a-markdown-renderer)
8. [Per-theme JavaScript](#per-theme-javascript)
9. [Dark mode](#dark-mode)
10. [Common patterns](#common-patterns)
11. [Gotchas](#gotchas)

## Concepts

* **Registry**: Every theme registers itself with `Abbey::Theme` in its `theme.rb` manifest. Abbey scans `app/themes/*/theme.rb` at boot.
* **Active theme**: Picked via `ABBEY_THEME=<name>` (or `Rails.application.config.theme = "<name>"`). With no env var, the implicit `default` theme renders Abbey's original look.
* **Chrome partial** (`app/views/layouts/_abbey_chrome.html.erb`): renders `<head>`, `<body>` wrapper, navigation, and footer using values from the active theme's manifest. Most themes never need their own layout markup.
* **Per-theme Tailwind bundle**: Each theme owns `app/themes/<name>/assets/tailwind.css`, compiled to `app/assets/builds/tailwind-<name>.css`. The default Abbey bundle is byte-for-byte unchanged no matter how many themes you install — themes don't leak utilities into the default scan.
* **View overrides**: Ship any subset of view files under `app/themes/<name>/views/`. They prepend to Rails' view path while your theme is active, so an `app/themes/<name>/views/blog/show.html.erb` wins over `app/views/blog/show.html.erb`.

## Quick start (30-second recolor)

For a pure recolor that inherits Abbey's default chrome:

```sh
bin/rails g abbey:theme aurora --minimal
```

This generates:

```
app/themes/aurora/
  theme.rb               # manifest
  assets/tailwind.css    # @theme tokens + your custom utilities
  views/layouts/application.html.erb  # 3-line shell
  README.md
```

Edit `theme.rb` (palette, font, theme color), edit `assets/tailwind.css` (your `@theme` tokens), then:

```sh
ABBEY_THEME=aurora bin/dev
```

That's it. Your theme is live.

For a serious visual override that needs to customize markup, drop the `--minimal` flag (full scaffold) or use `--from=retro` to clone an existing theme as a starting point:

```sh
bin/rails g abbey:theme aurora             # full scaffold (every view stubbed)
bin/rails g abbey:theme aurora --from=retro # clones retro's views as starter
```

## Folder layout

```
app/themes/aurora/
  theme.rb                      # required: registers the theme with Abbey
  assets/
    tailwind.css                # required if you want utility classes
    aurora-highlight.css        # optional: Rouge syntax theme override
  views/                        # optional: ERB overrides; subset is fine
    layouts/application.html.erb
    shared/_navigation.html.erb
    shared/_footer.html.erb
    shared/_admin_navigation.html.erb
    shared/_tags.html.erb
    shared/_dark_mode_script.html.erb
    blog/{index,show,index_by_tag}.html.erb
    pages/show.html.erb
    links/{index,_link}.html.erb
    papers/{index,_paper}.html.erb
  README.md                     # author notes (recommended)
```

You don't have to ship every file. View resolution falls through to the default templates for anything you don't override.

## The manifest (`theme.rb`)

```ruby
Abbey::Theme.register(:aurora) do |t|
  t.display_name      = "Aurora"
  t.html_class        = "theme-aurora"
  t.body_class        = "min-h-screen flex flex-col bg-aurora-bg text-aurora-fg"
  t.main_class        = "container mx-auto px-4 py-8 max-w-5xl flex-1"

  t.markdown_renderer = :minimal           # or :default

  t.theme_color_light = "#f5f3ff"
  t.theme_color_dark  = "#0b0a1f"

  t.fonts = [
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&display=swap"
  ]

  t.favicon_svg = <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
      <rect width="16" height="16" fill="#6366f1"/>
      <circle cx="8" cy="8" r="3" fill="#fef3c7"/>
    </svg>
  SVG
end
```

Every field is optional except the symbol name passed to `.register`. See [`THEMES_API.md`](THEMES_API.md) for the complete field list and defaults.

## The Tailwind entry point (`assets/tailwind.css`)

```css
@import 'tailwindcss';

/* Scan only this theme's views. Tailwind tree-shakes against everything
   under here, so the bundle stays minimal. */
@source "../views";

@plugin "@tailwindcss/typography";  /* optional, if you use prose */

@theme {
  /* Palette */
  --color-aurora-bg:     #f5f3ff;
  --color-aurora-fg:     #0b0a1f;
  --color-aurora-accent: #6366f1;
  --color-aurora-muted:  #6b7280;

  /* Fonts (rebound inside .theme-aurora scope via font-sans utility) */
  --font-display: "Inter", system-ui, sans-serif;

  /* Custom shadows */
  --shadow-aurora: 0 10px 30px -10px rgba(99,102,241,0.5);

  /* Animations */
  --animate-shimmer: aurora-shimmer 2s linear infinite;

  @keyframes aurora-shimmer {
    0%   { background-position: 0% 50%; }
    100% { background-position: 100% 50%; }
  }
}

/* Component classes that consume the tokens above. */
.theme-aurora .aurora-card {
  background: var(--color-aurora-bg);
  border: 1px solid color-mix(in oklab, var(--color-aurora-accent) 30%, transparent);
  box-shadow: var(--shadow-aurora);
}
```

Everything in `@theme` becomes Tailwind utilities — `bg-aurora-bg`, `text-aurora-accent`, `shadow-aurora`, `animate-shimmer`, etc. Use those in your view ERBs.

The compile loop:

```sh
bin/rails tailwindcss:build      # one-shot build, all themes
bin/rails themes:tailwind:watch  # foreman entry watches every theme
bin/dev                          # already wires up the watcher
```

## Overriding views

Drop an ERB file at `app/themes/aurora/views/<path>.html.erb` and it wins over `app/views/<path>.html.erb` whenever your theme is active. This applies to **every** view, including `layouts/application.html.erb`.

The default chrome partial does most of the layout work for you, so the minimum viable layout is:

```erb
<%= render "layouts/abbey_chrome" do %>
  <%= yield %>
<% end %>
```

Add any per-page wrappers, JS injection, or theme-specific markup inside the block.

To override only the navigation while keeping everything else default, ship just:

```
app/themes/aurora/views/shared/_navigation.html.erb
```

## Picking a markdown renderer

Abbey ships two:

| Renderer              | Output                                                                         |
|-----------------------|---------------------------------------------------------------------------------|
| `MarkdownRender`      | Inline Tailwind classes baked into the HTML (paragraphs, headings, code, etc.) |
| `MinimalMarkdownRender` | Semantic HTML only — no inline classes. Style via a wrapper like `.prose-X`.   |

Pick one in your manifest:

```ruby
t.markdown_renderer = :default  # MarkdownRender — backward compatible
t.markdown_renderer = :minimal  # MinimalMarkdownRender — recommended for new themes
```

If you ship your own renderer, pass the class directly:

```ruby
t.markdown_renderer = MyCustomRenderer
```

`:minimal` is recommended for new themes because it lets you style markdown content from your theme stylesheet (e.g. `.prose-aurora h1 { ... }`) without fighting hard-coded utility classes baked into the rendered HTML.

## Per-theme JavaScript

The chrome partial includes `shared/_dark_mode_script` near the end of the body. You can:

* **Leave it alone** — the default partial ships a simple cookie-based dark mode toggle.
* **Override it** — drop `app/themes/aurora/views/shared/_dark_mode_script.html.erb` to ship a richer version (Turbo-safe handling, keyboard shortcuts, easter eggs — see `app/themes/grimoire/views/shared/_dark_mode_script.html.erb` for an example with Konami code).

For arbitrary per-page JS (analytics, embeds, etc.), use `content_for(:after_body)` in your view and yield it from your theme's layout if you need it.

## Dark mode

Abbey's dark mode is class-based — `<html>` carries `dark` when the cookie is set. Tailwind's `dark:` variant works out of the box for any utility you declare in `@theme`.

The chrome partial reads two manifest fields to render the right `<html>` classes:

```ruby
t.dark_html_class  = "dark"             # add when dark mode is on
t.light_html_class = nil                # add when dark mode is off
```

Most themes only need `dark_html_class = "dark"` (the default). The default theme uses `"dark bg-gray-900"` / `"bg-white"` because it relies on an `<html>`-level background instead of `<body>`.

## Common patterns

### Pure recolor (no markup changes)

```sh
bin/rails g abbey:theme moss --minimal
```

Edit only `theme.rb` and `assets/tailwind.css`. The default chrome and view templates render through.

### Distinctive cards / typography

Ship `assets/tailwind.css` with custom `@theme` tokens + component classes, then override `views/blog/show.html.erb` and `views/blog/index.html.erb` to add the new classes.

### Custom favicon / theme color

All inline in `theme.rb` — `t.favicon_svg = "<svg ...>"` and `t.theme_color_light = "#fff"`. No precompiled assets to ship.

### Custom Rouge syntax theme

Drop `app/themes/aurora/assets/aurora-highlight.css` — Abbey's chrome partial auto-loads any `.css` file from your `assets/` directory (other than `tailwind.css`).

## Gotchas

* **Don't override `app/views/layouts/_abbey_chrome.html.erb`.** It's the shared partial — your theme's override won't be loaded because the partial lookup happens from the default view path. If you need a fundamentally different chrome, ship your own `views/layouts/application.html.erb` that doesn't render the chrome partial.

* **`@source "../views"` is required in your Tailwind entry point.** Without it, Tailwind only generates utilities used in the default app — none of your theme's view classes will get emitted.

* **Theme class collisions.** Tailwind only generates a utility if it sees the class name in scanned content. If you define `--color-aurora-bg` but never use `bg-aurora-bg` in a view, it won't appear in the CSS bundle. Add the class to a view (even just a comment in a view file) to force it.

* **Default bundle isolation is enforced.** `app/assets/tailwind/application.css` excludes `app/themes/**` from its scan. If you accidentally reference a theme utility in a default view, Tailwind won't emit it — the default bundle stays clean.

* **`bin/dev` runs three foreman processes**: web, default-css watcher, theme-css watcher. If you don't see your theme CSS updating on save, make sure the `themes:` process is running (check `Procfile.dev`).

* **Theme manifests are loaded once at boot.** Editing `theme.rb` in development requires a restart for the chrome partial to pick up new field values. View file edits hot-reload normally.

## Where to go next

* [`docs/THEMES_API.md`](THEMES_API.md) — exhaustive manifest field reference and registry API.
* `app/themes/retro/` and `app/themes/grimoire/` — full-featured production themes you can study.
* `app/themes/midnight/` — a minimal sample theme demonstrating the "30-second recolor" pattern.
