#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Login Test..."

# Unique email for this run
EMAIL="login_test_$(date +%s)@example.com"
PASSWORD="password123"

# 1. Register a new user (Setup)
echo -e "\n1. Registering user for login test..."
curl -s -o /dev/null -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Login User\", \"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}"

# 2. Login with valid credentials
echo -e "\n2. Logging in with valid credentials..."
RESPONSE=$(curl -s -X POST $LOGIN_URL \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")

if [[ $RESPONSE == *"access_token"* ]]; then
  echo -e "${GREEN}SUCCESS: Login successful (Token received)${NC}"
else
  echo -e "${RED}FAILED: Login failed. Response: $RESPONSE${NC}"
  exit 1
fi

# 3. Login with invalid password
echo -e "\n3. Logging in with invalid password..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $LOGIN_URL \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"wrongpassword\"}")

if [ "$HTTP_CODE" -eq 401 ]; then
  echo -e "${GREEN}SUCCESS: Invalid password rejected (401)${NC}"
else
  echo -e "${RED}FAILED: Expected 401, got $HTTP_CODE${NC}"
  exit 1
fi

# 4. Login with non-existent user
echo -e "\n4. Logging in with non-existent user..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $LOGIN_URL \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"nonexistent@example.com\", \"password\": \"$PASSWORD\"}")

if [ "$HTTP_CODE" -eq 401 ]; then
  echo -e "${GREEN}SUCCESS: Non-existent user rejected (401)${NC}"
else
  echo -e "${RED}FAILED: Expected 401, got $HTTP_CODE${NC}"
  exit 1
fi

echo -e "\n${GREEN}All login tests passed!${NC}"
