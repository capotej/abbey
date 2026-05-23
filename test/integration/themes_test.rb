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
    assert_no_match(%r{themes/retro}, response.body, "default theme should not load theme stylesheets")
    assert_select "header h1"
    assert_select "footer"
  end

  test "retro theme prepends its view path and loads theme stylesheets" do
    Rails.application.config.theme = "retro"

    get root_path
    assert_response :success
    assert_match(/class="theme-retro/, response.body)
    assert_match(%r{themes/retro}, response.body, "retro theme should load themes/retro CSS")
    # System test contract: header still has h1, footer still present.
    assert_select "header h1"
    assert_select "footer"
    # Required nav links remain after retheming.
    %w[Home About Projects Presentations Links Papers].each do |label|
      assert_match(/>#{label}</, response.body, "retro nav should contain link: #{label}")
    end
  end

  test "renderer follows theme configuration" do
    Rails.application.config.theme = "default"
    assert_equal MarkdownRender, Post.markdown_renderer,
                 "default theme should use the original utility-class renderer"

    Rails.application.config.theme = "retro"
    assert_equal MinimalMarkdownRender, Post.markdown_renderer,
                 "retro theme should switch to the minimal renderer"
  end

  test "theme_stylesheets helper is empty for default and populated for retro" do
    helper = Class.new do
      include ApplicationHelper
      attr_accessor :_theme

      def current_theme
        @_theme.to_s
      end

      def theme_active?
        current_theme.present? && current_theme != "default"
      end
    end.new

    helper._theme = "default"
    assert_empty helper.theme_stylesheets

    helper._theme = "retro"
    assert_includes helper.theme_stylesheets, "themes/retro"
    assert_includes helper.theme_stylesheets, "themes/retro-highlight"
  end
end
