# 解説：デプロイ基盤をRender(Postgres)からFly.io(SQLite)に移行した話

> 本番でメーラー(Resend)を使いたい、という一言から始まり、最終的にデプロイ先そのものを
> 変更する結果になった一連の作業の記録。「何を」変更したかだけでなく、「Fly.ioが何者で、
> なぜこの構成にしたか」を Mermaid 図で追えることを主眼に置く。

- 対象: 本番デプロイ基盤全体（Render → Fly.io）、`config/database.yml`、`fly.toml`、`Dockerfile`、GitHub Actions
- 作業日: 2026-07-02
- 経緯: パスワードリセット機能で本番メール送信をしたかったが、Renderの無料プランはSMTP送信をブロックしている。API型メール(Resend)に切り替えて解決したが、その過程でRenderの無料Postgres特有の設計上の問題（後述）と、無料Postgresの30日期限切れという制約に突き当たり、「無料枠のパッチを重ねるコスト」が「デプロイ先を変えるコスト」を上回ると判断してFly.ioに移行した

---

## 1. なぜRenderからFly.ioに移行したか

判断の流れを図にすると以下の通り。

```mermaid
flowchart TD
    A["本番でメール送信したい"] --> B{"Render無料プランでSMTP使える？"}
    B -- "No: ポート25/465/587が\n2025年9月末からブロック" --> C["Resend(API型メール)に切替"]
    C --> D["Renderにデプロイ"]
    D --> E["500エラー発生"]
    E --> F["原因調査"]
    F --> G["cache/queue/cableが同じPostgres DBを共有し\nschema_migrationsが衝突"]
    G --> H["primaryに統合する応急処置を実装"]
    H --> I{"そもそも無料のままでいい？"}
    I -- "調査すると..." --> J["無料Postgresは作成から30日で\n期限切れ・8/4に自動削除と判明"]
    J --> K{"コスト比較"}
    K -- "Render: Web無料+Postgres有料 $6~/月" --> L["どのみち有料化が必要"]
    K -- "Fly.io: VM+Volume $2~4/月" --> M["Fly.ioの方が安く\nRails8本来の構成に戻せる"]
    L --> N["Fly.io移行を決定"]
    M --> N
    N --> O["SQLite構成に戻し、Fly.ioへデプロイ"]

    style G fill:#f66,color:#fff
    style J fill:#f66,color:#fff
    style N fill:#6c6,color:#fff
```

途中で実装した「Postgres統合の応急処置」は、コミットする前に破棄した。無駄に見えるかもしれないが、実際に手を動かして複雑さを体感したからこそ「アーキテクチャごと変える」判断に自信を持てた、という経緯がある。

---

## 2. Fly.ioというプラットフォームの仕組み

Fly.ioは「Dockerイメージを、世界中のデータセンターにある軽量VM（Machine）で動かす」PaaS。Renderのような典型的なPaaSとの一番の違いは、**各Machineに永続ディスク（Volume）を直接アタッチできる**という点。

```mermaid
flowchart LR
    subgraph Internet["インターネット"]
        User(("ユーザー"))
    end

    subgraph FlyEdge["Fly.io エッジネットワーク"]
        Proxy["fly-proxy\n(Anycast, TLS終端)"]
    end

    subgraph Region["リージョン: nrt (東京)"]
        subgraph Machine["Machine (Firecracker microVM)"]
            App["Rails app\n(Puma + Solid Queue)"]
        end
        Volume[("Volume: data\n1GB, 東京リージョンに固定")]
        Machine <-->|"/data にマウント"| Volume
    end

    User -->|"HTTPS"| Proxy
    Proxy -->|"HTTP (内部)"| Machine

    style Volume fill:#48f,color:#fff
    style Machine fill:#fa4,color:#000
```

**RenderのFree Web Serviceとの決定的な違い**：RenderのFreeプランはコンテナのローカルファイルシステムが完全にエフェメラル（永続ディスクは有料プラン限定）。Fly.ioは無料枠こそ廃止されているが、VM本体（Machine）とは独立した**ブロックストレージ(Volume)**を、無料プランの制約を気にせず安価に使える。これが「SQLiteをそのまま本番で使う」という選択を現実的にしている理由。

---

## 3. 本アプリのFly.io上での構成

