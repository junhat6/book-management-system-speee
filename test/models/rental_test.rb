require "test_helper"

class RentalTest < ActiveSupport::TestCase
  test "有効な貸出データなら有効" do
    rental = Rental.new(user: users(:one), book: books(:one))

    assert rental.valid?
  end

  test "同じ書籍を二重に貸し出すと無効" do
    duplicate = Rental.new(user: users(:one), book: books(:two))

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:book], "は貸出中のため借りられません"
  end

  test "返却済みの本は再度借りられる" do
    rental = Rental.new(user: users(:two), book: books(:one))

    assert rental.valid?
  end

  test "モデルの検証を迂回してもDBの一意制約が二重貸出を防ぐ" do
    Rental.create!(user: users(:one), book: books(:one))
    bypass = Rental.new(user: users(:two), book: books(:one))

    assert_raises(ActiveRecord::RecordNotUnique) { bypass.save!(validate: false) }
  end
end
