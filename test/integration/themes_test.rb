require "test_helper"

class ThemesTest < ActionDispatch::IntegrationTest
  # The theme is read from Rails.application.config.theme at boot time, so we
  # exercise theme switching by toggling it in place around each request.
  setup do
    @original_theme = Rails.application.config.theme
  end

  teardown do
    Rails.application.config.theme = @original_theme
  end

  test "default theme renders the original layout" do
    Rails.application.config.theme = "default"

    get root_path
    assert_response :success
    assert_no_match(/class="theme-retro/, response.body)
    assert_no_match(/class="theme-grimoire/, response.body)
    assert_no_match(%r{/assets/retro[-/]},     response.body, "default theme should not load retro CSS")
    assert_no_match(%r{/assets/grimoire[-/]},  response.body, "default theme should not load grimoire CSS")
    # Default chrome contract: html background, main wrapper, default favicon.
    assert_match(/<html class="bg-white">/,                            response.body)
    assert_match(/<body class="min-h-screen bg-white dark:bg-gray-900/, response.body)
    assert_match(%r{<main class="container mx-auto px-4 py-8">},        response.body)
    assert_match(%r{<link rel="icon" href="data:image/svg\+xml,},       response.body, "default theme should emit its inline favicon")
    # No theme tailwind bundles leak into the default :app inclusion.
    assert_no_match(%r{/assets/tailwind-retro},    response.body, "default :app must not include per-theme tailwind bundles")
    assert_no_match(%r{/assets/tailwind-grimoire}, response.body, "default :app must not include per-theme tailwind bundles")
    assert_select "header h1"
    assert_select "footer"
  end

  test "chrome partial drives <head> entirely from theme manifest" do
    Rails.application.config.theme = "retro"

    get root_path
    assert_response :success
    body = response.body

    assert_match(/<html class="theme-retro">/,                        body, "retro html_class should be applied")
    assert_match(/<body class="min-h-screen flex flex-col font-sans/, body, "retro body_class should be applied")
    assert_match(%r{<main class="container mx-auto px-4 py-8 max-w-5xl content-layer flex-1">}, body)
    # theme_color emitted as media-aware pair from manifest
    assert_match %r{<meta name="theme-color" content="#fff8ef" media="\(prefers-color-scheme: light\)">}, body
    assert_match %r{<meta name="theme-color" content="#0a0e1a" media="\(prefers-color-scheme: dark\)">},  body
    # Manifest fonts emitted with preconnect
    assert_match %r{rel="preconnect" href="https://fonts.googleapis.com"}, body
    assert_match %r{Press\+Start\+2P}, body
    # Manifest favicon emitted (memphis 4-square SVG)
    assert_match %r{<link rel="icon" href="data:image/svg\+xml,.*memphis|.*ff3eb5}, body
  end

  test "dark mode cookie drives html classes from theme manifest" do
    Rails.application.config.theme = "default"
    cookies[:dark_mode] = "true"

    get root_path
    assert_response :success
    assert_match(/<html class="dark bg-gray-900">/, response.body)

    Rails.application.config.theme = "retro"
    get root_path
    assert_match(/<html class="theme-retro dark">/, response.body)
  end

  test "dark mode script syncs cookie state and survives turbo navigation" do
    Rails.application.config.theme = "retro"

    get root_path
    assert_response :success
    assert_match(/applyAbbeyDarkMode/, response.body)
    assert_match(/turbo:load/, response.body)
    assert_match(/theme-retro/, response.body)
  end

  test "retro theme prepends its view path and loads theme stylesheets" do
    Rails.application.config.theme = "retro"

    get root_path
    assert_response :success
    assert_match(/class="theme-retro/, response.body)
    assert_match(%r{/assets/tailwind-retro[-.]}, response.body, "retro theme should load its Tailwind bundle")
    assert_match(%r{/assets/retro[-.]},           response.body, "retro theme should load retro.css")
    assert_match(%r{/assets/retro-highlight[-.]}, response.body, "retro theme should load retro-highlight.css")
    # System test contract: header still has h1, footer still present.
    assert_select "header h1"
    assert_select "footer"
    # Required nav links remain after retheming.
    %w[Home About Projects Presentations Links Papers].each do |label|
      assert_match(/>#{label}</, response.body, "retro nav should contain link: #{label}")
    end
  end

  test "grimoire theme prepends its view path and loads theme stylesheets" do
    Rails.application.config.theme = "grimoire"

    get root_path
    assert_response :success
    assert_match(/class="theme-grimoire/, response.body)
    assert_match(%r{/assets/tailwind-grimoire[-.]}, response.body, "grimoire theme should load its Tailwind bundle")
    assert_match(%r{/assets/grimoire[-.]},           response.body, "grimoire theme should load grimoire.css")
    assert_match(%r{/assets/grimoire-highlight[-.]}, response.body, "grimoire theme should load grimoire-highlight.css")
    # System test contract: header still has h1, footer still present.
    assert_select "header h1"
    assert_select "footer"
    # Required nav links remain after retheming.
    %w[Home About Projects Presentations Links Papers].each do |label|
      assert_match(/>#{label}</, response.body, "grimoire nav should contain link: #{label}")
    end
  end

  test "renderer follows theme configuration" do
    Rails.application.config.theme = "default"
    assert_equal MarkdownRender, Post.markdown_renderer,
                 "default theme should use the original utility-class renderer"

    Rails.application.config.theme = "retro"
    assert_equal MinimalMarkdownRender, Post.markdown_renderer,
                 "retro theme should switch to the minimal renderer"

    Rails.application.config.theme = "grimoire"
    assert_equal MinimalMarkdownRender, Post.markdown_renderer,
                 "grimoire theme should switch to the minimal renderer"
  end

  test "theme_stylesheets helper is empty for default and populated for named themes" do
    helper = Class.new { include ApplicationHelper }.new

    Rails.application.config.theme = "default"
    assert_empty helper.theme_stylesheets

    Rails.application.config.theme = "retro"
    sheets = helper.theme_stylesheets
    assert_includes sheets, "retro"
    assert_includes sheets, "retro-highlight"

    Rails.application.config.theme = "grimoire"
    sheets = helper.theme_stylesheets
    assert_includes sheets, "grimoire"
    assert_includes sheets, "grimoire-highlight"
  end
end
