class FetchFeedJob < ApplicationJob
  include Feeds
  queue_as :default

  def perform(feed_record)
    response = feed_client.get(feed_record.url)
    feed = Feedjira.parse(response.body)
    attrs = feed.entries.map do |entry|
      {
        guid: entry.id,
        title: entry.title,
        summary: entry.summary,
        url: entry.url,
        feed_id: feed_record.id,
        published_at: entry.published
      }
    end
    FeedPost.insert_all(attrs)
  end
end