```mermaid
flowchart TB
    subgraph Machine["book-management-system-speee (Machine)"]
        direction TB
        Puma["Puma (Webサーバー)"]
        SQ_Sup["Solid Queue Supervisor\n(SOLID_QUEUE_IN_PUMA=true で\n同一プロセス内に同居)"]
        SQ_Sup --> SQ_D["Dispatcher"]
        SQ_Sup --> SQ_W["Worker"]
        SQ_Sup --> SQ_S["Scheduler"]
    end

    subgraph Volume["Volume: /data (永続)"]
        direction TB
        DB1[("production.sqlite3\n(primary: books/authors/users...)")]
        DB2[("production_cache.sqlite3\n(solid_cache)")]
        DB3[("production_queue.sqlite3\n(solid_queue)")]
        DB4[("production_cable.sqlite3\n(solid_cable)")]
    end

    Puma --> DB1
    Puma --> DB2
    SQ_W --> DB3
    SQ_D --> DB3
    SQ_S --> DB3
    Puma -.->|"ActionCable用\n(未使用時は空)"| DB4

    Puma -->|"HTTPS API"| Resend["Resend\n(メール送信API)"]

    style DB1 fill:#48f,color:#fff
    style DB2 fill:#48f,color:#fff
    style DB3 fill:#48f,color:#fff
    style DB4 fill:#48f,color:#fff
```

ポイントは、`primary` / `cache` / `queue` / `cable` が**それぞれ別々の物理SQLiteファイル**になっていること。Renderで使っていたPostgresは1個のDBインスタンスしか無料で持てなかったため、この4つを同じDBに無理やり同居させ、それぞれの`schema_migrations`管理テーブルが衝突するというバグを踏んだ（詳細は8章）。Fly.ioでは1つのVolumeの中に**ファイルとして**4つ分離して置けるので、この問題がそもそも起こらない。

---

## 4. SQLite + 永続Volumeの仕組み

コンテナ内のファイルシステムは「イメージレイヤー」＋「Volume」の2階建てになっている。

```mermaid
flowchart LR
    subgraph Container["コンテナのファイルシステム"]
        direction TB
        Ephemeral["イメージ由来の領域\n(/rails/app, /rails/binなど)\n\n再起動・再デプロイのたびに\nイメージから作り直される"]
        Persistent["/data\n(Volumeがマウントされた領域)\n\n再起動してもデータが残る"]
    end

    Deploy["fly deploy"] -->|"新しいイメージで\nEphemeralを置き換え"| Ephemeral
    Restart["Machine再起動\n(スケールtoゼロからの復帰など)"] -.->|"影響しない"| Persistent

    style Persistent fill:#48f,color:#fff
    style Ephemeral fill:#ccc,color:#000
```

Renderの無料プランで踏んだ問題は、まさにこの「Ephemeralな領域にSQLiteファイルを置いていた」に相当する状態だった（正確にはRender FreeにVolumeという概念自体が無い）。Fly.ioでは`fly.toml`の`[[mounts]]`でVolumeを明示的に`/data`にマウントし、`DATABASE_URL=sqlite3:///data/production.sqlite3`という環境変数でRailsにその場所を教えている。

---

## 5. デプロイの仕組み（push → 本番反映まで）

今回、GitHub Actionsによる自動デプロイを組んだので、`git push`するだけで以下が自動的に走る。

```mermaid
sequenceDiagram
    actor Dev as 開発者
    participant GH as GitHub
    participant Actions as GitHub Actions
    participant FlyBuild as Fly.io ビルダー
    participant Registry as Fly.io レジストリ
    participant Machine as 本番 Machine

    Dev->>GH: git push origin main
    GH->>Actions: on: push (main) をトリガー
    Actions->>Actions: CI (brakeman/bundler-audit/rubocop/test/system-test)
    Actions->>FlyBuild: flyctl deploy --remote-only
    FlyBuild->>FlyBuild: Dockerfileをビルド\n(bundle install, assets:precompile)
    FlyBuild->>Registry: イメージをpush
    Registry->>Machine: 新イメージで\nローリングアップデート
    Machine->>Machine: /rails/bin/docker-entrypoint実行\n(db:prepareでマイグレーション)
    Machine->>Machine: ヘルスチェック(/up)がpassするまで待機
    Machine-->>Dev: デプロイ完了通知
```

`FLY_API_TOKEN`がGitHub Secretsに（`fly launch`実行時に自動で）登録されているので、GitHub Actions上の`flyctl`がこのトークンでFly.ioにログインしてデプロイできる、という仕組み。

---

## 6. Machine起動時のシーケンス

Machineが起動する（スケールtoゼロからの復帰、または再デプロイ）たびに、以下の順で処理が走る。

