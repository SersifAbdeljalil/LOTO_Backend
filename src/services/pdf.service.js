// src/services/pdf.service.js
// ✅ FIX CRITIQUE genererPDFDeconsignation :
//    La colonne "Déconsigné par" utilise maintenant les VRAIES données de déconsignation
//    stockées sur chaque point (pt.decons_par_nom, pt.date_decons) au lieu de
//    deviner selon typeDeconsignation.
//
//    Résultat : quand le 2ème valide, le PDF contient les infos des DEUX
//    (chargé + process) car les données réelles sont lues depuis la DB.
//
//    CHANGEMENT REQUIS dans les controllers :
//    Passer points avec les champs de déconsignation enrichis :
//      pt.decons_par_nom  → nom de la personne qui a déconsigné ce point
//      pt.date_decons     → date de déconsignation de ce point
//    Ces champs viennent déjà de la query SQL (JOIN deconsignations).

const path = require('path');
const fs   = require('fs');
const PDFDocument = require('pdfkit');

const LOGO_PATH = path.join(__dirname, '../utils/OCPLOGO.png');

const getTagImagePath = (codeEquipement) => {
  if (!codeEquipement) return null;
  const tagImageDir = path.join(__dirname, '../../TAG_Image');
  const filePath    = path.join(tagImageDir, `${codeEquipement}.png`);
  return fs.existsSync(filePath) ? filePath : null;
};

const toMarocParts = (dt) => {
  const parts = new Intl.DateTimeFormat('fr-FR', {
    timeZone: 'Africa/Casablanca',
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false,
  }).formatToParts(dt);
  const get = (type) => parts.find(p => p.type === type)?.value || '00';
  return { day: get('day'), month: get('month'), year: get('year'), hours: get('hour'), minutes: get('minute'), seconds: get('second') };
};

const fmtDate = (d) => {
  if (!d) return '';
  const dt = new Date(d);
  if (isNaN(dt.getTime())) return '';
  return `${String(dt.getUTCDate()).padStart(2,'0')}/${String(dt.getUTCMonth()+1).padStart(2,'0')}/${dt.getUTCFullYear()}`;
};

const fmtHeure = (d) => {
  if (!d) return '';
  const dt = new Date(d);
  if (isNaN(dt.getTime())) return '';
  return `${String(dt.getUTCHours()).padStart(2,'0')}:${String(dt.getUTCMinutes()).padStart(2,'0')}`;
};

const fmtDateNow  = () => { const p = toMarocParts(new Date()); return `${p.day}/${p.month}/${p.year}`; };
const fmtHeureNow = () => { const p = toMarocParts(new Date()); return `${p.hours}:${p.minutes}:${p.seconds}`; };

// ── Dimensions colonnes communes aux deux fonctions ──────────────
const buildColumns = () => {
  const C = {
    num:    12,
    repere: 50,
    local:  48,
    disp:   48,
    etat:   26,
    charge: 34,
    cad:    40,
    cNom:   46,
    cDate:  32,
    cHeure: 22,
    vNom:   40,
    vDate:  30,
    dNom:   46,
    dDate:  61,
  };
  return C;
};

