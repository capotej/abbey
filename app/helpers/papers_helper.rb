module PapersHelper
  include Rails.application.routes.url_helpers

  def paper_view_path(paper)
    if paper.arxiv?
      paper.arxiv_pdf_url
    elsif paper.pdf.attached?
      rails_blob_path(paper.pdf, disposition: "inline")
    elsif paper.url.present?
      paper.url
    else
      nil
    end
  end
end