```mermaid
sequenceDiagram
    participant FC as Firecracker VM
    participant Entry as docker-entrypoint
    participant Rails as bin/rails db:prepare
    participant Puma as Puma
    participant SQ as Solid Queue Supervisor

    FC->>FC: Volume(/data)をマウント
    FC->>Entry: ENTRYPOINT実行
    Entry->>Entry: 起動コマンドが"rails server"か判定
    Entry->>Rails: db:prepare実行
    Rails->>Rails: primary: マイグレーション実行
    Rails->>Rails: cache/queue/cable: schema.rbロード\n(初回のみ。既存なら何もしない)
    Rails-->>Entry: 完了
    Entry->>Puma: exec ./bin/rails server
    Puma->>Puma: リクエスト受付開始
    Puma->>SQ: SOLID_QUEUE_IN_PUMA=trueなので\nSupervisorをプラグインとして起動
    SQ->>SQ: Dispatcher / Worker / Scheduler起動
    Note over Puma,SQ: ここまで完了して初めて/upが200を返す
```

`SOLID_QUEUE_IN_PUMA`の設定を最初忘れていて、「メールはEnqueueされるが送信されない（Performedのログが出ない）」という状態に一度なった。単一Machine構成では、Webサーバーとジョブワーカーを分けずに同じプロセス内に同居させるのがFly.io/Kamalでの定石。

---

## 7. メール送信の全体フロー(今回の本来の目的)

```mermaid
sequenceDiagram
    actor User as ユーザー
    participant PC as PasswordsController
    participant Job as ActionMailer::MailDeliveryJob
    participant SQ as Solid Queue Worker
    participant Resend as Resend API
    participant Mail as 受信箱

    User->>PC: POST /passwords (email_address)
    PC->>Job: PasswordsMailer.reset(user).deliver_later
    Job->>SQ: production_queue.sqlite3にEnqueue
    PC-->>User: 302 redirect (即座にレスポンス)
    Note over SQ: 非同期でポーリング中のWorkerが拾う
    SQ->>Resend: HTTPS APIでメール送信リクエスト
    Resend-->>Mail: メール配送
    Resend-->>SQ: 200 OK
```

`deliver_later`（同期的にSMTP接続するのではなく、いったんキューに積んで後で送る）にしているおかげで、ユーザーへのレスポンスがメール送信の成否を待たない設計になっている。これはRenderでもFly.ioでも変わらない、Rails側の設計の恩恵。

---

## 8. （参考）Renderで踏んだPostgres統合バグの構造

反面教師として構造を残しておく。

```mermaid
flowchart TD
    subgraph Postgres["1個のPostgres DB (Render無料枠)"]
        SM["schema_migrations テーブル\n(1個しかない)"]
    end

    Cache["cache設定\n(database.yml)"] -->|"db:prepare実行"| SM
    Queue["queue設定\n(database.yml)"] -->|"db:prepare実行"| SM
    Cable["cable設定\n(database.yml)"] -->|"db:prepare実行"| SM

    SM -.->|"cacheが先にversion:1を記録"| Blocked["queue/cableは\n「version:1は適用済み」と誤認\nスキップされる"]

    style SM fill:#f66,color:#fff
    style Blocked fill:#f66,color:#fff
```

`solid_cache`/`solid_queue`/`solid_cable`のスキーマスナップショットが、それぞれ独立に`version: 1`から採番されているのが元凶。物理的に同じDBを共有した瞬間に、この採番が衝突する。Fly.io + SQLiteでは各々が別ファイルなので、この採番の衝突自体が起こり得ない。

---

## 9. 変更したファイル一覧

| ファイル | 変更内容 |
|---|---|
| `config/database.yml` | production を Postgres(単一DB共有) → SQLite(4ファイル分離、Rails 8デフォルト) に戻す |
| `config/environments/production.rb` | `solid_queue.connects_to`を復元、Resendのdelivery_method設定はそのまま維持 |
| `Gemfile` / `Gemfile.lock` | `pg`を削除、`sqlite3`を全環境で利用可能に、`dockerfile-rails`を追加(fly launchが自動追加) |
| `Dockerfile` | ビルドステージに`libffi-dev`を追加(fly launchが検出した不足パッケージ) |
| `fly.toml` | 新規。Volumeマウント(`/data`)、ヘルスチェック、`SOLID_QUEUE_IN_PUMA=true`などを定義 |
| `config/dockerfile.yml` | 新規。`dockerfile-rails`gemの設定ファイル |
| `.github/workflows/fly-deploy.yml` | 新規。mainへのpushで`flyctl deploy`を自動実行 |
| `db/seeds.rb` | `must_have_author`バリデーションの順序バグを修正(著者未紐付けで`save!`していた) |
| `test/application_system_test_case.rb` / `test/system/books_test.rb` | 新規。CIの`system-test` Jobが空ディレクトリでLoadErrorになっていたのを解消 |

