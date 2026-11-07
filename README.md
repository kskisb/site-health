# site-health

Web制作会社やフリーランスが、保守しているクライアントのサイトを自動で点検し、毎月の報告書を日本語で作れるサービスです。稼働・SSL証明書・ドメイン・表示速度・リンク切れ・セキュリティの基本を定期的に点検し、そのままクライアントに渡せるレポートにまとめます。

サービス名は仮です。

## フォルダ

| フォルダ | 中身 |
| --- | --- |
| `backend/` | Rails API と Solid Queue（点検ジョブ） |
| `frontend/` | Nuxt（管理画面・共有レポート）。SPAとして Cloudflare Pages に置く |
| `workers/` | Cloudflare Workers（外からの見張り、独自ドメインの振り分け） |
| `infra/` | Terraform（Cloudflare、Grafana Cloud） |
| `openapi/` | `backend/` のテストから生成した OpenAPI の定義。`frontend/` の型の元になる |
| `.github/` | プルリクエストのテンプレートと GitHub Actions |

## 手元での動かし方

先に [mise](https://mise.jdx.dev/) と Docker Desktop を入れ、シェルで `mise activate` を有効にしておきます。RubyとNodeのバージョンは `.mise.toml` で決めてあり、Dockerで動かすのはPostgresだけです。

```bash
mise install                  # .mise.toml のRubyとNodeを入れる
docker compose up -d --wait   # Postgresを起動する
```

つながるかは `docker compose exec db psql -U postgres -c 'select version();'` で確かめられます。パスワードやポートを変えたいときは、`cp .env.example .env` で `.env` を作って値を入れます。

止めるときは `docker compose down` です。データはボリュームに残り、`docker compose down -v` で消えます。

### backend（Rails API）

```bash
cd backend
bundle install
bin/rails db:prepare   # DBを作り、マイグレーションを流す
bin/rails s            # http://localhost:3001 で起動する
```

テストとチェックは `bundle exec rspec`、`bin/rubocop`、`bin/brakeman` で動かします。`.env` でPostgresのパスワードやポートを変えたときは、Railsにも同じ環境変数を渡します（例：`set -a; source ../.env; set +a`）。
