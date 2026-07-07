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

# --- 本番でも投入する実在書籍データ ---
# Faker を使わず、実際に出版されている書籍の書誌情報（ISBN・出版社・出版年）を用いる。
# 空のままだと初回ログイン後に検索・タグ絞り込み・複数著者表示を試せないため。
PRODUCTION_BOOKS = [
  { title: "こころ", author: "夏目 漱石", publisher: "新潮文庫", published_year: 2004, isbn: "978-4-10-101013-7", tags: %w[近代文学 小説] },
  { title: "坊っちゃん", author: "夏目 漱石", publisher: "新潮文庫", published_year: 2012, isbn: "978-4-10-101003-8", tags: %w[近代文学 小説] },
  { title: "吾輩は猫である", author: "夏目 漱石", publisher: "新潮文庫", published_year: 2003, isbn: "978-4-10-101001-4", tags: %w[近代文学 小説] },
  { title: "三四郎", author: "夏目 漱石", publisher: "新潮文庫", published_year: 2011, isbn: "978-4-10-101004-5", tags: %w[近代文学 小説] },
  { title: "人間失格", author: "太宰 治", publisher: "新潮文庫", published_year: 1952, isbn: "978-4-10-100605-5", tags: %w[近代文学 小説] },
  { title: "走れメロス", author: "太宰 治", publisher: "新潮文庫", published_year: 1954, isbn: "978-4-10-100606-2", tags: %w[近代文学 短編集] },
  { title: "斜陽", author: "太宰 治", publisher: "新潮文庫", published_year: 1950, isbn: "978-4-10-100602-4", tags: %w[近代文学 小説] },
  { title: "羅生門・鼻", author: "芥川 龍之介", publisher: "新潮文庫", published_year: 2005, isbn: "978-4-10-102501-8", tags: %w[近代文学 短編集] },
  { title: "蜘蛛の糸・杜子春", author: "芥川 龍之介", publisher: "新潮文庫", published_year: 2013, isbn: "978-4-10-102503-2", tags: %w[近代文学 短編集] },
  { title: "河童・或阿呆の一生", author: "芥川 龍之介", publisher: "新潮文庫", published_year: 1968, isbn: "978-4-10-102506-3", tags: %w[近代文学 小説] },
  { title: "新編 銀河鉄道の夜", author: "宮沢 賢治", publisher: "新潮文庫", published_year: 2012, isbn: "978-4-10-109205-8", tags: %w[童話 小説] },
  { title: "注文の多い料理店", author: "宮沢 賢治", publisher: "新潮文庫", published_year: 1990, isbn: "978-4-10-109206-5", tags: %w[童話 小説] },
  { title: "痴人の愛", author: "谷崎 潤一郎", publisher: "新潮文庫", published_year: 2003, isbn: "978-4-10-100501-0", tags: %w[近代文学 小説] },
  { title: "細雪(上)", author: "谷崎 潤一郎", publisher: "新潮文庫", published_year: 1955, isbn: "978-4-10-100512-6", tags: %w[近代文学 小説] },
  { title: "阿部一族・舞姫", author: "森 鴎外", publisher: "新潮文庫", published_year: 1968, isbn: "978-4-10-102004-4", tags: %w[近代文学 小説] },
  { title: "山椒大夫・高瀬舟", author: "森 鴎外", publisher: "新潮文庫", published_year: 1968, isbn: "978-4-10-102005-1", tags: %w[近代文学 短編集] },
  { title: "にごりえ・たけくらべ", author: "樋口 一葉", publisher: "岩波文庫", published_year: 1999, isbn: "978-4-00-310251-0", tags: %w[近代文学 小説] },
  { title: "李陵・山月記", author: "中島 敦", publisher: "新潮文庫", published_year: 1969, isbn: "978-4-10-107701-7", tags: %w[近代文学 短編集] },
  { title: "檸檬", author: "梶井 基次郎", publisher: "新潮文庫", published_year: 2003, isbn: "978-4-10-109601-8", tags: %w[近代文学 短編集] },
  { title: "怪人二十面相", author: "江戸川 乱歩", publisher: "ポプラ文庫クラシック", published_year: 2008, isbn: "978-4-591-10619-8", tags: %w[ミステリー 少年小説] },
  { title: "陰獣", author: "江戸川 乱歩", publisher: "春陽文庫", published_year: 2015, isbn: "978-4-394-30146-2", tags: %w[ミステリー 小説] },
  { title: "雪国", author: "川端 康成", publisher: "新潮文庫", published_year: 2022, isbn: "978-4-10-100244-6", tags: %w[近代文学 小説] },
  { title: "伊豆の踊子", author: "川端 康成", publisher: "新潮文庫", published_year: 2022, isbn: "978-4-10-100245-3", tags: %w[近代文学 小説] },
  { title: "小僧の神様・城の崎にて", author: "志賀 直哉", publisher: "新潮文庫", published_year: 2005, isbn: "978-4-10-103005-0", tags: %w[近代文学 短編集] },
  { title: "武蔵野", author: "国木田 独歩", publisher: "岩波文庫", published_year: 2006, isbn: "978-4-00-310191-9", tags: %w[近代文学 小説] },
  { title: "リーダブルコード ―より良いコードを書くためのシンプルで実践的なテクニック", author: "ダスティン・ボズウェル、トレバー・フォシェ", publisher: "オライリー・ジャパン", published_year: 2012, isbn: "978-4-87311-565-8", tags: %w[技術書 プログラミング] },
  { title: "達人プログラマー(第2版) 熟達に向けたあなたの旅", author: "アンドリュー・ハント、デイビッド・トーマス", publisher: "オーム社", published_year: 2020, isbn: "978-4-274-22629-8", tags: %w[技術書 プログラミング] },
  { title: "SQLアンチパターン", author: "ビル・カーウィン", publisher: "オライリー・ジャパン", published_year: 2013, isbn: "978-4-87311-589-4", tags: %w[技術書 データベース] },
  { title: "プログラマが知るべき97のこと", author: "ケヴリン・ヘネイ", publisher: "オライリー・ジャパン", published_year: 2010, isbn: "978-4-87311-479-8", tags: %w[技術書 プログラミング] },
  { title: "Clean Code アジャイルソフトウェア達人の技", author: "ロバート・C・マーティン", publisher: "KADOKAWA", published_year: 2017, isbn: "978-4-04-893059-8", tags: %w[技術書 プログラミング] },
  { title: "リファクタリング(第2版) 既存のコードを安全に改善する", author: "マーチン・ファウラー", publisher: "オーム社", published_year: 2019, isbn: "978-4-274-22454-6", tags: %w[技術書 プログラミング] },
  { title: "テスト駆動開発", author: "ケント・ベック", publisher: "オーム社", published_year: 2017, isbn: "978-4-274-21788-3", tags: %w[技術書 プログラミング] },
  { title: "オブジェクト指向でなぜつくるのか 第2版", author: "平澤 章", publisher: "日経BP", published_year: 2011, isbn: "978-4-8222-8465-7", tags: %w[技術書 プログラミング] },
  { title: "UNIXという考え方 その設計思想と哲学", author: "マイク・ガンカーズ", publisher: "オーム社", published_year: 2001, isbn: "978-4-274-06406-7", tags: %w[技術書 コンピュータ] },
  { title: "プリンシプル オブ プログラミング", author: "上田 勲", publisher: "秀和システム", published_year: 2016, isbn: "978-4-7980-4614-3", tags: %w[技術書 プログラミング] },
  { title: "マネジメント[エッセンシャル版] 基本と原則", author: "P・F・ドラッカー", publisher: "ダイヤモンド社", published_year: 2001, isbn: "978-4-478-41023-3", tags: %w[ビジネス 経営学] },
  { title: "イノベーションと企業家精神[エッセンシャル版]", author: "P・F・ドラッカー", publisher: "ダイヤモンド社", published_year: 2015, isbn: "978-4-478-06650-8", tags: %w[ビジネス 経営学] },
  { title: "経営者の条件", author: "P・F・ドラッカー", publisher: "ダイヤモンド社", published_year: 2006, isbn: "978-4-478-30074-9", tags: %w[ビジネス 経営学] },
  { title: "完訳 7つの習慣 人格主義の回復", author: "スティーブン・R・コヴィー", publisher: "キングベアー出版", published_year: 2013, isbn: "978-4-86394-024-6", tags: %w[ビジネス 自己啓発] },
  { title: "影響力の武器[第三版] なぜ、人は動かされるのか", author: "ロバート・B・チャルディーニ", publisher: "誠信書房", published_year: 2014, isbn: "978-4-414-30422-0", tags: %w[ビジネス 心理学] },
  { title: "FACTFULNESS(ファクトフルネス) 10の思い込みを乗り越え、データを基に世界を正しく見る習慣", author: "ハンス・ロスリング", publisher: "日経BP", published_year: 2019, isbn: "978-4-8222-8960-7", tags: %w[ビジネス 経済書] },
  { title: "嫌われる勇気 自己啓発の源流「アドラー」の教え", author: "岸見 一郎、古賀 史健", publisher: "ダイヤモンド社", published_year: 2013, isbn: "978-4-478-02581-9", tags: %w[自己啓発 心理学] },
  { title: "21世紀の資本", author: "トマ・ピケティ", publisher: "みすず書房", published_year: 2014, isbn: "978-4-622-07876-0", tags: %w[経済書 経済学] },
  { title: "ボッコちゃん", author: "星 新一", publisher: "新潮文庫", published_year: 1971, isbn: "978-4-10-109801-2", tags: %w[SF 短編集] },
  { title: "日本沈没(上)", author: "小松 左京", publisher: "角川文庫", published_year: 2020, isbn: "978-4-04-109118-0", tags: %w[SF 小説] },
  { title: "点と線", author: "松本 清張", publisher: "新潮文庫", published_year: 1971, isbn: "978-4-10-110918-3", tags: %w[ミステリー 小説] },
  { title: "犬神家の一族", author: "横溝 正史", publisher: "角川文庫", published_year: 1972, isbn: "978-4-04-130405-1", tags: %w[ミステリー 小説] },
  { title: "容疑者Xの献身", author: "東野 圭吾", publisher: "文春文庫", published_year: 2008, isbn: "978-4-16-711012-3", tags: %w[ミステリー 小説] },
  { title: "火車", author: "宮部 みゆき", publisher: "新潮文庫", published_year: 1998, isbn: "978-4-10-136918-1", tags: %w[ミステリー 小説] },
  { title: "時をかける少女", author: "筒井 康隆", publisher: "角川文庫", published_year: 2006, isbn: "978-4-04-130521-8", tags: %w[SF 小説] }
].freeze

