"""Sample API for the secure-platform-pipeline project.

This app is the "developer team's service" that the platform secures.
It started with outdated dependencies and an unsafe YAML loader so the
security scanners had real findings. Those are now fixed; see the README.
"""
import os

import requests
import yaml
from flask import Flask, jsonify, request

app = Flask(__name__)

APP_VERSION = os.environ.get("APP_VERSION", "0.6.0")


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

    Uses yaml.safe_load. The original yaml.load call was flagged by CodeQL,
    and CI now checks that an unsafe payload is rejected.
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
