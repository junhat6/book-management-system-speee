---
name: verify
description: このリポジトリ（Rails 8 + SQLite + daisyUI）の変更を実際の画面フローで検証する手順。rails server を起動し、curl の cookie jar + CSRF token 抽出で認証付きフローを駆動する。
---

# 検証レシピ（Rails アプリを実際に駆動する）

## 起動と停止

```bash
bin/rails db:seed          # 冪等。admin@example.com / user@example.com（パスワードはどちらも 12345678）が入る
bin/rails server -p 3200 -d
curl -s http://localhost:3200/up   # ヘルスチェック（200 なら OK）
# 停止
kill $(cat tmp/pids/server.pid)
```

## 認証付きフローの駆動（curl + cookie jar + CSRF）

```bash
# ログイン（token は GET したページから抽出）
TOKEN=$(curl -s -c admin.jar http://localhost:3200/session/new | grep -o 'name="authenticity_token" value="[^"]*"' | head -1 | sed 's/.*value="//;s/"//')
curl -s -b admin.jar -c admin.jar -d "authenticity_token=$TOKEN" \
  -d "email_address=admin@example.com" -d "password=12345678" http://localhost:3200/session
```

## 罠: per-form CSRF token

このアプリは per-form CSRF token が有効。**POST 先の action と一致するフォームから token を取る**こと。
別フォームの token を流用すると 422 が返る（ページ先頭のフォームは検索やログアウトのことがある）。

```bash
PAGE=$(curl -s -b admin.jar http://localhost:3200/books/1 | tr '\n' ' ')
TOKEN=$(echo "$PAGE" | grep -o 'action="/books/1/rentals"[^!]\{0,300\}' | grep -o 'name="authenticity_token" value="[^"]*"' | head -1 | sed 's/.*value="//;s/"//')
```

- button_to の DELETE/PATCH は `-d "_method=delete"` / `-d "_method=patch"` で送る
- flash はリダイレクト後の**次の GET** に出る（`alert-error` / `alert-success` クラスを grep）
- 検証で作ったレコードは `bin/rails runner` で削除して戻す（has_many :through は delete_all 不可、直接 `Rental.where(...).delete_all`）
