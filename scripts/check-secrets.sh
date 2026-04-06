#!/bin/sh
# check-secrets.sh — Scans input for secret patterns.
# Usage:
#   echo "some text" | bash scripts/check-secrets.sh
#   bash scripts/check-secrets.sh file1.dart file2.dart
#
# Exit codes:
#   0 = clean (no secrets found)
#   1 = secrets detected (offending lines printed to stderr)
#
# Excluded: .md files (docs may reference pattern names)

set -e

PATTERNS='sk_live_|sk_test_|service_role|SUPABASE_SERVICE_ROLE_KEY\s*=\s*ey|password\s*[:=]\s*['"'"'""][^\s]{8,}|-----BEGIN.*PRIVATE KEY-----|ghp_[A-Za-z0-9_]{36}|gho_[A-Za-z0-9_]{36}|glpat-[A-Za-z0-9_\-]{20}'

FOUND=0

scan_input() {
  while IFS= read -r line; do
    if echo "$line" | grep -qE "$PATTERNS"; then
      echo "[SECRET DETECTED] $line" >&2
      FOUND=1
    fi
  done
}

if [ $# -eq 0 ]; then
  # Read from stdin
  scan_input
else
  # Read from file arguments, skip .md files
  for file in "$@"; do
    case "$file" in
      *.md) continue ;;
    esac
    if [ -f "$file" ]; then
      while IFS= read -r line; do
        if echo "$line" | grep -qE "$PATTERNS"; then
          echo "[SECRET DETECTED] $file: $line" >&2
          FOUND=1
        fi
      done < "$file"
    fi
  done
fi

if [ "$FOUND" -eq 1 ]; then
  echo "" >&2
  echo "Secret patterns detected. Remove secrets before committing." >&2
  exit 1
fi

exit 0
