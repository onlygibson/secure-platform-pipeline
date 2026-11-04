# Faster builds: single pip step, configurable port for local dev
FROM python:3.13-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

ENV PORT=5000
EXPOSE 8080

CMD ["python", "app.py"]