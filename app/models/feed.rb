class Feed < ApplicationRecord
  include Feeds
  has_many :feed_posts, dependent: :destroy
  validates_presence_of :url, :name
  validate :feed_is_valid
  after_save :populate_feed

  private
  # attempt to populate the feed on create/update which will error on invalid feeds
  def populate_feed
    FetchFeedJob.perform_now(self)
  end

  def feed_is_valid
    unless valid_feed(self.url)
      errors.add(:url, "is not a valid RSS or Atom feed")
    end
  end
end
