require "test_helper"

# == Schema Information
#
# Table name: rentals
#
#  id           :integer          not null, primary key
#  returned_at  :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  book_copy_id :integer          not null
#  user_id      :integer          not null
#
# Indexes
#
#  index_rentals_on_book_copy_id              (book_copy_id)
#  index_rentals_on_book_copy_id_when_active  (book_copy_id) UNIQUE WHERE returned_at IS NULL
#  index_rentals_on_user_id                   (user_id)
#
# Foreign Keys
#
#  book_copy_id  (book_copy_id => book_copies.id)
#  user_id       (user_id => users.id)
#
class RentalTest < ActiveSupport::TestCase
  test "空いているコピーへの貸出は有効" do
    rental = Rental.new(user: users(:one), book_copy: book_copies(:one_copy_a))

    assert rental.valid?
  end

  test "貸出中のコピーへの貸出は無効" do
    rental = Rental.new(user: users(:one), book_copy: book_copies(:two_copy_a))

    assert_not rental.valid?
    assert_includes rental.errors[:book_copy], "は貸出中のため借りられません"
  end

  test "返却済みになったコピーは再度借りられる" do
    rentals(:one).update!(returned_at: Time.current)
    rental = Rental.new(user: users(:one), book_copy: book_copies(:two_copy_a))

    assert rental.valid?
  end

  test "同じ本を借りている間は別のコピーも借りられない" do
    # users(:two) は books(:two) のコピーAを貸出中
    rental = Rental.new(user: users(:two), book_copy: book_copies(:two_copy_b))

    assert_not rental.valid?
    assert_includes rental.errors[:base], "すでにこの本を借りています"
  end

  test "別のユーザーなら同じ本の別のコピーを同時に借りられる" do
    rental = Rental.new(user: users(:one), book_copy: book_copies(:two_copy_b))

    assert rental.valid?
  end

  test "モデルの検証を迂回してもDBの一意制約がコピーの二重貸出を防ぐ" do
    bypass = Rental.new(user: users(:one), book_copy: book_copies(:two_copy_a))

    assert_raises(ActiveRecord::RecordNotUnique) { bypass.save!(validate: false) }
  end
end
