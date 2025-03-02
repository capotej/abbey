class Feed < ApplicationRecord
  has_many :feed_posts

  validates_presence_of :url, :name

  before_create :populate_feed

  private
  # attempt to populate the feed on create which will error on invalid feeds
  def populate_feed
    FetchFeedJob.perform_now(self.url)
  end
end
