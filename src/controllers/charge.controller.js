// src/controllers/charge.controller.js
// ✅ HEURE TÉLÉPHONE : tous les NOW() remplacés par devTime(req)
// ✅ deviceTime: req.deviceTime passé aux services PDF pour les dates "maintenant"

const db   = require('../config/db');
const path = require('path');
const fs   = require('fs');
const { success, error } = require('../utils/response');
const { envoyerNotification, envoyerNotificationMultiple } = require('../services/notification.service');
const { envoyerPushNotification }                          = require('./pushNotification.controller');
const { genererPDFUnifie, genererPDFDeconsignation }       = require('../services/pdf.service');
const { devTime }                                          = require('../middlewares/deviceTime.middleware');

const heureMarocDepuisDevice = (req) => {
  const dt = req.deviceTime || new Date();
  return new Intl.DateTimeFormat('fr-MA', {
    timeZone: 'Africa/Casablanca', hour: '2-digit', minute: '2-digit', hour12: false,
  }).format(dt);
};

const getDemandesAConsigner = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT d.*, e.nom AS equipement_nom, e.code_equipement AS tag,
              e.localisation AS equipement_localisation, l.code AS lot_code,
              CONCAT(u.prenom,' ',u.nom) AS demandeur_nom,
              CONVERT_TZ(d.created_at,'+00:00','+01:00') AS created_at,
              CONVERT_TZ(d.updated_at,'+00:00','+01:00') AS updated_at
       FROM demandes_consignation d
       JOIN equipements e ON d.equipement_id=e.id
       LEFT JOIN lots l ON d.lot_id=l.id
       JOIN users u ON d.agent_id=u.id
       WHERE d.statut IN ('en_attente','en_cours','validee','consigne_process')
       ORDER BY d.created_at DESC`
    );
    return success(res, rows.map(d => ({ ...d, types_intervenants: d.types_intervenants ? JSON.parse(d.types_intervenants) : [] })), 'Demandes récupérées');
  } catch (err) { console.error('getDemandesAConsigner error:', err); return error(res,'Erreur serveur',500); }
};

const getDemandesADeconsigner = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT d.*, e.nom AS equipement_nom, e.code_equipement AS tag,
              e.localisation AS equipement_localisation, l.code AS lot_code,
              CONCAT(u.prenom,' ',u.nom) AS demandeur_nom,
              CONVERT_TZ(d.created_at,'+00:00','+01:00') AS created_at,
              CONVERT_TZ(d.updated_at,'+00:00','+01:00') AS updated_at
       FROM demandes_consignation d
       JOIN equipements e ON d.equipement_id=e.id
       LEFT JOIN lots l ON d.lot_id=l.id
       JOIN users u ON d.agent_id=u.id
       WHERE d.statut IN (
         'deconsigne_genie_civil','deconsigne_mecanique','deconsigne_electrique',
         'deconsigne_gc','deconsigne_mec','deconsigne_elec','deconsigne_intervent',
         'deconsigne_process','deconsigne_charge','consigne','consigne_charge',
         'consigne_process','deconsignee','cloturee'
       ) AND d.deconsignation_demandee=1
       ORDER BY d.updated_at DESC`
    );
    return success(res, rows.map(d => ({ ...d, types_intervenants: d.types_intervenants ? JSON.parse(d.types_intervenants) : [] })), 'Demandes à déconsigner récupérées');
  } catch (err) { console.error('getDemandesADeconsigner error:', err); return error(res,'Erreur serveur',500); }
};

const getDemandeDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const [demandes] = await db.query(
      `SELECT d.*, e.nom AS equipement_nom, e.code_equipement AS tag,
              e.localisation AS equipement_localisation, e.entite AS equipement_entite,
              l.code AS lot_code, l.description AS lot_description,
              CONCAT(u.prenom,' ',u.nom) AS demandeur_nom, u.matricule AS demandeur_matricule,
              CONVERT_TZ(d.created_at,             '+00:00','+01:00') AS created_at,
              CONVERT_TZ(d.updated_at,             '+00:00','+01:00') AS updated_at,
              CONVERT_TZ(d.date_validation,        '+00:00','+01:00') AS date_validation,
              CONVERT_TZ(d.date_validation_charge, '+00:00','+01:00') AS date_validation_charge,
              CONVERT_TZ(d.date_validation_process,'+00:00','+01:00') AS date_validation_process
       FROM demandes_consignation d
       JOIN equipements e ON d.equipement_id=e.id
       LEFT JOIN lots l ON d.lot_id=l.id
       JOIN users u ON d.agent_id=u.id
       WHERE d.id=?`, [id]
    );
    if (!demandes.length) return error(res,'Demande introuvable',404);
    const demande = demandes[0];
    demande.types_intervenants = demande.types_intervenants ? JSON.parse(demande.types_intervenants) : [];
    const [plans] = await db.query(
      `SELECT p.*, CONCAT(ue.prenom,' ',ue.nom) AS etabli_nom, CONCAT(ua.prenom,' ',ua.nom) AS approuve_nom,
              CONVERT_TZ(p.date_etabli,  '+00:00','+01:00') AS date_etabli,
              CONVERT_TZ(p.date_approuve,'+00:00','+01:00') AS date_approuve,
              CONVERT_TZ(p.created_at,   '+00:00','+01:00') AS created_at,
              CONVERT_TZ(p.updated_at,   '+00:00','+01:00') AS updated_at
       FROM plans_consignation p
       LEFT JOIN users ue ON p.etabli_par=ue.id LEFT JOIN users ua ON p.approuve_par=ua.id
       WHERE p.demande_id=?`, [id]
    );
    const plan = plans[0] || null;
    let points = [];
    if (plan) {
      const [pts] = await db.query(
        `SELECT pc.*, ex.numero_cadenas, ex.mcc_ref, ex.charge_type AS exec_charge_type,
                ex.date_consigne AS date_consigne,
                CONCAT(uc.prenom,' ',uc.nom) AS consigne_par_nom
         FROM points_consignation pc
         LEFT JOIN executions_consignation ex ON ex.point_id=pc.id
         LEFT JOIN users uc ON ex.consigne_par=uc.id
         WHERE pc.plan_id=? ORDER BY pc.numero_ligne ASC`, [plan.id]
      );
      points = pts;
    }
    return success(res, { demande, plan, points }, 'Détail récupéré');
  } catch (err) { console.error('getDemandeDetail error:', err); return error(res,'Erreur serveur',500); }
};

const getDemandeDeconsignationDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const [demandes] = await db.query(
      `SELECT d.*, e.nom AS equipement_nom, e.code_equipement AS tag,
              e.localisation AS equipement_localisation, l.code AS lot_code,
              CONCAT(u.prenom,' ',u.nom) AS demandeur_nom,
              CONVERT_TZ(d.created_at,'+00:00','+01:00') AS created_at,
              CONVERT_TZ(d.updated_at,'+00:00','+01:00') AS updated_at
       FROM demandes_consignation d
       JOIN equipements e ON d.equipement_id=e.id
       LEFT JOIN lots l ON d.lot_id=l.id
       JOIN users u ON d.agent_id=u.id
       WHERE d.id=? AND d.deconsignation_demandee=1`, [id]
    );
    if (!demandes.length) return error(res,'Demande introuvable ou déconsignation non demandée',404);
    const demande = demandes[0];
    demande.types_intervenants = demande.types_intervenants ? JSON.parse(demande.types_intervenants) : [];
    const [plans] = await db.query('SELECT * FROM plans_consignation WHERE demande_id=?',[id]);
    const plan = plans[0] || null;
    let pointsElectriques = [];
    if (plan) {
      const [pts] = await db.query(
        `SELECT pc.id, pc.numero_ligne, pc.repere_point, pc.localisation,
                pc.dispositif_condamnation, pc.etat_requis, pc.charge_type,
                ex.numero_cadenas AS cadenas_consigne, ex.mcc_ref,
                ex.date_consigne AS date_consigne,
                CONCAT(uc.prenom,' ',uc.nom) AS consigne_par_nom
         FROM points_consignation pc
         LEFT JOIN executions_consignation ex ON ex.point_id=pc.id
         LEFT JOIN users uc ON ex.consigne_par=uc.id
         WHERE pc.plan_id=? AND pc.charge_type='electricien'
         ORDER BY pc.numero_ligne ASC`, [plan.id]
      );
      pointsElectriques = pts;
    }
    const [deconsignes] = await db.query(
      `SELECT d.point_id, d.numero_cadenas AS cadenas_decons,
              CONVERT_TZ(d.date_deconsigne,'+00:00','+01:00') AS date_decons,
              CONCAT(u.prenom,' ',u.nom) AS decons_par_nom
       FROM deconsignations d LEFT JOIN users u ON u.id=d.deconsigne_par
       WHERE d.point_id IN (
         SELECT pc.id FROM points_consignation pc
         JOIN plans_consignation pl ON pl.id=pc.plan_id
         WHERE pl.demande_id=? AND pc.charge_type='electricien'
       )`, [id]
    );
    const deconsignesMap = {};
    for (const d of deconsignes) deconsignesMap[d.point_id] = d;
    const pointsAvecEtat = pointsElectriques.map(pt => ({
      ...pt, decons_fait: !!deconsignesMap[pt.id],
      cadenas_decons: deconsignesMap[pt.id]?.cadenas_decons || null,
      date_decons: deconsignesMap[pt.id]?.date_decons || null,
      decons_par_nom: deconsignesMap[pt.id]?.decons_par_nom || null,
    }));
    const totalPoints = pointsAvecEtat.length;
    const pointsValides = pointsAvecEtat.filter(p => p.decons_fait).length;
    return success(res, {
      demande, plan, points: pointsAvecEtat,
      progression: { total: totalPoints, valides: pointsValides, restants: totalPoints - pointsValides,
        pourcentage: totalPoints > 0 ? Math.round((pointsValides/totalPoints)*100) : 0 },
      pret_a_valider: totalPoints > 0 && pointsValides === totalPoints,
    }, 'Détail déconsignation récupéré');
  } catch (err) { console.error('getDemandeDeconsignationDetail error:', err); return error(res,'Erreur serveur',500); }
};

