# Intentionally uses an older base image so container scanners report findings.
# Phase 3 hardens this: newer slim base, non-root user, pinned digest.
FROM python:3.8-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

EXPOSE 8080

# Deliberately runs as root. Kyverno will block this in Phase 5.
CMD ["python", "app.py"]
