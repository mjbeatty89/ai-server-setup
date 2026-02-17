#!/bin/bash
# Disk Setup Script - Configure storage for AI Server
# WARNING: This will DESTROY DATA on specified disks!

set -e

# Default Disk Configurations
AI_DISK="${AI_DISK:-/dev/nvme0n1}"
DATA_DISK="${DATA_DISK:-/dev/nvme1n1}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper Functions
get_disk_model() {
    local disk=$1
    lsblk -d -n -o MODEL "$disk" 2>/dev/null || echo "Unknown"
}

get_disk_size_gb() {
    local disk=$1
    local size_bytes
    size_bytes=$(lsblk -b -n -o SIZE -d "$disk" 2>/dev/null | head -n1)
    if [[ -z "$size_bytes" ]]; then
        echo "0"
    else
        echo $((size_bytes / 1024 / 1024 / 1024))
    fi
}

get_partition_path() {
    local disk=$1
    local part_num=$2
    if [[ "$disk" =~ [0-9]$ ]]; then
        echo "${disk}p${part_num}"
    else
        echo "${disk}${part_num}"
    fi
}

check_disk() {
    local disk=$1
    local expected_gb=$2
    local tolerance_percent=10

    if [[ ! -b "$disk" ]]; then
        return 1
    fi

    local size_gb
    size_gb=$(get_disk_size_gb "$disk")

    local min_size=$((expected_gb - (expected_gb * tolerance_percent / 100)))
    local max_size=$((expected_gb + (expected_gb * tolerance_percent / 100)))

    if [[ "$size_gb" -lt "$min_size" ]] || [[ "$size_gb" -gt "$max_size" ]]; then
        return 2 # Size mismatch
    fi

    return 0
}

echo -e "${RED}========================================${NC}"
echo -e "${RED}WARNING: DISK CONFIGURATION SCRIPT${NC}"
echo -e "${RED}This will DESTROY ALL DATA on:${NC}"
echo -e "${RED}- $AI_DISK (Target: ~500GB AI Workspace)${NC}"
echo -e "${RED}- $DATA_DISK (Target: ~4TB Data Storage)${NC}"
echo -e "${RED}========================================${NC}"
echo ""

# Pre-flight Checks
echo "Checking disks..."
AI_DISK_OK=true
DATA_DISK_OK=true

# Check AI Disk
if check_disk "$AI_DISK" 500; then
    echo -e "${GREEN}✓ AI Disk found: $AI_DISK ($(get_disk_model "$AI_DISK") - $(get_disk_size_gb "$AI_DISK")GB)${NC}"
else
    AI_DISK_OK=false
    if [[ -b "$AI_DISK" ]]; then
        echo -e "${RED}⚠ WARNING: AI Disk $AI_DISK size ($(get_disk_size_gb "$AI_DISK")GB) does not match expected ~500GB!${NC}"
    else
        echo -e "${RED}⚠ WARNING: AI Disk $AI_DISK not found!${NC}"
    fi
fi

# Check Data Disk
if check_disk "$DATA_DISK" 3700; then # 4TB is approx 3725 GiB, generic 4TB might vary. Using 3700 as base.
    echo -e "${GREEN}✓ Data Disk found: $DATA_DISK ($(get_disk_model "$DATA_DISK") - $(get_disk_size_gb "$DATA_DISK")GB)${NC}"
else
    # Allow a wider range for 4TB or if it's strictly > 3TB
    DATA_SIZE=$(get_disk_size_gb "$DATA_DISK")
    if [[ "$DATA_SIZE" -gt 3000 ]]; then
         echo -e "${GREEN}✓ Data Disk found: $DATA_DISK ($(get_disk_model "$DATA_DISK") - $(get_disk_size_gb "$DATA_DISK")GB)${NC}"
    else
        DATA_DISK_OK=false
        if [[ -b "$DATA_DISK" ]]; then
            echo -e "${RED}⚠ WARNING: Data Disk $DATA_DISK size ($(get_disk_size_gb "$DATA_DISK")GB) does not match expected ~4TB!${NC}"
        else
             echo -e "${RED}⚠ WARNING: Data Disk $DATA_DISK not found!${NC}"
        fi
    fi
fi

echo ""
echo "Current disk layout:"
lsblk
echo ""