const scannerCadenasDeconsignation = async (req, res) => {
  try {
    const { id } = req.params;
    const { point_id, cadenas_scanne } = req.body;
    const charge_id = req.user.id;
    if (!point_id || !cadenas_scanne) return error(res,'point_id et cadenas_scanne sont requis',400);
    const [demandes] = await db.query('SELECT d.id FROM demandes_consignation d WHERE d.id=? AND d.deconsignation_demandee=1',[id]);
    if (!demandes.length) return error(res,'Demande introuvable ou déconsignation non demandée',404);
    const [points] = await db.query(
      `SELECT pc.id, ex.numero_cadenas AS cadenas_consigne FROM points_consignation pc
       LEFT JOIN executions_consignation ex ON ex.point_id=pc.id
       WHERE pc.id=? AND pc.charge_type='electricien'`, [point_id]
    );
    if (!points.length) return error(res,'Point introuvable ou non électrique',404);
    const point = points[0];
    if (!point.cadenas_consigne) return error(res,'Aucun cadenas enregistré pour ce point lors de la consignation',400);
    if (point.cadenas_consigne.trim().toLowerCase() !== cadenas_scanne.trim().toLowerCase())
      return error(res,`Cadenas incorrect. Attendu: ${point.cadenas_consigne} — Scanné: ${cadenas_scanne}`,400);
    const [existant] = await db.query('SELECT id FROM deconsignations WHERE point_id=?',[point_id]);
    if (existant.length > 0) return success(res, { point_id, deja_fait: true }, 'Ce point est déjà déconsigné');
    await db.query('INSERT INTO deconsignations (point_id, numero_cadenas, deconsigne_par, date_deconsigne) VALUES (?,?,?,?)',
      [point_id, cadenas_scanne, charge_id, devTime(req)]);
    await db.query("UPDATE points_consignation SET statut='deconsigne' WHERE id=?",[point_id]);
    const [planRows] = await db.query('SELECT pl.id FROM plans_consignation pl WHERE pl.demande_id=?',[id]);
    let tousDeconsignes = false;
    if (planRows.length > 0) {
      const planId = planRows[0].id;
      const [totalRows] = await db.query("SELECT COUNT(*) AS total FROM points_consignation WHERE plan_id=? AND charge_type='electricien'",[planId]);
      const [deconsFaits] = await db.query(`SELECT COUNT(*) AS fait FROM deconsignations dc JOIN points_consignation pc ON pc.id=dc.point_id WHERE pc.plan_id=? AND pc.charge_type='electricien'`,[planId]);
      tousDeconsignes = totalRows[0].total > 0 && deconsFaits[0].fait >= totalRows[0].total;
    }
    return success(res, { point_id, cadenas_scanne, cadenas_ok: true, tous_valides: tousDeconsignes }, 'Cadenas déconsigné avec succès');
  } catch (err) { console.error('scannerCadenasDeconsignation error:', err); return error(res,'Erreur serveur',500); }
};

const demarrerConsignation = async (req, res) => {
  try {
    const { id } = req.params;
    const charge_id = req.user.id;
    const [rows] = await db.query(
      `SELECT statut,
              CONVERT_TZ(date_validation_charge, '+00:00','+01:00') AS date_validation_charge,
              CONVERT_TZ(date_validation_process,'+00:00','+01:00') AS date_validation_process
       FROM demandes_consignation WHERE id=?`, [id]
    );
    if (!rows.length) return error(res,'Demande introuvable',404);
    const current = rows[0];
    if (current.statut === 'en_cours') return success(res, { date_validation_charge: current.date_validation_charge, date_validation_process: current.date_validation_process }, 'Consignation déjà en cours');
    const statutsAutorisesCharge = ['en_attente','en_cours','validee','consigne_process'];
    if (!statutsAutorisesCharge.includes(current.statut)) return success(res, { date_validation_charge: current.date_validation_charge, date_validation_process: current.date_validation_process }, `Statut actuel : ${current.statut}`);
    const newStatut = current.statut === 'consigne_process' ? 'consigne_process' : 'en_cours';
    await db.query('UPDATE demandes_consignation SET statut=?, charge_id=?, updated_at=? WHERE id=?',[newStatut, charge_id, devTime(req), id]);
    const [updated] = await db.query(`SELECT CONVERT_TZ(date_validation_charge,'+00:00','+01:00') AS date_validation_charge, CONVERT_TZ(date_validation_process,'+00:00','+01:00') AS date_validation_process FROM demandes_consignation WHERE id=?`,[id]);
    return success(res, { date_validation_charge: updated[0].date_validation_charge, date_validation_process: updated[0].date_validation_process }, 'Consignation démarrée');
  } catch (err) { console.error('demarrerConsignation error:', err); return error(res,'Erreur serveur',500); }
};

const refuserDemande = async (req, res) => {
  try {
    const { id } = req.params; const { motif } = req.body; const charge_id = req.user.id;
    if (!motif || !motif.trim()) return error(res,'Le motif de refus est obligatoire',400);
    const [rows] = await db.query('SELECT statut, agent_id, numero_ordre FROM demandes_consignation WHERE id=?',[id]);
    if (!rows.length) return error(res,'Demande introuvable',404);
    const dem = rows[0];
    if (!['en_attente','en_cours'].includes(dem.statut)) return error(res,`Impossible de refuser avec statut: ${dem.statut}`,400);
    await db.query("UPDATE demandes_consignation SET statut='rejetee', commentaire_rejet=?, charge_id=?, updated_at=? WHERE id=?",[motif.trim(), charge_id, devTime(req), id]);
    const [chargeInfo] = await db.query('SELECT prenom, nom FROM users WHERE id=?',[charge_id]);
    const chargeNom = chargeInfo.length ? `${chargeInfo[0].prenom} ${chargeInfo[0].nom}` : 'Chargé';
    const heure = heureMarocDepuisDevice(req);
    await envoyerNotification(dem.agent_id, '❌ Demande refusée', `Votre demande ${dem.numero_ordre} a été refusée par ${chargeNom} à ${heure}. Motif : ${motif.trim()}`, 'rejet', `demande/${id}`);
    await envoyerPushNotification([dem.agent_id], 'Demande refusée', `${dem.numero_ordre} refusée — ${motif.trim()}`, { demande_id: id, statut: 'rejetee' });
    return success(res, null, 'Demande refusée avec succès');
  } catch (err) { console.error('refuserDemande error:', err); return error(res,'Erreur serveur',500); }
};

