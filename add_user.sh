#!/bin/bash
# Add a new user and configure sudo privileges.
# Usage:
#   sudo ./add_sudo_user.sh --user <username> --pass <yes|no>
#   sudo ./add_sudo_user.sh --help

set -e  # Exit on error

# --- Functions ---
show_help() {
  echo "Usage: $0 --user <username> --pass <yes|no>"
  echo
  echo "Options:"
  echo "  --user <username>   Specify the username to create."
  echo "  --pass <yes|no>     'yes' = passwordless sudo, 'no' = password required."
  echo "  --help              Show this help message."
  echo
  echo "Examples:"
  echo "  sudo $0 --user tziavas --pass yes"
  echo "  sudo $0 --user devuser --pass no"
}

# --- Parse arguments ---
USERNAME=""
PASSWORDLESS=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --user)
      USERNAME="$2"
      shift 2
      ;;
    --pass)
      PASSWORDLESS="$2"
      shift 2
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      echo "❌ Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# --- Validate ---
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root or with sudo."
  exit 1
fi

if [[ -z "$USERNAME" || -z "$PASSWORDLESS" ]]; then
  echo "❌ Missing required arguments."
  show_help
  exit 1
fi

# --- Create user if not exists ---
if id "$USERNAME" &>/dev/null; then
  echo "✅ User '$USERNAME' already exists."
else
  echo "🧩 Creating user '$USERNAME'..."
  adduser --disabled-password --gecos "" "$USERNAME"
fi

# --- Add to sudo group ---
echo "➕ Adding '$USERNAME' to sudo group..."
usermod -aG sudo "$USERNAME"

# --- Configure sudo privileges ---
SUDO_FILE="/etc/sudoers.d/$USERNAME"

if [[ "$PASSWORDLESS" =~ ^(yes|y|Y)$ ]]; then
  echo "🔒 Granting passwordless sudo to '$USERNAME'..."
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "$SUDO_FILE"
else
  echo "🔑 Granting normal sudo (password required) to '$USERNAME'..."
  echo "$USERNAME ALL=(ALL) ALL" > "$SUDO_FILE"
fi

chmod 440 "$SUDO_FILE"

echo "✅ User '$USERNAME' configured successfully."
if [[ "$PASSWORDLESS" =~ ^(yes|y|Y)$ ]]; then
  echo "➡️  '$USERNAME' has passwordless sudo access."
else
  echo "➡️  '$USERNAME' must enter their password for sudo."
fi

