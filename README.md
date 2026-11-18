# Shopiz

Open-source omnichannel inbox and AI sales assistant for Vietnamese online sellers. Shopiz brings Zalo, Facebook, Instagram, TikTok and website chat into one place, and lets your team take orders and collect payments right inside the conversation.

Shopiz is a fork of [Chatwoot](https://github.com/chatwoot/chatwoot). It keeps Chatwoot's support desk and adds channels, sales tools and integrations built for the Vietnamese market.

> Shopiz is an independent project. It is not affiliated with, endorsed by, or sponsored by Chatwoot Inc.

> **Tiếng Việt:** Shopiz là nền tảng chat đa kênh mã nguồn mở dành cho người bán hàng online tại Việt Nam, phát triển dựa trên Chatwoot. Shopiz gom tin nhắn từ Zalo (OA và cá nhân), Facebook, Instagram, TikTok và website về một hộp thư chung, có trợ lý AI tư vấn bán hàng, tạo đơn và thu tiền qua mã QR (SePay, PayOS, Tingee) ngay trong cuộc hội thoại. Bạn có thể tự cài đặt (self-host) theo hướng dẫn bên dưới. Báo lỗi hoặc góp ý tại [GitHub Issues](https://github.com/iamlehuyphuong/shopiz/issues).

## What Shopiz adds on top of Chatwoot

### Channels

- **Zalo Official Account (OA)** through the official Zalo API.
- **Zalo Personal** (personal Zalo accounts) through a Node.js bridge built on [`zca-js`](https://github.com/RFS-ADRENO/zca-js). Supports groups, reactions, stickers, media, label sync and reminders. The bridge is a separate service and is not included in this repository. Point Shopiz to it with `ZALO_API_URL` and `ZALO_API_KEY` in Super Admin. This is an unofficial integration: Zalo may lock or ban accounts that use it.
- **TikTok** and **TikTok Shop**.
- **Facebook and Instagram comments**: public and private replies to comments, auto-replies and spam auto-hide.
- **OMICall** telephony: click-to-call, call notes and tag sync.

### Sales

- Product catalog with variants, SKU, barcode and images, plus Excel import and export.
- Orders created and confirmed inside a conversation, with an order summary sent to the customer.
- QR-code payments through **SePay**, **PayOS** and **Tingee**, with payment webhooks that update the order automatically.
- Sync customers, products and orders from connected e-commerce platforms. Contacts are merged by phone number.

### AI assistant (Captain)

- Sales assistant that answers customers, sends product info, drafts and confirms orders and checks payments.
- Scenario templates and an assistant playground for testing replies.
- Copilot tools for agents, AI label suggestions and daily inbox summaries.
- Bring your own OpenAI API key.

### Other additions

- Google Calendar bookings.
- Custom SMTP per account.
- Automatic follow-up reminders.
- Vietnamese localization.

Everything from Chatwoot is still included: a shared inbox for live chat, email, WhatsApp, Telegram, Line and SMS; private notes and mentions; canned responses; automation; help center; reports and CSAT. See the [Chatwoot docs](https://www.chatwoot.com/help-center) for details on those features.

## Getting started

### Requirements

- Ruby 3.4.4 (see `.ruby-version`)
- Node.js 24 and pnpm 10
- PostgreSQL 16 with the `pgvector` extension
- Redis

### Local development

```bash
git clone https://github.com/iamlehuyphuong/shopiz.git
cd shopiz

cp .env.example .env          # then edit the values you need
bundle install && pnpm install
bundle exec rails db:chatwoot_prepare
bundle exec rails db:seed     # optional sample data

pnpm dev                      # or: overmind start -f Procfile.dev
```

The app runs at http://localhost:3005 (see `Procfile.dev`); set `FRONTEND_URL` in `.env` to match. `.env.example` lists every environment variable with a short description. Chatwoot's [environment variable reference](https://www.chatwoot.com/docs/self-hosted/configuration/environment-variables) also applies to Shopiz.

### Self-hosting with Docker

The production image is built from `docker/Dockerfile.prod` and published to `ghcr.io/iamlehuyphuong/shopiz`. To run it, start from `docker-compose.production.yaml` and change the `image` to the Shopiz image.

## Staying in sync with Chatwoot

Shopiz regularly merges upstream Chatwoot releases. The current base version is in `VERSION_CW`. `sync-chatwoot.sh <tag>` prepares a branch from a Chatwoot release tag for merging.

## Contributing

Bug reports, feature requests and pull requests are welcome. Read [CONTRIBUTING.md](./CONTRIBUTING.md) before opening a PR.

## Security

Do not report vulnerabilities in public issues. See [SECURITY.md](./SECURITY.md).

## License

Shopiz is released under the MIT License, with exceptions for some directories. See [LICENSE](./LICENSE) for details.

Shopiz is built on [Chatwoot](https://github.com/chatwoot/chatwoot) © Chatwoot Inc. "Chatwoot" is a trademark of Chatwoot Inc.
