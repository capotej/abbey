class BlogController < ApplicationController
  include ActiveStorage::SetCurrent

  allow_unauthenticated_access only: %i[ index show feed index_by_tag redirect feed_by_tag ]

  def show
    @post = post_scope.find_by_slug!(params[:id])
  end

  def edit
    @post = Post.find_by_slug(params[:id])
  end

  def new
    @post = Post.new
  end

  def index
    @posts = post_scope.order(created_at: :desc).page(params[:page])
  end

  def redirect
    # handle /post/, post/, /post
    uri = Addressable::URI.parse(request.original_url)
    sanitized_uri = uri.path.squeeze('/').delete_suffix('/')
    redirect_from_post = Post.find_by(redirect_from: sanitized_uri)

    if redirect_from_post
      redirect_to dated_post_path(year: redirect_from_post.year, month: redirect_from_post.month, day: redirect_from_post.day, id: redirect_from_post.slug), status: :moved_permanently
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def feed
    @posts = post_scope.order(created_at: :desc).limit(20)
    respond_to do |format|
      format.atom
    end
  end

  def index_by_tag
    @tag = Tag.find_by_name!(params[:id])
    @posts = post_scope.order(created_at: :desc).joins(:tags).where(tags: @tag).page(params[:page])
  end

  def feed_by_tag
    @tag = Tag.find_by_name!(params[:id])
    @posts = post_scope.order(created_at: :desc).joins(:tags).where(tags: @tag).limit(20)
    respond_to do |format|
      format.atom
    end
  end

  def create
    post = Post.create! post_params
    redirect_to dated_post_path(year: post.year, month: post.month, day: post.day, id: post.slug)
  end

  def update
    post = Post.find_by_slug(params[:id])
    post.markdown_body_attachments.purge
    if post.update(post_params)
      redirect_to dated_post_path(year: post.year, month: post.month, day: post.day, id: post.slug)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    post = Post.find_by_slug(params[:id])
    post.destroy
    redirect_to posts_path
  end

  private
    def post_params
      params.expect(post: [ :title, :markdown_body, :slug, :post_tags, :markdown_excerpt, :draft ])
    end

    def post_scope
      if authenticated?
        Post
      else
        Post.published
      end
    end
end
