#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Republic Registration Test..."

# Unique email for this run
EMAIL="owner_$(date +%s)@example.com"
PASSWORD="password123"

# 1. Register a new Owner
echo -e "\n1. Registering new Owner..."
curl -s -o /dev/null -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Republic Owner\", \"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}"

# 2. Login to get Token
echo -e "\n2. Logging in to get Token..."
LOGIN_RESPONSE=$(curl -s -X POST $LOGIN_URL \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo -e "${RED}FAILED: Could not get access token${NC}"
  exit 1
fi
echo -e "${GREEN}Token received${NC}"

# 3. Create Republic (Valid)
echo -e "\n3. Creating Republic (Valid)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $REPUBLIC_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"My Republic\", \"address\": \"123 Main St\", \"rooms\": 4}")

if [ "$HTTP_CODE" -eq 201 ]; then
  echo -e "${GREEN}SUCCESS: Republic created (201)${NC}"
else
  echo -e "${RED}FAILED: Expected 201, got $HTTP_CODE${NC}"
  exit 1
fi

# 4. Create Republic (Missing Token)
echo -e "\n4. Creating Republic (Missing Token)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $REPUBLIC_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Hacker Republic\", \"address\": \"Dark Web\", \"rooms\": 100}")

if [ "$HTTP_CODE" -eq 401 ]; then
  echo -e "${GREEN}SUCCESS: Unauthorized request rejected (401)${NC}"
else
  echo -e "${RED}FAILED: Expected 401, got $HTTP_CODE${NC}"
  exit 1
fi

echo -e "\n${GREEN}All republic tests passed!${NC}"
