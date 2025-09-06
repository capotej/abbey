require "test_helper"

class PdfPaperCreatorTest < ActiveSupport::TestCase
  def setup
    @pdf_url = "http://example.com/paper.pdf"
  end

  test "should create paper from PDF URL" do
    stub_request(:head, @pdf_url)
      .to_return(status: 200, headers: { "Content-Type" => "application/pdf" })
    stub_request(:get, @pdf_url)
      .to_return(status: 200, body: "PDF content", headers: { "Content-Type" => "application/pdf" })

    paper = PdfPaperCreator.create_from_url(@pdf_url)

    assert paper
    assert_equal @pdf_url, paper.url
    assert_equal "PDF Document", paper.title
    assert_equal "PDF document from #{@pdf_url}", paper.description
    assert paper.pdf.attached?
  end

  test "should return false for non-PDF URL" do
    html_url = "http://example.com/page.html"
    stub_request(:head, html_url)
      .to_return(status: 200, headers: { "Content-Type" => "text/html" })

    result = PdfPaperCreator.create_from_url(html_url)

    assert_equal false, result
  end
end
