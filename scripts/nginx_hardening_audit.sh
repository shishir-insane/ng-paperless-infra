#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
  echo -e "${YELLOW}Usage: $0 yourdomain.com${NC}"
  exit 1
fi

echo -e "${BLUE}Starting Nginx Security & Hardening Audit for ${DOMAIN}${NC}"

check_passed() {
  echo -e "${GREEN}[PASSED] $1${NC}"
}

check_failed() {
  echo -e "${RED}[FAILED] $1${NC}"
  echo -e "${YELLOW}Suggestion: $2${NC}"
}

# 1. NGINX Config Validation
echo -e "\n${BLUE}Checking NGINX configuration...${NC}"
sudo nginx -t &>/tmp/nginx_test.log
if grep -q "successful" /tmp/nginx_test.log; then
  check_passed "Nginx config syntax is valid"
else
  check_failed "Nginx config has errors" "Run 'sudo nginx -t' and fix the issues listed"
  cat /tmp/nginx_test.log
fi

# 2. SSL/TLS Test
echo -e "\n${BLUE}Checking SSL/TLS configuration...${NC}"
if [ ! -d "testssl.sh" ]; then
  git clone --quiet https://github.com/drwetter/testssl.sh.git
fi
cd testssl.sh && ./testssl.sh --quiet --warnings off https://$DOMAIN > ../ssl_test.log && cd ..
SSL_GRADE=$(grep "Overall grade" ssl_test.log | awk '{print $NF}')
if [[ "$SSL_GRADE" =~ ^A ]]; then
  check_passed "SSL/TLS configuration grade is $SSL_GRADE"
else
  check_failed "SSL/TLS grade is $SSL_GRADE" "Use modern ciphers and disable old protocols (SSLv3, TLS 1.0/1.1)"
fi

# 3. Security Headers Check
echo -e "\n${BLUE}Checking HTTP Security Headers...${NC}"
HEADERS=$(curl -sI https://$DOMAIN)

check_header() {
  HEADER_NAME=$1
  RECOMMENDATION=$2
  if echo "$HEADERS" | grep -qi "$HEADER_NAME"; then
    check_passed "$HEADER_NAME is set"
  else
    check_failed "$HEADER_NAME is missing" "$RECOMMENDATION"
  fi
}

check_header "Strict-Transport-Security" "Add 'Strict-Transport-Security' to enforce HTTPS"
check_header "X-Frame-Options" "Add 'X-Frame-Options: DENY' to prevent clickjacking"
check_header "X-Content-Type-Options" "Add 'X-Content-Type-Options: nosniff' to block MIME-type sniffing"
check_header "X-XSS-Protection" "Add 'X-XSS-Protection: 1; mode=block' to mitigate XSS attacks"
check_header "Referrer-Policy" "Add 'Referrer-Policy: no-referrer' or similar"
check_header "Content-Security-Policy" "Set a strict Content-Security-Policy to mitigate XSS/inline JS"

# 4. Open Ports and Vulnerabilities
echo -e "\n${BLUE}Running Nmap port and vulnerability scan...${NC}"
nmap -T4 -p 1-1000 --script vuln $DOMAIN -oN nmap_scan.txt
OPEN_PORTS=$(grep -E "^([0-9]+)/(tcp|udp)" nmap_scan.txt | awk '{print $1}' | tr '\n' ' ')
if [ -n "$OPEN_PORTS" ]; then
  check_passed "Open ports: $OPEN_PORTS"
else
  check_failed "No open ports found" "Ensure Nginx is running and accessible"
fi

# 5. HTTP Methods Check
echo -e "\n${BLUE}Checking HTTP Methods...${NC}"
METHODS=$(curl -s -X OPTIONS -i https://$DOMAIN | grep "Allow:" | cut -d' ' -f2-)
UNSAFE=$(echo $METHODS | grep -E 'PUT|DELETE|TRACE|CONNECT')
if [ -z "$UNSAFE" ]; then
  check_passed "Only safe HTTP methods allowed: $METHODS"
else
  check_failed "Unsafe HTTP methods enabled: $UNSAFE" "Limit allowed methods in Nginx config using 'if' block or allow methods"
fi

# 6. Version Disclosure
echo -e "\n${BLUE}Checking for version disclosure...${NC}"
if curl -sI https://$DOMAIN | grep -qi "Server:"; then
  SERVER_HEADER=$(curl -sI https://$DOMAIN | grep -i "Server:")
  if [[ $SERVER_HEADER == *"nginx/"* ]]; then
    check_failed "Nginx version is exposed: $SERVER_HEADER" "Add 'server_tokens off;' in nginx.conf to hide version"
  else
    check_passed "Nginx version not disclosed in Server header"
  fi
else
  check_passed "No Server header exposed"
fi

# 7. Permissions Check (manual confirmation)
echo -e "\n${BLUE}Checking recommended file permissions (manual review)...${NC}"
echo -e "${YELLOW}Suggestion: Ensure only root has write access to /etc/nginx, and the worker runs as a limited user${NC}"

# 8. Rate Limiting (manual config check)
echo -e "\n${BLUE}Checking rate limiting configuration...${NC}"
if grep -q "limit_req_zone" /etc/nginx/nginx.conf || grep -qr "limit_req" /etc/nginx/sites-enabled/; then
  check_passed "Rate limiting is configured"
else
  check_failed "No rate limiting detected" "Add 'limit_req_zone' and 'limit_req' to defend against DoS or brute-force attacks"
fi

echo -e "\n${BLUE}Nginx Audit Complete.${NC}"
echo -e "${GREEN}✔ Review passed items for validation.${NC}"
echo -e "${YELLOW}X Review failed items and apply hardening suggestions to improve your server's security.${NC}"
