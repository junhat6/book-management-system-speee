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

  STATUS_LABELS = { "active" => "貸出中", "returned" => "返却済み" }.freeze

  scope :with_status, ->(status) {
    case status.to_s
    when "active" then active
    when "returned" then where.not(returned_at: nil)
    else all
    end
  }

  # params 由来の値を order に直接渡すと SQL インジェクションになるため、
  # 許可リスト外のカラムは完全デフォルト（貸出日降順）に落とす。
  # id の第2キーは、同値キーでもページ跨ぎの重複・欠落が起きないよう全順序を確定させるため
  SORTABLE_COLUMNS = %w[created_at returned_at].freeze

  scope :sorted, ->(column, direction) {
    if SORTABLE_COLUMNS.include?(column.to_s)
      dir = %w[asc desc].include?(direction.to_s) ? direction.to_sym : :asc
      order(column.to_s => dir, id: :desc)
    else
      order(created_at: :desc, id: :desc)
    end
  }

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
