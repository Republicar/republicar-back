#!/bin/bash

# Base URL
URL="http://localhost:3001/auth/register"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Register Test..."

# 1. Register a new user (Valid)
echo -e "\n1. Registering new user (Valid)..."
EMAIL="test_$(date +%s)@example.com"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Test User\", \"email\": \"$EMAIL\", \"password\": \"password123\"}")

if [ "$RESPONSE" -eq 201 ]; then
  echo -e "${GREEN}SUCCESS: User registered (201)${NC}"
else
  echo -e "${RED}FAILED: Expected 201, got $RESPONSE${NC}"
  exit 1
fi

# 2. Register the same user again (Duplicate)
echo -e "\n2. Registering duplicate user..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Test User\", \"email\": \"$EMAIL\", \"password\": \"password123\"}")

if [ "$RESPONSE" -eq 409 ]; then
  echo -e "${GREEN}SUCCESS: Duplicate prevented (409)${NC}"
else
  echo -e "${RED}FAILED: Expected 409, got $RESPONSE${NC}"
  exit 1
fi

# 3. Invalid data (Short password)
echo -e "\n3. Testing invalid password..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Test User\", \"email\": \"invalid@example.com\", \"password\": \"123\"}")

if [ "$RESPONSE" -eq 400 ]; then
  echo -e "${GREEN}SUCCESS: Invalid password rejected (400)${NC}"
else
  echo -e "${RED}FAILED: Expected 400, got $RESPONSE${NC}"
  exit 1
fi

echo -e "\n${GREEN}All tests passed!${NC}"
