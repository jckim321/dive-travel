#!/usr/bin/env bash
# Ensure the R2 bucket's managed r2.dev public URL stays enabled.
# Requires: CLOUDFLARE_API_TOKEN (Account R2 Edit), R2_ACCOUNT_ID, R2_BUCKET_NAME
set -euo pipefail

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "CLOUDFLARE_API_TOKEN is not set — skip R2 public-access enforce."
  echo "Create a Cloudflare API token with Account → R2 → Edit, then:"
  echo "  gh secret set CLOUDFLARE_API_TOKEN"
  exit 0
fi

: "${R2_ACCOUNT_ID:?R2_ACCOUNT_ID is required}"
BUCKET="${R2_BUCKET_NAME:-dive-travel-app-storage}"

API="https://api.cloudflare.com/client/v4/accounts/${R2_ACCOUNT_ID}/r2/buckets/${BUCKET}/domains/managed"

echo "Checking r2.dev public access for bucket '${BUCKET}'..."
before="$(curl -sS -X GET "$API" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json")"
echo "GET managed domain: ${before}"

echo "Enforcing enabled=true..."
after="$(curl -sS -X PUT "$API" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"enabled":true}')"
echo "PUT managed domain: ${after}"

echo "$after" | python3 -c '
import json, sys
body = json.load(sys.stdin)
if not body.get("success"):
    raise SystemExit("Cloudflare API reported failure: " + json.dumps(body))
result = body.get("result") or {}
if result.get("enabled") is not True:
    raise SystemExit("r2.dev public access is still disabled after PUT")
print("OK — r2.dev public access enabled for:", result.get("domain", "(domain unknown)"))
'
