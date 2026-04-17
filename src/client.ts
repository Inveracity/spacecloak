/// <reference types="bun-types" />

import * as moduleBindings from './module_bindings';

const connectionBuilder = moduleBindings.DbConnection.builder().withUri('ws://localhost:3000')
    .withDatabaseName('spacecloakdb')
    .withToken(Bun.env.KEYCLOAK_TOKEN)
    .onConnect((conn, identity, token) => {
        console.log('Connected:', identity.toHexString());
        conn.subscriptionBuilder().subscribe('SELECT * FROM person');

    })

const conn = connectionBuilder.build();

conn.db.person.onInsert((ctx, newPerson) => {
    console.log('New person inserted:', newPerson.name);
});
