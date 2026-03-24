// src/services/rapportEquipe.pdf.service.js
// ✅ HEURE TÉLÉPHONE : deviceTime passé depuis le controller (req.deviceTime)
//    → now_device envoyé au script Python comme ISO string Maroc avec offset
//    → le Python utilise now_device au lieu de now_maroc() serveur
// ✅ FIX dureeMinutes : new Date() parse correctement les ISO+offset sans double conversion
'use strict';

const path         = require('path');
const fs           = require('fs');
const { execFile } = require('child_process');
const os           = require('os');

const PYTHON_SCRIPT = path.join(__dirname, 'rapportEquipe_pdf_service.py');
const LOGO_PATH     = path.join(__dirname, '../utils/OCPLOGO.png');

const METIER_LABELS = {
  genie_civil: 'Génie Civil',
  mecanique:   'Mécanique',
  electrique:  'Électrique',
  process:     'Process',
};

// ════════════════════════════════════════════════════════════════
// HELPER : convertit une date UTC (MySQL string ou Date)
// en ISO string avec l'offset Maroc réel (Africa/Casablanca).
// Ramadan-safe : l'offset est calculé dynamiquement.
// ════════════════════════════════════════════════════════════════
function toMarocISOString(dateInput) {
  if (!dateInput) return null;

  let date;
  if (dateInput instanceof Date) {
    date = dateInput;
  } else {
    const s = String(dateInput).trim().replace(' ', 'T');
    const withTZ = s.endsWith('Z') || s.includes('+') ? s : s + 'Z';
    date = new Date(withTZ);
  }
  if (isNaN(date.getTime())) return null;

  const formatter = new Intl.DateTimeFormat('fr-MA', {
    timeZone: 'Africa/Casablanca',
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    hour12: false,
  });

  const parts = formatter.formatToParts(date);
  const p     = {};
  parts.forEach(({ type, value }) => { p[type] = value; });

  const localMs = Date.UTC(
    parseInt(p.year),
    parseInt(p.month) - 1,
    parseInt(p.day),
    parseInt(p.hour === '24' ? '0' : p.hour),
    parseInt(p.minute),
    parseInt(p.second),
  );
  const offsetMinutes = Math.round((localMs - date.getTime()) / 60000);

  const localDate  = new Date(localMs);
  const pad        = (n) => String(n).padStart(2, '0');
  const absOffset  = Math.abs(offsetMinutes);
  const sign       = offsetMinutes >= 0 ? '+' : '-';
  const offsetStr  = `${sign}${pad(Math.floor(absOffset / 60))}:${pad(absOffset % 60)}`;

  return (
    `${localDate.getUTCFullYear()}-${pad(localDate.getUTCMonth() + 1)}-${pad(localDate.getUTCDate())}` +
    `T${pad(localDate.getUTCHours())}:${pad(localDate.getUTCMinutes())}:${pad(localDate.getUTCSeconds())}` +
    offsetStr
  );
}

// ✅ FIX : new Date() parse correctement les ISO strings avec offset (+01:00)
//    sans double conversion → durées correctes
function dureeMinutes(debut, fin) {
  if (!debut || !fin) return null;
  const d1 = new Date(debut);
  const d2 = new Date(fin);
  if (isNaN(d1) || isNaN(d2)) return null;
  const diff = Math.round((d2.getTime() - d1.getTime()) / 60000);
  return diff >= 0 ? diff : null;
}

