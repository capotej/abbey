require 'open-uri'
require 'feedjira'

class FetchFeedsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Feed.all.each do |feed_record|
      FetchFeedJob.perform_later feed_record.url
    end
  end
end
