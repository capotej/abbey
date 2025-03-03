module Feeds
  extend ActiveSupport::Concern

  def feed_client
    @feed_client ||= Faraday.new do |builder|
      builder.headers["User-Agent"] = "capotej/abbey FetchFeeds/v0.0.1"
      builder.use :http_cache, store: Rails.cache, strategy: Faraday::HttpCache::Strategies::ByVary
      builder.adapter Faraday.default_adapter
    end
  end


  def valid_feed(url)
    begin
      response = feed_client.get(url)

      case response.status
      when 200
        content_type = response.headers["content-type"]

        if content_type.include?("application/rss+xml") || content_type.include?("application/atom+xml") || content_type.include?("text/xml") || content.type_include?("application/xml") # The text/xml part is to deal with some older feeds.
          # Attempt to parse the feed to further validate.  If it errors, we'll catch it
          # in the rescue block below.  Using a quick parse instead of a full one
          # to save on processing time, but still validate the XML is well formed and
          # contains a root element.
          Nokogiri::XML::Reader.from_memory(response.body).each do |node|
            break # Stop after the first node to prevent processing the whole document
          end
          true
        else
          false
        end
      else
        false
      end
    rescue Faraday::Error => e
      Rails.logger.error "Faraday error validating feed: #{e.message}"
      false
    rescue Nokogiri::XML::SyntaxError => e
      Rails.logger.error "Nokogiri XML Syntax Error: #{e.message}"
      false
    rescue Exception => e
      Rails.logger.error "Unexpected error validating feed: #{e.message}"
      false
    end
  end
end
