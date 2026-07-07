# == Schema Information
#
# Table name: tags
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tags_on_name  (name) UNIQUE
#
class Tag < ApplicationRecord
  has_many :book_tags, dependent: :restrict_with_error
  has_many :books, through: :book_tags

  validates :name, presence: true, uniqueness: true
end