// ════════════════════════════════════════════════════════════════
// EXPORT PRINCIPAL
// ✅ deviceTime : req.deviceTime passé depuis le controller
// ════════════════════════════════════════════════════════════════
const genererRapportEquipePDF = ({ demande, membres, chef, stats, pdfPath, deviceTime }) => {
  return new Promise((resolve, reject) => {

    // ✅ Convertir toutes les dates membres UTC → ISO Maroc avec offset explicite
    const membresConverties = membres.map(m => {
      const heureSortie = m.heure_scan_sortie || m.heure_sortie || null;
      return {
        id:                  m.id,
        nom:                 m.nom               || '',
        badge_ocp_id:        m.badge_ocp_id       || '',
        matricule:           m.matricule           || '',
        numero_cadenas:      m.numero_cadenas      || '',
        cad_id:              m.cad_id              || '',
        heure_entree:        toMarocISOString(m.heure_entree),
        heure_sortie:        toMarocISOString(heureSortie),
        heure_scan_sortie:   toMarocISOString(m.heure_scan_sortie),
        scan_cadenas_sortie: m.scan_cadenas_sortie || '',
        statut:              m.statut              || 'en_attente',
      };
    });

    const dateDeconsignation = demande.date_deconsignation || demande.updated_at || null;

    // ✅ Calculer duree_totale_min avec la version corrigée de dureeMinutes
    let durTotale = stats ? stats.duree_totale_min : null;
    if (!durTotale) {
      const avecEntree = membresConverties.filter(m => m.heure_entree);
      const avecSortie = membresConverties.filter(m => m.heure_sortie);
      if (avecEntree.length > 0 && avecSortie.length > 0) {
        const premEntree = avecEntree.reduce((min, m) => m.heure_entree < min ? m.heure_entree : min, avecEntree[0].heure_entree);
        const dernSortie = avecSortie.reduce((max, m) => m.heure_sortie > max ? m.heure_sortie : max, avecSortie[0].heure_sortie);
        durTotale = dureeMinutes(premEntree, dernSortie);
      }
    }

    const statsCompletes = {
      ...(stats || {}),
      duree_totale_min: durTotale,
      total_membres:    membresConverties.length,
      membres_sortis:   membresConverties.filter(m => m.statut === 'sortie').length,
    };

    // ✅ now_device : heure téléphone convertie en ISO Maroc
    //    Le Python l'utilisera pour toutes les dates "maintenant" du rapport
    const nowDevice = deviceTime ? toMarocISOString(deviceTime) : toMarocISOString(new Date());

    const inputData = {
      demande: {
        ...demande,
        tag:            demande.tag             || demande.code_equipement || '',
        equipement_nom: demande.equipement_nom   || '',
        lot_code:       demande.lot_code          || '',
        raison:         demande.raison            || '',
        numero_ordre:   demande.numero_ordre      || '',
        statut:         demande.statut            || '',
        date_validation:         toMarocISOString(demande.date_validation || demande.created_at),
        date_deconsignation:     toMarocISOString(dateDeconsignation),
        date_validation_charge:  toMarocISOString(demande.date_validation_charge),
        date_validation_process: toMarocISOString(demande.date_validation_process),
      },
      membres:    membresConverties,
      chef: {
        id:           chef.id,
        nom:          chef.nom          || '',
        prenom:       chef.prenom       || '',
        type_metier:  chef.type_metier  || '',
        metier_label: METIER_LABELS[chef.type_metier] || chef.type_metier || '',
      },
      stats:      statsCompletes,
      logo_path:  fs.existsSync(LOGO_PATH) ? LOGO_PATH : '',
      // ✅ Heure téléphone pour les dates "now" dans le PDF
      now_device: nowDevice,
    };

    const tmpDir      = os.tmpdir();
    const tmpJsonPath = path.join(tmpDir, `rapport_input_${Date.now()}_${Math.random().toString(36).slice(2)}.json`);
    try {
      fs.writeFileSync(tmpJsonPath, JSON.stringify(inputData, null, 2), 'utf8');
    } catch (err) {
      return reject(new Error(`Impossible d'écrire le fichier JSON temporaire : ${err.message}`));
    }

    const pythonCmd = process.platform === 'win32' ? 'python' : 'python3';
    execFile(
      pythonCmd,
      [PYTHON_SCRIPT, tmpJsonPath, pdfPath],
      { timeout: 90000, maxBuffer: 10 * 1024 * 1024 },
      (err, stdout, stderr) => {
        try { fs.unlinkSync(tmpJsonPath); } catch (_) {}
        if (err) {
          console.error('[rapportEquipePDF] stdout:', stdout);
          console.error('[rapportEquipePDF] stderr:', stderr);
          return reject(new Error(`Génération PDF échouée : ${err.message}\n${stderr}`));
        }
        if (!fs.existsSync(pdfPath)) {
          return reject(new Error(`Le PDF n'a pas été créé : ${pdfPath}\n${stderr}`));
        }
        console.log('[rapportEquipePDF] PDF généré :', pdfPath);
        resolve(pdfPath);
      }
    );
  });
};

module.exports = { genererRapportEquipePDF };