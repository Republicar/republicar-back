#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"
OCCUPANT_URL="http://localhost:3001/occupant"
CATEGORY_URL="http://localhost:3001/category"
EXPENSE_URL="http://localhost:3001/expense"
DASHBOARD_URL="http://localhost:3001/dashboard"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Epic 4 Test (Dashboard)..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_epic4_${TIMESTAMP}@example.com"
PASSWORD="password123"

# 1. Register Owner
echo -e "\n1. Registering Owner..."
curl -s -o /dev/null -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Epic4 Owner\", \"email\": \"$OWNER_EMAIL\", \"password\": \"$PASSWORD\"}"

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
  -d "{\"name\": \"Epic4 Republic\", \"address\": \"123 Epic St\", \"rooms\": 3}"

# 4. Add Occupants
echo -e "\n4. Adding Occupants..."
curl -s -o /dev/null -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Alice\", \"email\": \"alice_epic4_${TIMESTAMP}@example.com\", \"password\": \"password123\", \"income\": 300000}"

curl -s -o /dev/null -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Bob\", \"email\": \"bob_epic4_${TIMESTAMP}@example.com\", \"password\": \"password123\", \"income\": 100000}"

# 5. Create Categories
echo -e "\n5. Creating Categories..."
curl -s -o /dev/null -X POST $CATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Food\"}"

curl -s -o /dev/null -X POST $CATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Utilities\"}"

# Get category IDs
LIST_CAT_RESPONSE=$(curl -s -X GET $CATEGORY_URL \
  -H "Authorization: Bearer $TOKEN")

FOOD_ID=$(echo $LIST_CAT_RESPONSE | grep -o '{"id":[0-9]*,"name":"Food"' | grep -o '[0-9]*' | head -1)
UTIL_ID=$(echo $LIST_CAT_RESPONSE | grep -o '{"id":[0-9]*,"name":"Utilities"' | grep -o '[0-9]*' | head -1)

echo "Food ID: $FOOD_ID"
echo "Utilities ID: $UTIL_ID"

# 6. Add Expenses (Current Month and Previous Months)
echo -e "\n6. Adding Expenses..."
# Current month expenses
CURRENT_DATE=$(date +%Y-%m-15)
curl -s -o /dev/null -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Current Month Food\", \"amount\": 20000, \"date\": \"$CURRENT_DATE\", \"categoryId\": $FOOD_ID}"

curl -s -o /dev/null -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Current Month Utilities\", \"amount\": 30000, \"date\": \"$CURRENT_DATE\", \"categoryId\": $UTIL_ID}"

# Previous months for trend
for i in 1 2 3 4 5; do
  PREV_DATE=$(date -d "$i months ago" +%Y-%m-15)
  AMOUNT=$((10000 * i))
  curl -s -o /dev/null -X POST $EXPENSE_URL \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"description\": \"Month -$i Expense\", \"amount\": $AMOUNT, \"date\": \"$PREV_DATE\", \"categoryId\": $FOOD_ID}"
done

# 7. Test Current Month Summary (HU18)
echo -e "\n7. Testing Dashboard Summary..."
SUMMARY_RESPONSE=$(curl -s -X GET "$DASHBOARD_URL/summary" \
  -H "Authorization: Bearer $TOKEN")

echo "Summary Response: $SUMMARY_RESPONSE"

if echo "$SUMMARY_RESPONSE" | grep -q '"totalExpenses":50000'; then
  echo -e "${GREEN}SUCCESS: Total expenses correct (500.00)${NC}"
else
  echo -e "${RED}FAILED: Total expenses incorrect${NC}"
  exit 1
fi

if echo "$SUMMARY_RESPONSE" | grep -q '"occupantCount":2'; then
  echo -e "${GREEN}SUCCESS: Occupant count correct${NC}"
else
  echo -e "${RED}FAILED: Occupant count incorrect${NC}"
  exit 1
fi

if echo "$SUMMARY_RESPONSE" | grep -q '"averagePerOccupant":25000'; then
  echo -e "${GREEN}SUCCESS: Average per occupant correct (250.00)${NC}"
else
  echo -e "${RED}FAILED: Average per occupant incorrect${NC}"
  exit 1
fi

# 8. Test Expenses by Category (HU19)
echo -e "\n8. Testing Expenses by Category..."
CATEGORY_RESPONSE=$(curl -s -X GET "$DASHBOARD_URL/by-category" \
  -H "Authorization: Bearer $TOKEN")

echo "Category Response: $CATEGORY_RESPONSE"

if echo "$CATEGORY_RESPONSE" | grep -q '"categoryName":"Food"' && echo "$CATEGORY_RESPONSE" | grep -q '"categoryName":"Utilities"'; then
  echo -e "${GREEN}SUCCESS: Categories present in breakdown${NC}"
else
  echo -e "${RED}FAILED: Categories missing${NC}"
  exit 1
fi

# 9. Test Monthly Trend (HU20)
echo -e "\n9. Testing Monthly Trend..."
TREND_RESPONSE=$(curl -s -X GET "$DASHBOARD_URL/monthly-trend?months=6" \
  -H "Authorization: Bearer $TOKEN")

echo "Trend Response: $TREND_RESPONSE"

# Should have 6 months of data
MONTH_COUNT=$(echo $TREND_RESPONSE | grep -o '"month":"' | wc -l)
if [ "$MONTH_COUNT" -eq 6 ]; then
  echo -e "${GREEN}SUCCESS: Monthly trend has 6 months${NC}"
else
  echo -e "${RED}FAILED: Monthly trend count incorrect ($MONTH_COUNT)${NC}"
  exit 1
fi

echo -e "\n${GREEN}All Epic 4 tests passed!${NC}"
