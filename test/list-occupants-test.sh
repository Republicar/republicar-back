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

echo "Starting List Occupants Test..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_list_${TIMESTAMP}@example.com"
OCCUPANT1_EMAIL="occupant1_${TIMESTAMP}@example.com"
OCCUPANT2_EMAIL="occupant2_${TIMESTAMP}@example.com"
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

# 4. Add Occupant 1
echo -e "\n4. Adding Occupant 1..."
curl -s -o /dev/null -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Occupant One\", \"email\": \"$OCCUPANT1_EMAIL\", \"password\": \"$PASSWORD\"}"

# 5. Add Occupant 2
echo -e "\n5. Adding Occupant 2..."
curl -s -o /dev/null -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Occupant Two\", \"email\": \"$OCCUPANT2_EMAIL\", \"password\": \"$PASSWORD\"}"

# 6. List Occupants
echo -e "\n6. Listing Occupants..."
LIST_RESPONSE=$(curl -s -X GET $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")

# Check if response contains both occupants
if [[ $LIST_RESPONSE == *"$OCCUPANT1_EMAIL"* ]] && [[ $LIST_RESPONSE == *"$OCCUPANT2_EMAIL"* ]]; then
  echo -e "${GREEN}SUCCESS: Both occupants found in list${NC}"
else
  echo -e "${RED}FAILED: Occupants not found in list${NC}"
  echo "Response: $LIST_RESPONSE"
  exit 1
fi

echo -e "\n${GREEN}All list occupants tests passed!${NC}"
