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

準備中です。

## 著作権

このリポジトリのコードの著作権は作者にあり、利用は許可していません。ライセンスは付けていないため、複製・改変・再配布・このコードを使ったサービスの運営はできません。
