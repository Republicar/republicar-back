#!/bin/bash

REGISTER_URL="http://localhost:3001/auth/register"
LOGIN_URL="http://localhost:3001/auth/login"
REPUBLIC_URL="http://localhost:3001/republic"
OCCUPANT_URL="http://localhost:3001/occupant"

TIMESTAMP=$(date +%s)
EMAIL="debug_owner_${TIMESTAMP}@example.com"
PASSWORD="password123"

echo "1. Registering owner..."
curl -s -X POST $REGISTER_URL \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Debug Owner\", \"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}"

echo -e "\n2. Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST $LOGIN_URL \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")
echo "Login response: $LOGIN_RESPONSE"

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
echo "Token: $TOKEN"

echo -e "\n3. Creating republic..."
REP_RESPONSE=$(curl -s -X POST $REPUBLIC_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name": "Debug Republic", "address": "123 St", "rooms": 3}')
echo "Republic response: $REP_RESPONSE"

echo -e "\n4. Adding occupant with income..."
OCC_RESPONSE=$(curl -s -X POST $OCCUPANT_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"name\": \"Alice\", \"email\": \"alice_${TIMESTAMP}@example.com\", \"password\": \"password123\", \"income\": 300000}")
echo "Occupant response: $OCC_RESPONSE"

echo -e "\n5. Checking database..."
sqlite3 local.db "SELECT * FROM users WHERE role='OCCUPANT';"
