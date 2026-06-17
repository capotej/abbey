require "test_helper"
require "abbey/theme"

class Abbey::ThemeTest < ActiveSupport::TestCase
  setup do
    @original_registry = Abbey::Theme.registry.dup
    @original_theme    = Rails.application.config.theme
  end

  teardown do
    Abbey::Theme.reset!
    @original_registry.each_value { |t| Abbey::Theme.registry[t.name] = t }
    Rails.application.config.theme = @original_theme
  end

  test ".register stores the theme with the given block-configured values" do
    Abbey::Theme.reset!

    theme = Abbey::Theme.register(:aurora) do |t|
      t.display_name      = "Aurora"
      t.html_class        = "theme-aurora"
      t.body_class        = "bg-aurora"
      t.markdown_renderer = :minimal
      t.theme_color_light = "#ffffff"
      t.theme_color_dark  = "#000000"
      t.fonts             = ["https://example/fonts.css"]
    end

    assert_equal :aurora,                       theme.name
    assert_equal "Aurora",                      theme.display_name
    assert_equal "theme-aurora",                theme.html_class
    assert_equal "bg-aurora",                   theme.body_class
    assert_equal MinimalMarkdownRender,         theme.markdown_renderer
    assert_equal "#ffffff",                     theme.theme_color_light
    assert_equal "#000000",                     theme.theme_color_dark
    assert_equal ["https://example/fonts.css"], theme.fonts
    assert_same theme, Abbey::Theme.registry[:aurora]
  end

  test "#markdown_renderer defaults to MarkdownRender when unspecified" do
    Abbey::Theme.reset!
    theme = Abbey::Theme.register(:plain)

    assert_equal MarkdownRender, theme.markdown_renderer
  end

  test "#markdown_renderer accepts an explicit renderer class" do
    Abbey::Theme.reset!
    custom = Class.new(MarkdownRender)
    theme  = Abbey::Theme.register(:custom) { |t| t.markdown_renderer = custom }

    assert_equal custom, theme.markdown_renderer
  end

  test ".active returns the DefaultTheme sentinel when no theme is configured" do
    Abbey::Theme.reset!
    Rails.application.config.theme = "default"

    assert_instance_of Abbey::Theme::DefaultTheme, Abbey::Theme.active
    assert Abbey::Theme.active.default?
    refute Abbey::Theme.active?
  end

  test ".active returns the DefaultTheme sentinel for unknown themes" do
    Abbey::Theme.reset!
    Rails.application.config.theme = "does-not-exist"

    assert Abbey::Theme.active.default?
  end

  test ".active returns the registered theme when configured" do
    Abbey::Theme.reset!
    aurora = Abbey::Theme.register(:aurora)
    Rails.application.config.theme = "aurora"

    assert_same aurora, Abbey::Theme.active
    assert Abbey::Theme.active?
  end

  test ".active honors ABBEY_THEME env var over config" do
    Abbey::Theme.reset!
    Abbey::Theme.register(:aurora)
    Abbey::Theme.register(:nightfall)
    Rails.application.config.theme = "aurora"

    ENV["ABBEY_THEME"] = "nightfall"
    begin
      assert_equal :nightfall, Abbey::Theme.active.name
    ensure
      ENV.delete("ABBEY_THEME")
    end
  end

  test ".discover lists every folder under app/themes that has a manifest" do
    discovered = Abbey::Theme.discover

    assert_includes discovered, :retro
    assert_includes discovered, :grimoire
  end

  test ".load_all! loads every manifest under app/themes" do
    Abbey::Theme.reset!
    Abbey::Theme.load_all!

    assert_includes Abbey::Theme.registry.keys, :retro
    assert_includes Abbey::Theme.registry.keys, :grimoire
  end

  test "#stylesheets enumerates the theme's assets, excluding tailwind.css" do
    Abbey::Theme.reset!
    Abbey::Theme.load_all!

    retro = Abbey::Theme.registry[:retro]
    assert_includes retro.stylesheets, "retro"
    assert_includes retro.stylesheets, "retro-highlight"
    refute_includes retro.stylesheets, "tailwind"
  end

  test "DefaultTheme has nil view/asset paths and no stylesheets" do
    default = Abbey::Theme::DefaultTheme.instance

    assert_nil    default.views_path
    assert_nil    default.assets_path
    assert_empty  default.stylesheets
    assert_equal  MarkdownRender, default.markdown_renderer
  end
end
