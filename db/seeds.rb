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
  new_author_names: fitzgerald.name
)
gatsby.save!

mockingbird = Book.find_or_initialize_by(isbn: "978-0-06-112008-4")
mockingbird.assign_attributes(
  title: "To Kill a Mockingbird",
  published_year: 1960,
  publisher: "J.B. Lippincott & Co.",
  new_author_names: lee.name
)
mockingbird.save!

# --- ここから先は開発・動作確認用にダミーデータを大量生成する ---
# Faker は Gemfile 上 :development, :test グループ限定のgemであり、本番ビルドには
# 含まれない（Dockerfileの BUNDLE_WITHOUT="development" 経由）。誤って本番で
# db:seed を実行してもクラッシュしないよう、この先のブロックは本番では実行しない。
return if Rails.env.production?

# 乱数列を固定し、`rails db:seed` を何度実行しても同じ値が生成されるようにする。
# find_or_create 系のメソッドと組み合わせることで、再実行してもレコードが増殖しない冪等なシードになる。
Faker::Config.random = Random.new(42)

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
      new_author_names: authors.sample(random: Faker::Config.random).name
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

  # 在庫管理: 3割の書籍は複数冊（2〜3冊）の在庫を持たせる。
  # 乱数列を固定しているため、再実行しても同じ書籍が同じ冊数になり増殖しない。
  all_books.each do |book|
    next unless Faker::Config.random.rand < 0.3

    desired_stock = Faker::Config.random.rand(2..3)
    (desired_stock - book.copies.count).times { book.copies.create! }
  end

  # 貸出はコピー単位で「同時に1人まで」という制約(Rental#copy_must_be_available と
  # rentals テーブルの部分ユニークインデックス)を持つ。過去の貸出は返却済みで積み上げ、
  # returned_at を nil のままにした1件が「現在貸出中」のコピーになる。
  # 既にRentalが存在する場合は再実行時の増殖を避けるためスキップする。
  if Rental.none?
    all_books.each do |book|
      book.copies.each do |copy|
        # 過去の貸出履歴（返却済み）を0〜2件、時系列が重ならないように積む
        history_count = Faker::Config.random.rand(0..2)
        history_count.times do |i|
          borrowed_on = (history_count - i + 1).months.ago
          Rental.create!(
            user: all_users.sample(random: Faker::Config.random),
            book_copy: copy,
            created_at: borrowed_on,
            returned_at: borrowed_on + Faker::Config.random.rand(3..14).days
          )
        end

        # 3割のコピーは現在貸出中にする。
        # 「同じ本を同じユーザーが二重に借りない」バリデーションに当たった場合はスキップする。
        if Faker::Config.random.rand < 0.3
          rental = Rental.new(
            user: all_users.sample(random: Faker::Config.random),
            book_copy: copy,
            created_at: Faker::Config.random.rand(1..10).days.ago
          )
          rental.save
        end
      end
    end
  end
end
