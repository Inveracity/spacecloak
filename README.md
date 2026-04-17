# Spacetimedb locally with Keycloak

## Step 1 generate keys for spacetimedb

```sh
# Unless already generated
mkdir -p ./spacetimedb-keys
openssl ecparam -name prime256v1 -genkey -noout -out ./spacetimedb-keys/id_ecdsa
openssl ec -in ./spacetimedb-keys/id_ecdsa -pubout -out ./spacetimedb-keys/id_ecdsa.pub
```

## Bootup the stack

```sh
docker compose up
```

## Configure Keycloak

### Hostsfile setup

Before accessing Keycloak set the following in your hostsfile, this is important when configuring keycloak locally

```
127.0.0.1 keycloak
```

now open `http://keycloak:8080` and login with admin/admin

### Realm

Create a new realm called `spacecloak`

### Client configuration

Create a new client called `spacetimedb-local`

| key | value |
|---|---|
| Client ID | spacetimedb-local |
| Name | spacetimedb-local |
| Description | (optional) |
| Root URL | `http://localhost:5173` |
| Home URL | `http://localhost:5173` |
| Valid redirect URIs | `http://localhost:5173/*` |
| Valid post logout redirect URIs | `http://localhost:5173/*` |
| Web origins | `http://localhost:5173` |
| Admin URL | `http://localhost:5173` |
| Client authentication | ON |
| Authentication flow | Standard Flow, Direct access grants |

Save it

Go to the _Roles_ tab

Create a role named `admin` with the description `spacecloak admins`

Go to the Credentials tab and copy the Client Secret into the `test.sh` script

### Groups

Create a new group called `spacecloak-admins`

Under Role mapping assign the Client role `admin` that has the `spacetimedb-local` client ID

### users

Create a new user called `testuser` and give it the password `password`

Go to the Groups tab  for `testuser` and assign it `spacecloak-admins`


## Test it

```sh
sudo chown -R $(id -u):$(id -g) spacetimedb-keys spacetimedb-data spacetimedb-config
spacetime logout
spacetime login --server-issued-login local
spacetime generate
spacetime publish --clear-database spacecloakdb
spacetime call add Alice
./test.sh
```
