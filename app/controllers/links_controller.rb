require "net/http"
require "uri"
require "digest"
require "stringio"

class LinksController < ApplicationController
  include ActiveStorage::SetCurrent
  allow_unauthenticated_access only: %i[ index feed ]

  def edit
    @link = Link.find(params[:id])
  end

  def new
    @link = Link.new
  end

  def index
    @links = Link.order(created_at: :desc).page(params[:page])
  end

  def feed
    @links = Link.order(created_at: :desc).limit(20)
    respond_to do |format|
      format.atom
    end
  end

  def create
    url = link_params[:url]

    # Check if the URL points to a PDF
    if pdf_url?(url)
      create_paper(url)
    else
      create_link
    end
  end

  def update
    @link = Link.find(params[:id])
    if @link.update(link_params)
      redirect_to links_path
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @link = Link.find(params[:id])
    @link.destroy
    redirect_to links_path
  end

  private
    def link_params
      params.expect(link: [ :title, :description, :url ])
    end

    def pdf_url?(url)
      return false unless url

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

    def create_paper(url)
      paper = Paper.new(url: url)

      # Set title and description
      paper.title = "PDF Document"
      paper.description = "PDF document from #{url}"

      if paper.save
        # Download and attach the PDF
        download_and_attach_pdf(paper, url)
        redirect_to papers_path
      else
        @link = Link.new(link_params)
        @link.errors.add(:url, "is invalid")
        render :new, status: :unprocessable_content
      end
    end

    def create_link
      @link = Link.new(link_params)
      if @link.save
        redirect_to links_path
      else
        render :new, status: :unprocessable_content
      end
    end

    def download_and_attach_pdf(paper, url)
      # Download the PDF and attach it to the paper
      begin
        uri = URI.parse(url)
        response = Net::HTTP.new(uri.host, uri.port)
        response.use_ssl = uri.scheme == "https"
        http_response = response.get(uri.request_uri)

        paper.pdf.attach(
          io: StringIO.new(http_response.body),
          filename: "#{Digest::SHA2.hexdigest(url)}.pdf",
          content_type: "application/pdf"
        )
      rescue => e
        Rails.logger.error "Failed to download PDF: #{e.message}"
      end
    end
end
