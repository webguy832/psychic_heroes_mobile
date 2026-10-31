const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'dbaas-db-8332155-do-user-33774385-0.f.db.ondigitalocean.com',
  port: parseInt(process.env.DB_PORT || '25060'),
  database: process.env.DB_NAME || 'psychicheroes_staging',
  user: process.env.DB_USER || 'doadmin',
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false }
});

async function main() {
  try {
    const res = await pool.query(`SELECT * FROM "AdvisorProfiles"`);
    console.log('Current AdvisorProfiles count:', res.rows.length);
    console.log('Current AdvisorProfiles:', res.rows);

    const users = await pool.query(`SELECT * FROM "AspNetUsers" WHERE LOWER("Email") LIKE '%advisor%' OR LOWER("UserName") LIKE '%advisor%'`);
    console.log('Current Advisor Users count:', users.rows.length);
    console.log('Current Advisor Users:', users.rows);
  } catch (e) {
    console.error('Database query error:', e);
  } finally {
    await pool.end();
  }
}

main();
