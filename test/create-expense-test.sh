#!/bin/bash

# Base URL
REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"
EXPENSE_URL="http://localhost:3001/expense"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Starting Create Expense Test..."

# Unique email for this run
TIMESTAMP=$(date +%s)
OWNER_EMAIL="owner_expense_${TIMESTAMP}@example.com"
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

# 4. Create Expense (Valid)
echo -e "\n4. Creating Expense (Valid)..."
EXPENSE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Electricity Bill\", \"amount\": 15000, \"date\": \"2023-10-27T10:00:00Z\"}")

if [ "$EXPENSE_RESPONSE" -eq 201 ]; then
  echo -e "${GREEN}SUCCESS: Expense created (201)${NC}"
else
  echo -e "${RED}FAILED: Expense creation failed ($EXPENSE_RESPONSE)${NC}"
  exit 1
fi

# 5. Create Expense (Negative Amount)
echo -e "\n5. Creating Expense (Negative Amount)..."
NEGATIVE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"description\": \"Bad Expense\", \"amount\": -100, \"date\": \"2023-10-27T10:00:00Z\"}")

if [ "$NEGATIVE_RESPONSE" -eq 400 ]; then
  echo -e "${GREEN}SUCCESS: Negative amount rejected (400)${NC}"
else
  echo -e "${RED}FAILED: Negative amount not rejected ($NEGATIVE_RESPONSE)${NC}"
  exit 1
fi

# 6. Create Expense (Missing Description)
echo -e "\n6. Creating Expense (Missing Description)..."
MISSING_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $EXPENSE_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"amount\": 100, \"date\": \"2023-10-27T10:00:00Z\"}")

if [ "$MISSING_RESPONSE" -eq 400 ]; then
  echo -e "${GREEN}SUCCESS: Missing description rejected (400)${NC}"
else
  echo -e "${RED}FAILED: Missing description not rejected ($MISSING_RESPONSE)${NC}"
  exit 1
fi

echo -e "\n${GREEN}All create expense tests passed!${NC}"