---

## 10. 実施した手順（作業ログ）

1. Resend公式gem(`resend`)を追加し、`config/initializers/resend.rb`でAPIキーを読み込む設定
2. `config.action_mailer.delivery_method = :resend`に変更、送信元を`onboarding@resend.dev`(検証不要のサンドボックス)に
3. Renderで500エラー発生 → 原因調査 → `db:migrate`ではなく`db:prepare`が必要と判明
4. 再度500エラー(`solid_queue_jobs`が無い) → cache/queue/cableのPostgres共有問題を発見
5. 一時対応としてqueue/cableをprimaryに統合する修正を作成(後に破棄)
6. Render無料Postgresの30日期限切れ・料金比較からFly.io移行を決定
7. `config/database.yml`等をSQLite(Rails 8デフォルト)構成に復元
8. `fly auth login` → `flyctl launch --no-deploy`でfly.toml等を生成
9. `Dockerfile`に`libffi-dev`を追加
10. `fly secrets set`で`APP_HOST`・`RESEND_API_KEY`を設定
11. `fly deploy`で初回デプロイ → `db/seeds.rb`のバグを発見・修正 → 再デプロイ
12. `SOLID_QUEUE_IN_PUMA`未設定でメールが送信されない問題を発見・修正 → 再デプロイ
13. 実際に自分のメールアドレス宛でパスワードリセットメールが届くことを確認
14. コミット・push → GitHub Actions経由の自動デプロイを確認
15. ついでに見つかったCIの既存不具合(crassのCVE、system-test未整備)を修正

---

## 11. Render vs Fly.io 比較

| 項目 | Render (Web無料 + Postgres) | Fly.io (Machine + Volume) |
|---|---|---|
| 月額目安 | 約$6〜（Postgresが有料化必須） | 約$2〜4 |
| DBの実体 | マネージドPostgres(別サービス) | SQLiteファイル(アプリと同じVolume内) |
| 無料Postgresの制約 | 30日で期限切れ、1GB上限 | 該当なし(Volumeは自分で持つ) |
| Rails 8デフォルト構成との親和性 | 低い(Postgres前提に手動で作り変えが必要) | 高い(Kamal向けデフォルトがほぼそのまま使える) |
| SMTP送信 | 無料プランでブロック(2025年9月〜) | 制限なし(ただし今回はAPI型のResendを継続利用) |
| スケールtoゼロ | あり(15分無操作で停止、コールドスタートあり) | あり(`auto_stop_machines`で同様の挙動) |

---

## 12. なぜRails 8のデフォルト構成にFly.ioが合うか

Rails 8は「`rails new`した直後から、Kamalで自前のVPSにDockerでデプロイする」ことを前提に設計されている。具体的には：

- SQLiteを`storage/`配下に置き、`config/deploy.yml`で`volumes:`として永続化する前提
- `solid_queue` / `solid_cache` / `solid_cable`は、それぞれ独立したSQLiteファイルとして動くのがデフォルト
- Dockerfile自体もRails標準ジェネレータが生成したものがそのまま使える

Fly.ioは「Dockerイメージ＋Volume」というKamalとほぼ同じメンタルモデルを、マネージドなインフラ（VM調達・ネットワーク・TLS終端）の上で提供してくれる。つまり「Kamalで自分のVPSを借りて運用する」ことの代わりに「Fly.ioに運用を任せる」形になっており、**Rails 8のデフォルトが想定するアーキテクチャを、インフラの面倒を見ずに再現できる**のがFly.ioを選んだ本質的な理由。RenderのPostgres前提の構成は、この設計思想から外れた場所に人力でパッチを当て続ける状態だった。

---

## 13. 今後の注意点・トレードオフ

- **コールドスタート**: `min_machines_running = 0`のため、15分程度アクセスが無いとMachineが止まり、次のリクエストで起動待ち（数秒〜十数秒）が発生する。Renderの無料枠と同様の体験。
- **単一リージョン制約**: SQLiteのVolumeは1つのMachineに紐づくため、複数リージョンに分散させることは基本的にできない（学習用途では問題にならない）。
- **バックアップ**: Volumeのスナップショット機能はあるが、Postgresのような自動バックアップは無いので、必要になったら`fly volumes snapshots`まわりを別途調べる必要がある。
- **Resendのサンドボックス制約**: 独自ドメインを検証するまでは、`onboarding@resend.dev`からは自分のResendアカウント登録メール宛にしか送れない。全ユーザーへの本番配信を試したくなったらドメイン検証が必要になる。
