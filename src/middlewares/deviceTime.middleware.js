// src/middleware/deviceTime.middleware.js
// ✅ Middleware Express — lit X-Device-Time depuis le header de chaque requête
// et l'attache à req.deviceTime (objet Date) et req.deviceTimeISO (string).
//
// Utilisation dans les controllers :
//   const now = req.deviceTime || new Date();  // fallback serveur si header absent
//   await db.query('INSERT ... VALUES (?, ...)', [..., now]);
//
// Le header X-Device-Time est injecté automatiquement par l'intercepteur axios
// côté mobile (client.js). Il contient une ISO string avec offset Maroc explicite.
// Ex: "2026-03-10T23:22:46+01:00"

/**
 * Parse une ISO string avec offset en objet Date UTC.
 * "2026-03-10T23:22:46+01:00" → Date UTC 2026-03-10T22:22:46Z
 * Ce Date UTC sera stocké correctement en MySQL DATETIME (qui stocke en UTC).
 */
const parseDeviceTime = (isoString) => {
  if (!isoString || typeof isoString !== 'string') return null;
  try {
    const dt = new Date(isoString.trim());
    return isNaN(dt.getTime()) ? null : dt;
  } catch {
    return null;
  }
};

/**
 * Middleware principal.
 * Attache req.deviceTime et req.deviceTimeISO à chaque requête.
 */
const deviceTimeMiddleware = (req, res, next) => {
  const header = req.headers['x-device-time'];
  const parsed = parseDeviceTime(header);

  if (parsed) {
    req.deviceTime    = parsed;            // Date UTC — utilisable dans db.query
    req.deviceTimeISO = parsed.toISOString(); // "2026-03-10T22:22:46.000Z"
  } else {
    // Fallback : heure serveur si le header est absent ou invalide
    req.deviceTime    = new Date();
    req.deviceTimeISO = req.deviceTime.toISOString();
  }

  next();
};

/**
 * Helper : formate req.deviceTime en string MySQL "YYYY-MM-DD HH:MM:SS" UTC.
 * Utilisable dans les requêtes SQL : INSERT ... VALUES (devTime(req), ...)
 *
 * MySQL stocke en UTC → le CONVERT_TZ côté SELECT affichera l'heure Maroc.
 */
const devTime = (req) => {
  const dt  = req.deviceTime || new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return (
    `${dt.getUTCFullYear()}-${pad(dt.getUTCMonth() + 1)}-${pad(dt.getUTCDate())}` +
    ` ${pad(dt.getUTCHours())}:${pad(dt.getUTCMinutes())}:${pad(dt.getUTCSeconds())}`
  );
};

module.exports = { deviceTimeMiddleware, devTime };