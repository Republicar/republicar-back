#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"
CATEGORY_URL="http://localhost:3001/category"
EXPENSE_URL="http://localhost:3001/expense"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting List Expenses Test..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_list_exp_${TIMESTAMP}@example.com"
PASSWORD="password123"

# 1. Register Owner
echo -e "\n1. Registering Owner..."
curl -s -o /dev/null -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"List Expense Owner\", \"email\": \"$OWNER_EMAIL\", \"password\": \"$PASSWORD\"}"

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
  -d "{\"name\": \"List Expense Republic\", \"address\": \"123 List St\", \"rooms\": 3}"

# 4. Create Categories
echo -e "\n4. Creating Categories..."
curl -s -o /dev/null -X POST $CATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Food\"}"

curl -s -o /dev/null -X POST $CATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Utilities\"}"

LIST_CAT_RESPONSE=$(curl -s -X GET $CATEGORY_URL \
  -H "Authorization: Bearer $TOKEN")

FOOD_ID=$(echo $LIST_CAT_RESPONSE | grep -o '{"id":[0-9]*,"name":"Food"' | grep -o '[0-9]*' | head -1)
UTIL_ID=$(echo $LIST_CAT_RESPONSE | grep -o '{"id":[0-9]*,"name":"Utilities"' | grep -o '[0-9]*' | head -1)

echo "Food ID: $FOOD_ID"
echo "Utilities ID: $UTIL_ID"

# 5. Create Expenses
echo -e "\n5. Creating Expenses..."
# Food Expense on 2023-10-01
curl -s -o /dev/null -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Groceries\", \"amount\": 5000, \"date\": \"2023-10-01\", \"categoryId\": $FOOD_ID}"

# Util Expense on 2023-10-15
curl -s -o /dev/null -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Electric\", \"amount\": 10000, \"date\": \"2023-10-15\", \"categoryId\": $UTIL_ID}"

# Food Expense on 2023-10-30
curl -s -o /dev/null -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Dinner\", \"amount\": 3000, \"date\": \"2023-10-30\", \"categoryId\": $FOOD_ID}"

# 6. List All Expenses
echo -e "\n6. List All Expenses..."
ALL_RESPONSE=$(curl -s -X GET $EXPENSE_URL \
  -H "Authorization: Bearer $TOKEN")

COUNT=$(echo $ALL_RESPONSE | grep -o "description" | wc -l)
if [ "$COUNT" -ge 3 ]; then
  echo -e "${GREEN}SUCCESS: All expenses listed ($COUNT)${NC}"
else
  echo -e "${RED}FAILED: Not all expenses listed ($COUNT)${NC}"
  echo "Response: $ALL_RESPONSE"
  exit 1
fi

# 7. List by Category (Food)
echo -e "\n7. List by Category (Food)..."
FOOD_RESPONSE=$(curl -s -X GET "$EXPENSE_URL?categoryId=$FOOD_ID" \
  -H "Authorization: Bearer $TOKEN")

if echo "$FOOD_RESPONSE" | grep -q "Groceries" && echo "$FOOD_RESPONSE" | grep -q "Dinner" && ! echo "$FOOD_RESPONSE" | grep -q "Electric"; then
  echo -e "${GREEN}SUCCESS: Filtered by category correctly${NC}"
else
  echo -e "${RED}FAILED: Category filter failed${NC}"
  echo "Response: $FOOD_RESPONSE"
  exit 1
fi

# 8. List by Date Range (Oct 10 - Oct 20)
echo -e "\n8. List by Date Range (Oct 10 - Oct 20)..."
DATE_RESPONSE=$(curl -s -X GET "$EXPENSE_URL?startDate=2023-10-10&endDate=2023-10-20" \
  -H "Authorization: Bearer $TOKEN")

if echo "$DATE_RESPONSE" | grep -q "Electric" && ! echo "$DATE_RESPONSE" | grep -q "Groceries" && ! echo "$DATE_RESPONSE" | grep -q "Dinner"; then
  echo -e "${GREEN}SUCCESS: Filtered by date range correctly${NC}"
else
  echo -e "${RED}FAILED: Date range filter failed${NC}"
  echo "Response: $DATE_RESPONSE"
  exit 1
fi

echo -e "\n${GREEN}All list expenses tests passed!${NC}"
