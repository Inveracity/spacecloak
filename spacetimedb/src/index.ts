import { schema, table, t } from 'spacetimedb/server';
import { SenderError } from "spacetimedb";
import { type ReducerCtx } from "spacetimedb/server";

const KEYCLOAK_ISSUER = 'http://keycloak:8080/realms/spacecloak';
const KEYCLOAK_CLIENT_IDS = ['spacetimedb-local'];

const spacetimedb = schema({
  person: table(
    { public: true },
    {
      name: t.string(),
    }
  ),
});
export default spacetimedb;

export const init = spacetimedb.init(_ctx => {
  // Called when the module is initially published
});

export const onDisconnect = spacetimedb.clientDisconnected(_ctx => {
  // Called every time a client disconnects
});

export const add = spacetimedb.reducer(
  { name: t.string() },
  (ctx, { name }) => {
    ctx.db.person.insert({ name });
  }
);


export const onConnect = spacetimedb.clientConnected(ctx => {
  const jwt = ctx.senderAuth.jwt;

  if (jwt == null) {
    throw new SenderError('Unauthorized: JWT is required to connect');
  }

  if (jwt.issuer != KEYCLOAK_ISSUER) {
    throw new SenderError(`Unauthorized: Invalid issuer ${jwt.issuer}`);
  }

  if (!jwt.audience.some(aud => KEYCLOAK_CLIENT_IDS.includes(aud))) {
    throw new SenderError(`Unauthorized: Invalid audience ${jwt.audience}`);
  }
});

function ensureAdminAccess(ctx: ReducerCtx<any>) {
  const auth = ctx.senderAuth;
  if (auth.isInternal) {
    return;
  }
  const jwt = auth.jwt;
  if (jwt == null) {
    throw new SenderError('Unauthorized: JWT is required');
  }
  //const roles = jwt.fullPayload['roles'];
  // @ts-expect-error
  const roles = jwt.fullPayload['resource_access']?.['spacetimedb-local']?.['roles'];
  console.log('User roles:', roles);
  if (!Array.isArray(roles) || !roles.includes('admin')) {
    throw new SenderError('Unauthorized: Admin role is required');
  }
}

export const adminonly = spacetimedb.reducer(ctx => {
  ensureAdminAccess(ctx);
});
