// src/routes/admin.routes.js
// ✅ Toutes les routes protégées — role: admin
// ✅ Upload photo user via multer

const express      = require('express');
const router       = express.Router();
const multer       = require('multer');
const path         = require('path');
const fs           = require('fs');
const authMiddleware = require('../middlewares/auth.middleware');
const roleMiddleware = require('../middlewares/role.middleware');
const ctrl           = require('../controllers/admin.controller');

// ── Upload photo user ──────────────────────────────────────────────────────
const uploadsDir = path.join(__dirname, '../../uploads/photos_membres');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename:    (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `user_${Date.now()}_${Math.random().toString(36).substr(2, 6)}${ext}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    cb(null, allowed.includes(file.mimetype));
  },
});

// ── Middleware commun ─────────────────────────────────────────────────────
const adminOnly = [authMiddleware, roleMiddleware(['admin'])];

// ── Dashboard ─────────────────────────────────────────────────────────────
router.get('/dashboard', adminOnly, ctrl.getDashboardStats);

// ── Zones ────────────────────────────────────────────────────────────────
router.get('/zones',         adminOnly, ctrl.getZones);
router.post('/zones',        adminOnly, ctrl.creerZone);
router.put('/zones/:id',     adminOnly, ctrl.modifierZone);
router.delete('/zones/:id',  adminOnly, ctrl.supprimerZone);

// ── Lots ─────────────────────────────────────────────────────────────────
router.get('/lots',          adminOnly, ctrl.getLots);
router.post('/lots',         adminOnly, ctrl.creerLot);
router.put('/lots/:id',      adminOnly, ctrl.modifierLot);
router.delete('/lots/:id',   adminOnly, ctrl.supprimerLot);

// ── Équipements ───────────────────────────────────────────────────────────
router.get('/equipements',         adminOnly, ctrl.getEquipements);
router.post('/equipements',        adminOnly, ctrl.creerEquipement);
router.put('/equipements/:id',     adminOnly, ctrl.modifierEquipement);
router.delete('/equipements/:id',  adminOnly, ctrl.supprimerEquipement);

// ── Plans prédéfinis ──────────────────────────────────────────────────────
router.get('/plans-predefinis/:equipement_id',         adminOnly, ctrl.getPlanPredefini);
router.post('/plans-predefinis',                       adminOnly, ctrl.ajouterLignePlan);
router.put('/plans-predefinis/:id',                    adminOnly, ctrl.modifierLignePlan);
router.delete('/plans-predefinis/:id',                 adminOnly, ctrl.supprimerLignePlan);
router.delete('/plans-predefinis/equipement/:equipement_id', adminOnly, ctrl.supprimerPlanComplet);

// ── Users (CRUD étendu admin) ─────────────────────────────────────────────
router.get('/users',                    adminOnly, ctrl.getUsers);
router.post('/users', adminOnly, upload.single('photo'), ctrl.creerUser);
router.put('/users/:id', adminOnly, upload.single('photo'), ctrl.modifierUser);
router.patch('/users/:id/toggle',       adminOnly, ctrl.toggleUserActif);
router.post('/users/:id/reset-password', adminOnly, ctrl.resetPasswordAdmin);

// ── Reset Password — Demandes (mot de passe oublié) ───────────────────────
// ⚠️ Route PUBLIQUE — l'utilisateur n'est pas connecté quand il demande un reset
router.post('/reset-password/demander', ctrl.demanderResetPassword);

// Routes admin uniquement
router.get('/reset-password/demandes',          adminOnly, ctrl.getDemandesReset);
router.post('/reset-password/demandes/:id/approuver', adminOnly, ctrl.approuverResetPassword);
router.post('/reset-password/demandes/:id/rejeter',   adminOnly, ctrl.rejeterResetPassword);

// ── Rapports ──────────────────────────────────────────────────────────────
router.get('/rapports',         adminOnly, ctrl.getRapports);
router.post('/rapports/envoyer', adminOnly, ctrl.envoyerRapport);

module.exports = router;