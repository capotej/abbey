class Project < ApplicationRecord
  validates :name, presence: true

  scope :by_year, -> { order(year: :desc) }
end
