# == Schema Information
#
# Table name: book_tags
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  book_id    :integer          not null
#  tag_id     :integer          not null
#
# Indexes
#
#  index_book_tags_on_book_id             (book_id)
#  index_book_tags_on_book_id_and_tag_id  (book_id,tag_id) UNIQUE
#  index_book_tags_on_tag_id              (tag_id)
#
# Foreign Keys
#
#  book_id  (book_id => books.id)
#  tag_id   (tag_id => tags.id)
#
class BookTag < ApplicationRecord
  belongs_to :book
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :book_id }
end
