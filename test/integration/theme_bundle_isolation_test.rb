require "test_helper"

# Regression test for Abbey's "drop-in theme" guarantee: the default
# Tailwind bundle must stay byte-for-byte unchanged regardless of how
# many themes the project ships. Each theme compiles to its own
# tailwind-<name>.css and is loaded only when that theme is active.
#
# These assertions catch:
#   * accidental leaks (the default scan picking up app/themes/**)
#   * accidental migration of theme tokens back into application.css
#   * theme bundles missing their own tokens
#
# Requires `bin/rails tailwindcss:build` to have run (the rails test
# rake task chains tailwindcss:build via test:prepare).
class ThemeBundleIsolationTest < ActiveSupport::TestCase
  BUILDS = Rails.root.join("app/assets/builds")

  def read(path)
    full = BUILDS.join(path)
    skip "Tailwind build #{path} missing — run `bin/rails tailwindcss:build`" unless full.exist?
    full.read
  end

  test "default tailwind.css does not contain any theme color tokens" do
    default = read("tailwind.css")

    refute_match(/--color-memphis-[a-z]+/, default,
                 "default bundle leaked Memphis color tokens — check @source not config in application.css")
    refute_match(/--color-grim-[a-z]+/,    default,
                 "default bundle leaked Grimoire color tokens — check @source not config in application.css")
    refute_match(/--shadow-retro/,         default,
                 "default bundle leaked retro shadow tokens")
  end

  test "default tailwind.css does not contain any theme-only utilities" do
    default = read("tailwind.css")

    refute_match(/\.bg-memphis-pink/,  default, "default bundle emitted bg-memphis-pink — check @source not config")
    refute_match(/\.bg-grim-void/,     default, "default bundle emitted bg-grim-void — check @source not config")
    refute_match(/\.shadow-retro-lg/,  default, "default bundle emitted shadow-retro-lg — check @source not config")
  end

  test "tailwind-retro.css contains memphis tokens + utilities" do
    retro = read("tailwind-retro.css")

    assert_match(/--color-memphis-pink/, retro, "retro bundle missing memphis pink token")
    assert_match(/--color-memphis-ink/,  retro, "retro bundle missing memphis ink token")
    assert_match(/--shadow-retro-lg/,    retro, "retro bundle missing retro-lg shadow token")
    assert_match(/\.bg-memphis-/,        retro, "retro bundle missing memphis bg utility (used in views)")
  end

  test "tailwind-grimoire.css contains grim tokens + utilities" do
    grimoire = read("tailwind-grimoire.css")

    assert_match(/--color-grim-void/,      grimoire, "grimoire bundle missing grim void token")
    assert_match(/--color-grim-parchment/, grimoire, "grimoire bundle missing grim parchment token")
    assert_match(/\.bg-grim-/,             grimoire, "grimoire bundle missing grim bg utility (used in views)")
  end

  test "retro bundle does not contain grimoire tokens (themes are isolated from each other)" do
    retro = read("tailwind-retro.css")

    refute_match(/--color-grim-[a-z]+/, retro,
                 "retro bundle leaked Grimoire tokens — each theme should only scan its own views")
  end

  test "midnight (sample theme) bundle ships its tokens and stays out of the default" do
    midnight = read("tailwind-midnight.css")
    default  = read("tailwind.css")

    assert_match(/--color-midnight-bg/,     midnight, "midnight bundle missing its core token")
    assert_match(/--color-midnight-accent/, midnight, "midnight bundle missing its accent token")
    refute_match(/--color-midnight-/,       default,  "default bundle leaked Midnight tokens")
  end
end
