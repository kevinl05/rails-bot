# RailsBot

Chat app where you talk to Ruby on Rails personified. Not a Rails assistant — the framework itself, with opinions, history, and DHH's latest Bluesky takes baked in.

## Architecture Overview

- **Rails 8.0** on Ruby 3.2.2, SQLite for all databases (primary, cache, queue, cable)
- **Anthropic Ruby SDK** (`anthropic` gem v1.23.0) calling `claude-sonnet-4-20250514`
- **Hotwire**: Turbo Streams broadcast assistant messages via Action Cable; Stimulus handles optimistic UI (user message appears instantly, thinking indicator, then broadcast replaces it)
- **Tailwind CSS v4** via `tailwindcss-rails` gem, dark theme (gray-950 bg, red-500 accents)
- **Importmap** for JS — no Node, no bundler
- **Deployed** to Fly.io at `https://rails-bot-chat.fly.dev` (EWR region, shared-cpu-1x, 512MB, free tier)
- **Auth**: HTTP Basic Auth via `AUTH_USER` / `AUTH_PASSWORD` env vars. Skipped if vars unset (local dev).
- **Persistence**: Fly volume mounted at `/data` for production SQLite files. Dev uses `storage/` directory.

## Critical Design Rules

1. The `anthropic` gem v1.23 uses `system_:` (with underscore) not `system` for the system prompt parameter. The streaming method is `client.messages.stream()` returning a `MessageStream` — iterate with `.each`, text events have `event.type == :text` and `event.text`.
2. Only assistant messages broadcast via Turbo Streams (`after_create_commit` on Message model, `if: :assistant?`). User messages are appended client-side by the Stimulus chat controller to avoid duplication.
3. The `RailsBot::Chat#call` method is synchronous — it blocks the controller while Claude responds. The Stimulus controller shows a thinking indicator during this wait.
4. DHH feed (Bluesky + HEY World blog) is fetched via `RailsBot::DhhFeed` and cached for 1 hour in `Rails.cache`. It's injected into the system prompt via string interpolation (`%{dhh_context}`).
5. Conversation titles are auto-generated after the first exchange via a background `Thread.new` API call. Don't use ActiveJob for this — it's intentionally lightweight.
6. Thruster runs as the HTTP proxy in production (via `bin/thrust`). It must bind to port 8080 (not 80) because the container runs as non-root user 1000. Set `HTTP_PORT=8080` in fly.toml env.
7. Health check endpoint is `/up` (Rails built-in `rails/health#show`). It bypasses our ApplicationController, so auth and `allow_browser` don't affect it.

## What NOT To Do

- **Do NOT use `bin/dev`** — the `tailwindcss:watch` task spawns `rg` (ripgrep) in a tight loop and nukes CPU. Use `bin/rails server` directly and run `bin/rails tailwindcss:build` manually when changing styles.
- **Do NOT store `system` role messages in the DB** — the system prompt is assembled dynamically in `RailsBot::Chat#system_prompt` from the constant + DHH feed. Only `user` and `assistant` roles go in the messages table.
- **Do NOT use `require "rss"`** — the `rss` stdlib was removed in Ruby 3.x. HEY World Atom feed is parsed with Nokogiri (already a Rails dependency).
- **Do NOT set `DATABASE_URL` in fly.toml env** — production DB paths are hardcoded in `config/database.yml` pointing to `/data/*.sqlite3` on the Fly volume.
- **Do NOT use `create_streaming` or pass `system` (without underscore) to the anthropic gem** — these are wrong API names for v1.23.

## Reference Files

- `app/services/rails_bot/chat.rb` — Claude API integration, system prompt, conversation history assembly, title generation
- `app/services/rails_bot/dhh_feed.rb` — Fetches DHH's Bluesky posts and HEY World blog titles, cached 1hr
- `app/javascript/controllers/chat_controller.js` — Optimistic UI: instant user bubble, thinking indicator, fetch POST, cleanup on response
- `app/javascript/controllers/scroll_controller.js` — MutationObserver auto-scrolls messages container
- `app/views/conversations/show.html.erb` — Main chat UI with `turbo_stream_from @conversation`
- `app/views/messages/_message.html.erb` — Message bubble partial (used for server render + Turbo broadcast)
- `fly.toml` — Fly.io config: EWR region, 8080 internal port, auto-stop, 1GB volume mount at `/data`
- `.env` — Local dev secrets (gitignored). Must contain `ANTHROPIC_API_KEY=sk-ant-...`
- `app/javascript/controllers/hello_controller.js` — Rails scaffold leftover, can be deleted

