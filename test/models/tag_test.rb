require "test_helper"

# == Schema Information
#
# Table name: tags
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tags_on_name  (name) UNIQUE
#
class TagTest < ActiveSupport::TestCase
  test "名前があれば有効" do
    tag = Tag.new(name: "技術書")

    assert tag.valid?
  end

  test "名前が空なら無効" do
    tag = Tag.new(name: "")

    assert_not tag.valid?
  end

  test "名前が重複していれば無効" do
    Tag.create!(name: "技術書")
    tag = Tag.new(name: "技術書")

    assert_not tag.valid?
    assert_includes tag.errors[:name], "has already been taken"
  end
end
