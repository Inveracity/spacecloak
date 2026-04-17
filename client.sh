# check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, please install it to run this script"
    exit
fi

TOKEN=$(curl -s -X POST -H "Host: keycloak:8080" \
  http://localhost:8080/realms/spacecloak/protocol/openid-connect/token \
  -d "client_id=spacetimedb-local" \
  -d "client_secret=IOXQcRQDn42ewxHfGSrfUpLh24HNFvD9" \
  -d "username=testuser" \
  -d "password=password" \
  -d "grant_type=password" )

export KEYCLOAK_TOKEN=$(echo $TOKEN | jq -r .access_token)

# Testing the admin only endpoint
curl -X POST http://localhost:3000/v1/database/spacecloakdb/call/adminonly \
  -H "Authorization: Bearer $KEYCLOAK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[]'

bun run src/client.ts
