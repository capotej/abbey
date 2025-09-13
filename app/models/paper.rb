require "net/http"
require "uri"
require "digest"

class Paper < ApplicationRecord
  validates_presence_of :url
  validates :url, uniqueness: true

  has_one_attached :pdf

  before_create :set_title_and_desc

  paginates_per 15

  def uuid
    Digest::SHA2.hexdigest self.url
  end

  def arxiv?
    url&.include?("arxiv.org")
  end

  def arxiv_pdf_url
    return nil unless arxiv?

    if url.include?("arxiv.org/abs/")
      url.gsub("arxiv.org/abs/", "arxiv.org/pdf/")
    elsif url.include?("arxiv.org/pdf/")
      url
    else
      nil
    end
  end

  def display_url
    arxiv? ? arxiv_pdf_url : nil
  end

  private

  def set_title_and_desc
    # Try to get title and description from the PDF metadata or URL
    self.title ||= extract_title_from_url
    self.description ||= "PDF document from #{url}"
  end

  def extract_title_from_url
    # Extract filename from URL if possible
    uri = URI.parse(url)
    filename = File.basename(uri.path, ".*")

    # If filename is meaningful, use it as title
    if filename.present? && filename != "index" && filename.length > 3
      filename.gsub(/[-_]/, " ").titleize
    else
      "Untitled Paper"
    end
  end
end
