require "test_helper"

# == Schema Information
#
# Table name: book_authors
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  author_id  :integer          not null
#  book_id    :integer          not null
#
# Indexes
#
#  index_book_authors_on_author_id              (author_id)
#  index_book_authors_on_book_id                (book_id)
#  index_book_authors_on_book_id_and_author_id  (book_id,author_id) UNIQUE
#
# Foreign Keys
#
#  author_id  (author_id => authors.id)
#  book_id    (book_id => books.id)
#
class BookAuthorTest < ActiveSupport::TestCase
  test "同じ書籍と著者の組み合わせは重複登録できない" do
    duplicate = BookAuthor.new(book: books(:one), author: authors(:one))

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:author_id], "has already been taken"
  end
end
