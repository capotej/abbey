require "application_system_test_case"

class ProjectsTest < ApplicationSystemTestCase
  test "can view projects page publicly" do
    visit projects_path
    assert_selector "h1", text: "Projects"
    assert_text "Abbey"
    assert_text "A personal blog built with Rails."
  end

  test "projects page shows GitHub link" do
    visit projects_path
    assert_link "Abbey", href: "https://github.com/capotej/abbey"
  end

  test "projects are ordered by year descending" do
    visit projects_path
    # Abbey (2024) should appear before Example Project (2022)
    first_position = page.text.index("Abbey")
    second_position = page.text.index("Example Project")
    assert first_position < second_position, "Abbey should appear before Example Project"
  end

  test "projects page shows language and license badges" do
    visit projects_path
    assert_text "Ruby"
    assert_text "MIT"
  end

  test "can create a new project when logged in" do
    sign_in_as users(:one)
    visit new_project_path

    fill_in "Name", with: "New Lib"
    fill_in "Year", with: "2025"
    fill_in "Github url", with: "https://github.com/capotej/new-lib"
    fill_in "License", with: "ISC"
    fill_in "Language", with: "Rust"
    fill_in "Description", with: "A new Rust library."
    click_button "Create Project"

    assert_current_path projects_path
    assert_text "New Lib"
    assert_text "Rust"
    assert_text "ISC"
  end

  test "cannot create project with missing name" do
    sign_in_as users(:one)
    visit new_project_path

    click_button "Create Project"
    assert_text "can't be blank"
  end

  test "edit link visible on projects when logged in" do
    sign_in_as users(:one)
    visit projects_path
    assert_link "Edit"
  end

  test "edit link hidden on projects when logged out" do
    visit projects_path
    assert_no_link "Edit"
  end

  test "can edit an existing project" do
    sign_in_as users(:one)
    visit projects_path

    click_link "Edit", match: :first
    fill_in "Name", with: "Updated Abbey"
    click_button "Update Project"

    assert_current_path projects_path
    assert_text "Updated Abbey"
  end

  test "can delete a project" do
    sign_in_as users(:one)
    visit projects_path

    click_link "Edit", match: :first
    accept_confirm do
      click_button "Delete"
    end

    assert_current_path projects_path
    assert_no_text "Abbey"
  end

  test "unauthenticated user redirected to login when accessing new project form" do
    visit new_project_path
    assert_current_path new_session_path
  end
end
