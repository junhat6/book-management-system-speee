require "test_helper"

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
class BookTagTest < ActiveSupport::TestCase
  test "同じ書籍とタグの組み合わせは重複登録できない" do
    tag = Tag.create!(name: "技術書")
    BookTag.create!(book: books(:one), tag: tag)
    duplicate = BookTag.new(book: books(:one), tag: tag)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tag_id], "has already been taken"
  end
end
