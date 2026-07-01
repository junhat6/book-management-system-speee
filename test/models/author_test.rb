require "test_helper"

# == Schema Information
#
# Table name: authors
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_authors_on_name  (name) UNIQUE
#
class AuthorTest < ActiveSupport::TestCase
  test "名前があれば有効" do
    author = Author.new(name: "芥川龍之介")

    assert author.valid?
  end

  test "名前が空なら無効" do
    author = Author.new(name: "")

    assert_not author.valid?
  end

  test "名前が重複していれば無効" do
    author = Author.new(name: authors(:one).name)

    assert_not author.valid?
    assert_includes author.errors[:name], "has already been taken"
  end
end
