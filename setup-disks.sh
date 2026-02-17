#!/bin/bash
# Disk Setup Script - Configure storage for AI Server
# WARNING: This will DESTROY DATA on specified disks!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
AI_WORKSPACE_DIR=${AI_WORKSPACE_DIR:-/ai-workspace}
DATA_DIR=${DATA_DIR:-/data}
FSTAB_FILE=${FSTAB_FILE:-/etc/fstab}

echo -e "${RED}========================================${NC}"
echo -e "${RED}WARNING: DISK CONFIGURATION SCRIPT${NC}"
echo -e "${RED}This will DESTROY ALL DATA on:${NC}"
echo -e "${RED}- /dev/nvme0n1 (500GB drive)${NC}"
echo -e "${RED}- Unused partitions on /dev/nvme1n1 (4TB)${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo "Current disk layout:"
lsblk
echo ""
echo -e "${YELLOW}Are you SURE you want to continue? Type 'yes' to proceed:${NC}"
read -r confirmation

if [[ "$confirmation" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# Setup 500GB drive as AI workspace
echo -e "${GREEN}[1/4] Setting up 500GB drive (/dev/nvme0n1)...${NC}"

# Wipe the drive
sudo wipefs -a /dev/nvme0n1
sudo sgdisk -Z /dev/nvme0n1

# Create new GPT table and single partition
sudo sgdisk -n 1:0:0 -t 1:8300 -c 1:"AI-Workspace" /dev/nvme0n1

# Format as ext4
sudo mkfs.ext4 -L ai-workspace /dev/nvme0n1p1

# Create mount point
sudo mkdir -p "$AI_WORKSPACE_DIR"

# Mount temporarily
sudo mount /dev/nvme0n1p1 "$AI_WORKSPACE_DIR"

# Set permissions
sudo chown -R $USER:$USER "$AI_WORKSPACE_DIR"

echo -e "${GREEN}[2/4] Setting up 4TB drive additional storage...${NC}"

# First, identify free space on nvme1n1
# We'll create a new partition in the unallocated space
# This assumes partitions p2, p3, p4 can be deleted (old data partitions)

echo "Current partitions on 4TB drive:"
sudo fdisk -l /dev/nvme1n1

echo -e "${YELLOW}Will delete partitions p2, p3, p4 to reclaim space. Continue? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    # Delete the unused partitions (keeping p1=EFI, p5=current system, p6=root)
    sudo sgdisk -d 2 /dev/nvme1n1 2>/dev/null || true
    sudo sgdisk -d 3 /dev/nvme1n1 2>/dev/null || true
    sudo sgdisk -d 4 /dev/nvme1n1 2>/dev/null || true
    
    # Create new partition for data
    sudo sgdisk -n 7:0:0 -t 7:8300 -c 7:"Data" /dev/nvme1n1
    
    # Format new partition
    sudo mkfs.ext4 -L data /dev/nvme1n1p7
    
    # Create mount point
    sudo mkdir -p "$DATA_DIR"
    
    # Mount temporarily
    sudo mount /dev/nvme1n1p7 "$DATA_DIR"
    
    # Set permissions
    sudo chown -R $USER:$USER "$DATA_DIR"
fi

echo -e "${GREEN}[3/4] Configuring $FSTAB_FILE for automatic mounting...${NC}"

# Backup current fstab
if [[ "$FSTAB_FILE" == "/etc/fstab" ]]; then
    sudo cp "$FSTAB_FILE" "$FSTAB_FILE.backup.$(date +%Y%m%d)"
else
    # For testing/custom path
    cp "$FSTAB_FILE" "$FSTAB_FILE.backup.$(date +%Y%m%d)" 2>/dev/null || sudo cp "$FSTAB_FILE" "$FSTAB_FILE.backup.$(date +%Y%m%d)"
fi

# Get UUIDs
UUID_AI=$(sudo blkid -s UUID -o value /dev/nvme0n1p1)
UUID_DATA=$(sudo blkid -s UUID -o value /dev/nvme1n1p7)

# Add entries to fstab
# Check if header already exists
if ! grep -q "AI Server Storage Configuration" "$FSTAB_FILE"; then
    echo "" | sudo tee -a "$FSTAB_FILE"
    echo "# AI Server Storage Configuration" | sudo tee -a "$FSTAB_FILE"
fi

# Check for AI Workspace entry (by UUID or mount point)
if ! grep -q "UUID=$UUID_AI" "$FSTAB_FILE" && ! grep -q "[[:space:]]$AI_WORKSPACE_DIR[[:space:]]" "$FSTAB_FILE"; then
    echo "UUID=$UUID_AI $AI_WORKSPACE_DIR ext4 defaults,noatime,errors=remount-ro 0 2" | sudo tee -a "$FSTAB_FILE"
else
    echo "Entry for AI Workspace (UUID=$UUID_AI or path $AI_WORKSPACE_DIR) already exists in $FSTAB_FILE"
fi

if [[ ! -z "$UUID_DATA" ]]; then
    # Check for Data entry (by UUID or mount point)
    if ! grep -q "UUID=$UUID_DATA" "$FSTAB_FILE" && ! grep -q "[[:space:]]$DATA_DIR[[:space:]]" "$FSTAB_FILE"; then
        echo "UUID=$UUID_DATA $DATA_DIR ext4 defaults,noatime,errors=remount-ro 0 2" | sudo tee -a "$FSTAB_FILE"
    else
        echo "Entry for Data (UUID=$UUID_DATA or path $DATA_DIR) already exists in $FSTAB_FILE"
    fi
fi

echo -e "${GREEN}[4/4] Setting up directory structure...${NC}"

# Create directory structure for AI workspace
mkdir -p "$AI_WORKSPACE_DIR"/{models,datasets,projects,configs,checkpoints}
mkdir -p "$AI_WORKSPACE_DIR"/models/{llm,vision,audio,custom}
mkdir -p "$AI_WORKSPACE_DIR"/datasets/{raw,processed,cache}
mkdir -p "$AI_WORKSPACE_DIR"/projects/{experiments,production}

# Create directory structure for data
if [[ -d "$DATA_DIR" ]]; then
    mkdir -p "$DATA_DIR"/{backup,downloads,docker,logs}
fi

# Create README in each location
cat > "$AI_WORKSPACE_DIR/README.md" << 'EOF'
# AI Workspace

This drive is dedicated to AI/ML workloads.

## Directory Structure
- `/models` - Pre-trained and fine-tuned models
  - `/llm` - Large Language Models
  - `/vision` - Computer Vision models
  - `/audio` - Audio/Speech models
  - `/custom` - Your custom trained models
- `/datasets` - Training and evaluation data
  - `/raw` - Original datasets
  - `/processed` - Preprocessed data
  - `/cache` - Temporary cache files
- `/projects` - Active AI projects
  - `/experiments` - Development and testing
  - `/production` - Production-ready code
- `/checkpoints` - Training checkpoints
- `/configs` - Configuration files

## Performance Notes
- This is an NVMe SSD optimized for fast I/O
- Mount options include 'noatime' to reduce write overhead
- Consider using symlinks from home directory for frequently accessed files
EOF

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Disk Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Storage configuration:"
echo "- $AI_WORKSPACE_DIR (500GB) - AI models and datasets"
if [[ -d "$DATA_DIR" ]]; then
    echo "- $DATA_DIR (3.5TB) - General data storage"
fi
echo ""
echo "Run 'df -h' to verify mounts"
echo "Reboot recommended to ensure proper mounting"
