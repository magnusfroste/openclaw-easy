# openclaw-easy

Thin Easypanel deployment for [OpenClaw](https://github.com/openclaw/openclaw) — configure everything via environment variables, no manual JSON editing.

On every start, `docker-compose.yml` runs a small inline script that writes `openclaw.json` from your env vars and then starts the gateway. This means your config always matches what you set in Easypanel, and updating is just a Redeploy.

## Easypanel setup

1. **Create a new service** → App → set *Application source* to **Docker Compose** from GitHub: `magnusfroste/openclaw-easy`

2. **Add a domain** in Easypanel pointing to port `18789`.

3. **Paste env vars** from `example.env` into the service's env panel and fill in the values:

   | Variable | Required | Description |
   |---|---|---|
   | `OPENCLAW_GATEWAY_TOKEN` | yes | Auth token — generate with `openssl rand -hex 32` |
   | `OPENCLAW_ALLOWED_ORIGINS` | yes | Your public domain, e.g. `https://openclaw.example.com` |
   | `OPENCLAW_TRUSTED_PROXIES` | yes | Proxy CIDRs — default covers Easypanel's `10.11.0.0/16` |
   | `OPENCLAW_BASE_URL` | no | Custom OpenAI-compatible endpoint base URL |
   | `OPENCLAW_API_KEY` | no | API key for the custom endpoint |
   | `OPENCLAW_MODEL` | no | Model ID served by the custom endpoint |
   | `OPENCLAW_PROVIDER` | no | Provider name shown in OpenClaw (any string) |
   | `OPENAI_API_KEY` | no | OpenAI key (cloud, alternative to custom endpoint) |
   | `ANTHROPIC_API_KEY` | no | Anthropic key |
   | `OPENROUTER_API_KEY` | no | OpenRouter key |

4. **Deploy** → the gateway starts at your domain on port `18789`.

## Upgrading

Bump `OPENCLAW_IMAGE` in the env panel and hit Redeploy. The gateway token and all settings survive because they come from env vars, not from inside the container.

## Why not the Easypanel catalog template?

The catalog template is outdated and passes `OPENCLAW_GATEWAY_CONTROLUI_ALLOWEDORIGINS` and `OPENCLAW_GATEWAY_TRUSTEDPROXIES` as env vars — these are **not recognized by OpenClaw** and are silently ignored. Those settings only work inside `openclaw.json`. This repo handles that correctly.

It also auto-generates the gateway token on first start and stores it in the config volume. After a redeploy the token may not survive, locking you out. Here you always set the token explicitly.
