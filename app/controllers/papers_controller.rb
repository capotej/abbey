class PapersController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

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

  private

  def paper_params
    params.require(:paper).permit(:title, :description)
  end
end
