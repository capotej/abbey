require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "valid project with all fields" do
    project = Project.new(
      name: "Abbey",
      year: 2024,
      github_url: "https://github.com/capotej/abbey",
      license: "MIT",
      language: "Ruby",
      description: "A personal blog."
    )
    assert project.valid?
  end

  test "invalid without name" do
    project = Project.new(name: nil)
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "ordered by year descending by default" do
    old = Project.create!(name: "Old", year: 2020)
    recent = Project.create!(name: "Recent", year: 2024)
    assert_equal [ recent, old ], Project.where(id: [ old.id, recent.id ]).order(year: :desc)
  end
end
