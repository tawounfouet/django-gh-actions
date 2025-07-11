#!/bin/bash

# 🔍 Setup Verification Script for DigitalOcean Deployment
# This script verifies the current setup status and provides guidance

set -e

echo "🔍 Django DevOps Setup Verification"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Server details
SERVER_IP="157.245.79.172"
APP_USER="django"
APP_DIR="/var/www/django-devops-app"

echo "📋 Checking setup status..."
echo ""

# Function to check status
check_status() {
    local item="$1"
    local status="$2"
    if [ "$status" = "true" ]; then
        echo -e "✅ ${GREEN}$item${NC}"
    else
        echo -e "❌ ${RED}$item${NC}"
    fi
}

# Check if we can connect to server
echo "🌐 Testing server connectivity..."
if ping -c 1 $SERVER_IP > /dev/null 2>&1; then
    check_status "Server ($SERVER_IP) is reachable" "true"
    SERVER_REACHABLE=true
else
    check_status "Server ($SERVER_IP) is reachable" "false"
    SERVER_REACHABLE=false
fi

echo ""
echo "📁 Local files status:"

# Check local files
files_to_check=(
    ".github/workflows/deploy-cloud.yml:GitHub Actions workflow for cloud deployment"
    "scripts/setup-digitalocean.sh:DigitalOcean server setup script"
    "docs/plan-action-devops_v2.md:DevOps plan v2 with DigitalOcean configuration"
    "docs/quick-start-digitalocean.md:Quick start guide for DigitalOcean"
    "scripts/deployment_helper.sh:Deployment helper utilities"
)

for file_desc in "${files_to_check[@]}"; do
    file="${file_desc%%:*}"
    desc="${file_desc#*:}"
    if [ -f "$file" ]; then
        check_status "$desc" "true"
    else
        check_status "$desc" "false"
    fi
done

echo ""
echo "🔧 Required GitHub Secrets:"
secrets=(
    "SSH_PRIVATE_KEY:Private key for server access"
    "SSH_HOST:Server IP address (157.245.79.172)"
    "SSH_USER:Server username (django)"
)

for secret_desc in "${secrets[@]}"; do
    secret="${secret_desc%%:*}"
    desc="${secret_desc#*:}"
    echo -e "📝 ${YELLOW}$secret${NC}: $desc"
done

echo ""
echo "📋 Next Steps Checklist:"
echo ""

# Create checklist
checklist=(
    "Run setup script on DigitalOcean server"
    "Configure GitHub repository secrets"
    "Test SSH connection to server"
    "Trigger deployment workflow"
    "Verify application is running"
)

for i in "${!checklist[@]}"; do
    echo "[ ] $((i+1)). ${checklist[i]}"
done

echo ""
echo "🚀 Quick Commands:"
echo ""
echo "1. Run server setup:"
echo -e "   ${BLUE}scp scripts/setup-digitalocean.sh $APP_USER@$SERVER_IP:~/setup.sh${NC}"
echo -e "   ${BLUE}ssh $APP_USER@$SERVER_IP 'chmod +x ~/setup.sh && sudo ~/setup.sh'${NC}"
echo ""
echo "2. Test SSH connection:"
echo -e "   ${BLUE}ssh $APP_USER@$SERVER_IP 'echo \"Connection successful!\"'${NC}"
echo ""
echo "3. Check application status:"
echo -e "   ${BLUE}curl -I http://$SERVER_IP${NC}"
echo ""

if [ "$SERVER_REACHABLE" = "true" ]; then
    echo "✨ Server is reachable! You can proceed with the setup."
else
    echo "⚠️  Server is not reachable. Check your DigitalOcean droplet status."
fi

echo ""
echo "📖 For detailed instructions, see:"
echo "   - docs/quick-start-digitalocean.md"
echo "   - docs/plan-action-devops_v2.md"
echo ""
