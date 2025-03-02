class FetchFeedJob < ApplicationJob
  queue_as :default

  def perform(feed_url)
    client = Faraday.new do |builder|
      builder.headers['User-Agent'] = 'capotej/abbey FetchFeeds/v0.0.1'
      builder.use :http_cache, store: Rails.cache, strategy: Faraday::HttpCache::Strategies::ByVary
      builder.adapter Faraday.default_adapter
    end

    response = client.get(feed_url)
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
