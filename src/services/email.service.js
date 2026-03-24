// src/services/email.service.js
// ✅ Anti-spam : headers SPF/DKIM-friendly, Message-ID, Date, Reply-To, text/plain fallback
// ✅ Nodemailer Gmail — mot de passe temporaire + notifications reset + rapports PDF

const nodemailer = require('nodemailer');
const path = require('path');
const fs   = require('fs');
const crypto = require('crypto');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
  // ✅ Anti-spam : pool de connexions + timeouts propres
  pool:           true,
  maxConnections: 3,
  rateDelta:      2000,
  rateLimit:      3,
});

transporter.verify((err) => {
  if (err) console.error('[EMAIL] Connexion Gmail échouée :', err.message);
  else     console.log('[EMAIL] Gmail SMTP prêt ✅');
});

// ── Chemins des logos ─────────────────────────────────────────────────────
const UTILS_DIR = path.resolve(__dirname, '../utils');
const OCP_LOGO  = path.join(UTILS_DIR, 'OCPLOGO.png');
const APP_LOGO  = path.join(UTILS_DIR, 'LOGO.png');

const getLogoAttachments = () => {
  const attachments = [];
  if (fs.existsSync(OCP_LOGO)) attachments.push({ filename: 'OCPLOGO.png', path: OCP_LOGO, cid: 'ocplogo@kofert', contentDisposition: 'inline' });
  if (fs.existsSync(APP_LOGO)) attachments.push({ filename: 'LOGO.png',    path: APP_LOGO, cid: 'applogo@kofert', contentDisposition: 'inline' });
  return attachments;
};

// ── Générer un Message-ID unique (anti-spam) ──────────────────────────────
const genererMessageId = () => {
  const domain = (process.env.EMAIL_USER || 'ocp.ma').split('@')[1] || 'ocp.ma';
  return `<${Date.now()}.${crypto.randomBytes(8).toString('hex')}@${domain}>`;
};

// ── Headers communs anti-spam ─────────────────────────────────────────────
const headersAntiSpam = () => ({
  'X-Mailer':         'OCP-Kofert-Mailer/1.0',
  'X-Priority':       '3',           // Normal (1=High déclenche les filtres)
  'X-MSMail-Priority':'Normal',
  'Importance':       'Normal',
  'Precedence':       'bulk',        // Indique un email système (non promotionnel)
  'Auto-Submitted':   'auto-generated',
  'Message-ID':       genererMessageId(),
  'Date':             new Date().toUTCString(),
});

// ── Générer mot de passe temporaire ───────────────────────────────────────
const genererMotPasseTemp = () => {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let mdp = '';
  for (let i = 0; i < 10; i++) mdp += chars[Math.floor(Math.random() * chars.length)];
  return mdp;
};

// ── Template HTML commun ──────────────────────────────────────────────────
// ✅ Anti-spam : structure table (meilleure compatibilité), pas de mots déclencheurs,
//               version text/plain obligatoire, ratio texte/image correct
const htmlTemplate = (contenu) => `
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>OCP Consignation</title>
</head>
<body style="margin:0;padding:0;background-color:#f0f7f0;font-family:'Segoe UI',Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background:#f0f7f0;">
    <tr><td align="center" style="padding:24px 16px;">
      <table role="presentation" width="560" cellspacing="0" cellpadding="0" border="0"
             style="max-width:560px;width:100%;background:#ffffff;border-radius:14px;overflow:hidden;border:1px solid #e0e8e0;">

        <!-- Header -->
        <tr>
          <td style="background:linear-gradient(135deg,#051F20,#235347);padding:28px 40px;text-align:center;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
              <tr>
                <td align="left" width="80">
                  <img src="cid:ocplogo@kofert" alt="OCP Group" height="40"
                       style="height:40px;object-fit:contain;filter:brightness(0) invert(1);opacity:0.9;" />
                </td>
                <td align="center">
                  <p style="color:#8EB69B;font-size:11px;margin:0;letter-spacing:2px;text-transform:uppercase;">
                    Système de Consignation
                  </p>
                  <h1 style="color:#DAF1DE;font-size:17px;margin:4px 0 0;letter-spacing:1px;font-weight:700;">
                    OCP — KOFERT
                  </h1>
                </td>
                <td align="right" width="80">
                  <img src="cid:applogo@kofert" alt="KOFERT" height="40"
                       style="height:40px;object-fit:contain;filter:brightness(0) invert(1);opacity:0.9;" />
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:32px 40px;">
            ${contenu}
          </td>
        </tr>

        <!-- Footer -->
        <tr>
          <td style="background:#f8fdf8;padding:18px 40px;text-align:center;border-top:1px solid #e8f5e9;">
            <p style="font-size:11px;color:#9EB69B;margin:0 0 6px;">
              © ${new Date().getFullYear()} OCP Group — KOFERT
            </p>
            <p style="font-size:10px;color:#BDBDBD;margin:0;">
              Ce message est généré automatiquement. Merci de ne pas y répondre.
            </p>
            <p style="font-size:10px;color:#BDBDBD;margin:6px 0 0;">
              OCP Group · Jorf Lasfar · El Jadida · Maroc
            </p>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>`;

