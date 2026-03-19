// src/routes/process.routes.js
// ✅ FIX : servirPDF sans restriction de rôle
// ✅ NOUVEAU : deconsignation-detail + scanner-decons-cadenas-process + /deconsigner
const express = require('express');
const router  = express.Router();
const ctrl    = require('../controllers/process.controller');
const auth    = require('../middlewares/auth.middleware');
const role    = require('../middlewares/role.middleware');
const PROCESS = role(['chef_process']);

// ── Consignation ──────────────────────────────────────────────────
router.get('/demandes',                              auth, PROCESS, ctrl.getDemandesAConsigner);
router.get('/demandes-a-deconsigner',                auth, PROCESS, ctrl.getDemandesADeconsigner);
router.get('/demandes/:id/pdf',                      auth,          ctrl.servirPDF);
router.get('/demandes/:id',                          auth, PROCESS, ctrl.getDemandeDetail);
router.post('/demandes/:id/demarrer',                auth, PROCESS, ctrl.demarrerConsignation);
router.post('/demandes/:id/valider',                 auth, PROCESS, ctrl.validerConsignation);
router.post('/points/:pointId/cadenas',              auth, PROCESS, ctrl.scannerCadenas);
router.post('/cadenas-libre',                        auth, PROCESS, ctrl.scannerCadenasLibre);
router.get('/historique',                            auth, PROCESS, ctrl.getHistorique);
router.post('/deconsigner-point/:pointId',           auth, PROCESS, ctrl.deconsignerPointProcess);

// ── Déconsignation ────────────────────────────────────────────────
// 1. Voir les détails de la déconsignation (points process + état cadenas)
router.get('/demandes/:id/deconsignation-detail',    auth, PROCESS, ctrl.getDemandeDeconsignationDetail);
// 2. Scanner un cadenas lors de la déconsignation process (vérification correspondance)
router.post('/demandes/:id/scanner-decons-cadenas-process', auth, PROCESS, ctrl.scannerCadenasDeconsignation);
// 3. Valider la déconsignation finale process (après scan de tous les cadenas)
router.post('/demandes/:id/deconsigner',             auth, PROCESS, ctrl.validerDeconsignationFinale);

module.exports = router;