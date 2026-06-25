# == Schema Information
#
# Table name: books
#
#  id             :integer          not null, primary key
#  isbn           :string
#  published_year :integer
#  publisher      :string
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_books_on_isbn  (isbn) UNIQUE
#
class Book < ApplicationRecord
  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :published_year, numericality: { only_integer: true, greater_than: 0 }, presence: true
  validates :publisher, presence: true
end
