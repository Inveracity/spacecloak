import * as moduleBindings from './module_bindings';

const connectionBuilder = moduleBindings.DbConnection.builder().withUri('ws://localhost:3000')
    .withDatabaseName('spacecloakdb')
    .onConnect((conn, identity, token) => {
        console.log('Connected:', identity.toHexString());
        conn.subscriptionBuilder().subscribe('SELECT * FROM person');
    })

const conn = connectionBuilder.build();

conn.reducers.sayHello().then(() => {
    console.log('Called sayHello reducer');
}).catch(err => {
    console.error('Error calling sayHello reducer:', err);
});

setTimeout(() => {
    conn.disconnect();
    console.log('Disconnected');
}, 10000);
