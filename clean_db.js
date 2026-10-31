const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'dbaas-db-8332155-do-user-33774385-0.f.db.ondigitalocean.com',
  port: parseInt(process.env.DB_PORT || '25060'),
  database: process.env.DB_NAME || 'psychicheroes_staging',
  user: process.env.DB_USER || 'doadmin',
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false }
});

async function clean() {
  try {
    console.log('Cleaning DB to have ONLY ONE advisor: Sanjeev Advisor (sanjeev@advisor.com)...');

    // 1. Clean AspNetUsers
    await pool.query(`DELETE FROM "AspNetUsers" WHERE LOWER("Email") != 'sanjeev@advisor.com' AND LOWER("Email") LIKE '%advisor%'`);
    await pool.query(`UPDATE "AspNetUsers" SET "FullName" = 'Sanjeev Advisor' WHERE LOWER("Email") = 'sanjeev@advisor.com'`);

    // 2. Clean AdvisorProfiles
    await pool.query(`DELETE FROM "AdvisorProfiles" WHERE "AdvisorId" != 'd3ed2ff2-1a19-43c2-931f-8ff040044973'`);
    await pool.query(`UPDATE "AdvisorProfiles" SET "DisplayName" = 'Sanjeev Advisor' WHERE "AdvisorId" = 'd3ed2ff2-1a19-43c2-931f-8ff040044973'`);

    // If multiple duplicate rows exist with same AdvisorId, delete duplicates keeping only 1 row
    const profiles = await pool.query(`SELECT ctid, "Id", "DisplayName" FROM "AdvisorProfiles"`);
    console.log('Found profile rows before deduplication:', profiles.rows.length);

    if (profiles.rows.length > 1) {
      const keepCtid = profiles.rows[0].ctid;
      await pool.query(`DELETE FROM "AdvisorProfiles" WHERE ctid != $1`, [keepCtid]);
    }

    const resAdvisor = await pool.query(`SELECT "Id", "AdvisorId", "DisplayName" FROM "AdvisorProfiles"`);
    console.log('Final AdvisorProfiles in DB:', resAdvisor.rows);

    const resUsers = await pool.query(`SELECT "Id", "FullName", "Email" FROM "AspNetUsers" WHERE LOWER("Email") LIKE '%advisor%'`);
    console.log('Final Advisor Users in DB:', resUsers.rows);

  } catch (e) {
    console.error('Error cleaning database:', e);
  } finally {
    await pool.end();
  }
}

clean();