const mettreEnAttente = async (req, res) => {
  try {
    const { id } = req.params; const { motif, heure_reprise } = req.body; const charge_id = req.user.id;
    const [rows] = await db.query('SELECT statut, agent_id, numero_ordre FROM demandes_consignation WHERE id=?',[id]);
    if (!rows.length) return error(res,'Demande introuvable',404);
    const dem = rows[0];
    const noteAttente = motif ? `En attente — ${motif}${heure_reprise ? ` — Reprise prévue : ${heure_reprise}` : ''}` : `Remise en attente par le chargé`;
    await db.query("UPDATE demandes_consignation SET statut='en_attente', charge_id=?, updated_at=?, commentaire_rejet=? WHERE id=?",[charge_id, devTime(req), noteAttente, id]);
    const [chargeInfo] = await db.query('SELECT prenom, nom FROM users WHERE id=?',[charge_id]);
    const chargeNom = chargeInfo.length ? `${chargeInfo[0].prenom} ${chargeInfo[0].nom}` : 'Chargé';
    const heure = heureMarocDepuisDevice(req);
    await envoyerNotification(dem.agent_id, 'Consignation suspendue', `La consignation ${dem.numero_ordre} a été suspendue par ${chargeNom} à ${heure}.${heure_reprise ? ` Reprise prévue : ${heure_reprise}` : ''} Motif : ${motif || 'Non précisé'}`, 'plan', `demande/${id}`);
    await envoyerPushNotification([dem.agent_id], 'Consignation suspendue', `${dem.numero_ordre} suspendue${heure_reprise ? ` — Reprise : ${heure_reprise}` : ''}`, { demande_id: id, statut: 'en_attente' });
    return success(res, null, 'Demande remise en attente');
  } catch (err) { console.error('mettreEnAttente error:', err); return error(res,'Erreur serveur',500); }
};

const scannerCadenas = async (req, res) => {
  try {
    const { pointId } = req.params; const { numero_cadenas, mcc_ref } = req.body; const charge_id = req.user.id;
    if (!numero_cadenas) return error(res,'numero_cadenas est requis',400);
    const mccRefVal = mcc_ref || '';
    const [points] = await db.query('SELECT id, charge_type FROM points_consignation WHERE id=?',[pointId]);
    if (!points.length) return error(res,'Point introuvable',404);
    const [existant] = await db.query('SELECT id FROM executions_consignation WHERE point_id=?',[pointId]);
    const dateConsigne = devTime(req);
    if (existant.length > 0) {
      await db.query('UPDATE executions_consignation SET numero_cadenas=?, mcc_ref=?, consigne_par=?, date_consigne=?, charge_type=? WHERE point_id=?',[numero_cadenas, mccRefVal, charge_id, dateConsigne, points[0].charge_type, pointId]);
    } else {
      await db.query('INSERT INTO executions_consignation (point_id, numero_cadenas, mcc_ref, consigne_par, date_consigne, charge_type) VALUES (?,?,?,?,?,?)',[pointId, numero_cadenas, mccRefVal, charge_id, dateConsigne, points[0].charge_type]);
    }
    await db.query("UPDATE points_consignation SET statut='consigne' WHERE id=?",[pointId]);
    return success(res, { pointId, numero_cadenas, mcc_ref: mccRefVal }, 'Cadenas scanné avec succès');
  } catch (err) { console.error('scannerCadenas error:', err); return error(res,'Erreur serveur',500); }
};

const scannerCadenasLibre = async (req, res) => {
  try {
    const { demande_id, numero_cadenas, mcc_ref, repere, localisation, dispositif, etat_requis, charge_type } = req.body;
    const charge_id = req.user.id;
    if (!demande_id || !numero_cadenas) return error(res,'demande_id et numero_cadenas sont requis',400);
    const mccRefVal = mcc_ref || ''; const chargeType = charge_type || 'electricien';
    const dt = devTime(req);
    let [plans] = await db.query('SELECT id FROM plans_consignation WHERE demande_id=?',[demande_id]);
    let plan_id;
    if (plans.length === 0) {
      const [planResult] = await db.query("INSERT INTO plans_consignation (demande_id, etabli_par, approuve_par, date_etabli, date_approuve, statut, remarques) VALUES (?,?,?,?,?,'en_execution','Plan créé automatiquement')",[demande_id, charge_id, charge_id, dt, dt]);
      plan_id = planResult.insertId;
    } else {
      plan_id = plans[0].id;
      await db.query("UPDATE plans_consignation SET statut='en_execution', updated_at=? WHERE id=?",[dt, plan_id]);
    }
    const [lineCount] = await db.query('SELECT MAX(numero_ligne) AS max_ligne FROM points_consignation WHERE plan_id=?',[plan_id]);
    const nextLigne = (lineCount[0].max_ligne || 0) + 1;
    const [pointResult] = await db.query("INSERT INTO points_consignation (plan_id, numero_ligne, repere_point, localisation, dispositif_condamnation, etat_requis, electricien_id, statut, charge_type) VALUES (?,?,?,?,?,?,?,'consigne',?)",[plan_id, nextLigne, repere || `Point-${nextLigne}`, localisation || '—', dispositif || '—', etat_requis || 'ouvert', charge_id, chargeType]);
    const point_id = pointResult.insertId;
    await db.query('INSERT INTO executions_consignation (point_id, numero_cadenas, mcc_ref, consigne_par, date_consigne, charge_type) VALUES (?,?,?,?,?,?)',[point_id, numero_cadenas, mccRefVal, charge_id, dt, chargeType]);
    return success(res, { point_id, plan_id, numero_cadenas, mcc_ref: mccRefVal, numero_ligne: nextLigne }, 'Cadenas enregistré');
  } catch (err) { console.error('scannerCadenasLibre error:', err); return error(res,'Erreur serveur',500); }
};

const enregistrerPhoto = async (req, res) => {
  try {
    const { id } = req.params; const { photo_base64 } = req.body;
    if (!photo_base64) return error(res,'Photo requise',400);
    const uploadsDir = path.join(__dirname, '../../uploads/consignations', id.toString());
    if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
    const fileName = `photo_${Date.now()}.jpg`;
    const base64Data = photo_base64.replace(/^data:image\/\w+;base64,/, '');
    fs.writeFileSync(path.join(uploadsDir, fileName), Buffer.from(base64Data, 'base64'));
    const photoPath = `uploads/consignations/${id}/${fileName}`;
    await db.query('UPDATE demandes_consignation SET photo_path=? WHERE id=?',[photoPath, id]);
    return success(res, { photo_path: photoPath }, 'Photo enregistrée');
  } catch (err) { console.error('enregistrerPhoto error:', err); return error(res,'Erreur serveur',500); }
};

