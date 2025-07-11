#!/bin/bash

# 📊 Deployment Status Monitor
# Monitors the health and status of the Django application on DigitalOcean

set -e

# Configuration
SERVER_IP="157.245.79.172"
APP_USER="django"
APP_DIR="/var/www/django-devops-app"
APP_URL="http://$SERVER_IP"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Functions
print_header() {
    echo -e "${BLUE}$1${NC}"
    echo "$(printf '%*s' ${#1} '' | tr ' ' '=')"
}

check_status() {
    local service="$1"
    local status="$2"
    if [ "$status" = "0" ]; then
        echo -e "✅ ${GREEN}$service is running${NC}"
        return 0
    else
        echo -e "❌ ${RED}$service is not running${NC}"
        return 1
    fi
}

# Main monitoring function
monitor_deployment() {
    print_header "🚀 Django DevOps Deployment Status Monitor"
    echo ""
    
    # 1. Test server connectivity
    print_header "🌐 Server Connectivity"
    if ping -c 1 $SERVER_IP > /dev/null 2>&1; then
        echo -e "✅ ${GREEN}Server ($SERVER_IP) is reachable${NC}"
        SERVER_AVAILABLE=true
    else
        echo -e "❌ ${RED}Server ($SERVER_IP) is not reachable${NC}"
        SERVER_AVAILABLE=false
        exit 1
    fi
    echo ""
    
    # 2. Test SSH connection
    print_header "🔐 SSH Connection"
    if ssh -o ConnectTimeout=5 -o BatchMode=yes $APP_USER@$SERVER_IP 'exit' 2>/dev/null; then
        echo -e "✅ ${GREEN}SSH connection successful${NC}"
        SSH_AVAILABLE=true
    else
        echo -e "❌ ${RED}SSH connection failed${NC}"
        echo -e "   ${YELLOW}Check your SSH keys and GitHub secrets configuration${NC}"
        SSH_AVAILABLE=false
    fi
    echo ""
    
    if [ "$SSH_AVAILABLE" = "true" ]; then
        # 3. Check system services
        print_header "🔧 System Services Status"
        
        # Check nginx
        ssh $APP_USER@$SERVER_IP 'systemctl is-active nginx' > /dev/null 2>&1
        check_status "Nginx" $?
        
        # Check supervisor
        ssh $APP_USER@$SERVER_IP 'systemctl is-active supervisor' > /dev/null 2>&1
        check_status "Supervisor" $?
        
        # Check gunicorn (via supervisor)
        ssh $APP_USER@$SERVER_IP 'sudo supervisorctl status django-devops-app' > /dev/null 2>&1
        check_status "Django Application (Gunicorn)" $?
        
        echo ""
        
        # 4. Check application health
        print_header "🏥 Application Health"
        
        # Test HTTP response
        if curl -s -I $APP_URL | head -n 1 | grep -q "200\|301\|302"; then
            echo -e "✅ ${GREEN}Application is responding${NC}"
            APP_RESPONDING=true
        else
            echo -e "❌ ${RED}Application is not responding${NC}"
            APP_RESPONDING=false
        fi
        
        # Check disk space
        DISK_USAGE=$(ssh $APP_USER@$SERVER_IP 'df -h / | tail -1 | awk "{print \$5}" | sed "s/%//"')
        if [ "$DISK_USAGE" -lt 80 ]; then
            echo -e "✅ ${GREEN}Disk usage: ${DISK_USAGE}%${NC}"
        else
            echo -e "⚠️  ${YELLOW}Disk usage: ${DISK_USAGE}% (High)${NC}"
        fi
        
        # Check memory usage
        MEMORY_USAGE=$(ssh $APP_USER@$SERVER_IP 'free | grep Mem | awk "{printf \"%.0f\", \$3/\$2 * 100.0}"')
        if [ "$MEMORY_USAGE" -lt 80 ]; then
            echo -e "✅ ${GREEN}Memory usage: ${MEMORY_USAGE}%${NC}"
        else
            echo -e "⚠️  ${YELLOW}Memory usage: ${MEMORY_USAGE}% (High)${NC}"
        fi
        
        echo ""
        
        # 5. Application details
        print_header "📋 Application Details"
        
        # Get current commit
        CURRENT_COMMIT=$(ssh $APP_USER@$SERVER_IP "cd $APP_DIR/app && git rev-parse --short HEAD" 2>/dev/null || echo "Unknown")
        echo -e "📝 Current commit: ${PURPLE}$CURRENT_COMMIT${NC}"
        
        # Get last deployment time
        LAST_DEPLOY=$(ssh $APP_USER@$SERVER_IP "stat -c %y $APP_DIR/app/.git/FETCH_HEAD 2>/dev/null | cut -d'.' -f1" || echo "Unknown")
        echo -e "⏰ Last deployment: ${PURPLE}$LAST_DEPLOY${NC}"
        
        # Get application uptime
        APP_UPTIME=$(ssh $APP_USER@$SERVER_IP 'sudo supervisorctl status django-devops-app | awk "{print \$4, \$5}"' 2>/dev/null || echo "Unknown")
        echo -e "⏱️  Application uptime: ${PURPLE}$APP_UPTIME${NC}"
        
        echo ""
        
        # 6. Recent logs
        print_header "📜 Recent Application Logs (Last 10 lines)"
        ssh $APP_USER@$SERVER_IP "tail -10 $APP_DIR/logs/gunicorn.log 2>/dev/null" || echo "No logs available"
        
        echo ""
        
        # 7. Quick health test
        print_header "🧪 Quick Health Test"
        
        if [ "$APP_RESPONDING" = "true" ]; then
            RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' $APP_URL)
            echo -e "⚡ Response time: ${PURPLE}${RESPONSE_TIME}s${NC}"
            
            STATUS_CODE=$(curl -o /dev/null -s -w '%{http_code}' $APP_URL)
            echo -e "📊 HTTP status: ${PURPLE}$STATUS_CODE${NC}"
            
            if [ "$STATUS_CODE" = "200" ]; then
                echo -e "✅ ${GREEN}Application is healthy${NC}"
            else
                echo -e "⚠️  ${YELLOW}Application returned status $STATUS_CODE${NC}"
            fi
        else
            echo -e "❌ ${RED}Cannot perform health test - application not responding${NC}"
        fi
        
    fi
    
    echo ""
    print_header "🎯 Summary"
    
    if [ "$SERVER_AVAILABLE" = "true" ] && [ "$SSH_AVAILABLE" = "true" ] && [ "$APP_RESPONDING" = "true" ]; then
        echo -e "🎉 ${GREEN}Deployment is healthy and operational!${NC}"
        echo -e "🌍 Access your application at: ${BLUE}$APP_URL${NC}"
    elif [ "$SERVER_AVAILABLE" = "true" ] && [ "$SSH_AVAILABLE" = "true" ]; then
        echo -e "⚠️  ${YELLOW}Server is accessible but application needs attention${NC}"
        echo -e "🔧 Check application logs and service status"
    else
        echo -e "❌ ${RED}Deployment has connectivity issues${NC}"
        echo -e "🔍 Check server status and SSH configuration"
    fi
    
    echo ""
    echo -e "📖 For troubleshooting, see: ${BLUE}docs/plan-action-devops_v2.md${NC}"
}

# Run monitoring with option for continuous mode
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    echo "🔄 Starting continuous monitoring (Ctrl+C to stop)..."
    echo ""
    while true; do
        monitor_deployment
        echo ""
        echo "⏳ Waiting 30 seconds for next check..."
        sleep 30
        clear
    done
else
    monitor_deployment
fi
