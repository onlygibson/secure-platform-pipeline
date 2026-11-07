
# Python 3.13: required by Flask 3.1 / requests 2.33, supported until 2029.
FROM python:3.13-slim

WORKDIR /app

RUN apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

COPY app/requirements.txt .
# Install dependencies, then remove pip: the app never uses it at runtime,
# and its bundled libraries carry known vulnerabilities (found by Trivy).
RUN pip install --no-cache-dir -r requirements.txt \
 && pip uninstall -y pip

COPY app/ .

EXPOSE 8080

RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin appuser
USER 10001

CMD ["python", "app.py"]
