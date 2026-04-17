NAME=$1

# if NAME is empty show usage
if [ -z "$NAME" ]; then
  echo "Usage: $0 <name>"
  exit 1
fi

TOKEN=$(curl -s -X POST -H "Host: keycloak:8080" \
  http://localhost:8080/realms/spacecloak/protocol/openid-connect/token \
  -d "client_id=spacetimedb-local" \
  -d "client_secret=IOXQcRQDn42ewxHfGSrfUpLh24HNFvD9" \
  -d "username=testuser" \
  -d "password=password" \
  -d "grant_type=password" )

curl -X POST http://localhost:3000/v1/database/spacecloakdb/call/add \
  -H "Authorization: Bearer $(echo $TOKEN | jq -r .access_token)" \
  -H "Content-Type: application/json" \
  -d "[\"$NAME\"]"
