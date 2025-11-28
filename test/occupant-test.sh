#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"
OCCUPANT_URL="http://localhost:3001/occupant"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Occupant Addition Test..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_${TIMESTAMP}@example.com"
OCCUPANT_EMAIL="occupant_${TIMESTAMP}@example.com"
PASSWORD="password123"

# 1. Register Owner
echo -e "\n1. Registering Owner..."
curl -s -o /dev/null -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Republic Owner\", \"email\": \"$OWNER_EMAIL\", \"password\": \"$PASSWORD\"}"

# 2. Login Owner
echo -e "\n2. Logging in Owner..."
LOGIN_RESPONSE=$(curl -s -X POST $LOGIN_URL \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$OWNER_EMAIL\", \"password\": \"$PASSWORD\"}")

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo -e "${RED}FAILED: Could not get access token${NC}"
  exit 1
fi

# 3. Create Republic
echo -e "\n3. Creating Republic..."
curl -s -o /dev/null -X POST $REPUBLIC_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"My Republic\", \"address\": \"123 Main St\", \"rooms\": 4}"

# 4. Add Occupant (Valid)
echo -e "\n4. Adding Occupant (Valid)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"New Occupant\", \"email\": \"$OCCUPANT_EMAIL\", \"password\": \"$PASSWORD\"}")

if [ "$HTTP_CODE" -eq 201 ]; then
  echo -e "${GREEN}SUCCESS: Occupant added (201)${NC}"
else
  echo -e "${RED}FAILED: Expected 201, got $HTTP_CODE${NC}"
  exit 1
fi

# 5. Add Occupant (Duplicate Email)
echo -e "\n5. Adding Occupant (Duplicate Email)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Another Occupant\", \"email\": \"$OCCUPANT_EMAIL\", \"password\": \"$PASSWORD\"}")

if [ "$HTTP_CODE" -eq 409 ]; then
  echo -e "${GREEN}SUCCESS: Duplicate email rejected (409)${NC}"
else
  echo -e "${RED}FAILED: Expected 409, got $HTTP_CODE${NC}"
  exit 1
fi

echo -e "\n${GREEN}All occupant tests passed!${NC}"
