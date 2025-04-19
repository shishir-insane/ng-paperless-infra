#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting INTERNAL Nginx Security Audit...${NC}"

check_passed() {
  echo -e "${GREEN}[PASSED] $1${NC}"
}

check_failed() {
  echo -e "${RED}[FAILED] $1${NC}"
  echo -e "${YELLOW}Suggestion: $2${NC}"
}

# Dependency Check
echo -e "\n${BLUE}Checking dependencies...${NC}"

for pkg in nginx stat grep awk; do
  if ! command -v $pkg &> /dev/null; then
    echo -e "${YELLOW}Installing missing package: $pkg${NC}"
    sudo apt update -qq && sudo apt install -y $pkg
  fi
done

# 1. NGINX Config Validation
echo -e "\n${BLUE}Checking NGINX configuration...${NC}"
sudo nginx -t &>/tmp/nginx_test.log
if grep -q "successful" /tmp/nginx_test.log; then
  check_passed "Nginx config syntax is valid"
else
  check_failed "Nginx config has errors" "Run 'sudo nginx -t' and fix the issues listed"
  cat /tmp/nginx_test.log
fi

# 2. Permissions Check
echo -e "\n${BLUE}Checking recommended file permissions...${NC}"
NGINX_CONF_DIR="/etc/nginx"
if [ "$(stat -c %a $NGINX_CONF_DIR)" -le 755 ]; then
  check_passed "Nginx config directory permissions are secure"
else
  check_failed "Loose permissions on $NGINX_CONF_DIR" "Set directory permissions to 755 or tighter"
fi

# 3. Check if running as limited user
echo -e "\n${BLUE}Checking if Nginx is running as a limited user...${NC}"
WORKER_USER=$(grep -E "^user" /etc/nginx/nginx.conf | awk '{print $2}' | sed 's/;//')
if [ "$WORKER_USER" == "www-data" ] || [ "$WORKER_USER" == "nginx" ]; then
  check_passed "Nginx is configured to run as a non-root user ($WORKER_USER)"
else
  check_failed "Nginx user is not set or not ideal" "Set 'user nginx;' or 'user www-data;' in nginx.conf"
fi

# 4. Rate Limiting Check
echo -e "\n${BLUE}Checking rate limiting configuration...${NC}"
if grep -q "limit_req_zone" /etc/nginx/nginx.conf || grep -qr "limit_req" /etc/nginx/sites-enabled/; then
  check_passed "Rate limiting is configured"
else
  check_failed "No rate limiting detected" "Add 'limit_req_zone' and 'limit_req' in server blocks to mitigate DoS"
fi

# 5. Version Disclosure
echo -e "\n${BLUE}Checking server_tokens setting...${NC}"
if grep -q "server_tokens off" /etc/nginx/nginx.conf; then
  check_passed "server_tokens is disabled"
else
  check_failed "server_tokens is not disabled" "Add 'server_tokens off;' to nginx.conf to hide version in headers"
fi

echo -e "\n${BLUE}Internal audit complete.${NC}"
