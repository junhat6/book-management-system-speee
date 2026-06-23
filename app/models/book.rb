class Book < ApplicationRecord
  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :published_year, numericality: { only_integer: true, greater_than: 0 }, presence: true
  validates :publisher, presence: true
end
