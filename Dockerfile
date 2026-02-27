FROM python:3.9-alpine AS builder

RUN apk add --no-cache build-base python3-dev patchelf

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt "nuitka[onefile]"

COPY . .

RUN python -m nuitka \
    --standalone \
    --onefile \
    --lto=yes \
    --include-package=flask \
    --include-package=aiosmtpd \
    --include-package=config \
    --include-package=src \
    --include-package=dotenv \
    --include-data-dir=src/frontend/templates=src/frontend/templates \
    --include-data-dir=src/frontend/static=src/frontend/static \
    app.py -o web_app

FROM alpine:latest

RUN apk add --no-cache libgcc libstdc++

WORKDIR /app

COPY --from=builder /app/web_app .

RUN adduser -D appuser \
    && mkdir -p /app/data \
    && chown -R appuser:appuser /app

USER appuser

EXPOSE 5000 2500

ENV SMTP_PORT=2500
ENV INBOX_FILE_NAME=/app/data/inbox.json

CMD ["./web_app"]
