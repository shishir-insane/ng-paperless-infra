#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
  echo -e "${YELLOW}Usage: $0 yourdomain.com${NC}"
  exit 1
fi

echo -e "${BLUE}Starting EXTERNAL Nginx Security Audit for ${DOMAIN}${NC}"

check_passed() {
  echo -e "${GREEN}[PASSED] $1${NC}"
}

check_failed() {
  echo -e "${RED}[FAILED] $1${NC}"
  echo -e "${YELLOW}Suggestion: $2${NC}"
}

# Dependency Check
echo -e "\n${BLUE}Checking dependencies...${NC}"

for pkg in curl git nmap; do
  if ! command -v $pkg &> /dev/null; then
    echo -e "${YELLOW}Installing missing package: $pkg${NC}"
    sudo apt update -qq && sudo apt install -y $pkg
  fi
done

# 1. SSL/TLS Test
echo -e "\n${BLUE}Checking SSL/TLS configuration...${NC}"
if [ ! -d "testssl.sh" ]; then
  git clone --quiet https://github.com/drwetter/testssl.sh.git
fi
cd testssl.sh && ./testssl.sh --quiet --warnings off https://$DOMAIN > ../ssl_test.log && cd ..
SSL_GRADE=$(grep "Overall grade" ssl_test.log | awk '{print $NF}')
if [[ "$SSL_GRADE" =~ ^A ]]; then
  check_passed "SSL/TLS configuration grade is $SSL_GRADE"
else
  check_failed "SSL/TLS grade is $SSL_GRADE" "Use strong ciphers, TLS 1.2/1.3, and HSTS headers"
fi

# 2. Security Headers
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
check_header "X-XSS-Protection" "Add 'X-XSS-Protection: 1; mode=block' to mitigate XSS"
check_header "Referrer-Policy" "Add 'Referrer-Policy: no-referrer' or similar"
check_header "Content-Security-Policy" "Set a strict CSP to reduce XSS and inline JS attacks"

# 3. Open Ports and Vulnerabilities
echo -e "\n${BLUE}Running Nmap port and vulnerability scan...${NC}"
nmap -T4 -p 1-1000 --script vuln $DOMAIN -oN nmap_scan.txt
OPEN_PORTS=$(grep -E "^([0-9]+)/(tcp|udp)" nmap_scan.txt | awk '{print $1}' | tr '\n' ' ')
if [ -n "$OPEN_PORTS" ]; then
  check_passed "Open ports: $OPEN_PORTS"
else
  check_failed "No open ports found" "Ensure server is reachable and Nginx is listening"
fi

# 4. HTTP Method Exposure
echo -e "\n${BLUE}Checking HTTP methods...${NC}"
METHODS=$(curl -s -X OPTIONS -i https://$DOMAIN | grep "Allow:" | cut -d' ' -f2-)
UNSAFE=$(echo $METHODS | grep -E 'PUT|DELETE|TRACE|CONNECT')
if [ -z "$UNSAFE" ]; then
  check_passed "Safe HTTP methods allowed: $METHODS"
else
  check_failed "Unsafe HTTP methods enabled: $UNSAFE" "Limit allowed methods in server block or using if statements"
fi

# 5. Version Disclosure
echo -e "\n${BLUE}Checking Server header disclosure...${NC}"
SERVER_HEADER=$(curl -sI https://$DOMAIN | grep -i "Server:")
if [[ $SERVER_HEADER == *"nginx/"* ]]; then
  check_failed "Nginx version is exposed: $SERVER_HEADER" "Add 'server_tokens off;' in nginx config to hide version"
else
  check_passed "Nginx version not disclosed in Server header"
fi

echo -e "\n${BLUE}External audit complete.${NC}"
