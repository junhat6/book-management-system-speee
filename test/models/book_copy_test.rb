require "test_helper"

# == Schema Information
#
# Table name: book_copies
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  book_id    :integer          not null
#
# Indexes
#
#  index_book_copies_on_book_id  (book_id)
#
# Foreign Keys
#
#  book_id  (book_id => books.id)
#
class BookCopyTest < ActiveSupport::TestCase
  test "available スコープは貸出中のコピーを除外する" do
    assert_includes BookCopy.available, book_copies(:two_copy_b)
    assert_not_includes BookCopy.available, book_copies(:two_copy_a)
  end

  test "返却済みの貸出しかないコピーは available に含まれる" do
    rentals(:one).update!(returned_at: Time.current)

    assert_includes BookCopy.available, book_copies(:two_copy_a)
  end

  test "貸出履歴のあるコピーは削除できない" do
    copy = book_copies(:two_copy_a)

    assert_no_difference("BookCopy.count") { copy.destroy }
    assert_includes copy.errors[:base], "貸出履歴があるため削除できません"
  end

  test "貸出履歴のないコピーは削除できる" do
    assert_difference("BookCopy.count", -1) { book_copies(:one_copy_a).destroy }
  end
end