// ═══════════════════════════════════════════════════════════════════
// genererPDFUnifie — inchangé
// ═══════════════════════════════════════════════════════════════════
const genererPDFUnifie = ({
  demande, plan, points,
  chargeInfo, processInfo,
  pdfPath, photoAbsPath,
}) => {
  return new Promise((resolve, reject) => {
    const tagImagePath = getTagImagePath(demande.tag);
    const doc    = new PDFDocument({ margin: 30, size: 'A4' });
    const stream = fs.createWriteStream(pdfPath);
    doc.pipe(stream);

    const ML = 30, PW = 535;
    const BLEU_HEADER = '#003087', BLEU_PLAN = '#5B9BD5', BLEU_PLAN_CLR = '#D6E4F3';
    const BLANC = '#FFFFFF', VERT_VALIDE = '#E8F5E9';

    const hdrH = 60;
    doc.rect(ML, 30, 75, hdrH).stroke('#000');
    if (fs.existsSync(LOGO_PATH)) {
      try { doc.image(LOGO_PATH, ML + 3, 32, { width: 69, height: 56, fit: [69, 56], align: 'center', valign: 'center' }); }
      catch (e) { doc.fontSize(7).font('Helvetica-Bold').fillColor(BLEU_HEADER).text('OCP', ML, 55, { width: 75, align: 'center' }); }
    }

    const titleX = ML + 77, titleW = PW - 77 - 95;
    doc.rect(titleX, 30, titleW, hdrH).stroke('#000');
    doc.fontSize(9).font('Helvetica-Bold').fillColor('#000').text('Formulaire', titleX, 38, { width: titleW, align: 'center' });
    doc.fontSize(7.5).font('Helvetica-Bold').text('Fiche Consignation/Déconsignation des', titleX, 51, { width: titleW, align: 'center' });
    doc.text('Energies et Produits Dangereux', titleX, 61, { width: titleW, align: 'center' });

    const refX = titleX + titleW + 2, refW = PW - 77 - titleW - 2;
    let ry = 30;
    ['F-HSE-SEC-22-01', 'Edition : 2.0', "Date d'émission\n01/09/2015", 'Page : 1/1'].forEach(txt => {
      const rh = txt.includes('\n') ? 18 : 13;
      doc.rect(refX, ry, refW, rh).stroke('#000');
      doc.fontSize(5.5).font('Helvetica').fillColor('#000').text(txt, refX + 1, ry + 2, { width: refW - 2, align: 'center' });
      ry += rh;
    });

    let y = 30 + hdrH + 6;
    doc.fontSize(7.5).font('Helvetica-Oblique').fillColor('#000').text('Entité : ', ML, y, { continued: true }).font('Helvetica').text(demande.lot_code || '');
    y += 12;
    doc.fontSize(7).font('Helvetica').fillColor('#000').text("N° d'ordre : ", ML, y, { continued: true }).font('Helvetica-Bold').text(demande.numero_ordre || '');
    doc.fontSize(7).font('Helvetica-Bold').fillColor('#000').text('Date : ', ML + 270, y, { continued: true }).font('Helvetica').text(fmtDateNow());
    y += 11;
    doc.fontSize(7).font('Helvetica').fillColor('#000').text('Equipement concerné : ', ML, y, { continued: true }).font('Helvetica-Bold').text(`${demande.equipement_nom || ''} (${demande.tag || ''})`);
    doc.moveTo(ML + 210, y + 9).lineTo(ML + PW, y + 9).stroke('#aaa');
    y += 12;
    doc.fontSize(7).font('Helvetica').fillColor('#000').text('Raison du cadenassage : ', ML, y, { continued: true }).font('Helvetica-Bold').text(demande.raison || '', { width: PW - 130 });
    doc.moveTo(ML + 140, y + 9).lineTo(ML + PW, y + 9).stroke('#aaa');
    y += 12;
    doc.rect(ML, y, PW, 12).stroke('#000');
    doc.fontSize(7).font('Helvetica').fillColor('#000').text(`Schémas : ${plan?.schema_ref || demande.tag || ''}`, ML + 3, y + 2, { width: PW - 6 });
    y += 14;

    const C = buildColumns();
    const planW     = C.num + C.repere + C.local + C.disp + C.etat + C.charge;
    const execW     = PW - planW;
    const consigneW = C.cad + C.cNom + C.cDate + C.cHeure;
    const verifieW  = C.vNom + C.vDate;
    const dConsW    = C.dNom + C.dDate;
    const ROW_H1 = 11, ROW_H2 = 18, ROW_DATA = 12;

    doc.rect(ML, y, planW, ROW_H1).fillAndStroke(BLEU_HEADER, BLEU_HEADER);
    doc.fontSize(6).font('Helvetica-Bold').fillColor(BLANC).text('Plan de consignation', ML, y + 2, { width: planW, align: 'center' });
    doc.rect(ML + planW, y, execW, ROW_H1).fillAndStroke(BLEU_HEADER, BLEU_HEADER);
    doc.fontSize(6).font('Helvetica-Bold').fillColor(BLANC).text('Exécution du plan de consignation', ML + planW, y + 2, { width: execW, align: 'center' });
    y += ROW_H1;

    doc.rect(ML, y, planW, ROW_H2).fillAndStroke(BLEU_PLAN, BLEU_PLAN);
    let gx = ML + planW;
    doc.rect(gx, y, consigneW, ROW_H2).fillAndStroke(BLANC, '#000');
    doc.fontSize(6).font('Helvetica-Bold').fillColor('#000').text('Consigné par', gx, y + 1, { width: consigneW, align: 'center' });
    gx += consigneW;
    doc.rect(gx, y, verifieW, ROW_H2).fillAndStroke(BLANC, '#000');
    doc.fontSize(6).font('Helvetica-Bold').fillColor('#000').text('Vérifié par', gx, y + 1, { width: verifieW, align: 'center' });
    gx += verifieW;
    doc.rect(gx, y, dConsW, ROW_H2).fillAndStroke(BLANC, '#000');
    doc.fontSize(6).font('Helvetica-Bold').fillColor('#000').text('Déconsigné par', gx, y + 1, { width: dConsW, align: 'center' });

    const sy = y + ROW_H2 / 2 + 1;
    const subP = (txt, wx, wy, ww) => {
      doc.rect(wx, wy, ww, ROW_H2 / 2).fillAndStroke(BLEU_PLAN, BLEU_PLAN);
      doc.fontSize(4.5).font('Helvetica-Bold').fillColor(BLANC).text(txt, wx + 1, wy + 1, { width: ww - 2, align: 'center' });
    };
    const subE = (txt, wx, wy, ww) => {
      doc.rect(wx, wy, ww, ROW_H2 / 2).fillAndStroke(BLANC, '#000');
      doc.fontSize(4.5).font('Helvetica-Bold').fillColor('#000').text(txt, wx + 1, wy + 1, { width: ww - 2, align: 'center' });
    };

    let sx = ML;
    subP('N°',        sx, sy, C.num);    sx += C.num;
    subP('Repère',    sx, sy, C.repere); sx += C.repere;
    subP('Localisa.', sx, sy, C.local);  sx += C.local;
    subP('Dispositif',sx, sy, C.disp);   sx += C.disp;
    subP('Etat',      sx, sy, C.etat);   sx += C.etat;
    subP('Chargé',    sx, sy, C.charge); sx += C.charge;
    subE('N° cadenas',sx, sy, C.cad);    sx += C.cad;
    subE('Nom',       sx, sy, C.cNom);   sx += C.cNom;
    subE('Date',      sx, sy, C.cDate);  sx += C.cDate;
    subE('Heure',     sx, sy, C.cHeure); sx += C.cHeure;
    subE('Nom',       sx, sy, C.vNom);   sx += C.vNom;
    subE('Date',      sx, sy, C.vDate);  sx += C.vDate;
    subE('Nom',       sx, sy, C.dNom);   sx += C.dNom;
    subE('Date',      sx, sy, C.dDate);
    y += ROW_H2;

    const chargeNom  = chargeInfo  ? `${chargeInfo.prenom} ${chargeInfo.nom}`   : '';
    const processNom = processInfo ? `${processInfo.prenom} ${processInfo.nom}` : '';
    const dateValid  = fmtDateNow();

    const cellP = (txt, cx, cw, bg, stroke) => {
      if (bg) doc.rect(cx, y, cw, ROW_DATA).fillAndStroke(bg, stroke || '#000');
      else    doc.rect(cx, y, cw, ROW_DATA).stroke('#000');
      doc.fontSize(4.8).font('Helvetica').fillColor('#000').text(
        String(txt || ''), cx + 1, y + 2, { width: cw - 2, align: 'center', ellipsis: true, lineBreak: false }
      );
    };

    const ORDERED = Array.from({ length: 9 }, (_, i) => points[i] || null);
    ORDERED.forEach((pt, i) => {
      const isProcess = pt && pt.charge_type === 'process';
      let bgPlan, bgExec;
      if (pt) {
        if (isProcess && processInfo) { bgPlan = i % 2 === 0 ? '#E3F0E3' : '#C8E6C9'; bgExec = i % 2 === 0 ? VERT_VALIDE : '#F1F8F1'; }
        else { bgPlan = i % 2 === 0 ? BLEU_PLAN : BLEU_PLAN_CLR; bgExec = i % 2 === 0 ? BLANC : '#F5F9FF'; }
      } else { bgPlan = i % 2 === 0 ? BLEU_PLAN : BLEU_PLAN_CLR; bgExec = i % 2 === 0 ? BLANC : '#F5F9FF'; }

      doc.rect(ML, y, planW, ROW_DATA).fillAndStroke(bgPlan, '#000');
      doc.rect(ML + planW, y, execW, ROW_DATA).fillAndStroke(bgExec, '#000');

      let dx = ML;
      if (pt) {
        const chargeLabel     = pt.charge_type === 'process' ? 'process' : 'elec.';
        const aEteConsigne    = !!pt.numero_cadenas;
        const executantNom    = pt.consigne_par_nom || (isProcess ? processNom : chargeNom);
        const verificateurNom = isProcess ? processNom : chargeNom;

        cellP(pt.numero_ligne,            dx, C.num);    dx += C.num;
        cellP(pt.repere_point || '',      dx, C.repere); dx += C.repere;
        cellP(pt.mcc_ref || pt.localisation || '', dx, C.local); dx += C.local;
        cellP(pt.dispositif_condamnation || '', dx, C.disp); dx += C.disp;
        cellP(pt.etat_requis || '',       dx, C.etat);   dx += C.etat;
        cellP(chargeLabel,                dx, C.charge); dx += C.charge;
        cellP(aEteConsigne ? pt.numero_cadenas : '', dx, C.cad);   dx += C.cad;
        cellP(aEteConsigne ? executantNom : '',      dx, C.cNom);  dx += C.cNom;
        cellP(aEteConsigne ? fmtDate(pt.date_consigne) : '',  dx, C.cDate);  dx += C.cDate;
        cellP(aEteConsigne ? fmtHeure(pt.date_consigne) : '', dx, C.cHeure); dx += C.cHeure;
        cellP(aEteConsigne ? verificateurNom : '', dx, C.vNom);  dx += C.vNom;
        cellP(aEteConsigne ? dateValid : '',       dx, C.vDate); dx += C.vDate;
        cellP('', dx, C.dNom);  dx += C.dNom;
        cellP('', dx, C.dDate);
      } else {
        [C.num, C.repere, C.local, C.disp, C.etat, C.charge,
         C.cad, C.cNom, C.cDate, C.cHeure, C.vNom, C.vDate, C.dNom, C.dDate
        ].forEach(cw => { cellP('', dx, cw); dx += cw; });
      }
      y += ROW_DATA;
    });

    const basH = 38, basW = PW / 2;
    doc.rect(ML, y, basW, basH).stroke('#000');
    doc.fontSize(6.5).font('Helvetica-Bold').fillColor('#000').text('Plan établi par :', ML + 4, y + 3);
    doc.fontSize(6).font('Helvetica-Bold').text('Date : ', ML + 4, y + 20, { continued: true }).font('Helvetica').text(chargeInfo ? dateValid : '');
    doc.fontSize(6).font('Helvetica-Bold').text('Signature :', ML + 4, y + 29);
    doc.rect(ML + basW, y, basW, basH).stroke('#000');
    doc.fontSize(6.5).font('Helvetica-Bold').fillColor('#000').text('Plan approuvé par :', ML + basW + 4, y + 3);
    doc.fontSize(6).font('Helvetica-Bold').text('Date : ', ML + basW + 4, y + 20, { continued: true }).font('Helvetica').text(processInfo ? dateValid : '');
    doc.fontSize(6).font('Helvetica-Bold').text('Signature :', ML + basW + 4, y + 29);
    y += basH + 5;

    doc.fontSize(6.5).font('Helvetica').fillColor('#000').text('Remarques : ', ML, y, { continued: true });
    doc.moveTo(ML + 55, y + 7).lineTo(ML + PW, y + 7).dash(2, { space: 2 }).stroke('#000'); doc.undash();
    y += 9;
    ['(1) Dispositif : cadenas, chaîne, accessoires de vanne...', '(2) Etat : ouvert ou fermé', '(3) Chargé : personne habilitée (électricien, chef équipe production)'].forEach(n => {
      doc.fontSize(5.5).font('Helvetica').fillColor('#000').text(n, ML, y); y += 7;
    });

    y += 5;
    doc.rect(ML, y, PW, 12).fillAndStroke(BLEU_PLAN, BLEU_PLAN);
    doc.fontSize(7).font('Helvetica-Bold').fillColor(BLANC).text("Schéma / Plan de l'équipement", ML, y + 2, { width: PW, align: 'center' });
    y += 14;
    const schemaH = 150;
    doc.rect(ML, y, PW, schemaH).stroke('#000');
    if (tagImagePath) {
      try { doc.image(tagImagePath, ML + 2, y + 2, { width: PW - 4, height: schemaH - 4, fit: [PW - 4, schemaH - 4], align: 'center', valign: 'center' }); } catch (e) {}
    }
    y += schemaH + 4;

    y += 5;
    doc.rect(ML, y, PW, 12).fillAndStroke(BLEU_PLAN, BLEU_PLAN);
    doc.fontSize(7).font('Helvetica-Bold').fillColor(BLANC).text('Photo du départ consigné', ML, y + 2, { width: PW, align: 'center' });
    y += 14;
    const photoH = 150;
    doc.rect(ML, y, PW, photoH).stroke('#000');
    if (photoAbsPath && fs.existsSync(photoAbsPath)) {
      try { doc.image(photoAbsPath, ML + 2, y + 2, { width: PW - 4, height: photoH - 4, fit: [PW - 4, photoH - 4], align: 'center', valign: 'center' }); } catch (e) {}
      y += photoH + 3;
      doc.fontSize(6).font('Helvetica').fillColor('#555').text(`Photo prise le ${fmtDateNow()} à ${fmtHeureNow()}`, ML, y, { width: PW, align: 'center' });
    } else {
      doc.fontSize(8).font('Helvetica').fillColor('#BDBDBD').text('Photo à prendre lors de la consignation sur terrain', ML, y + photoH / 2 - 5, { width: PW, align: 'center' });
    }

    doc.end();
    stream.on('finish', resolve);
    stream.on('error', reject);
  });
};

