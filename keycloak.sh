#!/bin/bash
set -e # Exit immediately if a command fails

# Configuration Variables
KC_URL="http://127.0.0.1:8080"
KC_USER="admin"
KC_PASS="admin"
REALM="spacecloak"
CLIENT_ID="spacetimedb-local"
URL_ROOT="http://localhost:5173"
# Use a writable path for the config file inside the container
CONFIG_PATH="/tmp/kcadm.config"

KCADM="/opt/keycloak/bin/kcadm.sh"

echo "Authenticating..."
$KCADM config credentials --server $KC_URL --realm master --user $KC_USER --password $KC_PASS --config $CONFIG_PATH

# 1. Create Realm
if ! $KCADM get realms/$REALM --config $CONFIG_PATH > /dev/null 2>&1; then
    echo "Creating realm: $REALM"
    $KCADM create realms -s realm=$REALM -s enabled=true --config $CONFIG_PATH
else
    echo "Realm '$REALM' already exists."
fi

# 2. Create Client
CLIENT_UUID=$($KCADM get clients -r $REALM -q clientId=$CLIENT_ID --fields id --format csv --noquotes --config $CONFIG_PATH | head -n 1 | tr -dc '[:graph:]')
if [ -z "$CLIENT_UUID" ]; then
    echo "Creating client: $CLIENT_ID"
    # Note: the -i flag returns the new UUID
    CLIENT_UUID=$($KCADM create clients -r $REALM \
      -s clientId=$CLIENT_ID -s name=$CLIENT_ID -s enabled=true \
      -s publicClient=false -s standardFlowEnabled=true -s directAccessGrantsEnabled=true \
      -s rootUrl="$URL_ROOT" -s baseUrl="$URL_ROOT" \
      -s "redirectUris=[\"$URL_ROOT/*\"]" -s "webOrigins=[\"$URL_ROOT\"]" \
      -s adminUrl="$URL_ROOT" -i --config $CONFIG_PATH)
else
    echo "Client '$CLIENT_ID' already exists."
fi

# 3. Create Client Role
if ! $KCADM get clients/$CLIENT_UUID/roles/admin -r $REALM --config $CONFIG_PATH > /dev/null 2>&1; then
    echo "Creating client role: admin"
    $KCADM create clients/$CLIENT_UUID/roles -r $REALM -s name=admin -s "description=spacecloak admins" --config $CONFIG_PATH
fi

# 4. Save Secret to a writable location (/tmp)
CLIENT_SECRET=$($KCADM get clients/$CLIENT_UUID/client-secret -r $REALM --fields value --format csv --noquotes --config $CONFIG_PATH)
echo "export CLIENT_SECRET=$CLIENT_SECRET" > /tmp/client.sh
echo "Client secret saved to /tmp/client.sh inside container"

# 5. Create Group
GROUP_ID=$($KCADM get groups -r $REALM -q name=spacecloak-admins --fields id --format csv --noquotes --config $CONFIG_PATH | head -n 1 | tr -dc '[:graph:]')
if [ -z "$GROUP_ID" ]; then
    echo "Creating group: spacecloak-admins"
    GROUP_ID=$($KCADM create groups -r $REALM -s name=spacecloak-admins -i --config $CONFIG_PATH)
fi

# 6. Assign Client Role to Group
echo "Assigning 'admin' role to group..."

# Fetch the role object (this is already a JSON string)
ROLE_REPR=$($KCADM get clients/$CLIENT_UUID/roles/admin -r $REALM --config $CONFIG_PATH)

# Ensure we wrap the role in brackets [ ] because the API expects a JSON array
echo "[$ROLE_REPR]" | $KCADM create groups/$GROUP_ID/role-mappings/clients/$CLIENT_UUID -r $REALM -f - --config $CONFIG_PATH

# 7. Create User
USER_ID=$($KCADM get users -r $REALM -q username=testuser --fields id --format csv --noquotes --config $CONFIG_PATH | head -n 1 | tr -dc '[:graph:]')
if [ -z "$USER_ID" ]; then
    echo "Creating user: testuser"
    USER_ID=$($KCADM create users -r $REALM -s username=testuser -s enabled=true -i --config $CONFIG_PATH)
    $KCADM set-password -r $REALM --username testuser --new-password password --config $CONFIG_PATH
fi

# 8. Assign User to Group
$KCADM update users/$USER_ID/groups/$GROUP_ID -r $REALM -n -s realm=$REALM -s userId=$USER_ID -s groupId=$GROUP_ID --config $CONFIG_PATH

# 9. Audience Mapper
if ! $KCADM get clients/$CLIENT_UUID/protocol-mappers/models -r $REALM --config $CONFIG_PATH | grep -q "spacetimedb-audience"; then
    echo "Creating audience mapper..."
    $KCADM create clients/$CLIENT_UUID/protocol-mappers/models -r $REALM \
      -s name=spacetimedb-audience \
      -s protocol=openid-connect \
      -s protocolMapper=oidc-audience-mapper \
      -s config='{"included.client.audience":"spacetimedb-local","id.token.claim":"false","access.token.claim":"true"}' \
      --config $CONFIG_PATH
fi

cat /tmp/client.sh
echo "Success!"
