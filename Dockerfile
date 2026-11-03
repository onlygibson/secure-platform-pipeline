
# Python 3.13: required by Flask 3.1 / requests 2.33, supported until 2029.
FROM python:3.13-slim

WORKDIR /app

COPY app/requirements.txt .
# Install dependencies, then remove pip: the app never uses it at runtime,
# and its bundled libraries carry known vulnerabilities (found by Trivy).
RUN pip install --no-cache-dir -r requirements.txt \
 && pip uninstall -y pip

COPY app/ .

EXPOSE 8080

# Deliberately runs as root. Kyverno will block this in Phase 5.
CMD ["python", "app.py"]
