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
class BookItem < ApplicationRecord
  belongs_to :book
  has_many :rentals

  scope :available, -> { where.not(id: Rental.active.select(:book_item_id)) }

  # 貸出履歴は「誰が何を借りたか」の記録なので、現物を消して履歴を失わないよう削除を止める
  before_destroy :must_not_have_rental_history

  # rentals を preload しておけば追加クエリなしで判定できる
  def available?
    rentals.none? { |rental| rental.active? }
  end

  private

  def must_not_have_rental_history
    return unless rentals.exists?

    errors.add(:base, "貸出履歴があるため削除できません")
    throw :abort
  end
end
