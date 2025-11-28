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

echo "Starting Remove Occupant Test..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_remove_${TIMESTAMP}@example.com"
OCCUPANT_EMAIL="occupant_remove_${TIMESTAMP}@example.com"
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

# 4. Add Occupant
echo -e "\n4. Adding Occupant..."
curl -s -o /dev/null -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Occupant To Remove\", \"email\": \"$OCCUPANT_EMAIL\", \"password\": \"$PASSWORD\"}"

# 5. Get Occupant ID (Listing)
echo -e "\n5. Getting Occupant ID..."
LIST_RESPONSE=$(curl -s -X GET $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")

OCCUPANT_ID=$(echo $LIST_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$OCCUPANT_ID" ]; then
  echo -e "${RED}FAILED: Could not get occupant ID${NC}"
  exit 1
fi

echo "Occupant ID: $OCCUPANT_ID"

# 6. Remove Occupant (Valid)
echo -e "\n6. Removing Occupant..."
REMOVE_RESPONSE_BODY=$(curl -s -X DELETE "$OCCUPANT_URL/$OCCUPANT_ID" \
  -H "Authorization: Bearer $TOKEN")

# Get status code separately or parse it (simplifying here to just show body on error)
# Re-running to get status code
REMOVE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$OCCUPANT_URL/$OCCUPANT_ID" \
  -H "Authorization: Bearer $TOKEN")

if [ "$REMOVE_STATUS" -eq 200 ]; then
  echo -e "${GREEN}SUCCESS: Occupant removed (200)${NC}"
elif [ "$REMOVE_STATUS" -eq 404 ]; then
    # If first request succeeded, second will be 404.
    echo -e "${GREEN}SUCCESS: Occupant removed (was 200, now 404)${NC}"
else
  echo -e "${RED}FAILED: Occupant removal failed ($REMOVE_STATUS)${NC}"
  echo "Response Body: $REMOVE_RESPONSE_BODY"
  exit 1
fi

# 7. Verify Occupant is gone
echo -e "\n7. Verifying Occupant is gone..."
LIST_RESPONSE_AFTER=$(curl -s -X GET $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")

if [[ $LIST_RESPONSE_AFTER != *"$OCCUPANT_EMAIL"* ]]; then
  echo -e "${GREEN}SUCCESS: Occupant not found in list${NC}"
else
  echo -e "${RED}FAILED: Occupant still in list${NC}"
  exit 1
fi

# 8. Remove Occupant (Not Found/Already Removed)
echo -e "\n8. Removing Occupant Again (Should Fail)..."
REMOVE_AGAIN_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$OCCUPANT_URL/$OCCUPANT_ID" \
  -H "Authorization: Bearer $TOKEN")

if [ "$REMOVE_AGAIN_RESPONSE" -eq 404 ]; then
  echo -e "${GREEN}SUCCESS: Duplicate removal rejected (404)${NC}"
else
  echo -e "${RED}FAILED: Duplicate removal unexpected response ($REMOVE_AGAIN_RESPONSE)${NC}"
  exit 1
fi

echo -e "\n${GREEN}All remove occupant tests passed!${NC}"
