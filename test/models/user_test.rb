require "test_helper"

# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  admin           :boolean          default(FALSE), not null
#  email_address   :string           not null
#  name            :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      name: "山田太郎",
      email_address: "taro@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "全項目が揃っていれば有効" do
    assert @user.valid?
  end

  test "name が空なら無効" do
    @user.name = ""

    assert_not @user.valid?
  end

  test "email_address が空なら無効" do
    @user.email_address = ""

    assert_not @user.valid?
  end

  test "password が短すぎると無効" do
    @user.password = @user.password_confirmation = "short"

    assert_not @user.valid?
  end

  test "email_address が重複していれば無効" do
    @user.save!
    duplicate = User.new(
      name: "別ユーザー",
      email_address: @user.email_address.upcase,
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "email_address は前後の空白を除去して小文字化される" do
    @user.email_address = "  TARO@EXAMPLE.COM  "

    @user.save!

    assert_equal "taro@example.com", @user.reload.email_address
  end
end
