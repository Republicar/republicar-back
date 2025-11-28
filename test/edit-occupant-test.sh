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

echo "Starting Edit Occupant Test..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_edit_${TIMESTAMP}@example.com"
OCCUPANT_EMAIL="occupant_edit_${TIMESTAMP}@example.com"
NEW_OCCUPANT_EMAIL="occupant_edit_new_${TIMESTAMP}@example.com"
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
  -d "{\"name\": \"Occupant Original\", \"email\": \"$OCCUPANT_EMAIL\", \"password\": \"$PASSWORD\"}"

# 5. Get Occupant ID (Listing)
echo -e "\n5. Getting Occupant ID..."
LIST_RESPONSE=$(curl -s -X GET $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")

# Extract ID using grep/sed (assuming simple JSON structure and it's the first occupant)
OCCUPANT_ID=$(echo $LIST_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$OCCUPANT_ID" ]; then
  echo -e "${RED}FAILED: Could not get occupant ID${NC}"
  exit 1
fi

echo "Occupant ID: $OCCUPANT_ID"

# 6. Edit Occupant (Valid Name)
echo -e "\n6. Editing Occupant (Valid Name)..."
EDIT_NAME_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$OCCUPANT_URL/$OCCUPANT_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Occupant Updated\"}")

if [ "$EDIT_NAME_RESPONSE" -eq 200 ]; then
  echo -e "${GREEN}SUCCESS: Occupant name updated (200)${NC}"
else
  echo -e "${RED}FAILED: Occupant name update failed ($EDIT_NAME_RESPONSE)${NC}"
  exit 1
fi

# 7. Edit Occupant (Valid Email)
echo -e "\n7. Editing Occupant (Valid Email)..."
EDIT_EMAIL_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$OCCUPANT_URL/$OCCUPANT_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"email\": \"$NEW_OCCUPANT_EMAIL\"}")

if [ "$EDIT_EMAIL_RESPONSE" -eq 200 ]; then
  echo -e "${GREEN}SUCCESS: Occupant email updated (200)${NC}"
else
  echo -e "${RED}FAILED: Occupant email update failed ($EDIT_EMAIL_RESPONSE)${NC}"
  exit 1
fi

echo -e "\n${GREEN}All edit occupant tests passed!${NC}"