// ✅ deviceTime: req.deviceTime passé à genererPDFUnifie
const validerConsignation = async (req, res) => {
  try {
    const { id } = req.params; const charge_id = req.user.id;
    const dt = devTime(req);
    const [demandes] = await db.query(
      `SELECT d.*, e.nom AS equipement_nom, e.code_equipement AS tag,
              e.localisation AS equipement_localisation, e.entite AS equipement_entite,
              l.code AS lot_code, CONCAT(ua.prenom,' ',ua.nom) AS demandeur_nom,
              ua.id AS agent_id_val, d.date_validation_process, d.date_validation_charge
       FROM demandes_consignation d
       JOIN equipements e ON d.equipement_id=e.id LEFT JOIN lots l ON d.lot_id=l.id
       JOIN users ua ON d.agent_id=ua.id WHERE d.id=?`, [id]
    );
    if (!demandes.length) return error(res,'Demande introuvable',404);
    const demande = demandes[0];
    demande.types_intervenants = demande.types_intervenants ? JSON.parse(demande.types_intervenants) : [];
    if (['consigne_charge','consigne'].includes(demande.statut)) return error(res,'Vous avez déjà validé cette consignation',400);
    if (!['en_attente','en_cours','validee','consigne_process'].includes(demande.statut)) return error(res,`Statut invalide pour valider : ${demande.statut}`,400);
    const [plans] = await db.query(`SELECT p.*, CONCAT(ue.prenom,' ',ue.nom) AS etabli_nom, CONCAT(ua2.prenom,' ',ua2.nom) AS approuve_nom FROM plans_consignation p LEFT JOIN users ue ON p.etabli_par=ue.id LEFT JOIN users ua2 ON p.approuve_par=ua2.id WHERE p.demande_id=?`,[id]);
    const plan = plans[0] || null;
    let points = [];
    if (plan) {
      const [pts] = await db.query(`SELECT pc.*, ex.numero_cadenas, ex.mcc_ref, ex.date_consigne, ex.charge_type AS exec_charge_type, CONCAT(uc.prenom,' ',uc.nom) AS consigne_par_nom FROM points_consignation pc LEFT JOIN executions_consignation ex ON ex.point_id=pc.id LEFT JOIN users uc ON ex.consigne_par=uc.id WHERE pc.plan_id=? ORDER BY pc.numero_ligne ASC`,[plan.id]);
      points = pts;
    }
    const pointsElec = points.filter(p => p.charge_type === 'electricien' || !p.charge_type);
    if (pointsElec.length > 0 && !pointsElec.every(p => p.numero_cadenas !== null)) return error(res,'Tous les cadenas électriques doivent être scannés avant validation',400);
    const [chargeInfo] = await db.query('SELECT prenom, nom, matricule, badge_ocp_id FROM users WHERE id=?',[charge_id]);
    if (!chargeInfo.length) return error(res,'Chargé introuvable',404);
    const charge = chargeInfo[0];
    const processDejaValide = demande.statut === 'consigne_process' || !!demande.date_validation_process;
    let processInfo = null;
    if (processDejaValide) {
      const [procExec] = await db.query(`SELECT DISTINCT u.prenom, u.nom FROM executions_consignation ex JOIN points_consignation pc ON pc.id=ex.point_id JOIN plans_consignation pl ON pl.id=pc.plan_id JOIN users u ON u.id=ex.consigne_par WHERE pl.demande_id=? AND ex.charge_type='process' LIMIT 1`,[id]);
      if (procExec.length) processInfo = { prenom: procExec[0].prenom, nom: procExec[0].nom };
    }
    const pdfDir = path.join(__dirname, '../../uploads/pdfs');
    if (!fs.existsSync(pdfDir)) fs.mkdirSync(pdfDir, { recursive: true });
    const pdfFileName = `F-HSE-SEC-22-01_${demande.numero_ordre}_unifie_${Date.now()}.pdf`;
    const pdfPath = path.join(pdfDir, pdfFileName);
    const photoAbsPath = demande.photo_path ? path.join(__dirname, '../../', demande.photo_path) : null;
    // ✅ deviceTime: req.deviceTime passé pour les dates "maintenant" du PDF
    await genererPDFUnifie({ demande, plan, points, chargeInfo: charge, processInfo, pdfPath, photoAbsPath, deviceTime: req.deviceTime });
    const pdfRelPath = `uploads/pdfs/${pdfFileName}`;
    const pointsProcess = points.filter(p => p.charge_type === 'process');
    const hasProcess = pointsProcess.length > 0 || (demande.types_intervenants || []).includes('process');
    let nouveauStatut = !hasProcess ? 'consigne' : processDejaValide ? 'consigne' : 'consigne_charge';
    const dateValidationFinal = nouveauStatut === 'consigne' ? `, date_validation='${dt}'` : '';
    await db.query(`UPDATE demandes_consignation SET statut=?, charge_id=?, date_validation_charge=?, pdf_path_charge=?, pdf_path_final=?, updated_at=? ${dateValidationFinal} WHERE id=?`,[nouveauStatut, charge_id, dt, pdfRelPath, pdfRelPath, dt, id]);
    if (plan && nouveauStatut === 'consigne') await db.query("UPDATE plans_consignation SET statut='execute', updated_at=? WHERE id=?",[dt, plan.id]);
    if (pointsElec.length > 0) await db.query("UPDATE points_consignation SET statut='verifie' WHERE plan_id=? AND charge_type IN ('electricien','') AND statut='consigne'",[plan ? plan.id : 0]);
    const [archiveExist] = await db.query('SELECT id FROM dossiers_archives WHERE demande_id=?',[id]);
    const remarques = nouveauStatut === 'consigne' ? (processDejaValide ? 'Consignation complète — Chargé EN SECOND — PDF final' : 'Consignation complète — PDF final') : 'Consignation chargé EN PREMIER — en attente process';
    if (archiveExist.length > 0) { await db.query('UPDATE dossiers_archives SET pdf_path=?, cloture_par=?, date_cloture=?, remarques=? WHERE demande_id=?',[pdfRelPath, charge_id, dt, remarques, id]); }
    else { await db.query('INSERT INTO dossiers_archives (demande_id, pdf_path, cloture_par, date_cloture, remarques) VALUES (?,?,?,?,?)',[id, pdfRelPath, charge_id, dt, remarques]); }
    const heure = heureMarocDepuisDevice(req);
    if (nouveauStatut === 'consigne') {
      await envoyerNotification(demande.agent_id_val, '✅ Consignation complète', `Votre demande ${demande.numero_ordre} — TAG ${demande.tag} est entièrement consignée à ${heure}. PDF F-HSE-SEC-22-01 disponible.`, 'execution', `demande/${id}`);
      await envoyerPushNotification([demande.agent_id_val], '✅ Consignation complète', `${demande.numero_ordre} — ${demande.tag} consigné à ${heure}.`, { demande_id: id, statut: 'consigne' });
      await _notifierChefsIntervenants(demande, id, heure);
    } else {
      await envoyerNotification(demande.agent_id_val, '⚡ Consignation électrique effectuée', `Points électriques consignés par ${charge.prenom} ${charge.nom} à ${heure}. En attente validation process.`, 'execution', `demande/${id}`);
      await envoyerPushNotification([demande.agent_id_val], '⚡ Consignation électrique effectuée', `${demande.numero_ordre} — points consignés à ${heure}.`, { demande_id: id, statut: 'consigne_charge' });
      const [chefProcess] = await db.query("SELECT u.id FROM users u JOIN roles r ON u.role_id=r.id WHERE r.nom='chef_process' AND u.actif=1");
      if (chefProcess.length > 0) {
        const chefProcessIds = chefProcess.map(u => u.id);
        await envoyerNotificationMultiple(chefProcessIds, '🔔 Validation process requise', `${charge.prenom} ${charge.nom} a validé les points électriques du départ ${demande.tag} à ${heure}. Veuillez valider vos points process.`, 'intervention', `demande/${id}`);
        await envoyerPushNotification(chefProcessIds, '🔔 Validation process requise', `${demande.tag} — points process en attente`, { demande_id: id, statut: 'consigne_charge' });
      }
    }
    return success(res, { pdf_path: pdfRelPath, nouveau_statut: nouveauStatut, process_deja_valide: processDejaValide }, 'Validation chargé effectuée');
  } catch (err) { console.error('validerConsignation error:', err); return error(res,'Erreur serveur',500); }
};

