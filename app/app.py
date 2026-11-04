"""Sample API for the secure-platform-pipeline project.

This app is the "developer team's service" that the platform secures.
Its dependencies are intentionally outdated so security scanners have
real findings to report and fix.
"""
import os

import requests
import yaml
from flask import Flask, jsonify, request

app = Flask(__name__)

APP_VERSION = os.environ.get("APP_VERSION", "0.1.0")


@app.route("/health")
def health():
    """Liveness and readiness probe for Kubernetes."""
    return jsonify(status="ok", version=APP_VERSION)


@app.route("/hello")
def hello():
    """Greets the caller. Name is taken from the query string."""
    name = request.args.get("name", "world")
    return jsonify(message="Hello, {}!".format(name))


@app.route("/config", methods=["POST"])
def load_config():
    """Parses a YAML body.

    Deliberate weakness: yaml.load without a safe loader. CodeQL should
    flag this in Phase 2. The fix is yaml.safe_load.
    """
    data = yaml.safe_load(request.get_data())
    return jsonify(parsed=data)


@app.route("/status/<path:service>")
def upstream_status(service):
    """Checks an allow-listed upstream service."""
    allowed = {"github": "https://www.githubstatus.com/api/v2/status.json"}
    url = allowed.get(service)
    if url is None:
        return jsonify(error="unknown service"), 404
    resp = requests.get(url, timeout=5)
    return jsonify(service=service, upstream_code=resp.status_code)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
