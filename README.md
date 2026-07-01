# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## カバレッジ（テスト網羅率）

```bash
rails t                      # テスト実行と同時に coverage/ が更新される
open coverage/index.html     # ブラウザでレポートを表示
```

## Seedデータとログイン情報

seedデータ投入:

```bash
bin/rails db:seed
```

投入されるログインユーザー:

- 管理者
	- email: admin@example.com
	- password: 12345678
- 一般ユーザー
	- email: user@example.com
	- password: 12345678