// ✅ deviceTime: req.deviceTime passé à genererPDFDeconsignation
const validerDeconsignationFinale = async (req, res) => {
  try {
    const { id } = req.params; const { badge_id } = req.body; const charge_id = req.user.id;
    const dt = devTime(req);
    if (!badge_id || !badge_id.trim()) return error(res,'Le scan du badge est obligatoire pour valider la déconsignation',400);
    const [chargeRows] = await db.query('SELECT id, prenom, nom, matricule, badge_ocp_id FROM users WHERE id=?',[charge_id]);
    if (!chargeRows.length) return error(res,'Chargé introuvable',404);
    const charge = chargeRows[0];
    if (!charge.badge_ocp_id) return error(res,"Aucun badge enregistré pour ce compte chargé. Contactez l'administrateur.",400);
    if (charge.badge_ocp_id.trim().toLowerCase() !== badge_id.trim().toLowerCase()) return error(res,'Badge incorrect. Veuillez scanner votre badge personnel.',400);
    const [demandes] = await db.query(`SELECT d.*, e.nom AS equipement_nom, e.code_equipement AS tag, e.localisation AS equipement_localisation, e.entite AS equipement_entite, l.code AS lot_code, CONCAT(ua.prenom,' ',ua.nom) AS demandeur_nom, ua.id AS agent_id_val FROM demandes_consignation d JOIN equipements e ON d.equipement_id=e.id LEFT JOIN lots l ON d.lot_id=l.id JOIN users ua ON d.agent_id=ua.id WHERE d.id=?`,[id]);
    if (!demandes.length) return error(res,'Demande introuvable',404);
    const demande = demandes[0];
    demande.types_intervenants = demande.types_intervenants ? JSON.parse(demande.types_intervenants) : [];
    if (demande.statut === 'deconsigne_charge') return error(res,'Vous avez déjà validé la déconsignation électrique',400);
    const STATUTS_DECONS_OK = ['deconsigne_genie_civil','deconsigne_mecanique','deconsigne_electrique','deconsigne_gc','deconsigne_mec','deconsigne_elec','deconsigne_intervent','deconsigne_process','consigne','consigne_charge','consigne_process'];
    if (!STATUTS_DECONS_OK.includes(demande.statut)) return error(res,`Statut invalide pour déconsigner (${demande.statut})`,400);
    const [planRows] = await db.query('SELECT id FROM plans_consignation WHERE demande_id=?',[id]);
    const plan = planRows[0] || null;
    if (plan) {
      const [totalElec] = await db.query("SELECT COUNT(*) AS total FROM points_consignation WHERE plan_id=? AND charge_type='electricien'",[plan.id]);
      const [deconsFaits] = await db.query(`SELECT COUNT(*) AS fait FROM deconsignations dc JOIN points_consignation pc ON pc.id=dc.point_id WHERE pc.plan_id=? AND pc.charge_type='electricien'`,[plan.id]);
      if (totalElec[0].total > 0 && deconsFaits[0].fait < totalElec[0].total) return error(res,`${totalElec[0].total - deconsFaits[0].fait} cadenas électrique(s) non encore scannés. Veuillez tous les scanner avant de valider.`,400);
    }
    let points = [];
    if (plan) {
      const [pts] = await db.query(`SELECT pc.*, ex.numero_cadenas, ex.mcc_ref, ex.date_consigne AS date_consigne, ex.charge_type AS exec_charge_type, CONCAT(uc.prenom,' ',uc.nom) AS consigne_par_nom, dc.numero_cadenas AS cadenas_decons, dc.date_deconsigne AS date_decons, CONCAT(ud.prenom,' ',ud.nom) AS decons_par_nom FROM points_consignation pc LEFT JOIN executions_consignation ex ON ex.point_id=pc.id LEFT JOIN users uc ON ex.consigne_par=uc.id LEFT JOIN deconsignations dc ON dc.point_id=pc.id LEFT JOIN users ud ON ud.id=dc.deconsigne_par WHERE pc.plan_id=? ORDER BY pc.numero_ligne ASC`,[plan.id]);
      points = pts;
    }
    let processInfo = null;
    if (demande.statut === 'deconsigne_process') {
      const [procRows] = await db.query(`SELECT DISTINCT u.prenom, u.nom FROM deconsignations dc JOIN points_consignation pc ON pc.id=dc.point_id JOIN plans_consignation pl ON pl.id=pc.plan_id JOIN users u ON u.id=dc.deconsigne_par WHERE pl.demande_id=? AND pc.charge_type='process' LIMIT 1`,[id]);
      if (procRows.length) processInfo = procRows[0];
    }
    const pdfDir = path.join(__dirname, '../../uploads/pdfs');
    if (!fs.existsSync(pdfDir)) fs.mkdirSync(pdfDir, { recursive: true });
    const pdfFileName = `F-HSE-SEC-22-01_${demande.numero_ordre}_decons_charge_${Date.now()}.pdf`;
    const pdfPath = path.join(pdfDir, pdfFileName);
    const photoAbsPath = demande.photo_path ? path.join(__dirname, '../../', demande.photo_path) : null;
    // ✅ deviceTime: req.deviceTime passé pour les dates "maintenant" du PDF
    await genererPDFDeconsignation({ demande, plan, points, chargeInfo: charge, processInfo, pdfPath, photoAbsPath, typeDeconsignation: 'charge', deviceTime: req.deviceTime });
    const pdfRelPath = `uploads/pdfs/${pdfFileName}`;
    const pointsProcess = plan ? points.filter(p => p.charge_type === 'process') : [];
    const hasProcess = pointsProcess.length > 0 || demande.types_intervenants.includes('process');
    const processDejaDecons = demande.statut === 'deconsigne_process';
    let nouveauStatut = !hasProcess ? 'deconsignee' : processDejaDecons ? 'deconsignee' : 'deconsigne_charge';
    const dateCol = nouveauStatut === 'deconsignee' ? `, date_deconsignation='${dt}'` : '';
    await db.query(`UPDATE demandes_consignation SET statut=?, pdf_path_final=?, updated_at=? ${dateCol} WHERE id=?`,[nouveauStatut, pdfRelPath, dt, id]);
    await db.query('UPDATE dossiers_archives SET pdf_path=?, cloture_par=?, date_cloture=?, remarques=? WHERE demande_id=?',[pdfRelPath, charge_id, dt, `PDF déconsignation — ${nouveauStatut}`, id]);
    const heure = heureMarocDepuisDevice(req);
    if (nouveauStatut === 'deconsignee') {
      await envoyerNotification(demande.agent_id_val, '🔓 Déconsignation complète — PDF disponible', `Votre demande ${demande.numero_ordre} — TAG ${demande.tag} est entièrement déconsignée à ${heure}. Le PDF est disponible.`, 'deconsignation', `demande/${id}`);
      await envoyerPushNotification([demande.agent_id_val], '🔓 Déconsignation complète', `${demande.numero_ordre} — ${demande.tag} déconsigné à ${heure}.`, { demande_id: id, statut: 'deconsignee' });
    } else {
      await envoyerNotification(demande.agent_id_val, '⚡ Déconsignation électrique validée', `Déconsignation électrique par ${charge.prenom} ${charge.nom} à ${heure}. En attente validation process.`, 'deconsignation', `demande/${id}`);
      await envoyerPushNotification([demande.agent_id_val], '⚡ Déconsignation électrique effectuée', `${demande.numero_ordre} — points électriques déconsignés à ${heure}.`, { demande_id: id, statut: 'deconsigne_charge' });
      const [chefProcess] = await db.query("SELECT u.id FROM users u JOIN roles r ON u.role_id=r.id WHERE r.nom='chef_process' AND u.actif=1");
      if (chefProcess.length > 0) {
        const ids = chefProcess.map(u => u.id);
        await envoyerNotificationMultiple(ids, '🔔 Déconsignation process requise', `${charge.prenom} ${charge.nom} a déconsigné ses points sur ${demande.tag} (${demande.numero_ordre}) à ${heure}. Veuillez déconsigner vos vannes process.`, 'deconsignation', `demande/${id}`);
        await envoyerPushNotification(ids, '🔔 Déconsignation process requise', `${demande.tag} — déconsignation process en attente`, { demande_id: id, statut: 'deconsigne_charge' });
      }
    }
    return success(res, { pdf_path: pdfRelPath, nouveau_statut: nouveauStatut, badge_verifie: true }, 'Déconsignation chargé validée');
  } catch (err) { console.error('validerDeconsignationFinale error:', err); return error(res,'Erreur serveur',500); }
};

