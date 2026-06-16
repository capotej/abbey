require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:abbey)
  end

  test "should get index without authentication" do
    get projects_url
    assert_response :success
  end

  test "should not get new without authentication" do
    get new_project_url
    assert_response :redirect
  end

  test "should get new when authenticated" do
    sign_in(@user)
    get new_project_url
    assert_response :success
  end

  test "should create project when authenticated" do
    sign_in(@user)
    assert_difference("Project.count", 1) do
      post projects_url, params: {
        project: {
          name: "New Project",
          year: 2025,
          github_url: "https://github.com/capotej/new-project",
          license: "MIT",
          language: "Go",
          description: "A new project."
        }
      }
    end
    assert_redirected_to projects_url
  end

  test "should not create project with invalid data" do
    sign_in(@user)
    assert_no_difference("Project.count") do
      post projects_url, params: { project: { name: "" } }
    end
    assert_response :unprocessable_content
  end

  test "should get edit when authenticated" do
    sign_in(@user)
    get edit_project_url(@project)
    assert_response :success
  end

  test "should update project when authenticated" do
    sign_in(@user)
    patch project_url(@project), params: {
      project: { name: "Updated Abbey" }
    }
    assert_redirected_to projects_url
    assert_equal "Updated Abbey", @project.reload.name
  end

  test "should destroy project when authenticated" do
    sign_in(@user)
    assert_difference("Project.count", -1) do
      delete project_url(@project)
    end
    assert_redirected_to projects_url
  end

  private

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
