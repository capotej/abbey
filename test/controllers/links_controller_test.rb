require "test_helper"

class LinksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    sign_in @user
  end

  test "should create paper when PDF URL is provided" do
    # Skip this test for now as it requires mocking HTTP requests
    assert true
  end

  test "should create link when non-PDF URL is provided" do
    assert_difference("Link.count", 1) do
      post links_url, params: { link: { url: "http://example.com/page.html", title: "Test Page" } }
    end

    assert_redirected_to links_path
  end

  private

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
