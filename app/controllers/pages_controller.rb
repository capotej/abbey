class PagesController < ApplicationController
  include ActiveStorage::SetCurrent
  allow_unauthenticated_access only: %i[ show ]

  def show
    @page = Page.find_by_slug!(params[:id])
  end

  def edit
    @page = Page.find_by_slug(params[:id])
  end

  def new
    @page = Page.new
  end

  def index
    @pages = Page.order(created_at: :desc).page(params[:page])
  end

  def create
    @page = Page.new(page_params)
    if @page.save
      redirect_to @page
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @page = Page.find_by_slug(params[:id])
    @page.markdown_body_attachments.purge
    if @page.update(page_params)
      redirect_to @page
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @page = Page.find_by_slug(params[:id])
    @page.destroy
    redirect_to posts_path
  end

  private
    def page_params
      params.expect(page: [ :title, :markdown_body, :slug ])
    end
end
