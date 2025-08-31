class PapersController < ApplicationController
  allow_unauthenticated_access only: %i[ index download ]

  def index
    @papers = Paper.order(created_at: :desc).page(params[:page])
  end

  def edit
    @paper = Paper.find(params[:id])
  end

  def update
    @paper = Paper.find(params[:id])
    if @paper.update(paper_params)
      redirect_to papers_path, notice: "Paper was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @paper = Paper.find(params[:id])
    @paper.destroy
    redirect_to papers_path, notice: "Paper was successfully deleted."
  end

  def download
    paper = Paper.find(params[:id])
    if paper.pdf.attached?
      redirect_to rails_blob_path(paper.pdf, disposition: "attachment")
    else
      redirect_to papers_path, notice: "PDF not available for download"
    end
  end

  def view
    paper = Paper.find(params[:id])
    if paper.pdf.attached?
      redirect_to rails_blob_path(paper.pdf, disposition: "inline")
    elsif paper.url.present?
      redirect_to paper.url, allow_other_host: true
    else
      redirect_to papers_path, notice: "PDF not available for viewing"
    end
  end

  private

  def paper_params
    params.require(:paper).permit(:title, :description)
  end
end
