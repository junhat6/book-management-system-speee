require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "user が無ければ無効" do
    session = Session.new(user: nil)

    assert_not session.valid?
  end

  test "user が紐づいていれば有効" do
    session = Session.new(user: users(:one))

    assert session.valid?
  end
end
