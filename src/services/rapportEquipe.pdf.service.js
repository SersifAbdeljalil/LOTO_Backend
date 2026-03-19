// src/services/rapportEquipe.pdf.service.js
// ✅ FIX 1 — Les dates MySQL sont en UTC, on les convertit en heure Maroc (Africa/Casablanca)
//            AVANT de les envoyer au script Python.
//            Le script Python reçoit des strings ISO AVEC timezone (+01:00 ou +00:00 Ramadan)
//            → to_maroc() les détecte et les traite correctement.
// ✅ FIX 2 — date_deconsignation réelle passée au lieu de now() dans le récap PDF
// ✅ FIX 3 — heure_scan_sortie utilisée en priorité sur heure_sortie pour la précision
// ✅ FIX 4 — stats.duree_totale_min calculée si absente
'use strict';

const path       = require('path');
const fs         = require('fs');
const { execFile } = require('child_process');
const os         = require('os');

const PYTHON_SCRIPT = path.join(__dirname, 'rapportEquipe_pdf_service.py');
const LOGO_PATH     = path.join(__dirname, '../utils/OCPLOGO.png');

const METIER_LABELS = {
  genie_civil: 'Génie Civil',
  mecanique:   'Mécanique',
  electrique:  'Électrique',
  process:     'Process',
};

// ── Conversion UTC → heure Maroc (Africa/Casablanca) ────────────────────────
// MySQL stocke en UTC. Node.js retourne les dates telles quelles (UTC).
// On convertit en ISO string avec l'offset Maroc réel AVANT d'envoyer au Python.
// Cela évite toute ambiguïté dans le script Python : il reçoit une date déjà localisée.
//
// Maroc : UTC+1 en temps normal, UTC+0 pendant le Ramadan (depuis 2020).
// On utilise l'API Intl pour obtenir l'offset réel dynamiquement.
// Cela est Ramadan-safe : l'offset sera 0 pendant le Ramadan, 1 sinon.

function getMarocOffsetMinutes(date) {
  // Méthode fiable : comparer UTC avec heure Maroc via Intl.DateTimeFormat
  // Intl connaît Africa/Casablanca avec les règles DST Ramadan si tzdata est à jour
  try {
    const utcMs = date.getTime();

    // Obtenir les composantes locales Maroc
    const formatter = new Intl.DateTimeFormat('fr-MA', {
      timeZone: 'Africa/Casablanca',
      year: 'numeric', month: '2-digit', day: '2-digit',
      hour: '2-digit', minute: '2-digit', second: '2-digit',
      hour12: false,
    });

    const parts = formatter.formatToParts(date);
    const p = {};
    parts.forEach(({ type, value }) => { p[type] = value; });

    // Reconstruire la date locale Maroc comme si c'était UTC
    const localMs = Date.UTC(
      parseInt(p.year),
      parseInt(p.month) - 1,
      parseInt(p.day),
      parseInt(p.hour === '24' ? '0' : p.hour),
      parseInt(p.minute),
      parseInt(p.second),
    );

    // Offset en minutes = différence entre heure locale Maroc et UTC
    return Math.round((localMs - utcMs) / 60000);
  } catch (e) {
    // Fallback : UTC+1 (heure normale Maroc hors Ramadan)
    console.warn('[rapportEquipePDF] Intl.DateTimeFormat unavailable, fallback UTC+1:', e.message);
    return 60;
  }
}

/**
 * Convertit une date UTC (string ou Date) en ISO string avec offset Maroc.
 * Ex : "2026-03-10 22:22:46" (UTC MySQL) → "2026-03-10T23:22:46+01:00" (Maroc normal)
 *                                        → "2026-03-10T22:22:46+00:00" (Maroc Ramadan)
 *
 * Le script Python reçoit cette string avec timezone explicite.
 * to_maroc() détecte la timezone et fait une conversion correcte.
 */
