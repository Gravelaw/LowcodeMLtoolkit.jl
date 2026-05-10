#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/infra/docker/compose.dev.yml"
REALM="${JULIAFLOW_KEYCLOAK_REALM:-juliaflow}"
CLIENT_ID="${JULIAFLOW_KEYCLOAK_CLIENT_ID:-juliaflow-gateway}"
USER_NAME="${JULIAFLOW_KEYCLOAK_USER:-user-owner}"
USER_PASSWORD="${JULIAFLOW_KEYCLOAK_PASSWORD:-owner-secret}"
GATEWAY_PORT="${JULIAFLOW_GATEWAY_PORT:-18088}"
GATEWAY_URL="http://127.0.0.1:${GATEWAY_PORT}"
PG_URL="${JULIAFLOW_TEST_POSTGRES_URL:-postgresql://juliaflow:juliaflow@127.0.0.1:5432/juliaflow}"
PG_SCHEMA="${JULIAFLOW_TEST_POSTGRES_SCHEMA:-juliaflow_auth_smoke_$(date +%s)}"
TMP_DIR="${JULIAFLOW_SMOKE_TMP:-$ROOT_DIR/tmp/auth-smoke}"
mkdir -p "$TMP_DIR"

json_field() {
  python3 -c '
import json, sys
path = sys.argv[1].split(".")
value = json.load(sys.stdin)
for part in path:
    if isinstance(value, list):
        value = value[int(part)]
    else:
        value = value[part]
print(value)
' "$1"
}

kc_token() {
  curl -fsS -X POST 'http://127.0.0.1:8080/realms/master/protocol/openid-connect/token' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=admin-cli' \
    --data-urlencode 'username=admin' \
    --data-urlencode 'password=admin' | json_field access_token
}

kc_get() { curl -fsS -H "Authorization: Bearer $ADMIN_TOKEN" "http://127.0.0.1:8080/admin/realms/$1"; }
kc_post() { curl -fsS -o /dev/null -w '%{http_code}' -X POST -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' -d "$3" "http://127.0.0.1:8080/admin/realms/$1/$2"; }

docker compose -f "$COMPOSE_FILE" up -d postgres keycloak
for _ in $(seq 1 90); do
  if curl -fsS http://127.0.0.1:8080/realms/master/.well-known/openid-configuration >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
ADMIN_TOKEN="$(kc_token)"

if ! kc_get "$REALM" >/dev/null 2>&1; then
  curl -fsS -o /dev/null -X POST 'http://127.0.0.1:8080/admin/realms' \
    -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
    -d "{\"realm\":\"$REALM\",\"enabled\":true}"
fi

CLIENTS_JSON="$(curl -fsS -H "Authorization: Bearer $ADMIN_TOKEN" "http://127.0.0.1:8080/admin/realms/$REALM/clients?clientId=$CLIENT_ID")"
CLIENT_UUID="$(printf '%s' "$CLIENTS_JSON" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data[0]["id"] if data else "")')"
if [[ -z "$CLIENT_UUID" ]]; then
  curl -fsS -o /dev/null -X POST "http://127.0.0.1:8080/admin/realms/$REALM/clients" \
    -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
    -d "{\"clientId\":\"$CLIENT_ID\",\"enabled\":true,\"publicClient\":true,\"directAccessGrantsEnabled\":true,\"protocol\":\"openid-connect\"}"
  CLIENTS_JSON="$(curl -fsS -H "Authorization: Bearer $ADMIN_TOKEN" "http://127.0.0.1:8080/admin/realms/$REALM/clients?clientId=$CLIENT_ID")"
  CLIENT_UUID="$(printf '%s' "$CLIENTS_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["id"])')"
fi

for mapper in juliaflow-role:juliaflow_role juliaflow-workspace:juliaflow_workspace; do
  NAME="${mapper%%:*}"; ATTR="${mapper##*:}"
  curl -fsS -o /dev/null -w '' -X POST "http://127.0.0.1:8080/admin/realms/$REALM/clients/$CLIENT_UUID/protocol-mappers/models" \
    -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
    -d "{\"name\":\"$NAME\",\"protocol\":\"openid-connect\",\"protocolMapper\":\"oidc-usermodel-attribute-mapper\",\"config\":{\"user.attribute\":\"$ATTR\",\"claim.name\":\"$ATTR\",\"jsonType.label\":\"String\",\"access.token.claim\":\"true\",\"id.token.claim\":\"true\"}}" || true
done

curl -fsS -o /dev/null -w '' -X POST "http://127.0.0.1:8080/admin/realms/$REALM/roles" \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"owner","description":"JuliaFlow owner smoke role"}' || true

USERS_JSON="$(curl -fsS -H "Authorization: Bearer $ADMIN_TOKEN" "http://127.0.0.1:8080/admin/realms/$REALM/users?username=$USER_NAME")"
USER_UUID="$(printf '%s' "$USERS_JSON" | python3 -c 'import json,sys; data=json.load(sys.stdin); print(data[0]["id"] if data else "")')"
if [[ -z "$USER_UUID" ]]; then
  curl -fsS -o /dev/null -X POST "http://127.0.0.1:8080/admin/realms/$REALM/users" \
    -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
    -d "{\"username\":\"$USER_NAME\",\"firstName\":\"Owner\",\"lastName\":\"User\",\"email\":\"owner@example.test\",\"enabled\":true,\"emailVerified\":true,\"requiredActions\":[],\"attributes\":{\"juliaflow_role\":[\"owner\"],\"juliaflow_workspace\":[\"workspace-a\"]}}"
  USERS_JSON="$(curl -fsS -H "Authorization: Bearer $ADMIN_TOKEN" "http://127.0.0.1:8080/admin/realms/$REALM/users?username=$USER_NAME")"
  USER_UUID="$(printf '%s' "$USERS_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["id"])')"
