#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"
CATEGORY_URL="http://localhost:3001/category"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Create Category Test..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_category_${TIMESTAMP}@example.com"
PASSWORD="password123"

# 1. Register Owner
echo -e "\n1. Registering Owner..."
curl -s -o /dev/null -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Category Owner\", \"email\": \"$OWNER_EMAIL\", \"password\": \"$PASSWORD\"}"

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
  -d "{\"name\": \"Category Republic\", \"address\": \"123 Cat St\", \"rooms\": 3}"

# 4. Create Category (Valid)
echo -e "\n4. Creating Category (Valid)..."
CATEGORY_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $CATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Fixed Bills\"}")

if [ "$CATEGORY_RESPONSE" -eq 201 ]; then
  echo -e "${GREEN}SUCCESS: Category created (201)${NC}"
else
  echo -e "${RED}FAILED: Category creation failed ($CATEGORY_RESPONSE)${NC}"
  exit 1
fi

# 5. List Categories
echo -e "\n5. Listing Categories..."
LIST_RESPONSE=$(curl -s -X GET $CATEGORY_URL \
  -H "Authorization: Bearer $TOKEN")

if echo "$LIST_RESPONSE" | grep -q "Fixed Bills"; then
  echo -e "${GREEN}SUCCESS: Created category found in list${NC}"
else
  echo -e "${RED}FAILED: Created category not found in list${NC}"
  echo "Response: $LIST_RESPONSE"
  exit 1
fi

# 6. Create Category (Missing Name)
echo -e "\n6. Creating Category (Missing Name)..."
MISSING_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $CATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{}")

if [ "$MISSING_RESPONSE" -eq 400 ]; then
  echo -e "${GREEN}SUCCESS: Missing name rejected (400)${NC}"
else
  echo -e "${RED}FAILED: Missing name not rejected ($MISSING_RESPONSE)${NC}"
  exit 1
fi

echo -e "\n${GREEN}All create category tests passed!${NC}"