// ═══════════════════════════════════════════════════════════════════
// genererPDFDeconsignation — CORRIGÉ
//
// ✅ FIX CRITIQUE : La colonne "Déconsigné par" est remplie point par point
//    en utilisant les VRAIES données stockées sur chaque point :
//      pt.decons_par_nom  → qui a déconsigné ce point (depuis table deconsignations)
//      pt.date_decons     → quand ce point a été déconsigné
//
//    Ainsi quand le 2ème valide et génère le PDF final :
//      - Les points électriques affichent le nom du CHARGÉ (déjà déconsigné)
//      - Les points process affichent le nom du PROCESS (vient de déconsigner)
//      - Rien n'est écrasé, tout est visible dans le même PDF
//
//    IMPORTANT : Les controllers doivent passer les points ENRICHIS avec :
//      pt.decons_par_nom et pt.date_decons (JOIN avec table deconsignations)
//    → Ces champs sont déjà présents dans les queries SQL existantes ✅
// ═══════════════════════════════════════════════════════════════════
const genererPDFDeconsignation = ({
  demande, plan, points,
  chargeInfo, processInfo,
  pdfPath, photoAbsPath,
  typeDeconsignation = 'charge',
}) => {
  return new Promise((resolve, reject) => {
    const tagImagePath = getTagImagePath(demande.tag);
    const doc    = new PDFDocument({ margin: 30, size: 'A4' });
    const stream = fs.createWriteStream(pdfPath);
    doc.pipe(stream);

    const ML = 30, PW = 535;
    const BLEU_HEADER = '#003087', BLEU_PLAN = '#5B9BD5', BLEU_PLAN_CLR = '#D6E4F3';
    const BLANC       = '#FFFFFF';
    // Couleurs fond pour la colonne déconsignation
    const VERT_DECONS  = '#E8F5E9';  // vert clair → point électrique déconsigné (chargé)
    const AMBRE_DECONS = '#FFF8E1';  // ambre clair → point process déconsigné

    const hdrH = 60;
    doc.rect(ML, 30, 75, hdrH).stroke('#000');
    if (fs.existsSync(LOGO_PATH)) {
      try { doc.image(LOGO_PATH, ML + 3, 32, { width: 69, height: 56, fit: [69, 56], align: 'center', valign: 'center' }); }
      catch (e) { doc.fontSize(7).font('Helvetica-Bold').fillColor(BLEU_HEADER).text('OCP', ML, 55, { width: 75, align: 'center' }); }
    }

    const titleX = ML + 77, titleW = PW - 77 - 95;
    doc.rect(titleX, 30, titleW, hdrH).stroke('#000');
    doc.fontSize(9).font('Helvetica-Bold').fillColor('#000').text('Formulaire', titleX, 38, { width: titleW, align: 'center' });
    doc.fontSize(7.5).font('Helvetica-Bold').text('Fiche Consignation/Déconsignation des', titleX, 51, { width: titleW, align: 'center' });
    doc.text('Energies et Produits Dangereux', titleX, 61, { width: titleW, align: 'center' });

    const refX = titleX + titleW + 2, refW = PW - 77 - titleW - 2;
    let ry = 30;
    ['F-HSE-SEC-22-01', 'Edition : 2.0', "Date d'émission\n01/09/2015", 'Page : 1/1'].forEach(txt => {
      const rh = txt.includes('\n') ? 18 : 13;
      doc.rect(refX, ry, refW, rh).stroke('#000');
      doc.fontSize(5.5).font('Helvetica').fillColor('#000').text(txt, refX + 1, ry + 2, { width: refW - 2, align: 'center' });
      ry += rh;
    });

    let y = 30 + hdrH + 6;
    doc.fontSize(7.5).font('Helvetica-Oblique').fillColor('#000').text('Entité : ', ML, y, { continued: true }).font('Helvetica').text(demande.lot_code || '');
    y += 12;
    doc.fontSize(7).font('Helvetica').fillColor('#000').text("N° d'ordre : ", ML, y, { continued: true }).font('Helvetica-Bold').text(demande.numero_ordre || '');
    doc.fontSize(7).font('Helvetica-Bold').fillColor('#000').text('Date : ', ML + 270, y, { continued: true }).font('Helvetica').text(fmtDateNow());
    y += 11;
    doc.fontSize(7).font('Helvetica').fillColor('#000').text('Equipement concerné : ', ML, y, { continued: true }).font('Helvetica-Bold').text(`${demande.equipement_nom || ''} (${demande.tag || ''})`);
    doc.moveTo(ML + 210, y + 9).lineTo(ML + PW, y + 9).stroke('#aaa');
    y += 12;
    doc.fontSize(7).font('Helvetica').fillColor('#000').text('Raison du cadenassage : ', ML, y, { continued: true }).font('Helvetica-Bold').text(demande.raison || '', { width: PW - 130 });
    doc.moveTo(ML + 140, y + 9).lineTo(ML + PW, y + 9).stroke('#aaa');
    y += 12;
    doc.rect(ML, y, PW, 12).stroke('#000');
    doc.fontSize(7).font('Helvetica').fillColor('#000').text(`Schémas : ${demande.tag || ''}`, ML + 3, y + 2, { width: PW - 6 });
    y += 14;

    const C = buildColumns();
    const planW     = C.num + C.repere + C.local + C.disp + C.etat + C.charge;
    const execW     = PW - planW;
    const consigneW = C.cad + C.cNom + C.cDate + C.cHeure;
    const verifieW  = C.vNom + C.vDate;
    const dConsW    = C.dNom + C.dDate;
    const ROW_H1 = 11, ROW_H2 = 18, ROW_DATA = 12;

    doc.rect(ML, y, planW, ROW_H1).fillAndStroke(BLEU_HEADER, BLEU_HEADER);
    doc.fontSize(6).font('Helvetica-Bold').fillColor(BLANC).text('Plan de consignation', ML, y + 2, { width: planW, align: 'center' });
    doc.rect(ML + planW, y, execW, ROW_H1).fillAndStroke(BLEU_HEADER, BLEU_HEADER);
    doc.fontSize(6).font('Helvetica-Bold').fillColor(BLANC).text('Exécution du plan de consignation', ML + planW, y + 2, { width: execW, align: 'center' });
    y += ROW_H1;

    doc.rect(ML, y, planW, ROW_H2).fillAndStroke(BLEU_PLAN, BLEU_PLAN);
    let gx = ML + planW;
    doc.rect(gx, y, consigneW, ROW_H2).fillAndStroke(BLANC, '#000');
    doc.fontSize(6).font('Helvetica-Bold').fillColor('#000').text('Consigné par', gx, y + 1, { width: consigneW, align: 'center' });
    gx += consigneW;
    doc.rect(gx, y, verifieW, ROW_H2).fillAndStroke(BLANC, '#000');
    doc.fontSize(6).font('Helvetica-Bold').fillColor('#000').text('Vérifié par', gx, y + 1, { width: verifieW, align: 'center' });
    gx += verifieW;
    doc.rect(gx, y, dConsW, ROW_H2).fillAndStroke(BLANC, '#000');
    doc.fontSize(6).font('Helvetica-Bold').fillColor('#000').text('Déconsigné par', gx, y + 1, { width: dConsW, align: 'center' });

    const sy = y + ROW_H2 / 2 + 1;
    const subP = (txt, wx, wy, ww) => {
      doc.rect(wx, wy, ww, ROW_H2 / 2).fillAndStroke(BLEU_PLAN, BLEU_PLAN);
      doc.fontSize(4.5).font('Helvetica-Bold').fillColor(BLANC).text(txt, wx + 1, wy + 1, { width: ww - 2, align: 'center' });
    };
    const subE = (txt, wx, wy, ww) => {
      doc.rect(wx, wy, ww, ROW_H2 / 2).fillAndStroke(BLANC, '#000');
      doc.fontSize(4.5).font('Helvetica-Bold').fillColor('#000').text(txt, wx + 1, wy + 1, { width: ww - 2, align: 'center' });
    };

    let sx = ML;
    subP('N°',        sx, sy, C.num);    sx += C.num;
    subP('Repère',    sx, sy, C.repere); sx += C.repere;
    subP('Localisa.', sx, sy, C.local);  sx += C.local;
    subP('Dispositif',sx, sy, C.disp);   sx += C.disp;
    subP('Etat',      sx, sy, C.etat);   sx += C.etat;
    subP('Chargé',    sx, sy, C.charge); sx += C.charge;
    subE('N° cadenas',sx, sy, C.cad);    sx += C.cad;
    subE('Nom',       sx, sy, C.cNom);   sx += C.cNom;
    subE('Date',      sx, sy, C.cDate);  sx += C.cDate;
    subE('Heure',     sx, sy, C.cHeure); sx += C.cHeure;
    subE('Nom',       sx, sy, C.vNom);   sx += C.vNom;
    subE('Date',      sx, sy, C.vDate);  sx += C.vDate;
    subE('Nom',       sx, sy, C.dNom);   sx += C.dNom;
    subE('Date',      sx, sy, C.dDate);
    y += ROW_H2;

    // ── Noms des intervenants ────────────────────────────────────
    const chargeNom  = chargeInfo  ? `${chargeInfo.prenom} ${chargeInfo.nom}`   : '';
    const processNom = processInfo ? `${processInfo.prenom} ${processInfo.nom}` : '';
    const dateValid  = fmtDateNow();

    const cellP = (txt, cx, cw, bgColor) => {
      if (bgColor) doc.rect(cx, y, cw, ROW_DATA).fillAndStroke(bgColor, '#000');
      else         doc.rect(cx, y, cw, ROW_DATA).stroke('#000');
      doc.fontSize(4.8).font('Helvetica').fillColor('#000').text(
        String(txt || ''), cx + 1, y + 2, { width: cw - 2, align: 'center', ellipsis: true, lineBreak: false }
      );
    };

    // ✅ FIX : on affiche les 9 premiers points du plan complet (elec + process mélangés)
    // Les points sont triés par numero_ligne donc l'ordre est cohérent
    const ORDERED = Array.from({ length: 9 }, (_, i) => points[i] || null);

    ORDERED.forEach((pt, i) => {
      const isProcess = pt && pt.charge_type === 'process';
      const isElec    = pt && (pt.charge_type === 'electricien' || !pt.charge_type);

      // Fond de ligne plan
      const bgPlan = i % 2 === 0 ? BLEU_PLAN : BLEU_PLAN_CLR;
      const bgExec = i % 2 === 0 ? BLANC : '#F5F9FF';

      doc.rect(ML, y, planW, ROW_DATA).fillAndStroke(bgPlan, '#000');
      doc.rect(ML + planW, y, execW, ROW_DATA).fillAndStroke(bgExec, '#000');

      let dx = ML;
      if (pt) {
        const chargeLabel     = isProcess ? 'process' : 'elec.';
        const aEteConsigne    = !!pt.numero_cadenas;
        const executantNom    = pt.consigne_par_nom || (isProcess ? processNom : chargeNom);
        const verificateurNom = isProcess ? processNom : chargeNom;

        // ✅ FIX CRITIQUE : lire les vraies données de déconsignation depuis le point
        // pt.decons_par_nom et pt.date_decons viennent du JOIN avec table deconsignations
        // dans les queries SQL des controllers (getDemandeDeconsignationDetail)
        const aEteDeconsigne  = !!pt.decons_par_nom || !!pt.date_decons;

        // ✅ Nom du déconsigneur : priorité aux vraies données DB
        // Fallback : si pas encore en DB → utiliser le nom de l'intervenant courant
        //   (cas du 1er validateur dont les données viennent d'être insérées)
        let deconNom  = '';
        let deconDate = '';

        if (pt.decons_par_nom) {
          // Donnée réelle depuis la table deconsignations → TOUJOURS prioritaire
          deconNom  = pt.decons_par_nom;
          deconDate = pt.date_decons ? fmtDate(pt.date_decons) : dateValid;
        } else if (isElec && typeDeconsignation === 'charge' && chargeNom) {
          // Ce point électrique vient d'être déconsigné par le chargé (1er validateur)
          // Les données DB ne sont pas encore dans pt (query faite avant l'INSERT)
          deconNom  = chargeNom;
          deconDate = dateValid;
        } else if (isProcess && typeDeconsignation === 'process' && processNom) {
          // Ce point process vient d'être déconsigné par le process (1er validateur)
          deconNom  = processNom;
          deconDate = dateValid;
        }

        // Fond coloré si ce point est déconsigné
        const bgDecons = aEteDeconsigne || deconNom
          ? (isProcess ? AMBRE_DECONS : VERT_DECONS)
          : null;

        cellP(pt.numero_ligne,                            dx, C.num);                              dx += C.num;
        cellP(pt.repere_point || '',                       dx, C.repere);                           dx += C.repere;
        cellP(pt.mcc_ref || pt.localisation || '',         dx, C.local);                            dx += C.local;
        cellP(pt.dispositif_condamnation || '',             dx, C.disp);                             dx += C.disp;
        cellP(pt.etat_requis || '',                        dx, C.etat);                             dx += C.etat;
        cellP(chargeLabel,                                 dx, C.charge);                           dx += C.charge;
        cellP(aEteConsigne ? pt.numero_cadenas : '',       dx, C.cad);                              dx += C.cad;
        cellP(aEteConsigne ? executantNom : '',             dx, C.cNom);                             dx += C.cNom;
        cellP(aEteConsigne ? fmtDate(pt.date_consigne) : '', dx, C.cDate);                          dx += C.cDate;
        cellP(aEteConsigne ? fmtHeure(pt.date_consigne) : '', dx, C.cHeure);                        dx += C.cHeure;
        cellP(aEteConsigne ? verificateurNom : '',          dx, C.vNom);                             dx += C.vNom;
        cellP(aEteConsigne ? fmtDate(pt.date_consigne) : '', dx, C.vDate);                          dx += C.vDate;
        // ✅ Colonne "Déconsigné par" — données réelles ou fallback 1er validateur
        cellP(deconNom,  dx, C.dNom, deconNom ? bgDecons : null); dx += C.dNom;
        cellP(deconDate, dx, C.dDate, deconDate ? bgDecons : null);
      } else {
        [C.num, C.repere, C.local, C.disp, C.etat, C.charge,
         C.cad, C.cNom, C.cDate, C.cHeure, C.vNom, C.vDate, C.dNom, C.dDate
        ].forEach(cw => { cellP('', dx, cw); dx += cw; });
      }
      y += ROW_DATA;
    });

    // ── Signatures ───────────────────────────────────────────────
    const basH = 38, basW = PW / 2;
    doc.rect(ML, y, basW, basH).stroke('#000');
    doc.fontSize(6.5).font('Helvetica-Bold').fillColor('#000').text('Déconsigné par (électrique) :', ML + 4, y + 3);
    doc.fontSize(6).font('Helvetica-Bold').text('Nom : ', ML + 4, y + 14, { continued: true }).font('Helvetica').text(chargeNom || '—');
    doc.fontSize(6).font('Helvetica-Bold').text('Date : ', ML + 4, y + 23, { continued: true }).font('Helvetica').text(
      chargeNom ? dateValid : '—'
    );
    doc.fontSize(6).font('Helvetica-Bold').text('Signature :', ML + 4, y + 30);

    doc.rect(ML + basW, y, basW, basH).stroke('#000');
    doc.fontSize(6.5).font('Helvetica-Bold').fillColor('#000').text('Déconsigné par (process) :', ML + basW + 4, y + 3);
    doc.fontSize(6).font('Helvetica-Bold').text('Nom : ', ML + basW + 4, y + 14, { continued: true }).font('Helvetica').text(processNom || '—');
    doc.fontSize(6).font('Helvetica-Bold').text('Date : ', ML + basW + 4, y + 23, { continued: true }).font('Helvetica').text(
      processNom ? dateValid : '—'
    );
    doc.fontSize(6).font('Helvetica-Bold').text('Signature :', ML + basW + 4, y + 30);
    y += basH + 5;

    doc.fontSize(6.5).font('Helvetica').fillColor('#000').text('Remarques : ', ML, y, { continued: true });
    doc.moveTo(ML + 55, y + 7).lineTo(ML + PW, y + 7).dash(2, { space: 2 }).stroke('#000'); doc.undash();
    y += 9;
    ['(1) Dispositif : cadenas, chaîne, accessoires de vanne...', '(2) Etat : ouvert ou fermé', '(3) Chargé : personne habilitée à réaliser la consignation'].forEach(n => {
      doc.fontSize(5.5).font('Helvetica').fillColor('#000').text(n, ML, y); y += 7;
    });

    y += 5;
    doc.rect(ML, y, PW, 12).fillAndStroke(BLEU_PLAN, BLEU_PLAN);
    doc.fontSize(7).font('Helvetica-Bold').fillColor(BLANC).text("Schéma / Plan de l'équipement", ML, y + 2, { width: PW, align: 'center' });
    y += 14;
    const schemaH = 110;
    doc.rect(ML, y, PW, schemaH).stroke('#000');
    if (tagImagePath) {
      try { doc.image(tagImagePath, ML + 2, y + 2, { width: PW - 4, height: schemaH - 4, fit: [PW - 4, schemaH - 4], align: 'center', valign: 'center' }); } catch (e) {}
    }
    y += schemaH + 4;

    doc.end();
    stream.on('finish', resolve);
    stream.on('error', reject);
  });
};

module.exports = { genererPDFUnifie, genererPDFDeconsignation, getTagImagePath };