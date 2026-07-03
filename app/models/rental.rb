class Rental < ApplicationRecord
  belongs_to :user
  belongs_to :book

  scope :active, -> { where(returned_at: nil) }

  validate :book_must_be_available, on: :create

  private

  def book_must_be_available
    return if book.blank?
    return unless Rental.active.exists?(book_id: book_id)

    errors.add(:book, "は貸出中のため借りられません")
  end
end
