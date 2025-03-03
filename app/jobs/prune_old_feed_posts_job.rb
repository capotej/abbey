class PruneOldFeedPostsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    FeedPost.where('created_at < ?', 30.days.ago).delete_all
  end
end
