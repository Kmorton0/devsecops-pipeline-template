from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def index():
    return '<html><body><h1>Demo app</h1><a href="/health">health</a></body></html>'


@app.route("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8080)