// ── Version texte brut (obligatoire anti-spam) ────────────────────────────
// Les emails sans version text/plain sont systématiquement filtrés
const textTemplate = (contenuTexte) =>
  `OCP Group — Système de Consignation KOFERT\n` +
  `${'─'.repeat(50)}\n\n` +
  `${contenuTexte}\n\n` +
  `${'─'.repeat(50)}\n` +
  `© ${new Date().getFullYear()} OCP Group — KOFERT\n` +
  `Message automatique — ne pas répondre.\n` +
  `OCP Group · Jorf Lasfar · El Jadida · Maroc`;

// ══════════════════════════════════════════════════════════════════
// 1. Envoyer mot de passe temporaire
// ══════════════════════════════════════════════════════════════════
const envoyerMotPasseTemp = async ({ email, nom, prenom, username, motPasseTemp }) => {
  const contenuHtml = `
    <p style="font-size:15px;color:#163832;margin:0 0 16px;">
      Bonjour <strong>${prenom} ${nom}</strong>,
    </p>
    <p style="font-size:14px;color:#424242;margin:0 0 18px;line-height:1.6;">
      Votre accès à la plateforme OCP Consignation a été mis à jour par l'administrateur système.
      Voici vos identifiants de connexion :
    </p>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
           style="background:#f0f7f0;border-left:4px solid #235347;border-radius:8px;margin:0 0 20px;">
      <tr><td style="padding:18px 22px;">
        <p style="margin:5px 0;font-size:14px;color:#163832;">
          <span style="font-weight:600;display:inline-block;min-width:150px;">Nom d'utilisateur :</span>
          <strong>${username}</strong>
        </p>
        <p style="margin:5px 0;font-size:14px;color:#163832;">
          <span style="font-weight:600;display:inline-block;min-width:150px;">Adresse email :</span>
          ${email}
        </p>
      </td></tr>
    </table>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
           style="background:#051F20;border-radius:10px;margin:0 0 20px;">
      <tr><td style="padding:20px 24px;text-align:center;">
        <p style="color:#8EB69B;font-size:12px;margin:0 0 10px;letter-spacing:1px;text-transform:uppercase;">
          Mot de passe temporaire
        </p>
        <p style="color:#DAF1DE;font-size:26px;font-family:'Courier New',monospace;
                  font-weight:700;letter-spacing:6px;margin:0;">
          ${motPasseTemp}
        </p>
      </td></tr>
    </table>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
           style="background:#fff8e1;border-left:4px solid #f59e0b;border-radius:8px;margin:0 0 18px;">
      <tr><td style="padding:13px 18px;">
        <p style="font-size:13px;color:#92400e;margin:0;line-height:1.5;">
          <strong>Important :</strong> Ce mot de passe est temporaire et à usage unique.
          Connectez-vous et modifiez-le immédiatement depuis l'application.
        </p>
      </td></tr>
    </table>

    <p style="font-size:12px;color:#9E9E9E;margin:0;line-height:1.5;">
      Si vous n'êtes pas à l'origine de cette demande, veuillez contacter
      votre administrateur système immédiatement.
    </p>`;

  const contenuTexte =
    `Bonjour ${prenom} ${nom},\n\n` +
    `Votre accès à la plateforme OCP Consignation a été mis à jour.\n\n` +
    `Nom d'utilisateur : ${username}\n` +
    `Adresse email     : ${email}\n` +
    `Mot de passe temp : ${motPasseTemp}\n\n` +
    `IMPORTANT : Ce mot de passe est temporaire. Connectez-vous et changez-le immédiatement.\n\n` +
    `Si vous n'êtes pas à l'origine de cette demande, contactez votre administrateur.`;

  await transporter.sendMail({
    from:       `"OCP Consignation" <${process.env.EMAIL_USER}>`,
    replyTo:    process.env.EMAIL_USER,
    to:         email,
    subject:    `[OCP Consignation] Vos identifiants de connexion — ${prenom} ${nom}`,
    text:       textTemplate(contenuTexte),
    html:       htmlTemplate(contenuHtml),
    headers:    headersAntiSpam(),
    attachments: getLogoAttachments(),
  });
  console.log(`[EMAIL] Mot de passe temporaire envoyé à ${email}`);
};

