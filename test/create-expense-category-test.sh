#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"
CATEGORY_URL="http://localhost:3001/category"
SUBCATEGORY_URL="http://localhost:3001/subcategory"
EXPENSE_URL="http://localhost:3001/expense"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Create Expense with Category Test..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_exp_cat_${TIMESTAMP}@example.com"
PASSWORD="password123"

# 1. Register Owner
echo -e "\n1. Registering Owner..."
curl -s -o /dev/null -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Expense Category Owner\", \"email\": \"$OWNER_EMAIL\", \"password\": \"$PASSWORD\"}"

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
  -d "{\"name\": \"Expense Republic\", \"address\": \"123 Exp St\", \"rooms\": 3}"

# 4. Create Category
echo -e "\n4. Creating Category..."
curl -s -o /dev/null -X POST $CATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Utilities\"}"

LIST_CAT_RESPONSE=$(curl -s -X GET $CATEGORY_URL \
  -H "Authorization: Bearer $TOKEN")
CATEGORY_ID=$(echo $LIST_CAT_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Category ID: $CATEGORY_ID"

# 5. Create Subcategory
echo -e "\n5. Creating Subcategory..."
curl -s -o /dev/null -X POST $SUBCATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Electricity\", \"categoryId\": $CATEGORY_ID}"

LIST_SUB_RESPONSE=$(curl -s -X GET "$SUBCATEGORY_URL/$CATEGORY_ID" \
  -H "Authorization: Bearer $TOKEN")
SUBCATEGORY_ID=$(echo $LIST_SUB_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Subcategory ID: $SUBCATEGORY_ID"

# 6. Create Expense (Valid with Category & Subcategory)
echo -e "\n6. Creating Expense (Valid with Category & Subcategory)..."
EXPENSE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Electric Bill\", \"amount\": 15000, \"date\": \"2023-10-27\", \"categoryId\": $CATEGORY_ID, \"subcategoryId\": $SUBCATEGORY_ID}")

if [ "$EXPENSE_RESPONSE" -eq 201 ]; then
  echo -e "${GREEN}SUCCESS: Expense created (201)${NC}"
else
  echo -e "${RED}FAILED: Expense creation failed ($EXPENSE_RESPONSE)${NC}"
  exit 1
fi

# 7. Create Expense (Valid with Category only)
echo -e "\n7. Creating Expense (Valid with Category only)..."
EXPENSE_CAT_ONLY_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"General Utility\", \"amount\": 5000, \"date\": \"2023-10-28\", \"categoryId\": $CATEGORY_ID}")

if [ "$EXPENSE_CAT_ONLY_RESPONSE" -eq 201 ]; then
  echo -e "${GREEN}SUCCESS: Expense created (201)${NC}"
else
  echo -e "${RED}FAILED: Expense creation failed ($EXPENSE_CAT_ONLY_RESPONSE)${NC}"
  exit 1
fi

# 8. Create Expense (Missing Category)
echo -e "\n8. Creating Expense (Missing Category)..."
MISSING_CAT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Missing Cat\", \"amount\": 1000, \"date\": \"2023-10-29\"}")

if [ "$MISSING_CAT_RESPONSE" -eq 400 ]; then
  echo -e "${GREEN}SUCCESS: Missing category rejected (400)${NC}"
else
  echo -e "${RED}FAILED: Missing category not rejected ($MISSING_CAT_RESPONSE)${NC}"
  exit 1
fi

# 9. Create Expense (Invalid Category)
echo -e "\n9. Creating Expense (Invalid Category)..."
INVALID_CAT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Invalid Cat\", \"amount\": 1000, \"date\": \"2023-10-29\", \"categoryId\": 99999}")

if [ "$INVALID_CAT_RESPONSE" -eq 404 ]; then
  echo -e "${GREEN}SUCCESS: Invalid category rejected (404)${NC}"
else
  echo -e "${RED}FAILED: Invalid category not rejected ($INVALID_CAT_RESPONSE)${NC}"
  exit 1
fi

# 10. Create Expense (Invalid Subcategory)
echo -e "\n10. Creating Expense (Invalid Subcategory)..."
INVALID_SUB_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Invalid Sub\", \"amount\": 1000, \"date\": \"2023-10-29\", \"categoryId\": $CATEGORY_ID, \"subcategoryId\": 99999}")

if [ "$INVALID_SUB_RESPONSE" -eq 404 ]; then
  echo -e "${GREEN}SUCCESS: Invalid subcategory rejected (404)${NC}"
else
  echo -e "${RED}FAILED: Invalid subcategory not rejected ($INVALID_SUB_RESPONSE)${NC}"
  exit 1
fi

echo -e "\n${GREEN}All create expense with category tests passed!${NC}"
