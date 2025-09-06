require "test_helper"

class LinksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    sign_in @user
  end

  test "should create paper when PDF URL is provided" do
    stub_request(:head, "http://example.com/paper.pdf")
      .to_return(status: 200, headers: { "Content-Type" => "application/pdf" })
    stub_request(:get, "http://example.com/paper.pdf")
      .to_return(status: 200, body: "PDF content", headers: { "Content-Type" => "application/pdf" })

    assert_difference("Paper.count", 1) do
      post links_url, params: { link: { url: "http://example.com/paper.pdf", title: "Test PDF" } }
    end

    assert_redirected_to papers_path
  end

  test "should create link when non-PDF URL is provided" do
    stub_request(:head, "http://example.com/page.html")
      .to_return(status: 200, headers: { "Content-Type" => "text/html" })
    stub_request(:get, "http://example.com/page.html")
      .to_return(status: 200, body: "<html><head><title>Test Page</title><meta name='description' content='Test description'></head></html>", headers: { "Content-Type" => "text/html" })

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