function toMarocISOString(dateInput) {
  if (!dateInput) return null;

  let date;
  if (dateInput instanceof Date) {
    date = dateInput;
  } else if (typeof dateInput === 'string') {
    // MySQL retourne "2026-03-10 22:22:46" sans timezone → c'est UTC
    // On force l'interprétation UTC en remplaçant espace par T et ajoutant Z
    const cleaned = dateInput.replace(' ', 'T');
    const withZ = cleaned.endsWith('Z') || cleaned.includes('+') ? cleaned : cleaned + 'Z';
    date = new Date(withZ);
  } else {
    return null;
  }

  if (isNaN(date.getTime())) return null;

  const offsetMin = getMarocOffsetMinutes(date);
  const offsetH   = Math.floor(Math.abs(offsetMin) / 60);
  const offsetM   = Math.abs(offsetMin) % 60;
  const sign      = offsetMin >= 0 ? '+' : '-';
  const offsetStr = `${sign}${String(offsetH).padStart(2, '0')}:${String(offsetM).padStart(2, '0')}`;

  // Reconstruire la date locale Maroc
  const localMs      = date.getTime() + offsetMin * 60000;
  const localDate    = new Date(localMs);

  const pad = (n) => String(n).padStart(2, '0');
  const iso = `${localDate.getUTCFullYear()}-${pad(localDate.getUTCMonth() + 1)}-${pad(localDate.getUTCDate())}` +
              `T${pad(localDate.getUTCHours())}:${pad(localDate.getUTCMinutes())}:${pad(localDate.getUTCSeconds())}` +
              offsetStr;

  return iso;
}

/**
 * Calcule la durée en minutes entre deux dates (strings UTC MySQL).
 */
function dureeMinutes(debut, fin) {
  if (!debut || !fin) return null;
  const d1 = new Date(debut.replace(' ', 'T') + (debut.includes('Z') || debut.includes('+') ? '' : 'Z'));
  const d2 = new Date(fin.replace(' ', 'T')   + (fin.includes('Z')   || fin.includes('+')   ? '' : 'Z'));
  if (isNaN(d1) || isNaN(d2)) return null;
  return Math.round((d2 - d1) / 60000);
}

/**
 * Génère le rapport PDF via le script Python.
 * @param {{ demande, membres, chef, stats, pdfPath }} opts
 */