production_books = PRODUCTION_BOOKS.map do |data|
  book = Book.find_or_initialize_by(isbn: data[:isbn])
  book.assign_attributes(
    title: data[:title],
    published_year: data[:published_year],
    publisher: data[:publisher],
    new_author_names: data[:author],
    new_tag_names: data[:tags].join("、")
  )
  book.save!
  book
end

# --- 本番でも投入する貸出履歴（返却済み2件・貸出中1件のデモ） ---
# 対象の書籍だけに絞って判定することで、開発環境で Faker ブロックが
# 「Rental が1件でもあれば全体スキップ」と誤判定しないようにする。
demo_rental_isbns = %w[978-4-10-101013-7 978-4-10-100605-5 978-4-87311-565-8]
demo_rental_books = production_books.select { |book| demo_rental_isbns.include?(book.isbn) }

if Rental.where(book_copy: demo_rental_books.flat_map(&:copies)).none?
  kokoro, ningen_shikkaku, readable_code = demo_rental_isbns.map { |isbn| demo_rental_books.find { |b| b.isbn == isbn } }

  Rental.create!(user: general_user, book_copy: kokoro.copies.first, created_at: 2.months.ago, returned_at: 2.months.ago + 10.days)
  Rental.create!(user: general_user, book_copy: ningen_shikkaku.copies.first, created_at: 3.months.ago, returned_at: 3.months.ago + 6.days)
  Rental.create!(user: general_user, book_copy: readable_code.copies.first, created_at: 1.week.ago)
end

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
  # 本番用の少数デモ貸出（production_books対象）とは無関係なので、
  # ここでは開発用に生成した books の copies だけを見て判定する。
  if Rental.where(book_copy: all_books.flat_map(&:copies)).none?
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
