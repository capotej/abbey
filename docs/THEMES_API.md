# Abbey Theme API Reference

This document is the exhaustive reference for the `Abbey::Theme` manifest API and registry. For a guided walkthrough of how to author a theme end-to-end, see [`THEMES.md`](THEMES.md).

> **Stability**: This API is the supported surface for community themes from Abbey 1.0 onward. Backward-incompatible changes will be called out in the changelog and require a major version bump.

## Table of contents

1. [Manifest fields](#manifest-fields)
2. [Registry methods](#registry-methods)
3. [Filesystem conventions](#filesystem-conventions)
4. [Boot flow](#boot-flow)
5. [Helpers available in theme views](#helpers-available-in-theme-views)
6. [Generator reference](#generator-reference)
7. [Rake tasks](#rake-tasks)
8. [Versioning](#versioning)

## Manifest fields

A theme manifest is a Ruby file at `app/themes/<name>/theme.rb`:

```ruby
Abbey::Theme.register(:aurora) do |t|
  t.display_name      = "Aurora"
  # ...
end
```

The block yields an `Abbey::Theme` instance with the following writable attributes. Every field is optional — defaults are shown.

| Field                  | Default                                | Description |
|------------------------|----------------------------------------|-------------|
| `display_name`         | `<name>.titleize`                      | Human-readable name. Used in admin UI and the manifest reference output. |
| `html_class`           | `"theme-<name>"`                       | Always-on classes added to `<html>`. Set to `nil` to omit. |
| `dark_html_class`      | `"dark"`                               | Class added to `<html>` when dark mode cookie is set. |
| `light_html_class`     | `nil`                                  | Class added to `<html>` when dark mode is off. |
| `body_class`           | `nil`                                  | Class set on `<body>`. Set to `nil` to omit the attribute entirely. |
| `main_class`           | `"container mx-auto px-4 py-8"`        | Class set on the `<main>` wrapper inside the chrome partial. |
| `markdown_renderer`    | `:default`                             | `:default`, `:minimal`, or an actual class. See [Renderer](#markdown-renderer). |
| `theme_color_light`    | `nil`                                  | Hex color for `<meta name="theme-color" media="(prefers-color-scheme: light)">`. |
| `theme_color_dark`     | `nil`                                  | Hex color for `<meta name="theme-color" media="(prefers-color-scheme: dark)">`. |
| `fonts`                | `[]`                                   | Array of full stylesheet URLs to inject in `<head>` (preconnect tags are emitted automatically). |
| `favicon_svg`          | `nil`                                  | Inline SVG string emitted as `<link rel="icon" href="data:image/svg+xml,...">`. |

### Markdown renderer

`markdown_renderer` accepts:

* `:default` — `MarkdownRender` (Tailwind-class-rich HTML output, backward compatible with older imported posts).
* `:minimal` — `MinimalMarkdownRender` (semantic HTML only; recommended for new themes that style markdown via wrapper classes like `.prose-<name>`).
* A class — your own renderer that responds to Redcarpet's `Renderer` interface.

```ruby
t.markdown_renderer = MyCustomRenderer
```

### Fonts

`fonts` is just an array of strings. Each is emitted as a separate `<link rel="stylesheet" href="...">` in `<head>`. The chrome partial also emits the standard Google Fonts preconnect tags whenever this array is non-empty. To skip preconnects, leave `fonts` empty and inject the link tags yourself via `content_for(:head)` in a view (Abbey doesn't currently call `yield(:head)` in the chrome partial — see the open issue tracker).

### Favicon

`favicon_svg` is the raw SVG source (no surrounding `<link>` tag). The chrome partial URL-encodes it and wraps it in `<link rel="icon" href="data:image/svg+xml,...">` so themes don't need to ship precompiled binary assets.

## Registry methods

```ruby
Abbey::Theme.register(name, &block)
```

Register a theme. `name` is symbolic. The block receives the theme instance for configuration.

```ruby
Abbey::Theme.active
```

Returns the currently active `Abbey::Theme` instance, or the `Abbey::Theme::DefaultTheme` sentinel if no named theme is configured (or the configured name isn't registered). Always non-nil — safe to call without nil-checking.

```ruby
Abbey::Theme.active?
```

Returns `true` if a named theme is active (i.e. `Abbey::Theme.active` is not the `DefaultTheme` sentinel).

```ruby
Abbey::Theme.registry
```

Hash of `{ Symbol => Abbey::Theme }`. Iterable.

```ruby
Abbey::Theme.discover
```

Returns an array of every theme name (`Symbol`) found on disk under `app/themes/*/theme.rb`, regardless of whether they've been loaded into the registry yet.

```ruby
Abbey::Theme.load_all!
```

Loads every manifest under `app/themes/*/theme.rb`. Uses `Kernel#load` (not `require`) so manifests are re-evaluatable for tests and dev reload. Called once at boot from `config/initializers/themes.rb`.

```ruby
Abbey::Theme.reset!
```

Empties the registry. Use in tests; don't call from app code.

```ruby
Abbey::Theme.configured_name
```

Returns the configured theme name string (from `ABBEY_THEME` env var or `Rails.application.config.theme`, defaulting to `"default"`).

## Filesystem conventions

```
app/themes/<name>/
  theme.rb               # manifest (required)
  assets/
    tailwind.css         # per-theme Tailwind entry point (recommended)
    <name>-highlight.css # optional: Rouge syntax theme
    *.css                # any extra CSS — auto-loaded when theme is active
  views/                 # ERB overrides (optional; ship any subset)
  README.md              # author notes
```

* The theme's `assets/` folder is registered with Propshaft at boot, so `stylesheet_link_tag "<filename-without-extension>"` resolves correctly.
* Logical asset paths are flat (no `themes/` prefix), so namespace your filenames (`<name>.css`, `<name>-highlight.css`) to avoid collisions.
* The `views/` folder is prepended to Rails' view path **per-request** while the theme is active. Theme switching at runtime works without restarting the process.

## Boot flow

```
Rails boot
  └─ config/initializers/themes.rb
       ├─ Rails.application.config.theme = ENV.fetch("ABBEY_THEME", "default")
       ├─ Abbey::Theme.load_all!
       │    └─ scans app/themes/*/theme.rb, evaluates each
       └─ Registers each theme's assets/ folder with config.assets.paths

Per-request
  └─ Theming concern (before_action)
       └─ Abbey::Theme.active.views_path → prepend_view_path

Layout render
  └─ app/views/layouts/application.html.erb (or theme override)
       └─ render "layouts/abbey_chrome"
            └─ reads Abbey::Theme.active manifest → emits head/body chrome
            └─ render "shared/{navigation,footer,dark_mode_script}"
                 └─ theme view overrides apply via prepended view path
```

## Helpers available in theme views

Theme view ERBs have access to every helper in `ApplicationHelper`, including:

| Helper                          | Returns |
|---------------------------------|---------|
| `current_theme`                 | The active theme's name as a string. |
| `active_theme`                  | The active `Abbey::Theme` instance. |
| `theme_active?`                 | `true` unless the active theme is the default sentinel. |
| `theme_stylesheets`             | Array of logical asset paths to load (e.g. `["tailwind-aurora", "aurora", "aurora-highlight"]`). |
| `dark_mode?`                    | `true` if the dark-mode cookie is set on the current request. |
| `chrome_html_class(theme)`      | Computed `<html>` class string for the active theme + dark mode state. |
| `meta_tags(...)`                | Emits the full set of OG / Twitter / canonical meta tags. |

Plus the standard Rails URL helpers, asset helpers, etc.

## Generator reference

```sh
bin/rails g abbey:theme NAME [--minimal] [--from=SOURCE]
```

| Flag        | Effect |
|-------------|--------|
| (no flag)   | Full scaffold: `theme.rb` + `assets/tailwind.css` + all 12 view stubs + `README.md`. |
| `--minimal` | Skips the view stubs; emits only manifest + tailwind entry + a 3-line layout + README. Use for pure recolors. |
| `--from=X`  | Clones theme `X`'s `views/` and non-`tailwind.css` assets as the starting point. Use for serious overrides. |

The generator:

* Validates the name against `/\A[a-z][a-z0-9_]*\z/`.
* Refuses to overwrite an existing `app/themes/<name>/`.
* Honors `destination_root` so it composes cleanly with `Rails::Generators::TestCase`.

## Rake tasks

| Task                            | What it does |
|---------------------------------|--------------|
| `bin/rails tailwindcss:build`   | Builds the default `tailwind.css` AND every theme's `tailwind-<name>.css` (the per-theme task is chained as an after-action). |
| `bin/rails themes:tailwind:build` | Builds only the per-theme bundles. |
| `bin/rails themes:tailwind:watch` | Spawns one Tailwind watcher per theme (used by `Procfile.dev`). |
| `bin/rails themes:tailwind:clobber` | Removes every compiled `tailwind-<name>.css`. Chained from `tailwindcss:clobber`. |

## Versioning

The manifest API and registry methods documented above are versioned alongside Abbey itself. Field additions are non-breaking. Field renames, removals, or behavior changes will be:

1. Announced in the changelog with a deprecation cycle (one minor version) when feasible.
2. Required to ship in a major version bump otherwise.

If you're shipping a community theme, pin Abbey's minimum version in your README.

## See also

* [`THEMES.md`](THEMES.md) — authoring guide and common patterns.
* [`lib/abbey/theme.rb`](../lib/abbey/theme.rb) — the registry implementation.
* [`app/views/layouts/_abbey_chrome.html.erb`](../app/views/layouts/_abbey_chrome.html.erb) — the chrome partial that consumes the manifest.
