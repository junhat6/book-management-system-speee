# 必須条件（基礎）

```mermaid
erDiagram
  users {
    int id PK "ユーザーID" 
    string name "ユーザー名"
    string email UK "メールアドレス"
    string password_digest "パスワード"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  rentals {
    int id PK "貸出履歴ID"
    int user_id FK "ユーザーID"
    int book_id FK "書籍ID (returned_at IS NULL の行のみ一意 二重貸し出し防止)"
    datetime returned_at  "返却日時"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  books {
    int id PK "書籍ID"
    string title "タイトル"
    string isbn UK "ISBN"
    int published_year "出版年"
    string publisher "出版社"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  book_authors {
    int id PK "書籍著者ID"
    int book_id FK "書籍ID"
    int author_id FK "著者ID"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  authors {
    int id PK "著者ID"
    string name "著者名"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  users ||--o{ rentals : ""
  rentals }o--|| books : ""
  books ||--|{ book_authors : ""
  authors ||--|{ book_authors : ""
```

## 発展要件（応用）

```mermaid
erDiagram
  users {
    int id PK "ユーザーID" 
    string name "ユーザー名"
    string email UK "メールアドレス"
    string password_digest "パスワード"
    string role "権限"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  rentals {
    int id PK "貸出履歴ID"
    int user_id FK "ユーザーID"
    int book_item_id FK "書籍現物ID (returned_at IS NULL の行のみ一意 二重貸し出し防止)"
    datetime returned_at  "返却日時"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  book_items {
    int id PK "書籍現物ID"
    int book_id FK "書籍ID"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  books {
    int id PK "書籍ID"
    string title "タイトル"
    string isbn UK "ISBN"
    int published_year "出版年"
    string publisher "出版社"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  book_authors {
    int id PK "書籍著者ID"
    int book_id FK "書籍ID"
    int author_id FK "著者ID"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  authors {
    int id PK "著者ID"
    string name "著者名"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  book_tags {
    int id PK "書籍タグID"
    int book_id FK "書籍ID (book_id と tag_id の組み合わせで一意)"
    int tag_id FK "タグID"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  tags {
    int id PK "タグID"
    string name UK "タグ名（ジャンル・タグ共通）"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  users ||--o{ rentals : ""
  rentals }o--|| book_items : ""
  book_items }|--|| books : ""
  books ||--|{ book_authors : ""
  authors ||--|{ book_authors : ""
  books ||--o{ book_tags : ""
  tags ||--o{ book_tags : ""
```

## 現在の実装（最終）

`db/schema.rb`（version: 2026_07_07_090000）時点の実際のテーブル構成。認証まわりの命名や `book_items` → `book_copies` へのリネームなど、設計段階からいくつか変更が入っている。Solid Queue / Solid Cable が使う `solid_queue_*` / `solid_cable_messages` テーブルは Rails 標準のジョブ・Action Cable 基盤であり業務ドメインに属さないため、この図では割愛する。

```mermaid
erDiagram
  users {
    int id PK "ユーザーID"
    string name "ユーザー名"
    string email_address UK "メールアドレス"
    string password_digest "パスワードハッシュ"
    boolean admin "管理者権限"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  sessions {
    int id PK "セッションID"
    int user_id FK "ユーザーID"
    string ip_address "接続元IPアドレス"
    string user_agent "ユーザーエージェント"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  rentals {
    int id PK "貸出履歴ID"
    int user_id FK "ユーザーID"
    int book_copy_id FK "書籍現物ID (returned_at IS NULL の行のみ一意 二重貸し出し防止)"
    datetime returned_at "返却日時"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  book_copies {
    int id PK "書籍現物ID"
    int book_id FK "書籍ID"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  books {
    int id PK "書籍ID"
    string title "タイトル"
    string isbn UK "ISBN"
    int published_year "出版年"
    string publisher "出版社"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  book_authors {
    int id PK "書籍著者ID"
    int book_id FK "書籍ID (book_id と author_id の組み合わせで一意)"
    int author_id FK "著者ID"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  authors {
    int id PK "著者ID"
    string name UK "著者名"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  book_tags {
    int id PK "書籍タグID"
    int book_id FK "書籍ID (book_id と tag_id の組み合わせで一意)"
    int tag_id FK "タグID"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  tags {
    int id PK "タグID"
    string name UK "タグ名（ジャンル・タグ共通）"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  users ||--o{ sessions : ""
  users ||--o{ rentals : ""
  rentals }o--|| book_copies : ""
  book_copies }|--|| books : ""
  books ||--|{ book_authors : ""
  authors ||--|{ book_authors : ""
  books ||--o{ book_tags : ""
  tags ||--o{ book_tags : ""
```

### 設計段階からの主な変更点

