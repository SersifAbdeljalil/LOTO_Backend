const fs   = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config();

// Certificat CA Aiven (ignoré si le fichier n'existe pas = environnement local sans SSL)
const caPath = path.join(__dirname, '../../ca.pem');
const sslConfig = process.env.DB_SSL === 'false'
  ? false
  : {
      rejectUnauthorized: true,
      ca: fs.existsSync(caPath) ? fs.readFileSync(caPath) : undefined,
    };

const pool = mysql.createPool({
  host     : process.env.DB_HOST || 'db',
  port     : process.env.DB_PORT || 3306,
  user     : process.env.DB_USER,
  password : process.env.DB_PASSWORD,
  database : process.env.DB_NAME,
  ssl      : sslConfig,
  waitForConnections : true,
  connectionLimit    : 10,
  queueLimit         : 0,
  timezone           : '+00:00',
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

// ✅ FIX — mysql2/promise pool utilise execute() pas query()
pool.query = pool.execute.bind(pool);

module.exports = pool;