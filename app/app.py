from flask import Flask, abort, jsonify, request

app = Flask(__name__)

# Fake demo data. No real people or credentials.
USERS = {
    1: {"id": 1, "name": "Alice Example", "email": "alice@example.test"},
    2: {"id": 2, "name": "Bob Example", "email": "bob@example.test"},
}


def current_user_id():
    """Demo authentication: trust a header. A real app would use a session or token."""
    try:
        return int(request.headers.get("X-User-Id", "0"))
    except ValueError:
        return 0


@app.after_request
def set_security_headers(response):
    # Content Security Policy: this app serves no scripts, styles, or images,
    # so everything is denied by default.
    response.headers["Content-Security-Policy"] = (
        "default-src 'none'; frame-ancestors 'none'; form-action 'none'; base-uri 'none'"
    )
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Permissions-Policy"] = "geolocation=(), camera=(), microphone=()"
    response.headers["Cross-Origin-Opener-Policy"] = "same-origin"
    response.headers["Cross-Origin-Embedder-Policy"] = "require-corp"
    response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
    response.headers["Cache-Control"] = "no-store"
    return response


@app.route("/")
def index():
    return '<html><body><h1>Demo app</h1><a href="/health">health</a></body></html>'


@app.route("/health")
def health():
    return jsonify(status="ok")


@app.route("/users/<int:user_id>")
def get_user(user_id):
    # DELIBERATE FLAW for a code review exercise: no check that the caller
    # is allowed to read this user's record (broken access control).
    return jsonify(USERS[user_id])


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8080)