// ══════════════════════════════════════════════════════════════════
// 2. Notifier l'admin d'une demande de reset
// ══════════════════════════════════════════════════════════════════
const notifierAdminResetDemande = async ({ adminEmail, demandeurNom, demandeurPrenom, demandeurUsername, demandeurEmail }) => {
  const dateStr = new Date().toLocaleString('fr-MA', { timeZone: 'Africa/Casablanca' });

  const contenuHtml = `
    <p style="font-size:15px;color:#163832;margin:0 0 16px;">
      Bonjour Administrateur,
    </p>
    <p style="font-size:14px;color:#424242;margin:0 0 18px;line-height:1.6;">
      Un utilisateur a soumis une demande de réinitialisation de mot de passe
      via l'application OCP Consignation.
    </p>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
           style="background:#f0f7f0;border-left:4px solid #235347;border-radius:8px;margin:0 0 20px;">
      <tr><td style="padding:18px 22px;">
        <p style="margin:6px 0;font-size:14px;color:#163832;">
          <span style="font-weight:600;display:inline-block;min-width:150px;">Nom complet :</span>
          <strong>${demandeurPrenom} ${demandeurNom}</strong>
        </p>
        <p style="margin:6px 0;font-size:14px;color:#163832;">
          <span style="font-weight:600;display:inline-block;min-width:150px;">Identifiant :</span>
          ${demandeurUsername}
        </p>
        <p style="margin:6px 0;font-size:14px;color:#163832;">
          <span style="font-weight:600;display:inline-block;min-width:150px;">Email :</span>
          ${demandeurEmail}
        </p>
        <p style="margin:6px 0;font-size:14px;color:#163832;">
          <span style="font-weight:600;display:inline-block;min-width:150px;">Date de demande :</span>
          ${dateStr}
        </p>
      </td></tr>
    </table>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
           style="background:#fff8e1;border-left:4px solid #f59e0b;border-radius:8px;margin:0 0 18px;">
      <tr><td style="padding:13px 18px;">
        <p style="font-size:13px;color:#92400e;margin:0;line-height:1.5;">
          Cette demande nécessite votre intervention. Connectez-vous au panneau
          d'administration pour approuver ou rejeter cette demande.
        </p>
      </td></tr>
    </table>`;

  const contenuTexte =
    `Bonjour Administrateur,\n\n` +
    `Une demande de réinitialisation de mot de passe a été soumise.\n\n` +
    `Nom complet  : ${demandeurPrenom} ${demandeurNom}\n` +
    `Identifiant  : ${demandeurUsername}\n` +
    `Email        : ${demandeurEmail}\n` +
    `Date         : ${dateStr}\n\n` +
    `Connectez-vous au panneau d'administration pour traiter cette demande.`;

  await transporter.sendMail({
    from:       `"OCP Consignation" <${process.env.EMAIL_USER}>`,
    replyTo:    process.env.EMAIL_USER,
    to:         adminEmail,
    subject:    `[OCP Consignation] Demande de réinitialisation — ${demandeurUsername}`,
    text:       textTemplate(contenuTexte),
    html:       htmlTemplate(contenuHtml),
    headers:    headersAntiSpam(),
    attachments: getLogoAttachments(),
  });
  console.log(`[EMAIL] Notif reset envoyée à admin ${adminEmail}`);
};

