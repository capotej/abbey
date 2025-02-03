class Post < ApplicationRecord
  include Rendering
  attr_accessor :post_tags
  attr_accessor :automated_editing

  has_many_attached :markdown_body_attachments

  has_many :taggings
  has_many :tags, through: :taggings

  paginates_per 5

  before_create :assign_slug

  after_create :create_tags
  after_update :create_tags
  after_find :set_post_tags

  validates_presence_of :title, :markdown_body, :markdown_excerpt

  scope :published, -> { where(draft: [ nil, false ]) }

  def uuid
    Digest::SHA2.hexdigest self.title + self.created_at.to_s
  end

  def rendered_body
    render(self.markdown_body)
  end

  def rendered_excerpt
    render(self.markdown_excerpt)
  end

  def year
    created_at.year
  end

  def month
    created_at.strftime("%m")
  end

  def day
    created_at.strftime("%d")
  end

  def to_param
    return nil unless persisted?
    slug
  end

  def set_post_tags
    self.post_tags ||= self.tags.map { it.name }.join(",")
  end

  def create_slug
    title.gsub("_", "-").parameterize
  end

  private
  def assign_slug
    self.slug = create_slug
  end

  def create_tags
    ActiveRecord::Base.transaction do
      if post_tags == "" || post_tags.nil?
        self.tags = []
      else
        post_tags.split(",").each do
          # TODO refactor to tag class
          t = Tag.find_or_create_by!(name: it.gsub("_", "-").parameterize)
          Tagging.find_or_create_by!(post_id: self.id, tag_id: t.id)
        end
      end
    end
  end
end
