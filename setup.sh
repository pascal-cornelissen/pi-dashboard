#!/bin/bash
# setup.sh — install or update pi-dashboard
# Safe to run multiple times.

set -e  # Stop on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="pi-dashboard"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo "==> Pi Dashboard setup"

# ── 1. Check Python version ──────────────────────────────────────────
echo "--- Checking Python version..."
PYTHON=$(command -v python3 || true)
if [ -z "$PYTHON" ]; then
  echo "ERROR: python3 not found. Please install it first."
  exit 1
fi

PYTHON_VERSION=$($PYTHON -c "import sys; print(sys.version_info.minor)")
if [ "$PYTHON_VERSION" -lt 8 ]; then
  echo "ERROR: Python 3.8 or newer required."
  exit 1
fi
echo "    OK: $($PYTHON --version)"

# ── 2. Git pull if this is already a repo ───────────────────────────
if [ -d "$SCRIPT_DIR/.git" ]; then
  echo "--- Pulling latest code..."
  git -C "$SCRIPT_DIR" pull
else
  echo "--- No git repo found, skipping pull."
fi

# ── 3. Create virtualenv if it doesn't exist ────────────────────────
VENV="$SCRIPT_DIR/venv"
if [ ! -d "$VENV" ]; then
  echo "--- Creating virtual environment..."
  $PYTHON -m venv "$VENV"
else
  echo "--- Virtual environment already exists, skipping."
fi

# ── 4. Install/update dependencies ──────────────────────────────────
echo "--- Installing dependencies..."
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet -r "$SCRIPT_DIR/requirements.txt"
echo "    OK"

# ── 5. Create config if none exists ─────────────────────────────────
CONFIG="$SCRIPT_DIR/config.toml"
if [ ! -f "$CONFIG" ]; then
  echo "--- Creating config.toml from example..."
  cp "$SCRIPT_DIR/config.toml.example" "$CONFIG"
  echo "    IMPORTANT: Edit $CONFIG before starting the service."
else
  echo "--- config.toml already exists, skipping."
fi

# ── 6. Install systemd service ───────────────────────────────────────
echo "--- Installing systemd service..."
cat > /tmp/${SERVICE_NAME}.service << EOF
[Unit]
Description=Pi Dashboard
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$SCRIPT_DIR
ExecStart=$VENV/bin/python $SCRIPT_DIR/run.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/${SERVICE_NAME}.service "$SERVICE_FILE"
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"
echo "    OK: service enabled and started"

echo ""
echo "==> Done. Dashboard running at http://$(hostname -I | awk '{print $1}'):5000"