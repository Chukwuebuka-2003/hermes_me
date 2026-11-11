# hermes_me

Hermes Agent deployment on Hetzner VPS dedicated to Telegram.

Everything runs from a single `docker-compose.yml` file.

---

## Why this is secure for Hetzner VPS

- No open incoming ports: Telegram connects using outbound long-polling to `api.telegram.org`. You do not need to open any ports (HTTP/HTTPS/8642) in your Hetzner Cloud firewall or UFW.
- User authorization: Restricted via `TELEGRAM_ALLOWED_USERS` so only your Telegram account can interact with the agent.
- 5GB storage limit: Container rootfs is capped at 5GB (`storage_opt: size: 5G`).
- Log rotation: Prevent logs from exhausting disk space (`max-size: 10m`, `max-file: 3`).
- Memory limit: Capped at 4096MB to protect small VPS instances.

---

## Prerequisites

1. Get your Telegram Bot Token:
   - Message `@BotFather` on Telegram.
   - Send `/newbot` and follow instructions to get the HTTP API token.
2. Get your Numeric Telegram User ID:
   - Message `@userinfobot` on Telegram to get your numeric ID (e.g. `123456789`).
3. Get an API key for your preferred LLM provider (OpenRouter, OpenAI, or Anthropic).

---

## Quick Start

### 1. Clone the repository on your VPS

```bash
git clone https://github.com/Chukwuebuka-2003/hermes_me.git
cd hermes_me
```

### 2. Configure your credentials

You can set your credentials directly in `docker-compose.yml` or via a `.env` file:

```bash
cp .env.example .env
```

Fill in:
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_ALLOWED_USERS`
- Your LLM API key (e.g., `OPENROUTER_API_KEY`)

### 3. Start Hermes Agent

```bash
docker compose up -d
```

### 4. Talk to your Bot

Open Telegram, find your bot, and send `/start` or any prompt.

---

## Management Commands

- View live logs:
  ```bash
  docker compose logs -f hermes
  ```

- Interactive terminal inside the container:
  ```bash
  docker compose exec -it hermes hermes
  ```

- Restart the bot:
  ```bash
  docker compose restart
  ```

- Update to latest version:
  ```bash
  docker compose pull
  docker compose up -d
  ```

- Stop the bot:
  ```bash
  docker compose down
  ```
