# 乱数列を固定し、`rails db:seed` を何度実行しても同じ値が生成されるようにする。
# find_or_create 系のメソッドと組み合わせることで、再実行してもレコードが増殖しない冪等なシードになる。
Faker::Config.random = Random.new(42)

admin_user = User.find_or_initialize_by(email_address: "admin@example.com")
admin_user.assign_attributes(
  name: "管理者",
  password: "12345678",
  password_confirmation: "12345678",
  admin: true
)
admin_user.save!

general_user = User.find_or_initialize_by(email_address: "user@example.com")
general_user.assign_attributes(
  name: "一般ユーザー",
  password: "12345678",
  password_confirmation: "12345678",
  admin: false
)
general_user.save!

fitzgerald = Author.find_or_create_by!(name: "F. Scott Fitzgerald")
lee = Author.find_or_create_by!(name: "Harper Lee")

gatsby = Book.find_or_initialize_by(isbn: "978-3-16-148410-0")
gatsby.assign_attributes(
  title: "The Great Gatsby",
  published_year: 1925,
  publisher: "Scribner",
  new_author_name: fitzgerald.name
)
gatsby.save!

mockingbird = Book.find_or_initialize_by(isbn: "978-0-06-112008-4")
mockingbird.assign_attributes(
  title: "To Kill a Mockingbird",
  published_year: 1960,
  publisher: "J.B. Lippincott & Co.",
  new_author_name: lee.name
)
mockingbird.save!

# --- ここから先は開発・動作確認用にダミーデータを大量生成する ---

NUMBER_OF_READERS = 20
NUMBER_OF_AUTHORS = 40
NUMBER_OF_BOOKS = 150

ActiveRecord::Base.transaction do
  readers = NUMBER_OF_READERS.times.map do |i|
    reader = User.find_or_initialize_by(email_address: "reader#{i + 1}@example.com")
    reader.assign_attributes(
      name: Faker::Name.unique.name,
      password: "password123",
      password_confirmation: "password123",
      admin: false
    )
    reader.save!
    reader
  end

  authors = NUMBER_OF_AUTHORS.times.map do
    Author.find_or_create_by!(name: Faker::Book.unique.author)
  end

  books = NUMBER_OF_BOOKS.times.map do
    isbn = Faker::Code.unique.isbn(base: 13)
    book = Book.find_or_initialize_by(isbn: isbn)
    book.assign_attributes(
      title: Faker::Book.title,
      published_year: Faker::Config.random.rand(1950..2025),
      publisher: Faker::Book.publisher,
      new_author_name: authors.sample(random: Faker::Config.random).name
    )
    book.save!

    # 3割の書籍は共著者を追加する
    if Faker::Config.random.rand < 0.3
      co_author = authors.sample(random: Faker::Config.random)
      book.authors << co_author unless book.authors.exists?(co_author.id)
    end

    book
  end

  all_users = [ general_user, *readers ]
  all_books = [ gatsby, mockingbird, *books ]

  # 書籍は「同時に1人にしか貸し出せない」という制約(Rental#book_must_be_available と
  # rentals テーブルの部分ユニークインデックス)を持つ。過去の貸出は時系列で重ならないように
  # 積み上げ、最後の1件だけ returned_at を nil のままにすると「現在貸出中」の書籍になる。
  # 既にRentalが存在する場合は再実行時の増殖を避けるためスキップする。
  if Rental.none?
    # TODO(human): all_books の各書籍に対して貸出履歴(Rentalレコード)を生成する
  end
end
