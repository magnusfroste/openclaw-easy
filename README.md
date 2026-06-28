# openclaw-easy

Thin Easypanel deployment for [OpenClaw](https://github.com/openclaw/openclaw) — configure everything via environment variables, no manual JSON editing.

On every start, `docker-compose.yml` runs a small inline script that writes `openclaw.json` from your env vars and then starts the gateway. This means your config always matches what you set in Easypanel, and updating is just a Redeploy.

It builds a thin image (`Dockerfile`) on top of the upstream OpenClaw image with a baseline of tools (sudo, build-essential, python3/pip, uv, git, ripgrep, …) and runs the container as **root**, so the agent can install whatever it needs at runtime. Every variable you set in the Easypanel env panel is passed through to the container as a runtime env var.

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
   | `OPENCLAW_MODEL_PRIMARY` | no | Default model as `provider/model`, e.g. `zai/glm-5.2` (redeploy-safe) |
   | `OPENCLAW_MODEL_FALLBACKS` | no | Comma-separated `provider/model` fallback list |
   | `OPENCLAW_<PROVIDER>_BASE_URL` | no | Override a built-in provider's endpoint, e.g. `OPENCLAW_ZAI_BASE_URL` |
   | `OPENAI_API_KEY` | no | OpenAI key (built-in provider) |
   | `ANTHROPIC_API_KEY` | no | Anthropic key (built-in provider) |
   | `OPENROUTER_API_KEY` | no | OpenRouter key (built-in provider) |
   | `ZAI_API_KEY` | no | Z.ai (GLM) key — built-in provider; `Z_AI_API_KEY` is a legacy alias |
   | *(any other var)* | no | Passed through to the container at runtime as-is |

### Choosing the model

Built-in providers (`openai`, `anthropic`, `openrouter`, `zai`, …) read their `*_API_KEY` from the env — set the key, then point `OPENCLAW_MODEL_PRIMARY` at e.g. `zai/glm-5.2`. Because the model selection is written into `openclaw.json` on every start, it **survives redeploys**. Picking a model in the Control UI instead does *not* survive — the inline script overwrites `openclaw.json` each start.

**z.ai (GLM) note:** the built-in `zai` provider defaults to the *general* endpoint (`…/api/paas/v4`, default model `glm-5.1`). To use `glm-5.2` on the **coding plan** you must also set `OPENCLAW_ZAI_BASE_URL=https://api.z.ai/api/coding/paas/v4` — otherwise the model breaks on redeploy. The override merges with the built-in provider (keeps its model catalog); the key still comes from `ZAI_API_KEY`.

### Agent install freedom

The container runs as root with build tools baked in, and any Easypanel env var reaches the agent's shell. The agent can `apt`/`pip`/`npm`-install ad-hoc; ad-hoc installs are lost on redeploy, so for anything permanent add it to the `Dockerfile`.

> **Security note:** root + the gateway being internet-exposed + `OPENCLAW_DISABLE_DEVICE_AUTH` + `host.docker.internal` mapped means the gateway token effectively grants root with a path toward the host. This is a deliberate single-user, high-trust setup — keep the token secret and the origins locked down.

4. **Deploy** → the gateway starts at your domain on port `18789`.

## Upgrading

Bump `OPENCLAW_IMAGE` in the env panel and hit Redeploy. The gateway token and all settings survive because they come from env vars, not from inside the container.

## Why not the Easypanel catalog template?

The catalog template is outdated and passes `OPENCLAW_GATEWAY_CONTROLUI_ALLOWEDORIGINS` and `OPENCLAW_GATEWAY_TRUSTEDPROXIES` as env vars — these are **not recognized by OpenClaw** and are silently ignored. Those settings only work inside `openclaw.json`. This repo handles that correctly.

It also auto-generates the gateway token on first start and stores it in the config volume. After a redeploy the token may not survive, locking you out. Here you always set the token explicitly.
