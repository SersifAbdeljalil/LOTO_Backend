// src/controllers/admin.controller.js
const bcrypt = require('bcrypt');
const path   = require('path');
const fs     = require('fs');
const db     = require('../config/db');
const { success, error } = require('../utils/response');
const {
  genererMotPasseTemp,
  envoyerMotPasseTemp,
  notifierAdminResetDemande,
  notifierRejetReset,
  envoyerRapportParEmail,
} = require('../services/email.service');

// ══════════════════════════════════════════════════════════════════
// DASHBOARD STATS
// ══════════════════════════════════════════════════════════════════
const getDashboardStats = async (req, res) => {
  try {
    const [[users]]       = await db.query('SELECT COUNT(*) AS total FROM users WHERE actif=1');
    const [[zones]]       = await db.query('SELECT COUNT(*) AS total FROM zones WHERE actif=1');
    const [[lots]]        = await db.query('SELECT COUNT(*) AS total FROM lots WHERE actif=1');
    const [[equips]]      = await db.query('SELECT COUNT(*) AS total FROM equipements WHERE actif=1');
    const [[demandes]]    = await db.query('SELECT COUNT(*) AS total FROM demandes_consignation');
    const [[consignees]]  = await db.query("SELECT COUNT(*) AS total FROM demandes_consignation WHERE statut='consigne'");
    const [[decons]]      = await db.query("SELECT COUNT(*) AS total FROM demandes_consignation WHERE statut='deconsignee'");
    const [[enAttente]]   = await db.query("SELECT COUNT(*) AS total FROM demandes_consignation WHERE statut='en_attente'");
    const [[resetPending]]= await db.query("SELECT COUNT(*) AS total FROM reset_password_demandes WHERE statut='en_attente'");
    const [demandesRecentes] = await db.query(
      `SELECT d.numero_ordre, d.statut, e.code_equipement AS tag,
              CONCAT(u.prenom,' ',u.nom) AS demandeur,
              CONVERT_TZ(d.created_at,'+00:00','+01:00') AS created_at
       FROM demandes_consignation d
       JOIN equipements e ON d.equipement_id=e.id
       JOIN users u ON d.agent_id=u.id
       ORDER BY d.created_at DESC LIMIT 5`
    );
    return success(res, {
      users:          users.total,
      zones:          zones.total,
      lots:           lots.total,
      equipements:    equips.total,
      demandes:       demandes.total,
      consignees:     consignees.total,
      deconsignees:   decons.total,
      en_attente:     enAttente.total,
      reset_pending:  resetPending.total,
      demandes_recentes: demandesRecentes,
    }, 'Stats récupérées');
  } catch (err) {
    console.error('getDashboardStats error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

// ══════════════════════════════════════════════════════════════════
// ZONES
// ══════════════════════════════════════════════════════════════════
const getZones = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT z.*,
              (SELECT COUNT(*) FROM lots WHERE zone_id=z.id AND actif=1) AS nb_lots,
              (SELECT COUNT(*) FROM equipements WHERE zone_id=z.id AND actif=1) AS nb_equipements,
              (SELECT COUNT(*) FROM users WHERE zone_id=z.id AND actif=1) AS nb_users
       FROM zones z ORDER BY z.code`
    );
    return success(res, rows, 'Zones récupérées');
  } catch (err) {
    console.error('getZones error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const creerZone = async (req, res) => {
  try {
    const { code, description } = req.body;
    if (!code || !code.trim()) return error(res, 'Le code zone est obligatoire', 400);
    const [exist] = await db.query('SELECT id FROM zones WHERE code=?', [code.trim().toUpperCase()]);
    if (exist.length) return error(res, 'Ce code zone existe déjà', 409);
    const [result] = await db.query(
      'INSERT INTO zones (code, description) VALUES (?, ?)',
      [code.trim().toUpperCase(), description?.trim() || null]
    );
    const [zone] = await db.query('SELECT * FROM zones WHERE id=?', [result.insertId]);
    return success(res, zone[0], 'Zone créée avec succès', 201);
  } catch (err) {
    console.error('creerZone error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const modifierZone = async (req, res) => {
  try {
    const { id } = req.params;
    const { code, description, actif } = req.body;
    const [exist] = await db.query('SELECT id FROM zones WHERE id=?', [id]);
    if (!exist.length) return error(res, 'Zone introuvable', 404);
    if (code) {
      const [dup] = await db.query('SELECT id FROM zones WHERE code=? AND id!=?', [code.trim().toUpperCase(), id]);
      if (dup.length) return error(res, 'Ce code zone existe déjà', 409);
    }
    await db.query(
      'UPDATE zones SET code=COALESCE(?,code), description=COALESCE(?,description), actif=COALESCE(?,actif) WHERE id=?',
      [code?.trim().toUpperCase() || null, description?.trim() || null, actif !== undefined ? actif : null, id]
    );
    const [zone] = await db.query('SELECT * FROM zones WHERE id=?', [id]);
    return success(res, zone[0], 'Zone modifiée');
  } catch (err) {
    console.error('modifierZone error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const supprimerZone = async (req, res) => {
  try {
    const { id } = req.params;
    const [lotsLies] = await db.query('SELECT id FROM lots WHERE zone_id=? AND actif=1', [id]);
    if (lotsLies.length) return error(res, `Impossible — ${lotsLies.length} lot(s) actif(s) dans cette zone`, 400);
    await db.query('UPDATE zones SET actif=0 WHERE id=?', [id]);
    return success(res, null, 'Zone désactivée');
  } catch (err) {
    console.error('supprimerZone error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

// ══════════════════════════════════════════════════════════════════
// LOTS
// ══════════════════════════════════════════════════════════════════
const getLots = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT l.*, z.code AS zone_code, z.description AS zone_description,
              (SELECT COUNT(*) FROM equipements WHERE lot_id=l.id AND actif=1) AS nb_equipements
       FROM lots l LEFT JOIN zones z ON l.zone_id=z.id
       ORDER BY z.code, l.code`
    );
    return success(res, rows, 'Lots récupérés');
  } catch (err) {
    console.error('getLots error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const creerLot = async (req, res) => {
  try {
    const { code, description, zone_id } = req.body;
    if (!code || !code.trim()) return error(res, 'Le code lot est obligatoire', 400);
    if (!zone_id) return error(res, 'La zone est obligatoire', 400);
    const [exist] = await db.query('SELECT id FROM lots WHERE code=?', [code.trim()]);
    if (exist.length) return error(res, 'Ce code lot existe déjà', 409);
    const [zone] = await db.query('SELECT id FROM zones WHERE id=? AND actif=1', [zone_id]);
    if (!zone.length) return error(res, 'Zone introuvable', 404);
    const [result] = await db.query(
      'INSERT INTO lots (code, description, zone_id) VALUES (?, ?, ?)',
      [code.trim(), description?.trim() || null, zone_id]
    );
    const [lot] = await db.query(
      'SELECT l.*, z.code AS zone_code FROM lots l LEFT JOIN zones z ON l.zone_id=z.id WHERE l.id=?',
      [result.insertId]
    );
    return success(res, lot[0], 'Lot créé avec succès', 201);
  } catch (err) {
    console.error('creerLot error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const modifierLot = async (req, res) => {
  try {
    const { id } = req.params;
    const { code, description, zone_id, actif } = req.body;
    const [exist] = await db.query('SELECT id FROM lots WHERE id=?', [id]);
    if (!exist.length) return error(res, 'Lot introuvable', 404);
    if (code) {
      const [dup] = await db.query('SELECT id FROM lots WHERE code=? AND id!=?', [code.trim(), id]);
      if (dup.length) return error(res, 'Ce code lot existe déjà', 409);
    }
    await db.query(
      'UPDATE lots SET code=COALESCE(?,code), description=COALESCE(?,description), zone_id=COALESCE(?,zone_id), actif=COALESCE(?,actif) WHERE id=?',
      [code?.trim() || null, description?.trim() || null, zone_id || null, actif !== undefined ? actif : null, id]
    );
    const [lot] = await db.query(
      'SELECT l.*, z.code AS zone_code FROM lots l LEFT JOIN zones z ON l.zone_id=z.id WHERE l.id=?',
      [id]
    );
    return success(res, lot[0], 'Lot modifié');
  } catch (err) {
    console.error('modifierLot error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const supprimerLot = async (req, res) => {
  try {
    const { id } = req.params;
    const [equipsLies] = await db.query('SELECT id FROM equipements WHERE lot_id=? AND actif=1', [id]);
    if (equipsLies.length) return error(res, `Impossible — ${equipsLies.length} équipement(s) actif(s) dans ce lot`, 400);
    await db.query('UPDATE lots SET actif=0 WHERE id=?', [id]);
    return success(res, null, 'Lot désactivé');
  } catch (err) {
    console.error('supprimerLot error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

// ══════════════════════════════════════════════════════════════════
// ÉQUIPEMENTS
// ══════════════════════════════════════════════════════════════════
const getEquipements = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT e.*, l.code AS lot_code, z.code AS zone_code,
              (SELECT COUNT(*) FROM plans_predefinis WHERE equipement_id=e.id) AS nb_points_plan
       FROM equipements e
       LEFT JOIN lots l ON e.lot_id=l.id
       LEFT JOIN zones z ON e.zone_id=z.id
       ORDER BY z.code, l.code, e.nom`
    );
    return success(res, rows, 'Équipements récupérés');
  } catch (err) {
    console.error('getEquipements error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const creerEquipement = async (req, res) => {
  try {
    const { code_equipement, nom, type, localisation, entite, lot_id, zone_id, raison_predefinie } = req.body;
    if (!code_equipement || !nom) return error(res, 'code_equipement et nom sont obligatoires', 400);
    if (!zone_id) return error(res, 'La zone est obligatoire', 400);
    const [exist] = await db.query('SELECT id FROM equipements WHERE code_equipement=?', [code_equipement.trim()]);
    if (exist.length) return error(res, 'Ce code équipement existe déjà', 409);
    const [result] = await db.query(
      `INSERT INTO equipements (code_equipement, nom, type, localisation, entite, lot_id, zone_id, raison_predefinie)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [code_equipement.trim(), nom.trim(), type?.trim() || 'equipement', localisation?.trim() || null,
       entite?.trim() || null, lot_id || null, zone_id, raison_predefinie?.trim() || null]
    );
    const [equip] = await db.query(
      'SELECT e.*, l.code AS lot_code, z.code AS zone_code FROM equipements e LEFT JOIN lots l ON e.lot_id=l.id LEFT JOIN zones z ON e.zone_id=z.id WHERE e.id=?',
      [result.insertId]
    );
    return success(res, equip[0], 'Équipement créé', 201);
  } catch (err) {
    console.error('creerEquipement error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const modifierEquipement = async (req, res) => {
  try {
    const { id } = req.params;
    const { code_equipement, nom, type, localisation, entite, lot_id, zone_id, raison_predefinie, actif } = req.body;
    const [exist] = await db.query('SELECT id FROM equipements WHERE id=?', [id]);
    if (!exist.length) return error(res, 'Équipement introuvable', 404);
    if (code_equipement) {
      const [dup] = await db.query('SELECT id FROM equipements WHERE code_equipement=? AND id!=?', [code_equipement.trim(), id]);
      if (dup.length) return error(res, 'Ce code équipement existe déjà', 409);
    }
    await db.query(
      `UPDATE equipements SET
        code_equipement   = COALESCE(?, code_equipement),
        nom               = COALESCE(?, nom),
        type              = COALESCE(?, type),
        localisation      = COALESCE(?, localisation),
        entite            = COALESCE(?, entite),
        lot_id            = COALESCE(?, lot_id),
        zone_id           = COALESCE(?, zone_id),
        raison_predefinie = COALESCE(?, raison_predefinie),
        actif             = COALESCE(?, actif)
       WHERE id=?`,
      [code_equipement?.trim() || null, nom?.trim() || null, type?.trim() || null,
       localisation?.trim() || null, entite?.trim() || null, lot_id || null, zone_id || null,
       raison_predefinie?.trim() || null, actif !== undefined ? actif : null, id]
    );
    const [equip] = await db.query(
      'SELECT e.*, l.code AS lot_code, z.code AS zone_code FROM equipements e LEFT JOIN lots l ON e.lot_id=l.id LEFT JOIN zones z ON e.zone_id=z.id WHERE e.id=?',
      [id]
    );
    return success(res, equip[0], 'Équipement modifié');
  } catch (err) {
    console.error('modifierEquipement error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const supprimerEquipement = async (req, res) => {
  try {
    const { id } = req.params;
    await db.query('UPDATE equipements SET actif=0 WHERE id=?', [id]);
    return success(res, null, 'Équipement désactivé');
  } catch (err) {
    console.error('supprimerEquipement error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

// ══════════════════════════════════════════════════════════════════
// PLANS PRÉDÉFINIS
// ══════════════════════════════════════════════════════════════════
const getPlanPredefini = async (req, res) => {
  try {
    const { equipement_id } = req.params;
    const [rows] = await db.query(
      `SELECT pp.*, e.nom AS equipement_nom, e.code_equipement AS tag
       FROM plans_predefinis pp
       JOIN equipements e ON pp.equipement_id=e.id
       WHERE pp.equipement_id=?
       ORDER BY pp.numero_ligne ASC`,
      [equipement_id]
    );
    return success(res, rows, 'Plan prédéfini récupéré');
  } catch (err) {
    console.error('getPlanPredefini error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const ajouterLignePlan = async (req, res) => {
  try {
    const { equipement_id, numero_ligne, repere_point, localisation, dispositif_condamnation, etat_requis, charge_type, role_id_requis } = req.body;
    if (!equipement_id || !etat_requis || !charge_type)
      return error(res, 'equipement_id, etat_requis et charge_type sont obligatoires', 400);
    const [equip] = await db.query('SELECT id FROM equipements WHERE id=? AND actif=1', [equipement_id]);
    if (!equip.length) return error(res, 'Équipement introuvable', 404);
    const [maxLigne] = await db.query('SELECT MAX(numero_ligne) AS max FROM plans_predefinis WHERE equipement_id=?', [equipement_id]);
    const nextLigne  = numero_ligne || ((maxLigne[0].max || 0) + 1);
    const roleReq    = charge_type === 'electricien' ? 21 : (role_id_requis || 19);
    const [result]   = await db.query(
      `INSERT INTO plans_predefinis (equipement_id, numero_ligne, repere_point, localisation, dispositif_condamnation, etat_requis, charge_type, role_id_requis)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [equipement_id, nextLigne, repere_point?.trim() || null, localisation?.trim() || null,
       dispositif_condamnation?.trim() || null, etat_requis, charge_type, roleReq]
    );
    const [ligne] = await db.query('SELECT * FROM plans_predefinis WHERE id=?', [result.insertId]);
    return success(res, ligne[0], 'Ligne ajoutée au plan', 201);
  } catch (err) {
    console.error('ajouterLignePlan error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const modifierLignePlan = async (req, res) => {
  try {
    const { id } = req.params;
    const { repere_point, localisation, dispositif_condamnation, etat_requis, charge_type, role_id_requis, numero_ligne } = req.body;
    const [exist] = await db.query('SELECT id FROM plans_predefinis WHERE id=?', [id]);
    if (!exist.length) return error(res, 'Ligne introuvable', 404);
    await db.query(
      `UPDATE plans_predefinis SET
        numero_ligne            = COALESCE(?, numero_ligne),
        repere_point            = COALESCE(?, repere_point),
        localisation            = COALESCE(?, localisation),
        dispositif_condamnation = COALESCE(?, dispositif_condamnation),
        etat_requis             = COALESCE(?, etat_requis),
        charge_type             = COALESCE(?, charge_type),
        role_id_requis          = COALESCE(?, role_id_requis)
       WHERE id=?`,
      [numero_ligne || null, repere_point?.trim() || null, localisation?.trim() || null,
       dispositif_condamnation?.trim() || null, etat_requis || null, charge_type || null,
       role_id_requis || null, id]
    );
    const [ligne] = await db.query('SELECT * FROM plans_predefinis WHERE id=?', [id]);
    return success(res, ligne[0], 'Ligne modifiée');
  } catch (err) {
    console.error('modifierLignePlan error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const supprimerLignePlan = async (req, res) => {
  try {
    const { id } = req.params;
    await db.query('DELETE FROM plans_predefinis WHERE id=?', [id]);
    return success(res, null, 'Ligne supprimée');
  } catch (err) {
    console.error('supprimerLignePlan error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const supprimerPlanComplet = async (req, res) => {
  try {
    const { equipement_id } = req.params;
    const [result] = await db.query('DELETE FROM plans_predefinis WHERE equipement_id=?', [equipement_id]);
    return success(res, { lignes_supprimees: result.affectedRows }, 'Plan complet supprimé');
  } catch (err) {
    console.error('supprimerPlanComplet error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

// ══════════════════════════════════════════════════════════════════
// USERS (CRUD ADMIN ÉTENDU)
// ══════════════════════════════════════════════════════════════════
const getUsers = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT u.id, u.nom, u.prenom, u.username, u.matricule, u.telephone,
              u.badge_ocp_id, u.numero_cadenas, u.photo, u.entite, u.zone,
              u.zone_id, u.type_metier, u.actif, u.email,
              CONVERT_TZ(u.created_at,'+00:00','+01:00') AS created_at,
              r.nom AS role, r.id AS role_id, z.code AS zone_code
       FROM users u
       JOIN roles r ON u.role_id=r.id
       LEFT JOIN zones z ON u.zone_id=z.id
       ORDER BY u.created_at DESC`
    );
    return success(res, rows, 'Utilisateurs récupérés');
  } catch (err) {
    console.error('getUsers error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const creerUser = async (req, res) => {
  try {
    const {
      nom, prenom, username, mot_de_passe, matricule,
      telephone, badge_ocp_id, numero_cadenas, role_id,
      entite, zone, zone_id, type_metier, email,
    } = req.body;

    if (!nom || !prenom || !username || !mot_de_passe || !role_id)
      return error(res, 'Champs obligatoires : nom, prenom, username, mot_de_passe, role_id', 400);
    if (mot_de_passe.length < 6)
      return error(res, 'Le mot de passe doit contenir au moins 6 caractères', 400);

    const [existUser] = await db.query('SELECT id FROM users WHERE username=?', [username]);
    if (existUser.length) return error(res, "Ce nom d'utilisateur est déjà pris", 409);
    if (matricule) {
      const [e] = await db.query('SELECT id FROM users WHERE matricule=?', [matricule]);
      if (e.length) return error(res, 'Ce matricule est déjà utilisé', 409);
    }
    if (badge_ocp_id) {
      const [e] = await db.query('SELECT id FROM users WHERE badge_ocp_id=?', [badge_ocp_id]);
      if (e.length) return error(res, 'Ce badge OCP est déjà utilisé', 409);
    }
    if (email) {
      const [e] = await db.query('SELECT id FROM users WHERE email=?', [email]);
      if (e.length) return error(res, 'Cet email est déjà utilisé', 409);
    }

    const photo_path = req.file ? `uploads/photos_membres/${req.file.filename}` : null;
    const hash = await bcrypt.hash(mot_de_passe, 10);

    const [result] = await db.query(
      `INSERT INTO users
         (nom, prenom, username, mot_de_passe, matricule, telephone,
          badge_ocp_id, numero_cadenas, photo, role_id, entite, zone,
          zone_id, type_metier, email)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [nom, prenom, username, hash, matricule || null, telephone || null,
       badge_ocp_id || null, numero_cadenas || null, photo_path,
       role_id, entite || null, zone || null, zone_id || null,
       type_metier || null, email || null]
    );

    const [newUser] = await db.query(
      `SELECT u.id, u.nom, u.prenom, u.username, u.matricule, u.telephone,
              u.badge_ocp_id, u.numero_cadenas, u.photo, u.entite, u.zone,
              u.zone_id, u.type_metier, u.actif, u.email,
              r.nom AS role, r.id AS role_id
       FROM users u JOIN roles r ON u.role_id=r.id WHERE u.id=?`,
      [result.insertId]
    );
    return success(res, newUser[0], 'Utilisateur créé avec succès', 201);
  } catch (err) {
    console.error('creerUser error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

// ✅ CORRIGÉ — mot_de_passe inclus + mot_passe_temp remis à 0 si nouveau mdp
const modifierUser = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      nom, prenom, username, matricule, telephone,
      badge_ocp_id, numero_cadenas, role_id, entite,
      zone, zone_id, type_metier, actif, email,
      mot_de_passe, // ✅ récupéré
    } = req.body;

    const [exist] = await db.query('SELECT id FROM users WHERE id=?', [id]);
    if (!exist.length) return error(res, 'Utilisateur introuvable', 404);

    if (username) {
      const [dup] = await db.query('SELECT id FROM users WHERE username=? AND id!=?', [username, id]);
      if (dup.length) return error(res, "Ce nom d'utilisateur est déjà pris", 409);
    }
    if (badge_ocp_id) {
      const [dup] = await db.query('SELECT id FROM users WHERE badge_ocp_id=? AND id!=?', [badge_ocp_id, id]);
      if (dup.length) return error(res, 'Ce badge OCP est déjà utilisé', 409);
    }
    if (email) {
      const [dup] = await db.query('SELECT id FROM users WHERE email=? AND id!=?', [email, id]);
      if (dup.length) return error(res, 'Cet email est déjà utilisé', 409);
    }

    // ✅ Hash mot de passe si fourni et valide
    let hashedPassword = null;
    if (mot_de_passe && mot_de_passe.trim().length >= 6) {
      hashedPassword = await bcrypt.hash(mot_de_passe.trim(), 10);
    }

    const photo_path = req.file ? `uploads/photos_membres/${req.file.filename}` : null;

    await db.query(
      `UPDATE users SET
        nom            = COALESCE(?, nom),
        prenom         = COALESCE(?, prenom),
        username       = COALESCE(?, username),
        matricule      = COALESCE(?, matricule),
        telephone      = COALESCE(?, telephone),
        badge_ocp_id   = COALESCE(?, badge_ocp_id),
        numero_cadenas = COALESCE(?, numero_cadenas),
        photo          = COALESCE(?, photo),
        role_id        = COALESCE(?, role_id),
        entite         = COALESCE(?, entite),
        zone           = COALESCE(?, zone),
        zone_id        = COALESCE(?, zone_id),
        type_metier    = COALESCE(?, type_metier),
        actif          = COALESCE(?, actif),
        email          = COALESCE(?, email),
        mot_de_passe   = COALESCE(?, mot_de_passe),
        mot_passe_temp = CASE WHEN ? IS NOT NULL THEN 0 ELSE mot_passe_temp END
       WHERE id=?`,
      [
        nom || null, prenom || null, username || null, matricule || null,
        telephone || null, badge_ocp_id || null, numero_cadenas || null,
        photo_path, role_id || null, entite || null, zone || null,
        zone_id || null, type_metier || null,
        actif !== undefined ? actif : null,
        email || null,
        hashedPassword,  // mot_de_passe — null = COALESCE garde l'ancien
        hashedPassword,  // CASE mot_passe_temp
        id,
      ]
    );

    const [updated] = await db.query(
      `SELECT u.id, u.nom, u.prenom, u.username, u.matricule, u.telephone,
              u.badge_ocp_id, u.numero_cadenas, u.photo, u.entite, u.zone,
              u.zone_id, u.type_metier, u.actif, u.email,
              r.nom AS role, r.id AS role_id
       FROM users u JOIN roles r ON u.role_id=r.id WHERE u.id=?`,
      [id]
    );
    return success(res, updated[0], 'Utilisateur modifié');
  } catch (err) {
    console.error('modifierUser error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const toggleUserActif = async (req, res) => {
  try {
    const { id } = req.params;
    if (parseInt(id) === req.user.id)
      return error(res, 'Vous ne pouvez pas désactiver votre propre compte', 400);
    const [rows] = await db.query('SELECT actif FROM users WHERE id=?', [id]);
    if (!rows.length) return error(res, 'Utilisateur introuvable', 404);
    const nouvelEtat = !rows[0].actif;
    await db.query('UPDATE users SET actif=? WHERE id=?', [nouvelEtat, id]);
    return success(res, { actif: nouvelEtat }, nouvelEtat ? 'Compte activé' : 'Compte désactivé');
  } catch (err) {
    console.error('toggleUserActif error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const resetPasswordAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await db.query(
      'SELECT id, nom, prenom, username, email FROM users WHERE id=?', [id]
    );
    if (!rows.length) return error(res, 'Utilisateur introuvable', 404);
    const user = rows[0];
    if (!user.email) return error(res, "Cet utilisateur n'a pas d'email enregistré", 400);

    const motPasseTemp = genererMotPasseTemp();
    const hash         = await bcrypt.hash(motPasseTemp, 10);

    await db.query(
      'UPDATE users SET mot_de_passe=?, mot_passe_temp=1 WHERE id=?',
      [hash, id]
    );
    await envoyerMotPasseTemp({
      email: user.email, nom: user.nom, prenom: user.prenom,
      username: user.username, motPasseTemp,
    });
    return success(res, { email_envoye: true, email: user.email },
      'Mot de passe réinitialisé — email envoyé');
  } catch (err) {
    console.error('resetPasswordAdmin error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

// ══════════════════════════════════════════════════════════════════
// DEMANDES RESET PASSWORD
// ══════════════════════════════════════════════════════════════════
const demanderResetPassword = async (req, res) => {
  try {
    const { username, email } = req.body;
    if (!username || !email) return error(res, 'username et email sont obligatoires', 400);

    const [rows] = await db.query(
      'SELECT id, nom, prenom, username, email FROM users WHERE username=? AND actif=1',
      [username.trim()]
    );
    if (!rows.length) return error(res, "Nom d'utilisateur introuvable", 404);
    const user = rows[0];
    if (!user.email || user.email.toLowerCase() !== email.toLowerCase().trim())
      return error(res, "L'email ne correspond pas à cet utilisateur", 400);

    const [dejaEnAttente] = await db.query(
      "SELECT id FROM reset_password_demandes WHERE user_id=? AND statut='en_attente'",
      [user.id]
    );
    if (dejaEnAttente.length)
      return error(res, "Vous avez déjà une demande en attente — patientez que l'admin la traite", 400);

    await db.query(
      "INSERT INTO reset_password_demandes (user_id, email_demande) VALUES (?, ?)",
      [user.id, email.trim()]
    );

    const [admins] = await db.query(
      "SELECT u.email FROM users u JOIN roles r ON u.role_id=r.id WHERE r.nom='admin' AND u.actif=1 AND u.email IS NOT NULL"
    );
    for (const admin of admins) {
      await notifierAdminResetDemande({
        adminEmail:        admin.email,
        demandeurNom:      user.nom,
        demandeurPrenom:   user.prenom,
        demandeurUsername: user.username,
        demandeurEmail:    email,
      }).catch(e => console.error('[EMAIL] Notif admin échouée:', e.message));
    }
    return success(res, null, 'Demande envoyée — un administrateur va traiter votre demande');
  } catch (err) {
    console.error('demanderResetPassword error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const getDemandesReset = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT rpd.*, u.nom, u.prenom, u.username, u.email,
              CONVERT_TZ(rpd.created_at,'+00:00','+01:00') AS created_at,
              r.nom AS role
       FROM reset_password_demandes rpd
       JOIN users u ON rpd.user_id=u.id
       JOIN roles r ON u.role_id=r.id
       ORDER BY rpd.created_at DESC`
    );
    return success(res, rows, 'Demandes reset récupérées');
  } catch (err) {
    console.error('getDemandesReset error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const approuverResetPassword = async (req, res) => {
  try {
    const { id } = req.params;
    const [demandes] = await db.query(
      `SELECT rpd.*, u.nom, u.prenom, u.username, u.email
       FROM reset_password_demandes rpd
       JOIN users u ON rpd.user_id=u.id WHERE rpd.id=?`,
      [id]
    );
    if (!demandes.length) return error(res, 'Demande introuvable', 404);
    const demande = demandes[0];
    if (demande.statut !== 'en_attente') return error(res, 'Cette demande a déjà été traitée', 400);
    if (!demande.email) return error(res, "L'utilisateur n'a pas d'email", 400);

    const motPasseTemp = genererMotPasseTemp();
    const hash         = await bcrypt.hash(motPasseTemp, 10);

    await db.query('UPDATE users SET mot_de_passe=?, mot_passe_temp=1 WHERE id=?', [hash, demande.user_id]);
    await db.query(
      "UPDATE reset_password_demandes SET statut='approuvee', traite_par=?, traite_le=NOW() WHERE id=?",
      [req.user.id, id]
    );
    await envoyerMotPasseTemp({
      email: demande.email, nom: demande.nom, prenom: demande.prenom,
      username: demande.username, motPasseTemp,
    });
    return success(res, { email_envoye: true }, 'Demande approuvée — mot de passe envoyé par email');
  } catch (err) {
    console.error('approuverResetPassword error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const rejeterResetPassword = async (req, res) => {
  try {
    const { id } = req.params;
    const { motif } = req.body;
    const [demandes] = await db.query(
      `SELECT rpd.*, u.nom, u.prenom, u.username, u.email
       FROM reset_password_demandes rpd
       JOIN users u ON rpd.user_id=u.id WHERE rpd.id=?`,
      [id]
    );
    if (!demandes.length) return error(res, 'Demande introuvable', 404);
    const demande = demandes[0];
    if (demande.statut !== 'en_attente') return error(res, 'Cette demande a déjà été traitée', 400);

    await db.query(
      "UPDATE reset_password_demandes SET statut='rejetee', motif_rejet=?, traite_par=?, traite_le=NOW() WHERE id=?",
      [motif || null, req.user.id, id]
    );
    if (demande.email) {
      await notifierRejetReset({
        email: demande.email, nom: demande.nom, prenom: demande.prenom,
        username: demande.username, motifRejet: motif,
      }).catch(e => console.error('[EMAIL] Notif rejet échouée:', e.message));
    }
    return success(res, null, 'Demande rejetée');
  } catch (err) {
    console.error('rejeterResetPassword error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

// ══════════════════════════════════════════════════════════════════
// RAPPORTS
// ══════════════════════════════════════════════════════════════════
const getRapports = async (req, res) => {
  try {
    const [consignations] = await db.query(
      `SELECT d.id, d.numero_ordre, d.statut, d.pdf_path_final,
              e.code_equipement AS tag, e.nom AS equipement_nom, l.code AS lot_code,
              CONCAT(u.prenom,' ',u.nom) AS demandeur,
              CONVERT_TZ(d.created_at,'+00:00','+01:00') AS created_at,
              CONVERT_TZ(d.updated_at,'+00:00','+01:00') AS updated_at
       FROM demandes_consignation d
       JOIN equipements e ON d.equipement_id=e.id
       LEFT JOIN lots l ON d.lot_id=l.id
       JOIN users u ON d.agent_id=u.id
       WHERE d.pdf_path_final IS NOT NULL
       ORDER BY d.updated_at DESC`
    );
    const [rapportsEquipe] = await db.query(
      `SELECT rc.id, rc.demande_id, rc.pdf_path, rc.statut_final,
              rc.nb_membres_total, rc.duree_totale_min,
              CONVERT_TZ(rc.heure_debut,'+00:00','+01:00') AS heure_debut,
              CONVERT_TZ(rc.heure_fin,'+00:00','+01:00') AS heure_fin,
              CONCAT(u.prenom,' ',u.nom) AS chef_nom, u.type_metier,
              d.numero_ordre
       FROM rapport_consignation rc
       JOIN users u ON rc.chef_equipe_id=u.id
       JOIN demandes_consignation d ON rc.demande_id=d.id
       ORDER BY rc.created_at DESC`
    );
    return success(res, { consignations, rapports_equipe: rapportsEquipe }, 'Rapports récupérés');
  } catch (err) {
    console.error('getRapports error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

const envoyerRapport = async (req, res) => {
  try {
    const { pdf_path, destinataire_email, sujet, message } = req.body;
    if (!pdf_path || !destinataire_email)
      return error(res, 'pdf_path et destinataire_email sont obligatoires', 400);
    const pdfAbsPath = path.join(__dirname, '../../', pdf_path);
    if (!fs.existsSync(pdfAbsPath)) return error(res, 'Fichier PDF introuvable', 404);
    await envoyerRapportParEmail({
      destinataireEmail: destinataire_email,
      sujet:   sujet   || '[OCP Consignation] Rapport PDF',
      message: message || null,
      pdfPath: pdfAbsPath,
      pdfNom:  path.basename(pdfAbsPath),
    });
    return success(res, { envoye: true, destinataire: destinataire_email }, 'Rapport envoyé par email');
  } catch (err) {
    console.error('envoyerRapport error:', err);
    return error(res, 'Erreur serveur', 500);
  }
};

module.exports = {
  getDashboardStats,
  getZones, creerZone, modifierZone, supprimerZone,
  getLots, creerLot, modifierLot, supprimerLot,
  getEquipements, creerEquipement, modifierEquipement, supprimerEquipement,
  getPlanPredefini, ajouterLignePlan, modifierLignePlan, supprimerLignePlan, supprimerPlanComplet,
  getUsers, creerUser, modifierUser, toggleUserActif, resetPasswordAdmin,
  demanderResetPassword, getDemandesReset, approuverResetPassword, rejeterResetPassword,
  getRapports, envoyerRapport,
};