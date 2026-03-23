"""
main.py — Flask app. Loads config and defines routes.
"""

import tomllib
from pathlib import Path
from flask import Flask, render_template, jsonify

from dashboard.files import scan_files

app = Flask(__name__, template_folder="../templates")


def load_config():
    config_path = Path(__file__).parent.parent / "config.toml"
    with open(config_path, "rb") as f:
        return tomllib.load(f)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/files")
def api_files():
    try:
        config = load_config()
        files = scan_files(
            downloads_path=config["files"]["downloads_path"],
            min_size_mb=config["files"]["min_size_mb"],
        )
        return jsonify({
            "ok": True,
            "files": [
                {
                    "name": f.name,
                    "path": f.path,
                    "size_bytes": f.size_bytes,
                    "modified": f.modified.strftime("%Y-%m-%d %H:%M"),
                }
                for f in files
            ],
        })
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500