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
    assert_select "header h1"
    assert_select "footer"
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
