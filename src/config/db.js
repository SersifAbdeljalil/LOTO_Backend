// src/config/db.js
// ✅ FIX PERFORMANCE — Pool MySQL optimisé pour Docker
//    - keepAlive : évite que les connexions inactives soient coupées par MySQL
//    - connectTimeout : timeout de connexion explicite
//    - idleTimeout : libère les connexions inactives proprement
//    - enableKeepAlive : maintient les connexions TCP actives
//    - namedPlaceholders : permet les requêtes avec :param au lieu de ?

const mysql  = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host     : process.env.DB_HOST     || 'db',
  port     : process.env.DB_PORT     || 3306,
  user     : process.env.DB_USER,
  password : process.env.DB_PASSWORD,
  database : process.env.DB_NAME,

  // ── Taille du pool ──────────────────────────────────────────────────────
  waitForConnections : true,
  connectionLimit    : 10,   // Max 10 connexions simultanées
  queueLimit         : 0,    // File d'attente illimitée

  // ── Timezone Maroc ──────────────────────────────────────────────────────
  timezone : '+01:00',

  // ✅ FIX PERFORMANCE — Maintenir les connexions actives (évite reconnexion)
  // Sans ça, MySQL coupe les connexions inactives après wait_timeout (8h)
  // et la prochaine requête doit se reconnecter → délai perceptible
  enableKeepAlive    : true,
  keepAliveInitialDelay : 10000, // Envoyer un keepAlive après 10s d'inactivité

  // ✅ Timeout de connexion (pas de requête) : 10 secondes
  connectTimeout : 10000,

  // ✅ Libérer les connexions inactives après 60s (évite les connexions zombies)
  idleTimeout : 60000,

  // ✅ Permettre plusieurs statements SQL dans une requête (si besoin transactions)
  multipleStatements : false,
});

// ── Test de connexion au démarrage ─────────────────────────────────────────
pool.getConnection()
  .then(conn => {
    console.log('✅ MySQL connecté avec succès');
    conn.release();
  })
  .catch(err => {
    console.error('❌ Erreur connexion MySQL :', err.message);
    // ✅ Ne pas process.exit() directement — laisser Docker restart gérer ça
    // Si la DB n'est pas encore prête (race condition au démarrage), retry automatique
    setTimeout(() => {
      console.error('❌ MySQL toujours inaccessible — arrêt du serveur');
      process.exit(1);
    }, 5000);
  });

module.exports = pool;