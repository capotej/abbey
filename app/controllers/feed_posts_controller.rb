class FeedPostsController < ApplicationController
  def index
    @feed_posts = FeedPost.order(created_at: :desc).page(params[:page])
  end

  def promote
    @feed_post = FeedPost.find(params[:feed_post_id])
    ActiveRecord::Base.transaction do
      @feed_post.update(promoted: true)
      Link.create(url: @feed_post.url)
    end
    redirect_to links_path
  end
end