// ══════════════════════════════════════════════════════════════════
// 3. Notifier l'utilisateur du rejet de sa demande
// ══════════════════════════════════════════════════════════════════
const notifierRejetReset = async ({ email, nom, prenom, username, motifRejet }) => {
  const contenuHtml = `
    <p style="font-size:15px;color:#163832;margin:0 0 16px;">
      Bonjour <strong>${prenom} ${nom}</strong>,
    </p>
    <p style="font-size:14px;color:#424242;margin:0 0 18px;line-height:1.6;">
      Votre demande de réinitialisation de mot de passe sur la plateforme
      OCP Consignation n'a pas pu être traitée favorablement.
    </p>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
           style="background:#f0f7f0;border-left:4px solid #235347;border-radius:8px;margin:0 0 20px;">
      <tr><td style="padding:18px 22px;">
        <p style="margin:6px 0;font-size:14px;color:#163832;">
          <span style="font-weight:600;display:inline-block;min-width:130px;">Identifiant :</span>
          ${username}
        </p>
        <p style="margin:6px 0;font-size:14px;color:#163832;">
          <span style="font-weight:600;display:inline-block;min-width:130px;">Motif :</span>
          ${motifRejet || 'Non précisé par l\'administrateur'}
        </p>
      </td></tr>
    </table>

    <p style="font-size:13px;color:#424242;margin:0;line-height:1.6;">
      Pour toute question concernant votre accès, veuillez contacter
      directement votre administrateur système.
    </p>`;

  const contenuTexte =
    `Bonjour ${prenom} ${nom},\n\n` +
    `Votre demande de réinitialisation de mot de passe n'a pas pu être traitée.\n\n` +
    `Identifiant : ${username}\n` +
    `Motif       : ${motifRejet || 'Non précisé'}\n\n` +
    `Pour toute question, contactez votre administrateur système.`;

  await transporter.sendMail({
    from:       `"OCP Consignation" <${process.env.EMAIL_USER}>`,
    replyTo:    process.env.EMAIL_USER,
    to:         email,
    subject:    `[OCP Consignation] Demande de réinitialisation non traitée`,
    text:       textTemplate(contenuTexte),
    html:       htmlTemplate(contenuHtml),
    headers:    headersAntiSpam(),
    attachments: getLogoAttachments(),
  });
  console.log(`[EMAIL] Notif rejet envoyée à ${email}`);
};

// ══════════════════════════════════════════════════════════════════
// 4. Envoyer rapport PDF par email
// ══════════════════════════════════════════════════════════════════
const envoyerRapportParEmail = async ({ destinataireEmail, sujet, message, pdfPath, pdfNom }) => {
  const attachments = [...getLogoAttachments()];
  if (pdfPath && fs.existsSync(pdfPath)) {
    attachments.push({
      filename:    pdfNom || path.basename(pdfPath),
      path:        pdfPath,
      contentType: 'application/pdf',
    });
  }

  const dateStr = new Date().toLocaleString('fr-MA', { timeZone: 'Africa/Casablanca' });

  const contenuHtml = `
    <p style="font-size:15px;color:#163832;margin:0 0 16px;">Bonjour,</p>
    <p style="font-size:14px;color:#424242;margin:0 0 18px;line-height:1.6;">
      ${message || 'Veuillez trouver ci-joint le rapport de consignation demandé.'}
    </p>

    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
           style="background:#f0f7f0;border-left:4px solid #235347;border-radius:8px;margin:0 0 20px;">
      <tr><td style="padding:18px 22px;">
        <p style="margin:6px 0;font-size:14px;color:#163832;">
          <span style="font-weight:600;display:inline-block;min-width:130px;">Document :</span>
          ${pdfNom || 'Rapport PDF'}
        </p>
        <p style="margin:6px 0;font-size:14px;color:#163832;">
          <span style="font-weight:600;display:inline-block;min-width:130px;">Envoyé le :</span>
          ${dateStr}
        </p>
      </td></tr>
    </table>`;

  const contenuTexte =
    `Bonjour,\n\n` +
    `${message || 'Veuillez trouver ci-joint le rapport de consignation demandé.'}\n\n` +
    `Document : ${pdfNom || 'Rapport PDF'}\n` +
    `Envoyé le : ${dateStr}`;

  await transporter.sendMail({
    from:       `"OCP Consignation" <${process.env.EMAIL_USER}>`,
    replyTo:    process.env.EMAIL_USER,
    to:         destinataireEmail,
    subject:    sujet || `[OCP Consignation] Rapport PDF — ${pdfNom || 'document'}`,
    text:       textTemplate(contenuTexte),
    html:       htmlTemplate(contenuHtml),
    headers:    headersAntiSpam(),
    attachments,
  });
  console.log(`[EMAIL] Rapport envoyé à ${destinataireEmail}`);
};

module.exports = {
  genererMotPasseTemp,
  envoyerMotPasseTemp,
  notifierAdminResetDemande,
  notifierRejetReset,
  envoyerRapportParEmail,
};