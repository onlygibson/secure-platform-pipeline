# Python 3.13: reqired by Flask 3.1 / requires 2.33, supported until 2029.
FROM python:3.13-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

EXPOSE 8080

# Deliberately runs as root. Kyverno will block this in Phase 5.
CMD ["python", "app.py"]

