require "test_helper"
require "nokogiri"

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

  test "feed should include both links and papers" do
    # Stub HTTP requests for link creation
    stub_request(:get, "http://example.com/test-link1")
      .to_return(status: 200, body: "<html><head><title>Link 1</title><meta name='description' content='Description 1'></head></html>", headers: { "Content-Type" => "text/html" })
    stub_request(:get, "http://example.com/test-link2")
      .to_return(status: 200, body: "<html><head><title>Link 2</title><meta name='description' content='Description 2'></head></html>", headers: { "Content-Type" => "text/html" })

    # Create some links
    link1 = Link.create!(url: "http://example.com/test-link1")
    link2 = Link.create!(url: "http://example.com/test-link2")

    # Create some papers
    paper1 = Paper.create!(url: "http://example.com/test-paper1.pdf", title: "Paper 1", description: "Description 1")
    paper2 = Paper.create!(url: "http://example.com/test-paper2.pdf", title: "Paper 2", description: "Description 2")

    # Make sure the papers have different created_at times
    paper1.update(created_at: 2.days.ago)
    paper2.update(created_at: 1.day.ago)

    get links_feed_url, params: { format: "atom" }

    assert_response :success
    assert response.content_type.start_with?("application/atom+xml")

    # Check that both links and papers are in the feed
    # Note: We might have more than 4 entries if there are existing fixtures
    assert_select "entry title", text: "Link 1"
    assert_select "entry title", text: "Link 2"
    assert_select "entry title", text: "Paper 1"
    assert_select "entry title", text: "Paper 2"
  end

  test "feed should use proper URLs for arXiv papers" do
    # Stub HTTP requests for link creation
    stub_request(:get, "http://example.com/test-link")
      .to_return(status: 200, body: "<html><head><title>Regular Link</title><meta name='description' content='Description'></head></html>", headers: { "Content-Type" => "text/html" })

    # Create a regular link
    link = Link.create!(url: "http://example.com/test-link")

    # Create a regular paper
    regular_paper = Paper.create!(url: "http://example.com/test-paper.pdf", title: "Regular Paper", description: "Description")

    # Create an arXiv paper
    arxiv_paper = Paper.create!(url: "https://arxiv.org/abs/1234.56789", title: "ArXiv Paper", description: "Description")

    get links_feed_url, params: { format: "atom" }

    assert_response :success

    # Check that the regular paper uses its own URL
    assert_select "entry link[href='#{regular_paper.url}']", count: 1

    # Check that the arXiv paper uses the PDF URL
    assert_select "entry link[href='#{arxiv_paper.display_url}']", count: 1
  end

  test "feed should be ordered by creation date" do
    # Stub HTTP requests for link creation
    stub_request(:get, "http://example.com/test-oldest")
      .to_return(status: 200, body: "<html><head><title>Oldest Link</title><meta name='description' content='Description'></head></html>", headers: { "Content-Type" => "text/html" })
    stub_request(:get, "http://example.com/test-newest")
      .to_return(status: 200, body: "<html><head><title>Newest Link</title><meta name='description' content='Description'></head></html>", headers: { "Content-Type" => "text/html" })

    # Create items at different times
    oldest_link = Link.create!(url: "http://example.com/test-oldest")
    oldest_link.update(created_at: 3.days.ago)

    middle_paper = Paper.create!(url: "http://example.com/test-middle.pdf", title: "Middle Paper", description: "Description")
    middle_paper.update(created_at: 2.days.ago)

    newest_link = Link.create!(url: "http://example.com/test-newest")
    newest_link.update(created_at: 1.day.ago)

    get links_feed_url, params: { format: "atom" }

    assert_response :success

    # Parse the XML to check ordering
    xml = Nokogiri::XML(response.body)
    entries = xml.xpath("//xmlns:entry")

    # Find our specific entries among possibly others
    entry_titles = entries.map { |entry| entry.at_xpath(".//xmlns:title").text }

    # Find positions of our test entries
    oldest_pos = entry_titles.index("Oldest Link")
    middle_pos = entry_titles.index("Middle Paper")
    newest_pos = entry_titles.index("Newest Link")

    # Verify that they exist
    refute_nil oldest_pos, "Oldest Link should be in the feed"
    refute_nil middle_pos, "Middle Paper should be in the feed"
    refute_nil newest_pos, "Newest Link should be in the feed"

    # Verify ordering: newest should come before middle, which should come before oldest
    assert newest_pos < middle_pos, "Newest Link should come before Middle Paper"
    assert middle_pos < oldest_pos, "Middle Paper should come before Oldest Link"
  end

  private

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end
end
