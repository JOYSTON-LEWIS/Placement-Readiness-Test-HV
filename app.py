import os
from flask import Flask, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

# Load environment variables from .env if present
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route("/api/hello", methods=["GET"])
def hello():
    return jsonify({"message": "hello world"}), 200

@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({
        "status": "OK",
        "message": "Python Flask APP is running"
    }), 200

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))  # Default to 5000
    app.run(host="0.0.0.0", port=port)