fi
curl -fsS -o /dev/null -X PUT "http://127.0.0.1:8080/admin/realms/$REALM/users/$USER_UUID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
  -d "{\"username\":\"$USER_NAME\",\"firstName\":\"Owner\",\"lastName\":\"User\",\"email\":\"owner@example.test\",\"enabled\":true,\"emailVerified\":true,\"requiredActions\":[],\"attributes\":{\"juliaflow_role\":[\"owner\"],\"juliaflow_workspace\":[\"workspace-a\"]}}"
curl -fsS -o /dev/null -X PUT "http://127.0.0.1:8080/admin/realms/$REALM/users/$USER_UUID/reset-password" \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
  -d "{\"type\":\"password\",\"value\":\"$USER_PASSWORD\",\"temporary\":false}"
OWNER_ROLE_JSON="$(curl -fsS -H "Authorization: Bearer $ADMIN_TOKEN" "http://127.0.0.1:8080/admin/realms/$REALM/roles/owner")"
curl -fsS -o /dev/null -X POST "http://127.0.0.1:8080/admin/realms/$REALM/users/$USER_UUID/role-mappings/realm" \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H 'Content-Type: application/json' \
  -d "[$OWNER_ROLE_JSON]" || true

TOKEN="$(curl -fsS -X POST "http://127.0.0.1:8080/realms/$REALM/protocol/openid-connect/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=password' \
  --data-urlencode "client_id=$CLIENT_ID" \
  --data-urlencode "username=$USER_NAME" \
  --data-urlencode "password=$USER_PASSWORD" | json_field access_token)"
PRINCIPAL_ID="$(printf '%s' "$TOKEN" | python3 -c 'import base64,json,sys; token=sys.stdin.read().strip(); seg=token.split(".")[1]; print(json.loads(base64.urlsafe_b64decode(seg + "=" * (-len(seg) % 4)))["sub"])')"

rm -f "$TMP_DIR/gateway.log" "$TMP_DIR/gateway.pid"
(
  JULIAFLOW_AUTH_MODE=oidc \
  JULIAFLOW_OIDC_DISCOVERY_URL="http://127.0.0.1:8080/realms/$REALM/.well-known/openid-configuration" \
  JULIAFLOW_OIDC_AUDIENCE=account \
  JULIAFLOW_OIDC_ALLOWED_ALGORITHMS=RS256 \
  JULIAFLOW_GATEWAY_BACKEND=postgres \
  JULIAFLOW_DATABASE_URL="$PG_URL" \
  JULIAFLOW_DATABASE_SCHEMA="$PG_SCHEMA" \
  JULIAFLOW_GATEWAY_PORT="$GATEWAY_PORT" \
  julia --project="$ROOT_DIR" "$ROOT_DIR/scripts/run-api-gateway.jl" >"$TMP_DIR/gateway.log" 2>&1
) &
GATEWAY_PID=$!
trap 'kill $GATEWAY_PID >/dev/null 2>&1 || true' EXIT
for _ in $(seq 1 90); do
  if curl -fsS "$GATEWAY_URL/health" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

AUTH=(-H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -H 'X-JuliaFlow-Workspace: workspace-a')
curl -fsS "${AUTH[@]}" "$GATEWAY_URL/api/v1/workflows" >/dev/null
curl -fsS -X PUT "${AUTH[@]}" "$GATEWAY_URL/api/v1/admin/auth/directory" \
  -d "{\"users\":[{\"principalId\":\"$PRINCIPAL_ID\",\"displayName\":\"Owner User\",\"email\":\"owner@example.test\",\"active\":true}],\"workspaces\":[{\"workspaceId\":\"workspace-a\",\"name\":\"Workspace A\",\"active\":true}]}" >/dev/null
curl -fsS -X PUT "${AUTH[@]}" "$GATEWAY_URL/api/v1/admin/auth/policies" \
  -d "{\"roleBindings\":[{\"principalId\":\"$PRINCIPAL_ID\",\"workspaceId\":\"workspace-a\",\"role\":\"owner\"}],\"resourcePolicies\":[{\"resourceType\":\"workflow\",\"resourceId\":\"wf-foundation\",\"workspaceId\":\"workspace-a\",\"permissionsByRole\":{\"owner\":[\"workflow:read\",\"workflow:write\",\"workflow:execute\",\"checkpoint:read\",\"checkpoint:write\",\"hub:read\",\"hub:install\",\"dashboard:publish\",\"policy:read\",\"policy:write\",\"audit:read\"]}}]}" >/dev/null
curl -fsS "${AUTH[@]}" "$GATEWAY_URL/api/v1/admin/auth/directory" | grep -q 'Owner User'
curl -fsS "${AUTH[@]}" "$GATEWAY_URL/api/v1/admin/auth/policies" | grep -q 'roleBindings'
curl -fsS "${AUTH[@]}" "$GATEWAY_URL/api/v1/audit/actions?limit=10" | tee "$TMP_DIR/audit.json" | grep -q 'auth.policy.update'

python3 - <<PY
import json
print(json.dumps({
  "status": "passed",
  "issuer": "http://127.0.0.1:8080/realms/$REALM",
  "algorithm": "RS256",
  "principalId": "$PRINCIPAL_ID",
  "repositoryBackend": "postgres",
  "postgresSchema": "$PG_SCHEMA",
  "auditEvidence": "$TMP_DIR/audit.json"
}))
PY
