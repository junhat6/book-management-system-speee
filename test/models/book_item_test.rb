require "test_helper"

# == Schema Information
#
# Table name: book_items
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  book_id    :integer          not null
#
# Indexes
#
#  index_book_items_on_book_id  (book_id)
#
# Foreign Keys
#
#  book_id  (book_id => books.id)
#
class BookItemTest < ActiveSupport::TestCase
  test "available スコープは貸出中の現物を除外する" do
    assert_includes BookItem.available, book_items(:two_item_b)
    assert_not_includes BookItem.available, book_items(:two_item_a)
  end

  test "返却済みの貸出しかない現物は available に含まれる" do
    rentals(:one).update!(returned_at: Time.current)

    assert_includes BookItem.available, book_items(:two_item_a)
  end

  test "貸出履歴のある現物は削除できない" do
    item = book_items(:two_item_a)

    assert_no_difference("BookItem.count") { item.destroy }
    assert_includes item.errors[:base], "貸出履歴があるため削除できません"
  end

  test "貸出履歴のない現物は削除できる" do
    assert_difference("BookItem.count", -1) { book_items(:one_item_a).destroy }
  end
end
