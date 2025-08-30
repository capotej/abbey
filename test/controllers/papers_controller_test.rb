require "test_helper"

class PapersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get papers_url
    assert_response :success
  end

  test "should get show" do
    paper = Paper.create!(url: "http://example.com/paper.pdf")
    get paper_url(paper)
    assert_response :success
  end
end
