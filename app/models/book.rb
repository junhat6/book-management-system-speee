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
  has_many :book_tags, dependent: :destroy
  has_many :tags, through: :book_tags
  has_many :copies, class_name: "BookCopy", dependent: :destroy
  has_many :rentals, through: :copies
  has_one_attached :cover_image

  attr_reader :new_author_names, :new_tag_names, :initial_stock_count
  attr_accessor :remote_cover_image_url

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :published_year, numericality: { only_integer: true, greater_than: 0 }, presence: true
  validates :publisher, presence: true
  validates :initial_stock_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 },
            allow_nil: true, on: :create
  validate :must_have_author

  before_save :attach_new_authors
  before_save :attach_new_tags
  # prepend しないと copies の dependent: :destroy が先に走り、
  # 履歴チェックの前にコピー削除が始まってしまう
  before_destroy :must_not_have_rental_history, prepend: true
  after_create :create_initial_copies
  # DBトランザクションの外で行うため before_save ではなく after_commit にする。
  # SQLite は単一ファイルへの書き込みロックを取るため、トランザクション内でネットワークI/O
  # （最大5秒）を挟むと books/book_copies/rentals への他の書き込みが待たされてしまう。
  # remote_cover_image_url が空なら即returnするだけなので、バリデーション失敗時や
  # 画像なしでの通常保存では何も起きない
  after_commit :attach_cover_image_from_remote_url

  scope :search, ->(query) {
    return all if query.blank?

    q = "%#{sanitize_sql_like(query)}%"
    left_joins(:authors)
      .where("books.title LIKE :q OR authors.name LIKE :q", q: q)
      .distinct
  }

  scope :with_tag, ->(tag_id) {
    return all if tag_id.blank?

    # joins(:tags).where(tags: { id: tag_id }) だと、Rails が同じ tags 関連への
    # includes(:tags) と結合して1本の eager load クエリにまとめてしまい、
    # プリロードされる tags まで tag_id の条件で絞られて他のタグが欠落する。
    # サブクエリで絞ることで includes(:tags) は独立した preload のままになる
    where(id: BookTag.where(tag_id: tag_id).select(:book_id))
  }

  # params 由来の値を order に直接渡すと SQL インジェクションになるため、
  # 許可リスト外のカラムは完全デフォルト（登録日降順）に落とす。
  # id の第2キーは、同値キーでもページ跨ぎの重複・欠落が起きないよう全順序を確定させるため
  SORTABLE_COLUMNS = %w[title published_year].freeze

  scope :sorted, ->(column, direction) {
    if SORTABLE_COLUMNS.include?(column.to_s)
      dir = %w[asc desc].include?(direction.to_s) ? direction.to_sym : :asc
      order(column.to_s => dir, id: :desc)
    else
      order(created_at: :desc, id: :desc)
    end
  }

  def new_author_names=(value)
    @new_author_names = value.to_s.strip.presence
  end

  def new_tag_names=(value)
    @new_tag_names = value.to_s.strip.presence
  end

  def initial_stock_count=(value)
    @initial_stock_count = value.presence&.to_i
  end

  def stock_count
    copies.size
  end

  # copies: :rentals を preload しておけば追加クエリなしで数えられる
  def available_stock_count
    copies.count { |copy| copy.available? }
  end

  def available_copy
    copies.available.first
  end

  def active_rental_for(user)
    return nil if user.nil?

    rentals.active.find_by(user: user)
  end

  private

  def must_have_author
    return if authors.any? || new_author_names.present?

    errors.add(:authors, "を1人以上指定してください")
  end

  def create_initial_copies
    (initial_stock_count || 1).times { copies.create! }
  end

  def must_not_have_rental_history
    return unless rentals.exists?

    errors.add(:base, "貸出履歴があるため削除できません")
    throw :abort
  end

  # タグと同じく読点・カンマ区切りで複数登録できるようにする
  # （Google Books API が著者を配列で返すため、複数著者を個別レコードとして扱う）
  def attach_new_authors
    new_author_names.to_s.split(/[、,]/).map(&:strip).reject(&:blank?).uniq.each do |name|
      author = Author.find_or_create_by!(name: name)
      authors << author unless authors.exists?(author.id)
    end
  end

  def attach_new_tags
    # 読点・カンマのどちらでも区切れるようにする（日本語入力での「、」を想定）
    new_tag_names.to_s.split(/[、,]/).map(&:strip).reject(&:blank?).uniq.each do |name|
      tag = Tag.find_or_create_by!(name: name)
      tags << tag unless tags.exists?(tag.id)
    end
  end

  # 表紙の取得失敗は登録・更新自体を妨げない（GoogleBooks と同じ「失敗は黙って諦める」方針）。
  # 管理者からは「プレビューで見えた画像が保存後に消えている」ように見えうるが、
  # 表紙は付随情報であり本の登録を止めてまで守るべき情報ではないため許容する
  def attach_cover_image_from_remote_url
    url = remote_cover_image_url
    return if url.blank?

    # cover_image.attach は ActiveStorage::Attachment（belongs_to :record, touch: true）経由で
    # このレコードを touch する。touch のコミットで after_commit が再度発火してしまうため、
    # 呼び出し前に属性を空にして二度目の発火を早期returnさせないと無限再帰する
    self.remote_cover_image_url = nil

    fetched = RemoteImage.fetch(url)
    cover_image.attach(io: fetched.io, filename: fetched.filename, content_type: fetched.content_type)
  rescue RemoteImage::Error => e
    Rails.logger.warn("Cover image fetch failed: #{e.message}")
  end
end
