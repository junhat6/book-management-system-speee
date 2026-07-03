# == Schema Information
#
# Table name: books
#
#  id             :integer          not null, primary key
#  isbn           :string
#  published_year :integer
#  publisher      :string
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_books_on_isbn  (isbn) UNIQUE
#
class Book < ApplicationRecord
  has_many :book_authors, dependent: :destroy
  has_many :authors, through: :book_authors
  has_many :rentals, dependent: :restrict_with_error

  attr_reader :new_author_name

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :published_year, numericality: { only_integer: true, greater_than: 0 }, presence: true
  validates :publisher, presence: true
  validate :must_have_author

  before_save :attach_new_author

  def new_author_name=(value)
    @new_author_name = value.to_s.strip.presence
  end

  def rented?
    rentals.active.exists?
  end

  def active_rental
    rentals.active.first
  end

  private

  def must_have_author
    return if authors.any? || new_author_name.present?

    errors.add(:authors, "を1人以上指定してください")
  end

  def attach_new_author
    return if new_author_name.blank?

    author = Author.find_or_create_by!(name: new_author_name)
    authors << author unless authors.exists?(author.id)
  end
end
