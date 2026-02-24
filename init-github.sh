#!/bin/bash
# Initialize GitHub repository for AI Server Setup

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}GitHub Repository Setup${NC}"
echo "========================"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Git not found. Installing...${NC}"
    sudo apt update
    sudo apt install -y git
fi

# Configure git (update with your details)
echo -e "${YELLOW}Setting up git configuration...${NC}"
read -p "Enter your GitHub username: " github_username
read -p "Enter your email for git commits: " github_email

git config --global user.name "$github_username"
git config --global user.email "$github_email"

# Initialize repository
echo -e "${GREEN}Initializing repository...${NC}"
git init

# Create .gitignore
cat > .gitignore << 'EOF'
# Temporary files
*.tmp
*.swp
*.swo
*~

# Backup files
*.backup
*.bak

# Private configurations (if any)
private/
.env

# OS files
.DS_Store
Thumbs.db
EOF

# Add all files
git add -A

# Initial commit
git commit -m "Initial commit: AI Server setup configuration

- Package lists for APT and Snap (1984 + 88 packages)
- Shell configurations (.bashrc, .profile)
- Automated setup scripts for system restoration
- Disk configuration scripts for optimal AI workload storage
- Complete documentation and README"

echo -e "${GREEN}Repository initialized!${NC}"
echo ""
echo "Next steps:"
echo "1. Create a new repository on GitHub named 'ai-server-setup'"
echo "2. Run the following commands:"
echo ""
echo "   git remote add origin https://github.com/$github_username/ai-server-setup.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "Or if you prefer SSH:"
echo "   git remote add origin git@github.com:$github_username/ai-server-setup.git"
echo "   git branch -M main"
echo "   git push -u origin main"