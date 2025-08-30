class PapersController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  before_action :authenticate_user!, except: %i[ index show ]

  def index
    @papers = Paper.order(created_at: :desc).page(params[:page])
  end

  def show
    @paper = Paper.find(params[:id])
  end

  def edit
    @paper = Paper.find(params[:id])
  end

  def update
    @paper = Paper.find(params[:id])
    if @paper.update(paper_params)
      redirect_to @paper, notice: "Paper was successfully updated."
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

  private

  def paper_params
    params.require(:paper).permit(:title, :description)
  end
end
