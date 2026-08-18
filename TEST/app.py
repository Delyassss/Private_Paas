import os
from flask import Flask
import redis

app = Flask(__name__)
r = redis.Redis(host="redis", port=6379)

@app.route("/")
def index():
    count = r.incr("visits")
    return f"Hello from your PaaS! This page has been visited {count} times.\n"

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
