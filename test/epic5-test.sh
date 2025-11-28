#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"
OCCUPANT_URL="http://localhost:3001/occupant"
CATEGORY_URL="http://localhost:3001/category"
EXPENSE_URL="http://localhost:3001/expense"
REPORT_URL="http://localhost:3001/report"
PORTAL_URL="http://localhost:3001/occupant/portal"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Epic 5 Test (Occupant Portal)..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_epic5_${TIMESTAMP}@example.com"
OCCUPANT_EMAIL="occupant_epic5_${TIMESTAMP}@example.com"
PASSWORD="password123"

# 1. Register Owner
echo -e "\n1. Registering Owner..."
curl -s -o /dev/null -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Epic5 Owner\", \"email\": \"$OWNER_EMAIL\", \"password\": \"$PASSWORD\"}"

# 2. Login Owner
echo -e "\n2. Logging in Owner..."
LOGIN_RESPONSE=$(curl -s -X POST $LOGIN_URL \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$OWNER_EMAIL\", \"password\": \"$PASSWORD\"}")

OWNER_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$OWNER_TOKEN" ]; then
  echo -e "${RED}FAILED: Could not get owner access token${NC}"
  exit 1
fi

# 3. Create Republic
echo -e "\n3. Creating Republic..."
curl -s -o /dev/null -X POST $REPUBLIC_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -d "{\"name\": \"Epic5 Republic\", \"address\": \"123 Epic St\", \"rooms\": 3}"

# 4. Create Occupant (HU21 - Email invitation covered by creating occupant with credentials)
echo -e "\n4. Creating Occupant..."
curl -s -o /dev/null -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -d "{\"name\": \"Epic5 Occupant\", \"email\": \"$OCCUPANT_EMAIL\", \"password\": \"$PASSWORD\", \"income\": 300000}"

# 5. Create Category and Expenses
echo -e "\n5. Creating Category and Expenses..."
curl -s -o /dev/null -X POST $CATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -d "{\"name\": \"Test Category\"}"

LIST_CAT_RESPONSE=$(curl -s -X GET $CATEGORY_URL \
  -H "Authorization: Bearer $OWNER_TOKEN")
CAT_ID=$(echo $LIST_CAT_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

CURRENT_DATE=$(date +%Y-%m-15)
curl -s -o /dev/null -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -d "{\"description\": \"Test Expense\", \"amount\": 40000, \"date\": \"$CURRENT_DATE\", \"categoryId\": $CAT_ID}"

# 6. Generate Report
echo -e "\n6. Generating Report..."
REPORT_RESPONSE=$(curl -s -X POST $REPORT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -d "{\"startDate\": \"2023-01-01\", \"endDate\": \"2025-12-31\", \"splitMethod\": \"EQUAL\"}")

REPORT_ID=$(echo $REPORT_RESPONSE | grep -o '"reportId":[0-9]*' | cut -d':' -f2)

if [ -z "$REPORT_ID" ]; then
  echo -e "${RED}FAILED: Report generation failed${NC}"
  echo "Response: $REPORT_RESPONSE"
  exit 1
fi
echo "Report ID: $REPORT_ID"

# 7. Login as Occupant (HU22)
echo -e "\n7. Logging in as Occupant..."
OCCUPANT_LOGIN_RESPONSE=$(curl -s -X POST $LOGIN_URL \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$OCCUPANT_EMAIL\", \"password\": \"$PASSWORD\"}")

OCCUPANT_TOKEN=$(echo $OCCUPANT_LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$OCCUPANT_TOKEN" ]; then
  echo -e "${RED}FAILED: Occupant login failed${NC}"
  exit 1
fi
echo -e "${GREEN}SUCCESS: Occupant logged in${NC}"

# 8. Get Report List (HU24)
echo -e "\n8. Getting Report List..."
REPORTS_RESPONSE=$(curl -s -X GET "$PORTAL_URL/reports" \
  -H "Authorization: Bearer $OCCUPANT_TOKEN")

echo "Reports Response: $REPORTS_RESPONSE"

if echo "$REPORTS_RESPONSE" | grep -q "\"reportId\":$REPORT_ID"; then
  echo -e "${GREEN}SUCCESS: Occupant can see report in list${NC}"
else
  echo -e "${RED}FAILED: Report not found in occupant's list${NC}"
  exit 1
fi

if echo "$REPORTS_RESPONSE" | grep -q '"myShare":40000'; then
  echo -e "${GREEN}SUCCESS: Occupant's share amount is correct (400.00)${NC}"
else
  echo -e "${RED}FAILED: Share amount incorrect${NC}"
  exit 1
fi

# 9. Get Report Details (HU23)
echo -e "\n9. Getting Report Details..."
DETAILS_RESPONSE=$(curl -s -X GET "$PORTAL_URL/reports/$REPORT_ID" \
  -H "Authorization: Bearer $OCCUPANT_TOKEN")

echo "Details Response: $DETAILS_RESPONSE"

if echo "$DETAILS_RESPONSE" | grep -q '"myShare":40000'; then
  echo -e "${GREEN}SUCCESS: Report details show correct share${NC}"
else
  echo -e "${RED}FAILED: Report details incorrect${NC}"
  exit 1
fi

if echo "$DETAILS_RESPONSE" | grep -q '"totalAmount":40000'; then
  echo -e "${GREEN}SUCCESS: Report details show total amount${NC}"
else
  echo -e "${RED}FAILED: Total amount missing${NC}"
  exit 1
fi

echo -e "\n${GREEN}All Epic 5 tests passed!${NC}"
