class PdfPaperCreator
  require "net/http"
  require "uri"
  require "digest"
  require "stringio"

  def initialize(url)
    @url = url
  end

  def self.create_from_url(url)
    new(url).create
  end

  def create
    return false unless pdf_url?(@url)

    paper = Paper.new(url: pdf_url)

    # Set title and description
    if @url.include?("arxiv.org/abs/")
      # Use metainspector to get title and description from the abstract page
      page = MetaInspector.new(@url)
      paper.title = page.best_title
      paper.description = page.best_description
    else
      paper.title = "PDF Document"
      paper.description = "PDF document from #{@url}"
    end

    if paper.save
      # Download and attach the PDF
      download_and_attach_pdf(paper, pdf_url)
      paper
    else
      false
    end
  end

  private

  def pdf_url?(url)
    return false unless url

    # Special handling for arxiv URLs
    if url.include?("arxiv.org/abs/")
      return true
    end

    uri = URI.parse(url)
    return false unless uri.is_a?(URI::HTTP)

    # Make a HEAD request to check content type
    response = Net::HTTP.new(uri.host, uri.port)
    response.use_ssl = uri.scheme == "https"
    begin
      head_response = response.request_head(uri.request_uri)
      content_type = head_response["content-type"]
      content_type&.include?("application/pdf")
    rescue
      false
    end
  end

  def pdf_url
    if @url.include?("arxiv.org/abs/")
      @url.gsub("arxiv.org/abs/", "arxiv.org/pdf/")
    else
      @url
    end
  end

  def download_and_attach_pdf(paper, url)
    # Download the PDF and attach it to the paper
    begin
      uri = URI.parse(url)
      response = Net::HTTP.new(uri.host, uri.port)
      response.use_ssl = uri.scheme == "https"
      http_response = response.get(uri.request_uri)

      # Check if the response is successful
      if http_response.code == "200"
        paper.pdf.attach(
          io: StringIO.new(http_response.body),
          filename: "#{Digest::SHA2.hexdigest(url)}.pdf",
          content_type: "application/pdf"
        )
      else
        Rails.logger.error "Failed to download PDF: HTTP #{http_response.code} for #{url}"
      end
    rescue => e
      Rails.logger.error "Failed to download PDF: #{e.message}"
    end
  end
end
