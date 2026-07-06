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
class Rental < ApplicationRecord
  belongs_to :user
  belongs_to :book_copy
  has_one :book, through: :book_copy

  scope :active, -> { where(returned_at: nil) }

  validate :copy_must_be_available, on: :create
  validate :must_not_rent_same_book_twice, on: :create

  def active?
    returned_at.nil?
  end

  private

  def copy_must_be_available
    return if book_copy.blank?
    return unless Rental.active.exists?(book_copy_id: book_copy_id)

    errors.add(:book_copy, "は貸出中のため借りられません")
  end

  def must_not_rent_same_book_twice
    return if user.blank? || book_copy.blank?
    return unless user.rentals.active.joins(:book_copy).exists?(book_copies: { book_id: book_copy.book_id })

    errors.add(:base, "すでにこの本を借りています")
  end
end
