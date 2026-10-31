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
    // 1. Deduplicate AspNetUsers for sanjeev@advisor.com
    const userRows = await pool.query(`SELECT ctid, "Id", "Email", "FullName" FROM "AspNetUsers" WHERE LOWER("Email") = 'sanjeev@advisor.com'`);
    console.log('AspNetUsers rows:', userRows.rows);
    if (userRows.rows.length > 1) {
      const keepCtid = userRows.rows[0].ctid;
      await pool.query(`DELETE FROM "AspNetUsers" WHERE LOWER("Email") = 'sanjeev@advisor.com' AND ctid != $1`, [keepCtid]);
    }
    await pool.query(`UPDATE "AspNetUsers" SET "FullName" = 'Sanjeev Advisor' WHERE LOWER("Email") = 'sanjeev@advisor.com'`);

    // 2. Clear AdvisorProfiles and insert 1 clean row for Sanjeev Advisor
    await pool.query(`DELETE FROM "AdvisorProfiles"`);
    await pool.query(`
      INSERT INTO "AdvisorProfiles" (
        "Id", "AdvisorId", "LoginId", "DisplayName", "BriefDescription", "AboutMyServices", 
        "ExperienceAndQualifications", "Language", "Fee", "CallRatePerMinute", "VideoRatePerMinute", 
        "EmailServicesCharge", "HourFee", "Category", "CreatedOn", "TotalReviews", "Rating", "IsOnline", 
        "Status", "ProfileStatus", "EmailVerified", "PhoneVerified", "Specialities",
        "DoFreeMins", "IsBusy", "InitReviewCount", "OrderBy", "Ranking", "AcceptTextReading", "IsOnVacation", "IsAcceptCoupon"
      ) VALUES (
        '42a0b813-31c4-4335-8637-b7c525640736', 
        'd3ed2ff2-1a19-43c2-931f-8ff040044973', 
        'd3ed2ff2-1a19-43c2-931f-8ff040044973', 
        'Sanjeev Advisor', 
        '<p>Master Clairvoyant & Spiritual Advisor</p>', 
        '<p>Honest, accurate, and compassionate spiritual guidance for love, career, and life guidance.</p>', 
        '15+ years of professional intuitive readings worldwide.', 
        'English', 
        '3.99', '3.99', '3.99', '0.00', '0.00',
        'Tarot & Psychic Reading', 
        NOW(), 154, '5.0', true, 0, 2, true, true, 
        'Clairvoyance, Love & Relationships, Career & Finance',
        false, false, 0, 0, 0, false, false, false
      )
    `);

    console.log('--- DB SETUP SUCCESSFUL ---');
    const finalAdvisor = await pool.query(`SELECT "Id", "AdvisorId", "DisplayName" FROM "AdvisorProfiles"`);
    console.log('AdvisorProfiles in DB (Count:', finalAdvisor.rows.length, '):', finalAdvisor.rows);

    const finalUsers = await pool.query(`SELECT "Id", "FullName", "Email" FROM "AspNetUsers" WHERE LOWER("Email") LIKE '%advisor%'`);
    console.log('AspNetUsers (Advisors Count:', finalUsers.rows.length, '):', finalUsers.rows);

  } catch (e) {
    console.error('Error fixing tables:', e);
  } finally {
    await pool.end();
  }
}

main();
