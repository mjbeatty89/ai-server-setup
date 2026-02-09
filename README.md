# AI Server Setup - Ubuntu System Configuration

This repository contains your complete system configuration backup for quickly restoring your Ubuntu AI server after a fresh installation.

## 📦 Contents

- `setup.sh` - Main restoration script for packages and configurations
- `setup-disks.sh` - Disk partitioning and mount configuration script
- `packages/` - Lists of installed packages
  - `installed-packages.txt` - All APT packages (1984 packages)
  - `installed-snaps.txt` - All Snap packages (88 packages)
- `configs/` - System configuration files
  - `.bashrc` - Bash configuration
  - `.profile` - Profile settings

## 🚀 Quick Start After Fresh Ubuntu Install

### Step 1: Clone this repository
```bash
git clone https://github.com/YOUR_USERNAME/ai-server-setup.git
cd ai-server-setup
```

### Step 2: Run the main setup script
```bash
chmod +x setup.sh
./setup.sh
```

This will:
- Install all your APT packages
- Install all your Snap packages (including VS Code, Docker, etc.)
- Restore your shell configurations
- Set up Docker
- Optionally install NVIDIA drivers

### Step 3: Configure storage drives
```bash
chmod +x setup-disks.sh
./setup-disks.sh
```

⚠️ **WARNING**: This script will WIPE the 500GB drive and reconfigure partitions on the 4TB drive!

## 📁 Recommended Partition Layout

### During Ubuntu Installation
Choose "Something else" for partitioning and create:

**On 4TB NVMe (nvme1n1):**
- 512MB - EFI System Partition (if UEFI)
- 100GB - ext4 mounted at `/`
- 32GB - swap
- Remaining (~3.5TB) - ext4 mounted at `/home`

**Leave 500GB NVMe (nvme0n1) untouched** - will be configured post-install

### Post-Installation Storage
After running `setup-disks.sh`:
- `/ai-workspace` (500GB) - Dedicated AI/ML workspace
- `/data` (3.5TB from 4TB drive) - General data storage
- Both with automatic mounting via `/etc/fstab`

## 🔧 Manual Steps After Setup

1. **GitHub Configuration**
   ```bash
   git config --global user.name "Matthew Beatty"
   git config --global user.email "your-email@example.com"
   ```

2. **SSH Keys** (if needed)
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   cat ~/.ssh/id_ed25519.pub  # Add to GitHub
   ```

3. **Docker** - Log out and back in for group changes

4. **NVIDIA** - Reboot after driver installation

## 📝 Notable Installed Software

### Development Tools
- VS Code, Sublime Text, Vim, Emacs, Helix
- Docker, Kubernetes tools (kubectl, kubetail)
- Git, GitHub CLI
- Multiple language runtimes (Go, .NET, Python)

### AI/ML Related
- Docker (for containerized training)
- NVIDIA drivers (optional during setup)
- Python with pip

### Productivity
- 1Password, Bitwarden
- Browsers: Firefox, Chrome, Brave, Opera, Vivaldi
- Communication: Slack, Discord, Signal, Telegram
- Waveterm, Alacritty, Konsole, Ghostty (terminals)

### System Tools
- LXD, Multipass
- Home Assistant tools
- Arduino, ESP tools
- Network tools

## 🔄 Keeping This Updated

To update your package lists:
```bash
# Update APT package list
dpkg --get-selections | grep -v deinstall | awk '{print $1}' > packages/installed-packages.txt

# Update Snap package list
snap list --color=never | tail -n +2 | awk '{print $1}' > packages/installed-snaps.txt

# Commit and push changes
git add -A
git commit -m "Update package lists"
git push
```

## ⚠️ Security Notes

- The repository doesn't contain sensitive data (passwords, keys, etc.)
- Review configs before pushing to public repo
- Consider making the repo private if it contains personal preferences

## 🤝 Contributing

This is a personal configuration, but feel free to fork and adapt for your own use!

---
Created for Matthew Beatty's AI Server with dual GPUs
Location: Ann Arbor, MI