if [[ "$AI_DISK_OK" == "false" ]] || [[ "$DATA_DISK_OK" == "false" ]]; then
    echo -e "${RED}CRITICAL WARNING: Disk checks failed! The detected disks do not match expectations.${NC}"
    echo -e "${YELLOW}Please verify your hardware or update the script variables (AI_DISK, DATA_DISK).${NC}"
    echo -e "${YELLOW}To force execution, type 'FORCE' (all caps):${NC}"
    read -r confirmation
    if [[ "$confirmation" != "FORCE" ]]; then
        echo "Aborted."
        exit 1
    fi
else
    echo -e "${YELLOW}Are you SURE you want to continue? Type 'yes' to proceed:${NC}"
    read -r confirmation
    if [[ "$confirmation" != "yes" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Setup AI Workspace Drive
echo -e "${GREEN}[1/4] Setting up AI workspace drive ($AI_DISK)...${NC}"

# Define partition paths
AI_PART=$(get_partition_path "$AI_DISK" 1)
DATA_PART=$(get_partition_path "$DATA_DISK" 7)

# Wipe the drive
sudo wipefs -a "$AI_DISK"
sudo sgdisk -Z "$AI_DISK"

# Create new GPT table and single partition
sudo sgdisk -n 1:0:0 -t 1:8300 -c 1:"AI-Workspace" "$AI_DISK"

# Format as ext4
sudo mkfs.ext4 -L ai-workspace "$AI_PART"

# Create mount point
sudo mkdir -p /ai-workspace

# Mount temporarily
sudo mount "$AI_PART" /ai-workspace

# Set permissions
sudo chown -R $USER:$USER /ai-workspace

echo -e "${GREEN}[2/4] Setting up additional data storage ($DATA_DISK)...${NC}"

# First, identify free space on DATA_DISK
# We'll create a new partition in the unallocated space
# This assumes partitions p2, p3, p4 can be deleted (old data partitions)

echo "Current partitions on Data drive:"
sudo fdisk -l "$DATA_DISK"

echo -e "${YELLOW}Will delete partitions 2, 3, 4 on $DATA_DISK to reclaim space. Continue? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    # Delete the unused partitions (keeping p1=EFI, p5=current system, p6=root)
    sudo sgdisk -d 2 "$DATA_DISK" 2>/dev/null || true
    sudo sgdisk -d 3 "$DATA_DISK" 2>/dev/null || true
    sudo sgdisk -d 4 "$DATA_DISK" 2>/dev/null || true
    
    # Create new partition for data
    sudo sgdisk -n 7:0:0 -t 7:8300 -c 7:"Data" "$DATA_DISK"
    
    # Format new partition
    sudo mkfs.ext4 -L data "$DATA_PART"
    
    # Create mount point
    sudo mkdir -p /data
    
    # Mount temporarily
    sudo mount "$DATA_PART" /data
    
    # Set permissions
    sudo chown -R $USER:$USER /data
fi

echo -e "${GREEN}[3/4] Configuring /etc/fstab for automatic mounting...${NC}"

# Backup current fstab
sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d)

# Get UUIDs
UUID_AI=$(sudo blkid -s UUID -o value "$AI_PART")
UUID_DATA=$(sudo blkid -s UUID -o value "$DATA_PART")

# Add entries to fstab
echo "" | sudo tee -a /etc/fstab
echo "# AI Server Storage Configuration" | sudo tee -a /etc/fstab
echo "UUID=$UUID_AI /ai-workspace ext4 defaults,noatime,errors=remount-ro 0 2" | sudo tee -a /etc/fstab

if [[ ! -z "$UUID_DATA" ]]; then
    echo "UUID=$UUID_DATA /data ext4 defaults,noatime,errors=remount-ro 0 2" | sudo tee -a /etc/fstab
fi

echo -e "${GREEN}[4/4] Setting up directory structure...${NC}"

# Create directory structure for AI workspace
mkdir -p /ai-workspace/{models,datasets,projects,configs,checkpoints}
mkdir -p /ai-workspace/models/{llm,vision,audio,custom}
mkdir -p /ai-workspace/datasets/{raw,processed,cache}
mkdir -p /ai-workspace/projects/{experiments,production}

# Create directory structure for data
if [[ -d "/data" ]]; then
    mkdir -p /data/{backup,downloads,docker,logs}
fi

# Create README in each location
cat > /ai-workspace/README.md << 'EOF'
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
echo "- /ai-workspace (500GB) - AI models and datasets"
if [[ -d "/data" ]]; then
    echo "- /data (3.5TB) - General data storage"
fi
echo ""
echo "Run 'df -h' to verify mounts"
echo "Reboot recommended to ensure proper mounting"