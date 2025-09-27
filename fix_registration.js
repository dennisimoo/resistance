// Simple test to register a user directly
const bcrypt = require('bcryptjs');
const { Client } = require('pg');

const client = new Client({
    connectionString: 'postgres://resistance_user:resistance_pass@localhost:5433/resistance'
});

async function testRegistration() {
    try {
        await client.connect();
        console.log('Connected to database');

        const username = 'testuser_direct';
        const password = 'testpass';
        const email = 'test_direct@example.com';

        const cryptpass = bcrypt.hashSync(password, 8);

        const result = await client.query(
            'INSERT INTO users(name, passwd, is_valid, email) VALUES ($1, $2, true, $3) RETURNING id',
            [username, cryptpass, email]
        );

        console.log('Registration successful, user ID:', result.rows[0].id);

    } catch (error) {
        console.error('Registration failed:', error);
    } finally {
        await client.end();
    }
}

testRegistration();