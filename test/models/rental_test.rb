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

  test "with_status(\"active\") は貸出中の履歴のみを返す" do
    assert_equal [ rentals(:one) ], Rental.with_status("active").to_a
  end

  test "with_status(\"returned\") は返却済みの履歴のみを返す" do
    assert_equal [ rentals(:two) ], Rental.with_status("returned").to_a
  end

  test "with_status に不正な値・空値を渡すと絞り込まれない" do
    assert_equal Rental.all.to_a, Rental.with_status("invalid").to_a
    assert_equal Rental.all.to_a, Rental.with_status(nil).to_a
  end

  test "sorted はデフォルトで貸出日の新しい順" do
    assert_equal [ rentals(:one), rentals(:two) ], Rental.sorted(nil, nil).to_a
  end

  test "sorted(\"created_at\", \"asc\") で貸出日の古い順に並び替えられる" do
    assert_equal [ rentals(:two), rentals(:one) ], Rental.sorted("created_at", "asc").to_a
  end

  test "sorted(\"returned_at\", \"asc\") で返却日の古い順に並び替えられる" do
    older = Rental.create!(user: users(:one), book_copy: book_copies(:one_copy_a), returned_at: 15.days.ago)

    result = Rental.where(id: [ older.id, rentals(:two).id ]).sorted("returned_at", "asc")

    assert_equal [ older, rentals(:two) ], result.to_a
  end

  test "sorted に許可されていないカラムを渡すと貸出日の新しい順にフォールバックする" do
    assert_equal Rental.sorted(nil, nil).to_a, Rental.sorted("user_id", "asc").to_a
  end
end
