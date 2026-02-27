# Changelog (fork)

Short log of changes in this fork compared to the original [haileyydev/maildrop](https://github.com/haileyydev/maildrop).  
**Scope:** diff vs `master` (all commits on `binary` and related branches). Use this to see what differs from upstream at a glance.

---

## Unreleased / current (vs master)

### Python & runtime

- **Python 3.13:** Bump from Python 3.9. Builder and local dev use 3.13; final Docker image is Alpine with the compiled binary only.
- **Root no longer required:** In `app.py`, the “must be run as root” check was removed so the app can run without `sudo` (e.g. in Docker as non-root or on high ports).

### SMTP & config

- **Default SMTP port:** In `config.py`, default `SMTP_PORT` changed from `25` to `2500` (and a typo `25))` fixed). Container listens on 2500; map to host 25 only if needed.
- **SMTP thread: asyncore → asyncio:**  
  - Removed `asyncore` and the `pyasyncore` dependency (stdlib `asyncore` was removed in Python 3.12).  
  - In `src/backend/smtp_server.py`, the SMTP thread is kept alive with **asyncio**: a dedicated event loop runs `loop.run_forever()`. aiosmtpd still uses its own thread/loop; this only replaces the “block forever” behaviour. On start failure, the function now `return`s instead of entering the loop.

### Docker & CI

- **Dockerfile:** Replaced single-stage `python:3.9-slim` with a **multi-stage build**:
  - **Stage 1 (builder):** `python:3.13-alpine`, build deps, Nuitka; compiles `app.py` to a single **onefile** binary `web_app` (Flask, aiosmtpd, config, src, dotenv, templates, static; LTO enabled).
  - **Stage 2 (runtime):** `alpine:latest`; only the binary + `libgcc`/`libstdc++`. Non-root user `appuser`, `/app/data` for inbox, `ENV SMTP_PORT=2500` and `INBOX_FILE_NAME=/app/data/inbox.json`. `CMD ["./web_app"]`.
- **.dockerignore:** Added (git, Docker files, Python cache, venv, tests, scripts, docs, etc.) to keep build context small and reproducible.
- **GitHub Actions:** New workflow `.github/workflows/build-publish.yml` — **Build and publish (latest)** on `workflow_dispatch`. Builds multi-arch Docker images (amd64, arm64), pushes to GHCR (`ghcr.io/<repo>`), with optional manifest for unified tags. Uses Buildx and GHA cache.

### Backend robustness

- **Email parser (`src/backend/email_parser.py`):**
  - `To`/`From` wrapped in `str()` when reading from the message (safe if not string).
  - Body decoding: handle `get_payload(decode=True)` returning `None` or non-bytes; normalize to bytes then decode with `errors="replace"`; catch `LookupError`/`TypeError` for charset and fall back to `utf-8`.
- **Flask app (`src/backend/flask_app.py`):** Template and static paths set to **absolute paths** derived from `__file__` (required for Nuitka onefile, which unpacks to e.g. `/tmp`).

### Frontend & email display

- **Email body iframe (`src/frontend/static/scripts/main.js`):**
  - New **`wrapEmailBodyForReadability()`**: wraps HTML in a minimal document with inline styles so body is readable and **respects `prefers-color-scheme`** (light/dark). Forces links to open in a new tab (`target="_blank"` and `rel="noopener noreferrer"`).
  - Iframe now has `sandbox="sandbox allow-popups"` for security while allowing link popups.
- **Styles (`src/frontend/static/styles/style.css`):**
  - New CSS variable `--email-body-bg` (light default).
  - `@media (prefers-color-scheme: dark)` for `:root` sets `--email-body-bg` to match dark theme.
  - `.email-body-iframe` uses `background-color: var(--email-body-bg)` so the iframe background follows system light/dark.

### Dependencies

- **requirements.txt:** Removed `pyasyncore` (replaced by asyncio in this fork).

---

## Summary table (vs original/master)

| Area              | Original (master)              | This fork                               |
| ----------------- | ------------------------------ | --------------------------------------- |
| Python             | 3.9                            | 3.13                                     |
| Run as root        | Required                       | Not required                             |
| SMTP default port  | 25                             | 2500                                     |
| SMTP thread        | `asyncore.loop()` + pyasyncore | asyncio `loop.run_forever()`             |
| Docker             | Single-stage, run `python app.py` | Multi-stage, Nuitka onefile binary      |
| Docker base        | python:3.9-slim                | python:3.13-alpine → alpine + binary    |
| CI                 | —                              | GHA: multi-arch build & publish (GHCR)   |
| Email body display | —                              | prefers-color-scheme, safe decode, sandbox iframe |
| Paths in Flask     | Relative                       | Absolute (Nuitka onefile)                |
