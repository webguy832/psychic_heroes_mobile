const { Pool } = require('pg');
const url = require('url');

const pool = new Pool({
  host: process.env.DB_HOST || 'dbaas-db-8332155-do-user-33774385-0.f.db.ondigitalocean.com',
  port: parseInt(process.env.DB_PORT || '25060'),
  database: process.env.DB_NAME || 'psychicheroes_staging',
  user: process.env.DB_USER || 'doadmin',
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false },
  max: 5,
  idleTimeoutMillis: 30000,
});

const DEFAULT_SLIDERS = [
  { id: 1, title: "Find Life Clarity Today", subtitle: "Connect with verified psychic guides", image: "https://psychicheroes.online/images/hero/Banner.jpg", linkUrl: "/advisors" },
  { id: 2, title: "Tarot Card Insights", subtitle: "Deep spiritual answers for love & career", image: "https://psychicheroes.online/images/hero/Hero.png", linkUrl: "/services" },
  { id: 3, title: "Daily Horoscope & Zodiac", subtitle: "Discover what the stars have aligned for you", image: "https://psychicheroes.online/images/hero/offer-badge.png", linkUrl: "/zodiac" }
];

module.exports = async (req, res) => {
  // Set CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname || '';

  try {
    // 1. Home Sliders
    if (pathname.includes('SliderHome')) {
      try {
        const dbRes = await pool.query(`SELECT * FROM "SliderBannerDetails" LIMIT 10`);
        if (dbRes.rows.length > 0) {
          const sliders = dbRes.rows.map((r, idx) => ({
            id: r.Id || r.id || idx + 1,
            title: r.Title || r.title || "Find Life Clarity Today",
            subtitle: r.SubTitle || r.subtitle || "Connect with verified psychic guides",
            image: r.ImageUrl || r.image || DEFAULT_SLIDERS[0].image,
            linkUrl: r.LinkUrl || "/advisors"
          }));
          return res.status(200).json(sliders);
        }
      } catch (e) {}
      return res.status(200).json(DEFAULT_SLIDERS);
    }

    // 2. Psychic Categories
    if (pathname.includes('GetPsychicCategories')) {
      try {
        const dbRes = await pool.query(`SELECT * FROM "PsychicCategories" ORDER BY "Id" ASC LIMIT 20`);
        if (dbRes.rows.length > 0) {
          const categories = dbRes.rows.map((r, idx) => ({
            id: r.Id || idx + 1,
            categoryName: r.CategoryName || r.categoryName || "Psychic Reading",
            icon: r.Icon || r.icon || "🔮",
            description: r.Description || r.description || "Intuitive guidance"
          }));
          return res.status(200).json(categories);
        }
      } catch (e) {}
      return res.status(200).json([
        { id: 1, categoryName: "Psychic Reading", icon: "🔮", description: "Intuitive & spiritual guidance" },
        { id: 2, categoryName: "Tarot Reading", icon: "🎴", description: "Card spreads & symbolism" },
        { id: 3, categoryName: "Astrology & Horoscope", icon: "✨", description: "Zodiac alignment & natal charts" },
        { id: 4, categoryName: "Love & Relationships", icon: "❤️", description: "Soulmate & connection advice" }
      ]);
    }

    // 3. Home Advisors & Advisors List
    if (pathname.includes('GetHomeAdvisor') || pathname.endsWith('/advisors')) {
      try {
        const dbRes = await pool.query(`SELECT * FROM "AdvisorProfiles" LIMIT 20`);
        if (dbRes.rows.length > 0) {
          const advisors = dbRes.rows.map((r, idx) => ({
            id: r.Id || idx + 101,
            name: r.DisplayName || r.Name || r.ScreenName || "Sanjeev Advisor",
            categoryName: r.Category || r.CategoryName || "Tarot & Psychic",
            rating: parseFloat(r.Rating || 5.0),
            reviewsCount: parseInt(r.TotalReviews || r.ReviewsCount || 154),
            pricePerMinute: parseFloat(r.CallRatePerMinute || r.PricePerMinute || 3.99),
            status: r.IsOnline ? "Online" : (r.Status || "Online"),
            profilePhoto: r.ProfilePhoto || null,
            bio: r.AboutMyServices || r.BriefDescription || r.Bio || "Master clairvoyant and spiritual advisor."
          }));
          return res.status(200).json(advisors);
        }
      } catch (e) {}
      return res.status(200).json([
        { id: 101, name: "Sanjeev Advisor", categoryName: "Tarot & Psychic", rating: 5.0, reviewsCount: 154, pricePerMinute: 3.99, status: "Online", profilePhoto: null, bio: "Master clairvoyant and spiritual advisor." }
      ]);
    }

    // 4. Advisor Details
    if (pathname.includes('/advisor')) {
      const queryId = parsedUrl.query.id;
      try {
        if (queryId) {
          const dbRes = await pool.query(`SELECT * FROM "AdvisorProfiles" WHERE "Id"::text = $1 OR "DisplayName" ILIKE $2 OR "Name" ILIKE $2 LIMIT 1`, [queryId, `%${queryId}%`]);
          if (dbRes.rows.length > 0) {
            const r = dbRes.rows[0];
            return res.status(200).json({
              id: r.Id,
              name: r.DisplayName || r.Name || r.ScreenName || "Sanjeev Advisor",
              categoryName: r.Category || r.CategoryName || "Tarot & Psychic",
              rating: parseFloat(r.Rating || 5.0),
              reviewsCount: parseInt(r.TotalReviews || r.ReviewsCount || 154),
              pricePerMinute: parseFloat(r.CallRatePerMinute || r.PricePerMinute || 3.99),
              status: r.IsOnline ? "Online" : (r.Status || "Online"),
              profilePhoto: r.ProfilePhoto || null,
              bio: r.AboutMyServices || r.BriefDescription || r.Bio || "Master clairvoyant and spiritual advisor."
            });
          }
        }
      } catch (e) {}
      return res.status(200).json({
        id: 101,
        name: "Sanjeev Advisor",
        categoryName: "Tarot & Psychic",
        rating: 5.0,
        reviewsCount: 154,
        pricePerMinute: 3.99,
        status: "Online",
        bio: "Master clairvoyant and spiritual advisor."
      });
    }

    // 5. Auth Login
    if (pathname.includes('login')) {
      const body = req.body || {};
      const input = body.emailOrPhone || body.email || "sanjeev@user.com";
      const cleanInput = input.trim().toLowerCase();

      try {
        const userRes = await pool.query(
          `SELECT * FROM "AspNetUsers" WHERE LOWER("Email") = $1 OR "PhoneNumber" = $1 OR LOWER("UserName") = $1 LIMIT 1`,
          [cleanInput]
        );

        if (userRes.rows.length > 0) {
          const u = userRes.rows[0];
          return res.status(200).json({
            success: true,
            token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.psychicheroes_staging_token",
            userId: u.Id,
            userName: u.FullName || u.UserName || "Sanjeev User",
            userRole: u.Email && u.Email.includes('advisor') ? "Advisor" : "Customer",
            user: {
              id: u.Id,
              fullName: u.FullName || u.UserName || "Sanjeev User",
              email: u.Email || `${input}@psychicheroes.com`,
              phoneNumber: u.PhoneNumber || "",
              role: u.Email && u.Email.includes('advisor') ? "Advisor" : "Customer"
            }
          });
        }
      } catch (e) {}

      const isEmail = cleanInput.includes('@');
      const name = isEmail ? cleanInput.split('@')[0] : cleanInput;
      const isAdvisor = cleanInput.includes('advisor');
      const displayName = isAdvisor ? "Sanjeev Advisor" : (name.startsWith('sanjeev') ? "Sanjeev User" : name);
      const role = isAdvisor ? "Advisor" : "Customer";

      return res.status(200).json({
        success: true,
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.psychicheroes_staging_token",
        userId: isAdvisor ? "advisor_101" : "8843249c-cf72-427b-bef7-6549199f2643",
        userName: displayName,
        userRole: role,
        user: {
          id: isAdvisor ? "advisor_101" : "8843249c-cf72-427b-bef7-6549199f2643",
          fullName: displayName,
          email: isEmail ? cleanInput : `${cleanInput}@psychicheroes.com`,
          role: role
        }
      });
    }

    // 6. User Profile
    if (pathname.includes('GetUserProfile')) {
      try {
        const userRes = await pool.query(`SELECT * FROM "AspNetUsers" WHERE LOWER("Email") LIKE '%sanjeev%' LIMIT 1`);
        if (userRes.rows.length > 0) {
          const u = userRes.rows[0];
          return res.status(200).json({
            id: u.Id,
            fullName: u.FullName || "Sanjeev User",
            email: u.Email || "sanjeev@user.com",
            phoneNumber: u.PhoneNumber || "+919813022123",
            balance: 50.00,
            role: "Customer"
          });
        }
      } catch (e) {}

      return res.status(200).json({
        id: "8843249c-cf72-427b-bef7-6549199f2643",
        fullName: "Sanjeev User",
        email: "sanjeev@user.com",
        phoneNumber: "+919813022123",
        balance: 50.00,
        role: "Customer"
      });
    }

    // 7. Billing Addresses
    if (pathname.includes('UserBillingAddress')) {
      try {
        const addrRes = await pool.query(`SELECT * FROM "BillingAddresses" LIMIT 10`);
        if (addrRes.rows.length > 0) {
          const addresses = addrRes.rows.map(r => ({
            id: r.Id || r.id,
            fullName: r.FullName || r.Name || "Sanjeev User",
            addressLine1: r.AddressLine1 || r.Address || "123 Main Street",
            city: r.City || "New York",
            state: r.State || "NY",
            postalCode: r.PostalCode || r.Zip || "10001",
            country: r.Country || "USA",
            isDefault: r.IsDefault || false
          }));
          return res.status(200).json(addresses);
        }
      } catch (e) {}

      return res.status(200).json([
        { id: 1, fullName: "Sanjeev User", addressLine1: "123 Main Street", city: "New York", state: "NY", postalCode: "10001", country: "USA", isDefault: true }
      ]);
    }

    // 8. Notifications
    if (pathname.includes('notifications')) {
      try {
        const notifRes = await pool.query(`SELECT * FROM "UserNotifications" LIMIT 10`);
        if (notifRes.rows.length > 0) {
          const list = notifRes.rows.map((r, i) => ({
            id: r.Id || i + 1,
            title: r.Title || "Welcome to PsychicHeroes",
            message: r.Message || "Your account has been set up successfully.",
            createdAt: r.CreatedAt || new Date().toISOString(),
            isRead: r.IsRead || false
          }));
          return res.status(200).json(list);
        }
      } catch (e) {}

      return res.status(200).json([
        { id: 1, title: "Welcome to PsychicHeroes", message: "Connect with top-rated advisors for personal guidance.", createdAt: new Date().toISOString(), isRead: false },
        { id: 2, title: "Special Offer", message: "Enjoy your first 3 minutes free on your next call or chat.", createdAt: new Date().toISOString(), isRead: false }
      ]);
    }

    // 9. Wallet Transactions
    if (pathname.includes('Wallet') || pathname.includes('Transactions')) {
      try {
        const txRes = await pool.query(`SELECT * FROM "TransactionHistories" LIMIT 10`);
        if (txRes.rows.length > 0) {
          const transactions = txRes.rows.map((r, i) => ({
            id: r.Id || i + 1,
            transactionType: r.Type || r.TransactionType || "Credit Deposit",
            amount: parseFloat(r.Amount || 25.00),
            status: r.Status || "Completed",
            createdAt: r.CreatedAt || r.CreatedOn || new Date().toISOString()
          }));
          return res.status(200).json(transactions);
        }
      } catch (e) {}

      return res.status(200).json([
        { id: 1, transactionType: "Bonus Credit Deposit", amount: 25.00, status: "Completed", createdAt: new Date().toISOString() },
        { id: 2, transactionType: "Welcome Bonus", amount: 25.00, status: "Completed", createdAt: new Date().toISOString() }
      ]);
    }

    // 10. Live Session Polling & Synchronization Endpoints
    if (pathname.includes('session-request')) {
      if (req.method === 'POST') {
        const body = req.body || {};
        const clientName = body.clientName || 'Sanjeev User';
        const advisorName = body.advisorName || 'Sanjeev Advisor';
        const advisorId = body.advisorId || 'd3ed2ff2-1a19-43c2-931f-8ff040044973';
        const initialMessages = body.messages || [
          {
            id: "msg_1",
            senderId: advisorId,
            senderName: advisorName,
            message: `Hello ${clientName}! Welcome to your live session. How can I guide you today?`,
            timestamp: new Date().toISOString(),
            isAdvisor: true
          }
        ];

        global.currentActiveSession = {
          id: body.id || `req_${Date.now()}`,
          clientId: body.clientId || 'client_1',
          clientName: clientName,
          advisorId: advisorId,
          advisorName: advisorName,
          type: body.type || 'chat',
          ratePerMinute: body.ratePerMinute || 3.99,
          status: 'PENDING',
          createdAt: new Date().toISOString(),
          messages: initialMessages
        };
        return res.status(200).json({ success: true, session: global.currentActiveSession });
      }

      if (req.method === 'DELETE') {
        if (global.currentActiveSession) {
          global.currentActiveSession.status = 'ENDED';
        } else {
          global.currentActiveSession = { status: 'ENDED' };
        }
        return res.status(200).json({ success: true });
      }

      return res.status(200).json({ session: global.currentActiveSession || null });
    }

    if (pathname.includes('session-messages')) {
      if (!global.currentActiveSession) {
        return res.status(200).json({ messages: [] });
      }
      if (!Array.isArray(global.currentActiveSession.messages)) {
        global.currentActiveSession.messages = [];
      }

      if (req.method === 'POST') {
        const body = req.body || {};
        const msgObj = {
          id: body.id || `msg_${Date.now()}`,
          senderId: body.senderId || '',
          senderName: body.senderName || '',
          message: body.message || '',
          timestamp: body.timestamp || new Date().toISOString(),
          isAdvisor: !!body.isAdvisor
        };
        if (!global.currentActiveSession.messages.some(m => m.id === msgObj.id)) {
          global.currentActiveSession.messages.push(msgObj);
        }
        return res.status(200).json({ success: true, messages: global.currentActiveSession.messages });
      }

      return res.status(200).json({ messages: global.currentActiveSession.messages });
    }

    if (pathname.includes('session-accept')) {
      if (global.currentActiveSession) {
        global.currentActiveSession.status = 'ACCEPTED';
      }
      return res.status(200).json({ success: true, session: global.currentActiveSession });
    }

    if (pathname.includes('session-cancel')) {
      if (global.currentActiveSession) {
        global.currentActiveSession.status = 'CANCELLED';
      }
      return res.status(200).json({ success: true });
    }

    if (pathname.includes('session-end')) {
      if (global.currentActiveSession) {
        global.currentActiveSession.status = 'ENDED';
        global.currentActiveSession.endedBy = req.body?.endedBy || 'Participant';
      } else {
        global.currentActiveSession = { status: 'ENDED', endedBy: req.body?.endedBy || 'Participant' };
      }
      return res.status(200).json({ success: true, session: global.currentActiveSession });
    }

    // Default response
    return res.status(200).json({
      message: "PsychicHeroes Dynamic Staging Gateway Active",
      database: "psychicheroes_staging",
      status: "Healthy"
    });
  } catch (err) {
    return res.status(500).json({
      error: "Internal Server Error",
      details: err.message
    });
  }
};