| 項目 | 設計時（発展要件） | 実装 | 理由 |
|---|---|---|---|
| ユーザーのメール | `email` | `email_address` | Rails 8 の `bin/rails generate authentication` が生成する標準の認証スキャフォールドがこのカラム名を使うため |
| ユーザーの権限 | `role` (string) | `admin` (boolean) | 権限が「管理者かどうか」の二値のみで、多段階の役割が不要だったため boolean に単純化 |
| 書籍現物 | `book_items` | `book_copies` | 同一書籍の物理的な複製・蔵書1冊を表す語として `copy` の方がドメイン上一意に意味が伝わると考え、`BookCopy` モデル名とも一致させた。OSSの図書館管理システム（ILS）にも先例があり（例: Evergreen ILSの `asset.copy` テーブル）、一定の妥当性はあった。ただし2026-07-21に、開発者の語感として `book_items` の方がしっくりくるという判断で `book_items` に再度リネームされている（詳細は「現在の実装（最新）」参照） |
| セッション管理 | （未定義） | `sessions` テーブルを新規追加 | Rails 8 標準の認証機構が Cookie に署名付きセッションIDのみを保持し、実体（`ip_address` / `user_agent` など）をDBで管理する方式のため。これにより特定端末からのログアウト（セッション無効化）が可能になる |
| 著者名の一意性 | 制約なし | `authors.name` に UNIQUE 制約 | 同姓同名の著者レコードが重複作成されるのを防ぐため（`Author.find_or_create_by!` で名寄せする実装と対応） |

## 現在の実装（最新）

`db/schema.rb`（version: 2026_07_21_060000）時点。上記「現在の実装（最終）」からの差分は、①書影画像機能（ISBN検索時に Google Books API から取得した表紙画像を Active Storage で保存する機能）の追加に伴う `active_storage_*` テーブル群、②`book_copies` → `book_items` への再リネーム（詳細は下記）の2点。

```mermaid
erDiagram
  users {
    int id PK "ユーザーID"
    string name "ユーザー名"
    string email_address UK "メールアドレス"
    string password_digest "パスワードハッシュ"
    boolean admin "管理者権限"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  sessions {
    int id PK "セッションID"
    int user_id FK "ユーザーID"
    string ip_address "接続元IPアドレス"
    string user_agent "ユーザーエージェント"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  rentals {
    int id PK "貸出履歴ID"
    int user_id FK "ユーザーID"
    int book_item_id FK "書籍現物ID (returned_at IS NULL の行のみ一意 二重貸し出し防止)"
    datetime returned_at "返却日時"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  book_items {
    int id PK "書籍現物ID"
    int book_id FK "書籍ID"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  books {
    int id PK "書籍ID"
    string title "タイトル"
    string isbn UK "ISBN"
    int published_year "出版年"
    string publisher "出版社"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  book_authors {
    int id PK "書籍著者ID"
    int book_id FK "書籍ID (book_id と author_id の組み合わせで一意)"
    int author_id FK "著者ID"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  authors {
    int id PK "著者ID"
    string name UK "著者名"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  book_tags {
    int id PK "書籍タグID"
    int book_id FK "書籍ID (book_id と tag_id の組み合わせで一意)"
    int tag_id FK "タグID"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  tags {
    int id PK "タグID"
    string name UK "タグ名（ジャンル・タグ共通）"
    datetime created_at "作成日時"
    datetime updated_at "更新日時"
  }
  active_storage_blobs {
    int id PK "BlobID"
    string key UK "ストレージ上のファイルキー"
    string filename "ファイル名"
    string content_type "MIMEタイプ"
    text metadata "メタデータ"
    string service_name "ストレージサービス名"
    bigint byte_size "ファイルサイズ（バイト）"
    string checksum "チェックサム"
    datetime created_at "作成日時"
  }
  active_storage_attachments {
    int id PK "AttachmentID"
    string name "添付名 (例: cover_image)"
    string record_type "添付先モデル名 (例: Book)"
    bigint record_id "添付先レコードID (record_type と合わせて多態関連)"
    bigint blob_id FK "BlobID"
    datetime created_at "作成日時"
  }
  active_storage_variant_records {
    int id PK "VariantRecordID"
    bigint blob_id FK "元BlobID"
    string variation_digest "バリアント識別子（リサイズ設定等のダイジェスト）"
  }
  users ||--o{ sessions : ""
  users ||--o{ rentals : ""
  rentals }o--|| book_items : ""
  book_items }|--|| books : ""
  books ||--|{ book_authors : ""
  authors ||--|{ book_authors : ""
  books ||--o{ book_tags : ""
  tags ||--o{ book_tags : ""
  books ||--o{ active_storage_attachments : "record (polymorphic, cover_image)"
  active_storage_blobs ||--o{ active_storage_attachments : ""
  active_storage_blobs ||--o{ active_storage_variant_records : ""
```

### 「現在の実装（最終）」からの変更点

| 項目 | 内容 | 理由 |
|---|---|---|
| `active_storage_blobs` / `active_storage_attachments` / `active_storage_variant_records` | 新規追加 | ISBN検索時に Google Books API から取得した書影画像を `Book#cover_image`（`has_one_attached`）として保存するため。Active Storage 標準のテーブル構成で、`books` とは `record_type`/`record_id` による多態関連（今回は `Book` のみが対象）。Solid Queue / Solid Cable と同様、Rails 標準基盤のテーブルだが、業務データ（画像）を保持する点が異なるためここでは明示している |
| 書籍現物 | `book_copies` → `book_items` に再リネーム | 一度 `copy` を採用したものの、開発者の語感として発展要件の設計時点の命名（`book_items`）の方がしっくりくると判断し、実装（テーブル名・モデル名 `BookItem`・関連メソッド名・ルーティング）とER図の両方を `book_items` に統一した。`copy` にもOSSの図書館システム（Evergreen ILS の `asset.copy` 等）という先例があり選択として妥当ではあったが、命名は最終的にはチーム・開発者の言語感覚に基づく判断であり、先例の有無だけで一意に「正解」が決まるものではない |
