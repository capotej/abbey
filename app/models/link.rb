require 'metainspector'

class Link < ApplicationRecord
  validates_presence_of :url

  before_create :set_title_and_desc

  paginates_per 15

  def uuid
    Digest::SHA2.hexdigest self.url
  end

  private
  def set_title_and_desc
    page = MetaInspector.new(self.url)
    self.title = page.best_title
    self.description = page.best_description
  end

end
