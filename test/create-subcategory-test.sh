#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"
CATEGORY_URL="http://localhost:3001/category"
SUBCATEGORY_URL="http://localhost:3001/subcategory"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Create Subcategory Test..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_subcategory_${TIMESTAMP}@example.com"
PASSWORD="password123"

# 1. Register Owner
echo -e "\n1. Registering Owner..."
curl -s -o /dev/null -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Subcategory Owner\", \"email\": \"$OWNER_EMAIL\", \"password\": \"$PASSWORD\"}"

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
  -d "{\"name\": \"Subcategory Republic\", \"address\": \"123 Sub St\", \"rooms\": 3}"

# 4. Create Category
echo -e "\n4. Creating Category..."
CATEGORY_RESPONSE=$(curl -s -X POST $CATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Utilities\"}")

# We need the category ID. Since the response is just a message, we list categories to get it.
LIST_RESPONSE=$(curl -s -X GET $CATEGORY_URL \
  -H "Authorization: Bearer $TOKEN")

CATEGORY_ID=$(echo $LIST_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$CATEGORY_ID" ]; then
  echo -e "${RED}FAILED: Could not get category ID${NC}"
  exit 1
fi

echo "Category ID: $CATEGORY_ID"

# 5. Create Subcategory (Valid)
echo -e "\n5. Creating Subcategory (Valid)..."
SUBCATEGORY_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $SUBCATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Electricity\", \"categoryId\": $CATEGORY_ID}")

if [ "$SUBCATEGORY_RESPONSE" -eq 201 ]; then
  echo -e "${GREEN}SUCCESS: Subcategory created (201)${NC}"
else
  echo -e "${RED}FAILED: Subcategory creation failed ($SUBCATEGORY_RESPONSE)${NC}"
  exit 1
fi

# 6. List Subcategories
echo -e "\n6. Listing Subcategories..."
LIST_SUB_RESPONSE=$(curl -s -X GET "$SUBCATEGORY_URL/$CATEGORY_ID" \
  -H "Authorization: Bearer $TOKEN")

if echo "$LIST_SUB_RESPONSE" | grep -q "Electricity"; then
  echo -e "${GREEN}SUCCESS: Created subcategory found in list${NC}"
else
  echo -e "${RED}FAILED: Created subcategory not found in list${NC}"
  echo "Response: $LIST_SUB_RESPONSE"
  exit 1
fi

# 7. Create Subcategory (Invalid Category)
echo -e "\n7. Creating Subcategory (Invalid Category)..."
INVALID_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $SUBCATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Invalid\", \"categoryId\": 99999}")

if [ "$INVALID_RESPONSE" -eq 404 ]; then
  echo -e "${GREEN}SUCCESS: Invalid category rejected (404)${NC}"
else
  echo -e "${RED}FAILED: Invalid category not rejected ($INVALID_RESPONSE)${NC}"
  exit 1
fi

echo -e "\n${GREEN}All create subcategory tests passed!${NC}"
