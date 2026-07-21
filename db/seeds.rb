# db/seed_images/<ISBN>.jpg があれば表紙として添付する（`bin/rails db:seed_images` で事前取得したもの）。
# seeds.rb は本番デプロイ時にも実行されるため、ここではネットワークに一切アクセスしない
# （Google Books API を都度叩くと、レート制限やAPI障害がデプロイに影響してしまう）
def attach_seed_cover_image(book)
  return if book.cover_image.attached?

  path = Rails.root.join("db/seed_images/#{book.isbn}.jpg")
  return unless File.exist?(path)

  book.cover_image.attach(io: File.open(path), filename: "#{book.isbn}.jpg", content_type: "image/jpeg")
end

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

# --- 貸出デモ用の一般ユーザーを複数人用意する ---
# 1ユーザーだけだと「同じ本を同時に複数人が借りている」状態や、
# ユーザーごとの貸出履歴一覧を試すことができないため。
READER_PROFILES = [
  { email: "reader1@example.com", name: "田中 太郎" },
  { email: "reader2@example.com", name: "佐藤 花子" },
  { email: "reader3@example.com", name: "鈴木 一郎" },
  { email: "reader4@example.com", name: "高橋 美咲" },
  { email: "reader5@example.com", name: "伊藤 健太" }
].freeze

readers = READER_PROFILES.map do |profile|
  reader = User.find_or_initialize_by(email_address: profile[:email])
  reader.assign_attributes(
    name: profile[:name],
    password: "12345678",
    password_confirmation: "12345678",
    admin: false
  )
  reader.save!
  reader
end

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
attach_seed_cover_image(gatsby)

mockingbird = Book.find_or_initialize_by(isbn: "978-0-06-112008-4")
mockingbird.assign_attributes(
  title: "To Kill a Mockingbird",
  published_year: 1960,
  publisher: "J.B. Lippincott & Co.",
  new_author_names: lee.name
)
mockingbird.save!
attach_seed_cover_image(mockingbird)

