namespace :db do
  desc "seeds.rb が使う表紙画像を Google Books API から取得し db/seed_images/ に保存する。" \
       "既存ファイルはスキップするため、PRODUCTION_BOOKS に本を追加した後の再実行でも重複取得はしない。" \
       "取得した画像は db/seed_images/ に含めてコミットし、seeds.rb はこのローカルファイルから添付する" \
       "（seeds.rb 自体は本番デプロイ時にも実行されるため、ネットワーク依存にしないための一度きりの下ごしらえ）"
  task seed_images: :environment do
    dir = Rails.root.join("db/seed_images")
    FileUtils.mkdir_p(dir)

    # seeds.rb に書かれている ISBN だけを対象にする。開発DBには手動テストで
    # 登録した無関係な本が紛れ込んでいることがあるため、Book.all ではなく
    # seeds.rb の記述内容そのものから対象を絞り込む
    seed_isbns = File.read(Rails.root.join("db/seeds.rb")).scan(/isbn: "([0-9-]+)"/).flatten.uniq

    Book.where(isbn: seed_isbns).order(:isbn).find_each do |book|
      path = dir.join("#{book.isbn}.jpg")
      if path.exist?
        puts "SKIP (既存): #{book.isbn} #{book.title}"
        next
      end

      begin
        volume = GoogleBooks.lookup(book.isbn)
        if volume&.image_url.blank?
          puts "SKIP (画像なし): #{book.isbn} #{book.title}"
          next
        end

        fetched = RemoteImage.fetch(volume.image_url)
        File.binwrite(path, fetched.io.read)
        puts "OK: #{book.isbn} #{book.title}"
      rescue GoogleBooks::Error, RemoteImage::Error => e
        puts "FAIL: #{book.isbn} #{book.title} (#{e.message})"
      end
    end
  end
end