## Key Integration Details

**Anthropic API (Claude)**
- Gem: `anthropic` v1.23.0
- Model: `claude-sonnet-4-20250514`
- Non-streaming: `client.messages.create(model:, max_tokens:, system_:, messages:)` → `.content.first.text`
- Streaming: `client.messages.stream(...)` → `.each { |event| event.text if event.type == :text }`
- API key via `ENV.fetch("ANTHROPIC_API_KEY")`

**DHH Bluesky Feed**
- Endpoint: `https://public.api.bsky.app/xrpc/app.bsky.feed.getAuthorFeed?actor=dhh.bsky.social&limit=10`
- No auth required. Returns JSON with `feed[].post.record.text`

**DHH HEY World Blog**
- Atom feed: `https://world.hey.com/dhh/feed.atom`
- Parsed with Nokogiri. Extracts entry titles only.

**Fly.io Secrets** (set via `fly secrets set`):
- `ANTHROPIC_API_KEY`, `AUTH_USER`, `AUTH_PASSWORD`, `RAILS_MASTER_KEY`

## Build Philosophy

This is a prototype — ship fast, keep it simple, make it feel good. The persona prompt is the product; the app is just the delivery mechanism. When improving:
- Polish the system prompt and persona behavior before adding features
- Keep the UI minimal and chat-focused — no dashboards, no settings pages
- Prefer Rails conventions (Turbo, Stimulus, ERB) over reaching for React/JS frameworks
- If Claude's response quality is the issue, tune the prompt, don't add middleware

This is NOT a license to scope-creep. Do what's asked, do it well, ship it.

## Cleanup & Garbage Collection

- Delete `app/javascript/controllers/hello_controller.js` — unused scaffold artifact
- `.kamal/` directory exists from Rails generator but Kamal isn't used (we deploy via Fly). Can be removed.
- `config/deploy.yml` is Kamal config — also unused, can be removed
- Keep `storage/` gitignored and empty in repo (dev SQLite files live there)
- If adding features, don't leave TODO comments — either do it or don't

## Testing & Verification

- No tests written yet (prototype). Standard Rails test suite is scaffolded in `test/`.
- **Local verification**: `bin/rails server` then hit `http://localhost:3000`. Requires `ANTHROPIC_API_KEY` in `.env` with funded credits.
- **Production verification**: `curl -u kevo:railsbot2024 https://rails-bot-chat.fly.dev/` should return 200 with HTML.
- **Health check**: `curl https://rails-bot-chat.fly.dev/up` should return 200 (no auth needed).
- **Deploy**: `fly deploy -a rails-bot-chat --local-only` (requires OrbStack/Docker running + `FLY_API_TOKEN` set). Remote builder is unreliable on free tier.
- Nothing is verified until you've actually sent a message and seen Rails respond in character.

## Tool Awareness

- Tailwind CSS changes require manual `bin/rails tailwindcss:build` — the watch mode is broken
- OrbStack must be running for local Docker builds (`fly deploy --local-only`)
- Fly.io free tier remote builder frequently fails with "insufficient resources" — always use `--local-only`
- The `anthropic` gem docs are sparse — read source at `~/.rbenv/versions/3.2.2/lib/ruby/gems/3.2.0/gems/anthropic-1.23.0/` when in doubt

## Guardrails

- Prefer editing existing files over creating new ones
- No proactive documentation files unless asked
- Commit at milestones with clear messages — no AI attribution in commits
- Never `git push` without asking first
- The `.env` file contains real API keys — never commit it, never log it, never expose it in error messages
- The system prompt in `chat.rb` is the core product — changes to it should be deliberate and tested conversationally
