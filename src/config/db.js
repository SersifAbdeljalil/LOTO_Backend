// src/config/db.js
// ✅ Compatible LOCAL (Docker) + PRODUCTION (Aiven MySQL)
// ✅ SSL conditionnel : activé par défaut, désactivé si DB_SSL=false
// ✅ TIMEZONE +00:00 : pas de double conversion (comme l'original)

const mysql  = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host     : process.env.DB_HOST     || 'db',
  port     : process.env.DB_PORT     || 3306,
  user     : process.env.DB_USER,
  password : process.env.DB_PASSWORD,
  database : process.env.DB_NAME,

  // ── SSL — activé par défaut (Aiven), désactivé en local avec DB_SSL=false ──
  ssl      : process.env.DB_SSL === 'false' ? false : { rejectUnauthorized: true },

  // ── Taille du pool ──────────────────────────────────────────────────────
  waitForConnections : true,
  connectionLimit    : 10,
  queueLimit         : 0,

  // ✅ FIX TIMEZONE — '+00:00' = pas de conversion par le driver
  //    Les dates MySQL (DATETIME UTC) sont retournées telles quelles
  //    La conversion UTC→Maroc est faite côté applicatif (pdf.service.js)
  timezone : '+00:00',

  // ✅ FIX PERFORMANCE — Maintenir les connexions actives
  enableKeepAlive       : true,
  keepAliveInitialDelay : 10000,
  connectTimeout        : 10000,
  idleTimeout           : 60000,
  multipleStatements    : false,
});

// ── Test de connexion au démarrage ─────────────────────────────────────────
pool.getConnection()
  .then(conn => {
    console.log('✅ MySQL connecté avec succès');
    conn.release();
  })
  .catch(err => {
    console.error('❌ Erreur connexion MySQL :', err.message);
    setTimeout(() => {
      console.error('❌ MySQL toujours inaccessible — arrêt du serveur');
      process.exit(1);
    }, 5000);
  });

module.exports = pool;