const _notifierChefsIntervenants = async (demande, demandeId, heure) => {
  const types = demande.types_intervenants || [];
  if (types.length === 0) return;
  const roleNomMap = { genie_civil: 'chef_genie_civil', mecanique: 'chef_mecanique', electrique: 'chef_electrique' };
  const roleNomsCibles = types.filter(t => t !== 'process').map(t => roleNomMap[t]).filter(Boolean);
  if (roleNomsCibles.length > 0) {
    const placeholders = roleNomsCibles.map(() => '?').join(', ');
    const [chefsCibles] = await db.query(`SELECT u.id FROM users u JOIN roles r ON u.role_id=r.id WHERE r.nom IN (${placeholders}) AND u.actif=1`, roleNomsCibles);
    if (chefsCibles.length > 0) {
      const chefIds = chefsCibles.map(u => u.id);
      await envoyerNotificationMultiple(chefIds, '🔓 Autorisation de travail disponible', `Le départ ${demande.tag} (LOT ${demande.lot_code}) est consigné depuis ${heure}. Vos équipes peuvent intervenir.`, 'autorisation', `demande/${demandeId}`);
      await envoyerPushNotification(chefIds, '🔓 Autorisation de travail disponible', `${demande.tag} (LOT ${demande.lot_code}) consigné`, { demande_id: demandeId, statut: 'consigne' });
      await envoyerNotificationMultiple(chefIds, '👷 Entrez vos équipes SVP', `Le départ ${demande.tag} est consigné à ${heure}. Enregistrez les membres de votre équipe.`, 'intervention', `equipe/${demandeId}`);
      await envoyerPushNotification(chefIds, '👷 Entrez vos équipes SVP', `${demande.tag} consigné — Enregistrez votre équipe maintenant`, { demande_id: demandeId, statut: 'consigne', action: 'enregistrer_equipe' });
    }
  }
};