const genererRapportEquipePDF = ({ demande, membres, chef, stats, pdfPath }) => {
  return new Promise((resolve, reject) => {

    // ✅ FIX 1 — Convertir toutes les dates membres UTC → ISO Maroc avec offset
    const membresConverties = membres.map(m => {
      // Utiliser heure_scan_sortie en priorité (plus précis) sinon heure_sortie
      const heureSortiePrecise = m.heure_scan_sortie || m.heure_sortie || null;

      return {
        id                 : m.id,
        nom                : m.nom               || '',
        badge_ocp_id       : m.badge_ocp_id       || '',
        matricule          : m.matricule           || '',
        numero_cadenas     : m.numero_cadenas      || '',
        cad_id             : m.cad_id              || '',
        // ✅ Conversion UTC → Maroc avec offset explicite
        heure_entree       : toMarocISOString(m.heure_entree),
        heure_sortie       : toMarocISOString(heureSortiePrecise),
        heure_scan_sortie  : toMarocISOString(m.heure_scan_sortie),
        scan_cadenas_sortie: m.scan_cadenas_sortie || '',
        statut             : m.statut              || 'en_attente',
      };
    });

    // ✅ FIX 2 — date_deconsignation réelle + conversion UTC → Maroc
    const dateDeconsignation = demande.date_deconsignation || demande.updated_at || null;

    // ✅ FIX 4 — Calculer stats.duree_totale_min si absent
    // La durée totale = durée maximale parmi les membres (depuis entrée du premier jusqu'à sortie du dernier)
    let durTotale = stats ? stats.duree_totale_min : null;
    if (!durTotale && membresConverties.length > 0) {
      const entreesValides = membresConverties.filter(m => m.heure_entree);
      const sortiesValides = membresConverties.filter(m => m.heure_sortie);
      if (entreesValides.length > 0 && sortiesValides.length > 0) {
        // Première entrée → dernière sortie
        const premEntree = entreesValides.reduce((min, m) =>
          m.heure_entree < min ? m.heure_entree : min, entreesValides[0].heure_entree);
        const dernSortie = sortiesValides.reduce((max, m) =>
          m.heure_sortie > max ? m.heure_sortie : max, sortiesValides[0].heure_sortie);
        durTotale = dureeMinutes(
          premEntree.replace(/T/, ' ').replace(/[+-]\d{2}:\d{2}$/, ''),
          dernSortie.replace(/T/, ' ').replace(/[+-]\d{2}:\d{2}$/, ''),
        );
      }
    }

    // ✅ Stats complètes passées au Python
    const statsCompletes = {
      ...(stats || {}),
      duree_totale_min: durTotale,
      total_membres   : membresConverties.length,
      membres_sortis  : membresConverties.filter(m => m.statut === 'sortie').length,
    };

    // Construire le JSON d'entrée pour le script Python
    const inputData = {
      demande: {
        ...demande,
        tag             : demande.tag             || demande.code_equipement || '',
        equipement_nom  : demande.equipement_nom   || '',
        lot_code        : demande.lot_code          || '',
        raison          : demande.raison            || '',
        numero_ordre    : demande.numero_ordre      || '',
        statut          : demande.statut            || '',
        // ✅ FIX 2 — date réelle de consignation et déconsignation converties
        date_validation       : toMarocISOString(demande.date_validation || demande.created_at),
        date_deconsignation   : toMarocISOString(dateDeconsignation),
        date_validation_charge: toMarocISOString(demande.date_validation_charge),
        date_validation_process: toMarocISOString(demande.date_validation_process),
      },
      membres : membresConverties,
      chef: {
        id          : chef.id,
        nom         : chef.nom          || '',
        prenom      : chef.prenom       || '',
        type_metier : chef.type_metier  || '',
        metier_label: METIER_LABELS[chef.type_metier] || chef.type_metier || '',
      },
      stats    : statsCompletes,
      logo_path: fs.existsSync(LOGO_PATH) ? LOGO_PATH : '',
    };

    // Écrire le JSON dans un fichier temporaire
    const tmpDir      = os.tmpdir();
    const tmpJsonPath = path.join(tmpDir, `rapport_input_${Date.now()}_${Math.random().toString(36).slice(2)}.json`);

    try {
      fs.writeFileSync(tmpJsonPath, JSON.stringify(inputData, null, 2), 'utf8');
    } catch (err) {
      return reject(new Error(`Impossible d'écrire le fichier JSON temporaire : ${err.message}`));
    }

    // Détecter python3 ou python
    const pythonCmd = process.platform === 'win32' ? 'python' : 'python3';

    execFile(
      pythonCmd,
      [PYTHON_SCRIPT, tmpJsonPath, pdfPath],
      { timeout: 90000, maxBuffer: 10 * 1024 * 1024 },
      (err, stdout, stderr) => {
        // Nettoyage du fichier temporaire
        try { fs.unlinkSync(tmpJsonPath); } catch (_) {}

        if (err) {
          console.error('[rapportEquipePDF] Erreur Python stdout:', stdout);
          console.error('[rapportEquipePDF] Erreur Python stderr:', stderr);
          return reject(new Error(`Génération PDF échouée : ${err.message}\n${stderr}`));
        }

        if (!fs.existsSync(pdfPath)) {
          return reject(new Error(`Le PDF n'a pas été créé : ${pdfPath}\nstdout: ${stdout}\nstderr: ${stderr}`));
        }

        console.log('[rapportEquipePDF] PDF généré avec succès :', pdfPath);
        resolve(pdfPath);
      }
    );
  });
};

module.exports = { genererRapportEquipePDF };