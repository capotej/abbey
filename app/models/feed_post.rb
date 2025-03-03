class FeedPost < ApplicationRecord
  belongs_to :feed
  paginates_per 15
end
