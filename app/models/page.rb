class Page < ApplicationRecord
  include Rendering

  has_many_attached :markdown_body_attachments

  validates_presence_of :title, :markdown_body
  before_create :assign_slug

  def to_param
    return nil unless persisted?
    slug
  end

  def create_slug
    title.gsub("_", "-").parameterize
  end

  def rendered_body
    render(self.markdown_body)
  end

  private
  def assign_slug
    self.slug = create_slug
  end
end