# --- 実在書籍データ ---
# 実際に出版されている書籍の書誌情報（ISBN・出版社・出版年）を用いる。
# 空のままだと検索・タグ絞り込み・複数著者表示を試せないため。
# stock を指定した書籍は在庫を複数冊持たせ、貸出デモで使う（指定なしは1冊）。
PRODUCTION_BOOKS = [
  { title: "こころ", author: "夏目 漱石", publisher: "新潮文庫", published_year: 2004, isbn: "978-4-10-101013-7", tags: %w[近代文学 小説], stock: 3 },
  { title: "坊っちゃん", author: "夏目 漱石", publisher: "新潮文庫", published_year: 2012, isbn: "978-4-10-101003-8", tags: %w[近代文学 小説] },
  { title: "吾輩は猫である", author: "夏目 漱石", publisher: "新潮文庫", published_year: 2003, isbn: "978-4-10-101001-4", tags: %w[近代文学 小説] },
  { title: "三四郎", author: "夏目 漱石", publisher: "新潮文庫", published_year: 2011, isbn: "978-4-10-101004-5", tags: %w[近代文学 小説] },
  { title: "人間失格", author: "太宰 治", publisher: "新潮文庫", published_year: 1952, isbn: "978-4-10-100605-5", tags: %w[近代文学 小説], stock: 2 },
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
  { title: "リーダブルコード ―より良いコードを書くためのシンプルで実践的なテクニック", author: "ダスティン・ボズウェル、トレバー・フォシェ", publisher: "オライリー・ジャパン", published_year: 2012, isbn: "978-4-87311-565-8", tags: %w[技術書 プログラミング], stock: 3 },
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
  { title: "嫌われる勇気 自己啓発の源流「アドラー」の教え", author: "岸見 一郎、古賀 史健", publisher: "ダイヤモンド社", published_year: 2013, isbn: "978-4-478-02581-9", tags: %w[自己啓発 心理学], stock: 2 },
  { title: "21世紀の資本", author: "トマ・ピケティ", publisher: "みすず書房", published_year: 2014, isbn: "978-4-622-07876-0", tags: %w[経済書 経済学] },
  { title: "ボッコちゃん", author: "星 新一", publisher: "新潮文庫", published_year: 1971, isbn: "978-4-10-109801-2", tags: %w[SF 短編集] },
  { title: "日本沈没(上)", author: "小松 左京", publisher: "角川文庫", published_year: 2020, isbn: "978-4-04-109118-0", tags: %w[SF 小説] },
  { title: "点と線", author: "松本 清張", publisher: "新潮文庫", published_year: 1971, isbn: "978-4-10-110918-3", tags: %w[ミステリー 小説] },
  { title: "犬神家の一族", author: "横溝 正史", publisher: "角川文庫", published_year: 1972, isbn: "978-4-04-130405-1", tags: %w[ミステリー 小説] },
  { title: "容疑者Xの献身", author: "東野 圭吾", publisher: "文春文庫", published_year: 2008, isbn: "978-4-16-711012-3", tags: %w[ミステリー 小説], stock: 2 },
  { title: "火車", author: "宮部 みゆき", publisher: "新潮文庫", published_year: 1998, isbn: "978-4-10-136918-1", tags: %w[ミステリー 小説], stock: 2 },
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
  attach_seed_cover_image(book)

  # 新規作成時に1冊だけ自動で作られるので、指定冊数との差分だけ追加する
  # （既に投入済みなら差分は0になり、再実行しても増殖しない）
  desired_stock = data[:stock] || 1
  (desired_stock - book.items.count).times { book.items.create! }

  book
end
books_by_isbn = production_books.index_by(&:isbn)

# --- 貸出履歴のデモデータ ---
# 「返却済み」「貸出中」に加え、返却期限の概念はアプリ側に無いため、
# created_at を数十日前にしたまま returned_at を nil にすることで
# 「借りたまま長期間経っている（延滞）」状態を表現する。
if Rental.none?
  rent = lambda do |user:, isbn:, item_index:, created_at:, returned_after: nil|
    item = books_by_isbn.fetch(isbn).items.order(:id)[item_index]
    Rental.create!(
      user: user,
      book_item: item,
      created_at: created_at,
      returned_at: returned_after ? created_at + returned_after : nil
    )
  end

  general, tanaka, sato, suzuki, takahashi, ito = [ general_user, *readers ]

  # 返却済み（貸出履歴）
  rent.call(user: general,    isbn: "978-4-10-101013-7", item_index: 0, created_at: 2.months.ago,  returned_after: 10.days) # こころ
  rent.call(user: general,    isbn: "978-4-10-100605-5", item_index: 0, created_at: 3.months.ago,  returned_after: 6.days)  # 人間失格
  rent.call(user: sato,       isbn: "978-4-16-711012-3", item_index: 0, created_at: 2.months.ago,  returned_after: 14.days) # 容疑者Xの献身
  rent.call(user: suzuki,     isbn: "978-4-10-101003-8", item_index: 0, created_at: 4.months.ago,  returned_after: 7.days)  # 坊っちゃん
  rent.call(user: takahashi,  isbn: "978-4-10-136918-1", item_index: 0, created_at: 1.month.ago,   returned_after: 5.days)  # 火車
  rent.call(user: ito,        isbn: "978-4-478-02581-9", item_index: 0, created_at: 5.months.ago,  returned_after: 12.days) # 嫌われる勇気
  rent.call(user: sato,       isbn: "978-4-10-101004-5", item_index: 0, created_at: 6.months.ago,  returned_after: 8.days)  # 三四郎
  rent.call(user: suzuki,     isbn: "978-4-10-100244-6", item_index: 0, created_at: 2.months.ago,  returned_after: 9.days)  # 雪国

  # 貸出中（借りて間もない、通常の貸出状態）
  rent.call(user: general,    isbn: "978-4-87311-565-8", item_index: 0, created_at: 1.week.ago)  # リーダブルコード
  rent.call(user: tanaka,     isbn: "978-4-10-101013-7", item_index: 1, created_at: 3.days.ago)   # こころ（2冊目）
  rent.call(user: suzuki,     isbn: "978-4-10-100605-5", item_index: 1, created_at: 5.days.ago)   # 人間失格（2冊目）
  rent.call(user: ito,        isbn: "978-4-10-136918-1", item_index: 1, created_at: 2.days.ago)   # 火車（2冊目）
  rent.call(user: ito,        isbn: "978-4-274-21788-3", item_index: 0, created_at: 1.day.ago)    # テスト駆動開発

  # 貸出中（延滞デモ：長期間 returned_at が付かないまま借りっぱなし）
  rent.call(user: sato,       isbn: "978-4-10-101013-7", item_index: 2, created_at: 40.days.ago)  # こころ（3冊目）
  rent.call(user: takahashi,  isbn: "978-4-16-711012-3", item_index: 1, created_at: 45.days.ago)  # 容疑者Xの献身（2冊目）
  rent.call(user: tanaka,     isbn: "978-4-478-02581-9", item_index: 1, created_at: 30.days.ago)  # 嫌われる勇気（2冊目）
end
