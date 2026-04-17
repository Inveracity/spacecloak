spacetime sql "SELECT * FROM person"

TOKEN=$(curl -s -X POST -H "Host: keycloak:8080" \
  http://localhost:8080/realms/spacecloak/protocol/openid-connect/token \
  -d "client_id=spacetimedb-local" \
  -d "client_secret=IOXQcRQDn42ewxHfGSrfUpLh24HNFvD9" \
  -d "username=testuser" \
  -d "password=password" \
  -d "grant_type=password" )

  echo $TOKEN
  echo $TOKEN | jq -r .access_token | cut -d. -f2 | base64 -d 2>/dev/null | jq .

$TOKEN bun run src/client.ts

# curl -X POST http://localhost:3000/v1/database/spacecloakdb/call/say_hello \
#   -H "Authorization: Bearer $(echo $TOKEN | jq -r .access_token)" \
#   -H "Content-Type: application/json" \
#   -d '[]'


# curl -X POST http://localhost:3000/v1/database/spacecloakdb/call/adminonly \
#   -H "Authorization: Bearer $(echo $TOKEN | jq -r .access_token)" \
#   -H "Content-Type: application/json" \
#   -d '[]'
