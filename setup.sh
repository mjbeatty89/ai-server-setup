#!/bin/bash
# AI Server Setup Script - Automated system configuration
# Run this after fresh Ubuntu installation to restore your environment

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AI Server Setup - System Restoration${NC}"
echo -e "${GREEN}========================================${NC}"

# Function to print status
print_status() {
    echo -e "${YELLOW}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root!"
   exit 1
fi

# Ask about NVIDIA drivers early
print_status "Would you like to install NVIDIA drivers for your GPUs? (y/n)"
read -r INSTALL_NVIDIA

# Update system first
print_status "Updating package lists..."
sudo apt update

# Install essential packages first
print_status "Installing essential packages..."
ESSENTIALS="curl wget git build-essential software-properties-common apt-transport-https ca-certificates gnupg lsb-release"
sudo apt install -y $ESSENTIALS

# Add all repositories first to consolidate apt update
print_status "Configuring repositories..."

# 1Password Repo
(
    print_status "Adding 1Password repository..."
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | sudo tee /etc/apt/sources.list.d/1password.list
) &

# Docker Repo
(
    print_status "Adding Docker repository..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
) &

# NVIDIA Repo (conditional)
if [[ "$INSTALL_NVIDIA" =~ ^[Yy]$ ]]; then
    (
        print_status "Adding NVIDIA repository..."
        sudo add-apt-repository ppa:graphics-drivers/ppa -y -n
    ) &
fi

wait

# Consolidate apt update
print_status "Updating package lists with new repositories..."
sudo apt update

# Install Docker
print_status "Installing Docker..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

# Install APT packages
print_status "Installing APT packages (this will take a while)..."
PACKAGE_FILE="packages/installed-packages.txt"
if [ -f "$PACKAGE_FILE" ]; then
    # Filter out packages that might cause issues or need special handling
    SKIP_PACKAGES="1password|snap|docker|nvidia|cuda|linux-image|linux-headers|linux-modules"
    
    PACKAGES=$(grep -vE "$SKIP_PACKAGES" "$PACKAGE_FILE" | tr '\n' ' ')
    
    # Install in larger batches to reduce apt invocations
    echo "$PACKAGES" | xargs -n 3000 sudo apt install -y --ignore-missing || true
    print_success "APT packages installed"
else
    print_error "Package list not found: $PACKAGE_FILE"
fi

# Install Snap packages
print_status "Installing Snap packages..."
SNAP_FILE="packages/installed-snaps.txt"
if [ -f "$SNAP_FILE" ]; then
    while IFS= read -r snap; do
        if [[ ! -z "$snap" && "$snap" != "snapd" && "$snap" != "bare" && "$snap" != "core"* ]]; then
            print_status "Installing snap: $snap"
            sudo snap install "$snap" 2>/dev/null || sudo snap install "$snap" --classic 2>/dev/null || print_error "Failed to install snap: $snap"
        fi
    done < "$SNAP_FILE"
    print_success "Snap packages installed"
else
    print_error "Snap list not found: $SNAP_FILE"
fi

# Restore configuration files
print_status "Restoring configuration files..."
if [ -d "configs" ]; then
    cp configs/.bashrc ~/
    cp configs/.profile ~/
    print_success "Configuration files restored"
else
    print_error "Config directory not found"
fi

# Install Python pip
print_status "Installing Python pip..."
sudo apt install -y python3-pip python3-venv

# Install NVIDIA drivers (if selected)
if [[ "$INSTALL_NVIDIA" =~ ^[Yy]$ ]]; then
    print_status "Installing NVIDIA drivers..."
    sudo apt install -y nvidia-driver-550 nvidia-utils-550
    print_success "NVIDIA drivers installed (reboot required)"
fi

# Create AI workspace directory
print_status "Creating /ai-workspace directory structure..."
sudo mkdir -p /ai-workspace/{models,datasets,projects,configs}
sudo chown -R $USER:$USER /ai-workspace
print_success "AI workspace created"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Log out and back in for Docker group changes"
echo "2. Reboot for NVIDIA drivers (if installed)"
echo "3. Mount your drives to /ai-workspace and /data"
echo ""
echo "Some packages may have failed to install due to repository changes."
echo "Review the output above and manually install any critical missing packages."
