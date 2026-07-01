# == Schema Information
#
# Table name: authors
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_authors_on_name  (name) UNIQUE
#
class Author < ApplicationRecord
  has_many :book_authors, dependent: :restrict_with_error
  has_many :books, through: :book_authors

  validates :name, presence: true, uniqueness: true
end
