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
| 書籍現物 | `book_items` | `book_copies` | 「同じ本の複製・冊」を表す語として `copy`（蔵書の1冊）の方が一般的で、`BookCopy` モデル名とも一致させた |
| セッション管理 | （未定義） | `sessions` テーブルを新規追加 | Rails 8 標準の認証機構が Cookie に署名付きセッションIDのみを保持し、実体（`ip_address` / `user_agent` など）をDBで管理する方式のため。これにより特定端末からのログアウト（セッション無効化）が可能になる |
| 著者名の一意性 | 制約なし | `authors.name` に UNIQUE 制約 | 同姓同名の著者レコードが重複作成されるのを防ぐため（`Author.find_or_create_by!` で名寄せする実装と対応） |
