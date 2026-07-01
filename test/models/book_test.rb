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
end
