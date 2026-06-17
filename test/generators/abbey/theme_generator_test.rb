require "test_helper"
require "rails/generators/test_case"
require "generators/abbey/theme/theme_generator"

class Abbey::Generators::ThemeGeneratorTest < Rails::Generators::TestCase
  tests Abbey::Generators::ThemeGenerator

  destination File.expand_path("../../tmp/generator_test", __dir__)
  setup :prepare_destination

  test "generates a complete theme scaffold under app/themes/<name>/" do
    run_generator [ "midnight" ]

    assert_file "app/themes/midnight/theme.rb",            /Abbey::Theme\.register\(:midnight\)/
    assert_file "app/themes/midnight/theme.rb",            /t\.display_name\s+=\s+"Midnight"/
    assert_file "app/themes/midnight/theme.rb",            /t\.html_class\s+=\s+"theme-midnight"/
    assert_file "app/themes/midnight/assets/tailwind.css", /@import 'tailwindcss'/
    assert_file "app/themes/midnight/assets/tailwind.css", /@source "..\/views"/
    assert_file "app/themes/midnight/assets/tailwind.css", /--color-midnight-/
    assert_file "app/themes/midnight/views/layouts/application.html.erb", %r{render "layouts/abbey_chrome"}
    assert_file "app/themes/midnight/views/shared/_navigation.html.erb"
    assert_file "app/themes/midnight/views/shared/_footer.html.erb"
    assert_file "app/themes/midnight/views/shared/_admin_navigation.html.erb"
    assert_file "app/themes/midnight/views/shared/_tags.html.erb"
    assert_file "app/themes/midnight/views/blog/index.html.erb"
    assert_file "app/themes/midnight/views/blog/show.html.erb"
    assert_file "app/themes/midnight/views/blog/index_by_tag.html.erb"
    assert_file "app/themes/midnight/views/pages/show.html.erb"
    assert_file "app/themes/midnight/views/links/index.html.erb"
    assert_file "app/themes/midnight/views/links/_link.html.erb"
    assert_file "app/themes/midnight/views/papers/index.html.erb"
    assert_file "app/themes/midnight/views/papers/_paper.html.erb"
    assert_file "app/themes/midnight/README.md"
  end

  test "--minimal only emits manifest + tailwind + layout shell" do
    run_generator [ "spark", "--minimal" ]

    assert_file "app/themes/spark/theme.rb"
    assert_file "app/themes/spark/assets/tailwind.css"
    assert_file "app/themes/spark/views/layouts/application.html.erb"
    assert_file "app/themes/spark/README.md"
    assert_no_file "app/themes/spark/views/shared/_navigation.html.erb"
    assert_no_file "app/themes/spark/views/blog/show.html.erb"
  end

  test "--from clones the source theme's views + assets" do
    FileUtils.mkdir_p(File.join(destination_root, "app/themes/retro/views/shared"))
    FileUtils.mkdir_p(File.join(destination_root, "app/themes/retro/assets"))
    File.write(File.join(destination_root, "app/themes/retro/views/shared/_navigation.html.erb"), "MARKER_NAV")
    File.write(File.join(destination_root, "app/themes/retro/assets/retro-highlight.css"),         "MARKER_HIGHLIGHT")

    run_generator [ "neon", "--from=retro" ]

    assert_file "app/themes/neon/theme.rb"
    assert_file "app/themes/neon/assets/tailwind.css"
    assert_file "app/themes/neon/views/shared/_navigation.html.erb", "MARKER_NAV"
    assert_file "app/themes/neon/assets/retro-highlight.css",        "MARKER_HIGHLIGHT"
    # Source theme's tailwind.css is NOT cloned (regenerated from template).
    refute_includes File.read(File.join(destination_root, "app/themes/neon/assets/tailwind.css")),
                    "memphis"
  end

  test "rejects invalid theme names" do
    # Thor catches Thor::Error and prints to stderr; the generator returns
    # normally rather than raising, so we assert on stderr output.
    # Rails::Generators::NamedBase runs file_name through #underscore, so
    # casing alone isn't enough to fail — invalid input here is anything
    # that survives normalization and still doesn't fit the slug shape.
    [ "Has Spaces", "9starts-numeric", "with.dots" ].each do |bad|
      err = capture(:stderr) { run_generator [ bad ] }
      assert_match(/must be lowercase/, err, "should reject name: #{bad.inspect}")
    end
  end

  test "refuses to overwrite an existing theme" do
    run_generator [ "twice" ]
    err = capture(:stderr) { run_generator [ "twice" ] }
    assert_match(/A theme already exists/, err)
  end

  test "generated theme.rb is valid Ruby that registers with Abbey::Theme" do
    run_generator [ "valid" ]

    Abbey::Theme.reset!
    load File.join(destination_root, "app/themes/valid/theme.rb")
    theme = Abbey::Theme.registry[:valid]

    assert theme, "generated manifest should register the :valid theme"
    assert_equal "Valid",         theme.display_name
    assert_equal "theme-valid",   theme.html_class
    assert_equal MarkdownRender,  theme.markdown_renderer
  ensure
    Abbey::Theme.reset!
    Abbey::Theme.load_all!
  end
end
