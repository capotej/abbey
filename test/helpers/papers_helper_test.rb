require "test_helper"

class PapersHelperTest < ActionView::TestCase
  include PapersHelper

  test "paper_view_path for arxiv paper" do
    paper = Paper.new(url: "https://arxiv.org/abs/1234.56789")
    assert_equal "https://arxiv.org/pdf/1234.56789", paper_view_path(paper)
  end

  test "paper_view_path for paper with attached pdf" do
    paper = Paper.create!(url: "https://example.com/paper.pdf")
    file = Rack::Test::UploadedFile.new("test/fixtures/files/sample.pdf", "application/pdf")
    paper.pdf.attach(file)

    # The exact path will include a digest, so we'll just check that it's a blob path
    path = paper_view_path(paper)
    assert path.include?("/rails/active_storage/blobs/")
    assert path.include?("disposition=inline")
  end

  test "paper_view_path for paper with external url" do
    paper = Paper.new(url: "https://example.com/paper.pdf")
    assert_equal "https://example.com/paper.pdf", paper_view_path(paper)
  end

  test "paper_view_path returns nil for paper with no url or attachment" do
    paper = Paper.new(url: "")
    assert_nil paper_view_path(paper)
  end
end
