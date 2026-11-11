# hermes_me

My Hermes Agent setup on a Hetzner VPS.

This repository contains an optimized, production-hardened Docker Compose configuration for running [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent) on a Hetzner Cloud VPS.

---

## Security Best Practices for Hetzner Cloud

Hetzner VPS instances assign public IPv4 and IPv6 addresses directly to your network interface without a hardware firewall by default.

This Docker Compose configuration enforces:
1. **Loopback Binding (`127.0.0.1`)**: Ports `8642` (API) and `9119` (Dashboard) bind only to localhost so unauthenticated bots and scanners cannot hit them.
2. **Access Methods**:
   - **Mode A (Recommended)**: Private access via an SSH tunnel (`ssh -L 9119:127.0.0.1:9119 ...`).
   - **Mode B**: Domain-based public access through **Caddy** with automated Let's Encrypt TLS and HTTP Basic Authentication.
3. **5GB Storage Quota**: Enforces a 5GB limit on the container writable layer (`storage_opt: size: 5G`) and includes a 5GB loop-mount script for `./data` so persistent files and session databases never exceed 5GB.
4. **Log Rotation**: Limits container log files to 10MB x 3 to prevent filling up the VPS disk.
5. **UID/GID Mapping**: Avoids Docker root permission conflicts by aligning container permissions with your VPS host user.

---

## Quick Start Guide

### 1. VPS Host Preparation

Ensure Docker and the Docker Compose plugin are installed on your Hetzner VPS:

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install Docker (if not installed)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Configure UFW Firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp     # SSH
# If using Caddy for domain-based HTTPS:
# sudo ufw allow 80/tcp
# sudo ufw allow 443/tcp
sudo ufw enable
```

*(Note: Relog if you just added your user to the `docker` group).*

---

### 2. Prepare Storage (5GB Limit) and Initial Setup

Clone this repository on your VPS:

```bash
git clone https://github.com/Chukwuebuka-2003/hermes_me.git
cd hermes_me

# Option A: Create a strict 5GB hard-capped virtual disk for ./data (Recommended)
# This creates a sparse 5GB ext4 loop-mount image that prevents disk overrun:
./setup-5gb-storage.sh

# Option B: Standard directory without loop-mount:
# mkdir -p ./data && chown -R $(id -u):$(id -g) ./data

# Run the interactive setup wizard once to configure API keys / providers:
docker run -it --rm \
  -v $(pwd)/data:/opt/data \
  nousresearch/hermes-agent setup
```

---

### 3. Configure `.env`

Copy the template:

```bash
cp .env.example .env
```

Edit `.env` and configure your settings:
```bash
# Set UID and GID to your VPS user (check with `id -u` and `id -g`)
HERMES_UID=1000
HERMES_GID=1000

# Set a secure key for the API server:
API_SERVER_KEY=$(openssl rand -hex 24)
```

---

### 4. Start the Agent

#### Mode A: Private & Secure (Via SSH Tunnel - Recommended)
No domain or open web ports required.

```bash
docker compose up -d
```

To access the Web Dashboard from your local computer:
```bash
ssh -N -L 9119:127.0.0.1:9119 user@your-hetzner-vps-ip
```
Then open `http://localhost:9119` in your local browser!

---

#### Mode B: Domain with Automatic HTTPS (Via Caddy)
If you have a domain pointing to your Hetzner VPS IP and want direct HTTPS access:

1. In `.env`, set:
   ```env
   HERMES_DOMAIN=hermes.yourdomain.com
   CADDY_LETSENCRYPT_EMAIL=your-email@example.com
   ```
2. (Optional) Generate a hashed password for dashboard Basic Auth:
   ```bash
   docker run --rm caddy:2.8-alpine caddy hash-password --plaintext "YourPasswordHere"
   ```
   Paste the hash into `DASHBOARD_BASIC_AUTH_HASH` in `.env`.

3. Launch with Caddy enabled:
   ```bash
   docker compose --profile caddy up -d
   ```

---

## Management & Common Commands

- **View Live Logs**:
  ```bash
  docker compose logs -f hermes
  ```

- **Open Interactive CLI inside Hermes Agent**:
  ```bash
  docker compose exec -it hermes hermes
  ```

- **Restart the Stack**:
  ```bash
  docker compose restart
  ```

- **Update Hermes Agent to Latest Release**:
  ```bash
  docker compose pull
  docker compose up -d
  ```

- **Stop the Stack**:
  ```bash
  docker compose down
  ```

---

## Chat Integrations (Telegram / Discord / Slack)

You can connect Hermes to messaging apps by providing the bot tokens in your `.env`:
- `TELEGRAM_BOT_TOKEN`
- `DISCORD_BOT_TOKEN`
- `SLACK_BOT_TOKEN` & `SLACK_APP_TOKEN`

Once added to `.env`, restart the container:
```bash
docker compose up -d
```
Hermes Agent will start the gateway listeners in the background.
