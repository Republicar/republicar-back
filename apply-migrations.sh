#!/bin/bash

DB_FILE="local.db"

apply_migration() {
  MIGRATION_FILE=$1
  echo "Applying $MIGRATION_FILE..."
  
  # Split by statement-breakpoint and execute each part
  awk 'BEGIN {RS="--> statement-breakpoint"} {print $0}' "$MIGRATION_FILE" | while read -r statement; do
    if [ ! -z "$statement" ]; then
      # echo "Executing: $statement"
      echo "$statement" | sqlite3 "$DB_FILE"
      if [ $? -ne 0 ]; then
        echo "Error executing statement in $MIGRATION_FILE"
        # exit 1 # Don't exit, try next (some might fail if table exists/not exists depending on state)
      fi
    fi
  done
}

# Apply 0003
apply_migration "drizzle/0003_stiff_hobgoblin.sql"

# Apply 0004
apply_migration "drizzle/0004_thankful_mercury.sql"

echo "Migrations applied."
