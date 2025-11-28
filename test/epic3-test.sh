#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"
OCCUPANT_URL="http://localhost:3001/occupant"
EXPENSE_URL="http://localhost:3001/expense"
REPORT_URL="http://localhost:3001/report"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Epic 3 Test (Reports & Splitting)..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_epic3_${TIMESTAMP}@example.com"
PASSWORD="password123"

# 1. Register Owner
echo -e "\n1. Registering Owner..."
curl -s -o /dev/null -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Epic3 Owner\", \"email\": \"$OWNER_EMAIL\", \"password\": \"$PASSWORD\"}"

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
  -d "{\"name\": \"Epic3 Republic\", \"address\": \"123 Epic St\", \"rooms\": 3}"

# 4. Add Occupants (Alice: 3000, Bob: 1000)
echo -e "\n4. Adding Occupants..."
curl -s -o /dev/null -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Alice\", \"email\": \"alice_${TIMESTAMP}@example.com\", \"income\": 300000}"

curl -s -o /dev/null -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Bob\", \"email\": \"bob_${TIMESTAMP}@example.com\", \"income\": 100000}"

# 4a. Create Category
echo -e "\n4a. Creating Category..."
curl -s -o /dev/null -X POST $CATEGORY_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"General\"}"

LIST_CAT_RESPONSE=$(curl -s -X GET $CATEGORY_URL \
  -H "Authorization: Bearer $TOKEN")
CAT_ID=$(echo $LIST_CAT_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo "Category ID: $CAT_ID"

# 5. Add Expenses
echo -e "\n5. Adding Expenses..."
# Exp1: 400.00 (40000 cents) - To be included
curl -s -o /dev/null -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Electricity\", \"amount\": 40000, \"date\": \"2023-11-01\", \"categoryId\": $CAT_ID}"

# Exp2: 100.00 (10000 cents) - To be excluded
curl -s -o /dev/null -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Personal Beer\", \"amount\": 10000, \"date\": \"2023-11-02\", \"categoryId\": $CAT_ID}"

# Get Exp2 ID to exclude it
echo "Listing expenses to find ID..."
LIST_EXP_RESPONSE=$(curl -s -X GET "$EXPENSE_URL" \
  -H "Authorization: Bearer $TOKEN")

echo "List Response: $LIST_EXP_RESPONSE"

# Extract ID of the expense with description "Personal Beer"
EXP2_ID=$(echo $LIST_EXP_RESPONSE | grep -o '{"id":[0-9]*,"description":"Personal Beer"' | grep -o '[0-9]*' | head -1)
echo "Expense 2 ID: $EXP2_ID"

if [ -z "$EXP2_ID" ]; then
  echo -e "${RED}FAILED: Could not find Expense 2 ID${NC}"
  exit 1
fi

# 6. Exclude Expense 2
echo -e "\n6. Excluding Expense 2..."
EXCLUDE_RESPONSE=$(curl -s -X PATCH "$EXPENSE_URL/$EXP2_ID/exclude" \
  -H "Authorization: Bearer $TOKEN")

if echo "$EXCLUDE_RESPONSE" | grep -q '"isExcluded":true'; then
  echo -e "${GREEN}SUCCESS: Expense excluded${NC}"
else
  echo -e "${RED}FAILED: Expense exclusion failed${NC}"
  echo "Response: $EXCLUDE_RESPONSE"
  exit 1
fi

# 7. Generate Report (Proportional)
echo -e "\n7. Generating Report (Proportional)..."
REPORT_RESPONSE=$(curl -s -X POST $REPORT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"startDate\": \"2023-11-01\", \"endDate\": \"2023-11-30\", \"splitMethod\": \"PROPORTIONAL\"}")

REPORT_ID=$(echo $REPORT_RESPONSE | grep -o '"reportId":[0-9]*' | cut -d':' -f2)

if [ -z "$REPORT_ID" ]; then
  echo -e "${RED}FAILED: Report generation failed${NC}"
  echo "Response: $REPORT_RESPONSE"
  exit 1
fi
echo "Report ID: $REPORT_ID"

# 8. Verify Report Details (HU13, HU15, HU16)
echo -e "\n8. Verifying Report Details..."
DETAILS_RESPONSE=$(curl -s -X GET "$REPORT_URL/$REPORT_ID" \
  -H "Authorization: Bearer $TOKEN")

# Total Amount should be 40000 (Exp1 only)
TOTAL=$(echo $DETAILS_RESPONSE | grep -o '"totalAmount":40000')
if [ -n "$TOTAL" ]; then
  echo -e "${GREEN}SUCCESS: Total amount correct (400.00)${NC}"
else
  echo -e "${RED}FAILED: Total amount incorrect${NC}"
  echo "Response: $DETAILS_RESPONSE"
  exit 1
fi

# Alice Share: 3000/4000 * 400 = 300.00 (30000)
# Bob Share: 1000/4000 * 400 = 100.00 (10000)
ALICE_SHARE=$(echo $DETAILS_RESPONSE | grep -o '"shareAmount":30000')
BOB_SHARE=$(echo $DETAILS_RESPONSE | grep -o '"shareAmount":10000')

if [ -n "$ALICE_SHARE" ] && [ -n "$BOB_SHARE" ]; then
  echo -e "${GREEN}SUCCESS: Proportional split correct (Alice: 300, Bob: 100)${NC}"
else
  echo -e "${RED}FAILED: Proportional split incorrect${NC}"
  echo "Response: $DETAILS_RESPONSE"
  exit 1
fi

# 9. List Reports (HU17 - History)
echo -e "\n9. Listing Reports..."
LIST_REP_RESPONSE=$(curl -s -X GET $REPORT_URL \
  -H "Authorization: Bearer $TOKEN")

if echo "$LIST_REP_RESPONSE" | grep -q "\"id\":$REPORT_ID"; then
  echo -e "${GREEN}SUCCESS: Report found in list${NC}"
else
  echo -e "${RED}FAILED: Report not found in list${NC}"
  exit 1
fi

echo -e "\n${GREEN}All Epic 3 tests passed!${NC}"