const getHistorique = async (req, res) => {
  try {
    const charge_id = req.user.id;
    const [rows] = await db.query(`SELECT d.*, e.nom AS equipement_nom, e.code_equipement AS tag, l.code AS lot_code, CONCAT(u.prenom,' ',u.nom) AS demandeur_nom, d.pdf_path_final AS pdf_path, CONVERT_TZ(d.created_at,'+00:00','+01:00') AS created_at, CONVERT_TZ(d.updated_at,'+00:00','+01:00') AS updated_at, CONVERT_TZ(d.date_validation,'+00:00','+01:00') AS date_validation, CONVERT_TZ(d.date_validation_charge,'+00:00','+01:00') AS date_validation_charge FROM demandes_consignation d JOIN equipements e ON d.equipement_id=e.id LEFT JOIN lots l ON d.lot_id=l.id JOIN users u ON d.agent_id=u.id WHERE d.charge_id=? ORDER BY d.updated_at DESC`,[charge_id]);
    return success(res, rows.map(d => ({ ...d, types_intervenants: d.types_intervenants ? JSON.parse(d.types_intervenants) : [] })), 'Historique récupéré');
  } catch (err) { console.error('getHistorique error:', err); return error(res,'Erreur serveur',500); }
};

const servirPDF = async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await db.query('SELECT statut, pdf_path_final, pdf_path_charge, types_intervenants FROM demandes_consignation WHERE id=?',[id]);
    if (!rows.length) return res.status(404).json({ message: 'Demande introuvable' });
    const demande = rows[0];
    const types = demande.types_intervenants ? JSON.parse(demande.types_intervenants) : [];
    const hasProcess = types.includes('process');
    const STATUTS_PDF_OK = ['consigne','deconsigne_genie_civil','deconsigne_mecanique','deconsigne_electrique','deconsigne_gc','deconsigne_mec','deconsigne_elec','deconsigne_intervent','deconsigne_charge','deconsigne_process','deconsignee','cloturee'];
    const peutVoir = STATUTS_PDF_OK.includes(demande.statut) || (demande.statut === 'consigne_charge' && !hasProcess);
    if (!peutVoir) return res.status(403).json({ message: demande.statut === 'consigne_charge' ? 'Le PDF final sera disponible une fois que le chef process aura également validé.' : 'Vous devez valider la consignation avant de pouvoir accéder au PDF', statut: demande.statut, besoin: demande.statut === 'consigne_charge' ? 'validation_process' : 'validation_charge' });
    const pdfRelPath = demande.pdf_path_final || demande.pdf_path_charge;
    if (!pdfRelPath) return res.status(404).json({ message: 'PDF non encore généré' });
    const pdfAbsPath = path.join(__dirname, '../../', pdfRelPath);
    if (!fs.existsSync(pdfAbsPath)) {
      const [archive] = await db.query('SELECT pdf_path FROM dossiers_archives WHERE demande_id=?',[id]);
      if (archive.length && archive[0].pdf_path) {
        const fallbackPath = path.join(__dirname, '../../', archive[0].pdf_path);
        if (fs.existsSync(fallbackPath)) { res.setHeader('Content-Type','application/pdf'); res.setHeader('Content-Disposition',`inline; filename="consignation_${id}.pdf"`); return fs.createReadStream(fallbackPath).pipe(res); }
      }
      return res.status(404).json({ message: 'Fichier PDF introuvable sur le serveur' });
    }
    res.setHeader('Content-Type','application/pdf');
    res.setHeader('Content-Disposition',`inline; filename="consignation_${id}.pdf"`);
    fs.createReadStream(pdfAbsPath).pipe(res);
  } catch (err) { console.error('servirPDF error:', err); return res.status(500).json({ message: 'Erreur serveur' }); }
};

module.exports = {
  getDemandesAConsigner, getDemandesADeconsigner, getDemandeDetail,
  getDemandeDeconsignationDetail, scannerCadenasDeconsignation,
  demarrerConsignation, refuserDemande, mettreEnAttente,
  scannerCadenas, scannerCadenasLibre, enregistrerPhoto,
  validerConsignation, validerDeconsignationFinale,
  getHistorique, servirPDF,
};