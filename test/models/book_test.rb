require "test_helper"

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
class BookTest < ActiveSupport::TestCase
  def setup
    @book = Book.new(
      title: "テスト駆動開発",
      isbn: "9784274217883",
      published_year: 2017,
      publisher: "オーム社",
      author_ids: [ authors(:one).id ]
    )
  end

  test "全項目が揃っていれば有効" do
    assert @book.valid?
  end

  test "title が空なら無効" do
    @book.title = ""
    assert_not @book.valid?
  end

  test "publisher が空なら無効" do
    @book.publisher = ""
    assert_not @book.valid?
  end

  test "isbn が空なら無効" do
    @book.isbn = ""
    assert_not @book.valid?
  end

  test "published_year が 0 以下なら無効" do
    @book.published_year = 0
    assert_not @book.valid?
  end

  test "published_year が数値でなければ無効" do
    @book.published_year = "abc"
    assert_not @book.valid?
  end

  test "isbn が既存と重複していれば無効" do
    @book.save
    duplicate = Book.new(
      title: "テスト駆動開発",
      isbn: @book.isbn,
      published_year: 2017,
      publisher: "オーム社",
      author_ids: [ authors(:two).id ]
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:isbn], "has already been taken"
  end

  test "著者が未指定なら無効" do
    @book.author_ids = []
    @book.new_author_name = nil

    assert_not @book.valid?
    assert_includes @book.errors[:authors], "を1人以上指定してください"
  end

  test "新しい著者名があれば保存時に著者を作成して紐づける" do
    @book.author_ids = []
    @book.new_author_name = "村上春樹"

    assert_difference("Author.count", 1) do
      assert @book.save
    end

    assert_equal [ "村上春樹" ], @book.reload.authors.map(&:name)
  end

  test "既存の著者名なら新規作成せずに紐づける" do
    @book.author_ids = []
    @book.new_author_name = authors(:one).name

    assert_no_difference("Author.count") do
      assert @book.save
    end

    assert_equal [ authors(:one).name ], @book.reload.authors.map(&:name)
  end

  test "新規著者名の前後空白は除去して保存する" do
    @book.author_ids = []
    @book.new_author_name = "  村上春樹  "

    assert_difference("Author.count", 1) do
      assert @book.save
    end

    assert_equal [ "村上春樹" ], @book.reload.authors.map(&:name)
  end

  test "既に紐づいている著者名を指定しても重複して紐づけない" do
    book = books(:one)
    book.new_author_name = authors(:one).name

    assert_no_difference("BookAuthor.count") do
      assert book.save
    end

    assert_equal 2, book.reload.authors.count
  end

  test "stock_count は登録済みコピーの冊数を返す" do
    assert_equal 1, books(:one).stock_count
    assert_equal 2, books(:two).stock_count
  end

  test "available_stock_count は貸出中を除いた冊数を返す" do
    assert_equal 1, books(:one).available_stock_count
    assert_equal 1, books(:two).available_stock_count
  end

  test "available_copy は空いているコピーを返す" do
    assert_equal book_copies(:two_copy_b), books(:two).available_copy
  end

  test "全コピーが貸出中なら available_copy は nil" do
    Rental.create!(user: users(:one), book_copy: book_copies(:two_copy_b))

    assert_nil books(:two).reload.available_copy
  end

  test "active_rental_for は自分のアクティブな貸出を返す" do
    assert_equal rentals(:one), books(:two).active_rental_for(users(:two))
    assert_nil books(:two).active_rental_for(users(:one))
  end

  test "initial_stock_count を指定して登録するとその冊数のコピーが作られる" do
    @book.initial_stock_count = 3

    assert_difference("BookCopy.count", 3) { @book.save! }
  end

  test "initial_stock_count 未指定なら1冊のコピーが作られる" do
    assert_difference("BookCopy.count", 1) { @book.save! }
  end

  test "initial_stock_count が0以下なら無効" do
    @book.initial_stock_count = 0

    assert_not @book.valid?
  end

  test "貸出履歴のあるコピーを持つ本は削除できない" do
    assert_no_difference("Book.count") { books(:two).destroy }
  end

  test "貸出履歴がなければコピーごと本を削除できる" do
    assert_difference("Book.count" => -1, "BookCopy.count" => -1) { books(:one).destroy }
  end

  test "タイトルの部分一致で検索できる" do
    matched = Book.create!(title: "吾輩は猫である", isbn: "1111111111111", published_year: 1905, publisher: "大倉書店", author_ids: [ authors(:one).id ])
    unmatched = Book.create!(title: "人間失格", isbn: "2222222222222", published_year: 1948, publisher: "筑摩書房", author_ids: [ authors(:two).id ])

    results = Book.search("吾輩")

    assert_includes results, matched
    assert_not_includes results, unmatched
  end

  test "著者名の部分一致で検索できる" do
    matched = Book.create!(title: "こころ", isbn: "3333333333333", published_year: 1914, publisher: "岩波書店", author_ids: [ authors(:one).id ])
    unmatched = Book.create!(title: "人間失格", isbn: "4444444444444", published_year: 1948, publisher: "筑摩書房", author_ids: [ authors(:two).id ])

    results = Book.search("漱石")

    assert_includes results, matched
    assert_not_includes results, unmatched
  end

  test "該当が無ければ空" do
    assert_empty Book.search("存在しない検索語")
  end

  test "検索語が空なら全件" do
    assert_equal Book.count, Book.search("").count
    assert_equal Book.count, Book.search(nil).count
  end

  test "共著本でも重複しない" do
    book = books(:one)

    results = Book.search(book.title)

    assert_equal 1, results.where(id: book.id).count
  end

  # --- 発展要件3: タグ・ジャンル管理（多対多） ---

  test "タグが無くても有効" do
    @book.tag_ids = []

    assert @book.valid?
  end

  test "tag_ids で既存タグを紐づけられる" do
    tag = Tag.create!(name: "技術書")
    @book.tag_ids = [ tag.id ]

    assert @book.save
    assert_equal [ "技術書" ], @book.reload.tags.map(&:name)
  end

  test "new_tag_names で複数の新しいタグを作成して紐づける（読点・カンマ区切り）" do
    @book.new_tag_names = "技術書、Ruby, 入門"

    assert_difference("Tag.count", 3) do
      assert @book.save
    end

    assert_equal [ "Ruby", "入門", "技術書" ], @book.reload.tags.map(&:name).sort
  end

  test "既存のタグ名なら新規作成せずに紐づける" do
    Tag.create!(name: "技術書")
    @book.new_tag_names = "技術書"

    assert_no_difference("Tag.count") do
      assert @book.save
    end

    assert_equal [ "技術書" ], @book.reload.tags.map(&:name)
  end

  test "既に紐づいているタグ名を指定しても重複して紐づけない" do
    tag = Tag.create!(name: "技術書")
    @book.tag_ids = [ tag.id ]
    @book.save!
    @book.new_tag_names = "技術書"

    assert_no_difference("BookTag.count") do
      assert @book.save
    end
  end

  test "with_tag は指定タグが付いた本だけを返す" do
    tag = Tag.create!(name: "技術書")
    tagged = Book.create!(title: "リーダブルコード", isbn: "9999999999999", published_year: 2012, publisher: "オライリー", author_ids: [ authors(:one).id ], tag_ids: [ tag.id ])
    untagged = books(:one)

    results = Book.with_tag(tag.id)

    assert_includes results, tagged
    assert_not_includes results, untagged
  end

  test "with_tag に空を渡すと全件" do
    assert_equal Book.count, Book.with_tag(nil).count
    assert_equal Book.count, Book.with_tag("").count
  end
end
