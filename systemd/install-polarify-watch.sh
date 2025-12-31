#!/bin/bash
# Installation script for polarify-watch systemd service

SERVICE_NAME="polarify-watch.service"
SERVICE_FILE="$(dirname "$0")/$SERVICE_NAME"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "Installing Polarify Dark Mode Watcher service..."

# Create systemd user directory if it doesn't exist
mkdir -p "$SYSTEMD_USER_DIR"

# Copy service file
cp "$SERVICE_FILE" "$SYSTEMD_USER_DIR/"
echo "✓ Copied service file to $SYSTEMD_USER_DIR"

# Reload systemd daemon
systemctl --user daemon-reload
echo "✓ Reloaded systemd daemon"

# Enable the service
systemctl --user enable "$SERVICE_NAME"
echo "✓ Enabled $SERVICE_NAME"

# Start the service
systemctl --user start "$SERVICE_NAME"
echo "✓ Started $SERVICE_NAME"

# Show status
echo ""
echo "Service status:"
systemctl --user status "$SERVICE_NAME" --no-pager

echo ""
echo "Installation complete!"
echo ""
echo "Useful commands:"
echo "  • Check status:  systemctl --user status $SERVICE_NAME"
echo "  • View logs:     journalctl --user -u $SERVICE_NAME -f"
echo "  • Stop service:  systemctl --user stop $SERVICE_NAME"
echo "  • Restart:       systemctl --user restart $SERVICE_NAME"
echo "  • Disable:       systemctl --user disable $SERVICE_NAME"
