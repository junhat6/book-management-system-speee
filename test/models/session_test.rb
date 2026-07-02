require "test_helper"

# == Schema Information
#
# Table name: sessions
#
#  id         :integer          not null, primary key
#  ip_address :string
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
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
