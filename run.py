from dashboard.main import app, load_config

if __name__ == "__main__":
    config = load_config()
    app.run(
        host=config["server"]["host"],
        port=config["server"]["port"],
        debug=True,
    )