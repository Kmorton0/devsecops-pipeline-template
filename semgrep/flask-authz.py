from flask import Flask, jsonify, abort, request

app = Flask(__name__)
USERS = {1: {"id": 1, "name": "Alice Example"}}


def current_user_id():
    return int(request.headers.get("X-User-Id", "0"))


@app.route("/vulnerable/<int:user_id>")
def vulnerable(user_id):
    # ruleid: flask-route-id-lookup-without-authorization
    return jsonify(USERS[user_id])


@app.route("/vulnerable-get/<int:user_id>")
def vulnerable_get(user_id):
    # ruleid: flask-route-id-lookup-without-authorization
    return jsonify(USERS.get(user_id))


@app.route("/safe/<int:user_id>")
def safe(user_id):
    if user_id != current_user_id():
        abort(403)
    # ok: flask-route-id-lookup-without-authorization
    return jsonify(USERS[user_id])


@app.route("/health")
def health():
    # ok: flask-route-id-lookup-without-authorization
    return jsonify(USERS[1])
