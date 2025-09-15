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
    links = Link.order(created_at: :desc).limit(20)
    papers = Paper.order(created_at: :desc).limit(20)

    # Combine and sort by created_at, then take the most recent 20
    @entries = (links + papers).sort_by(&:created_at).reverse.first(20)

    respond_to do |format|
      format.atom
    end
  end

  def create
    url = link_params[:url]

    # Check if the URL points to a PDF and create a paper if it does
    paper = PdfPaperCreator.create_from_url(url)
    if paper
      redirect_to papers_path
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

    def create_link
      @link = Link.new(link_params)
      if @link.save
        redirect_to links_path
      else
        render :new, status: :unprocessable_content
      end
    end
end
