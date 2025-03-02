class FeedPostsController < ApplicationController
  def index
    @feed_posts = FeedPost.order(created_at: :desc).page(params[:page])
  end
end
