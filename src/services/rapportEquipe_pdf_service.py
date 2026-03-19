#!/usr/bin/env python3
# src/services/rapportEquipe_pdf_service.py
#
# ✅ FIX MAJEUR 1 — Les dates reçues depuis Node.js sont maintenant des ISO strings
#    AVEC timezone explicite (ex: "2026-03-10T23:22:46+01:00" ou "+00:00" en Ramadan).
#    Le Node.js fait la conversion UTC→Maroc AVANT d'envoyer ici.
#    to_maroc() les détecte via tzinfo et les traite correctement SANS double conversion.
#
# ✅ FIX MAJEUR 2 — gen_timeline() : suppression du double décalage.
#    L'ancien code faisait datetime.fromtimestamp(ts, tz=UTC) puis to_maroc()
#    → double conversion. Maintenant on travaille directement avec les objets
#    datetime aware retournés par to_maroc().
#
# ✅ FIX 3 — table_recap() : utilise demande.date_deconsignation réelle
#    au lieu de now_maroc() pour "Date déconsig."
#
# ✅ FIX 4 — duree_min() robuste : fonctionne avec strings ISO+offset ET datetime aware
#
# ✅ FIX 5 — gen_bar_chart() et gen_timeline() : gèrent gracieusement les membres
#    sans heure_entree (statut en_attente)
#
# NOTE TIMEZONE :
#    Node.js envoie des ISO strings avec offset Maroc explicite.
#    Python les parse avec fromisoformat() → tzinfo présent → conversion directe.
#    Aucune ambiguïté. Ramadan-safe car l'offset vient de Node (Intl.DateTimeFormat).

import sys
import json
import os
from datetime import datetime, timezone, timedelta
import io

# ── TIMEZONE : parser les ISO strings avec offset explicite ──────────────────
# Node.js envoie maintenant des strings avec offset (ex: +01:00 ou +00:00).
# On les parse directement. Si par hasard une string sans offset arrive (ancien code),
# on applique un fallback UTC+1.

try:
    from zoneinfo import ZoneInfo
    MAROC_TZ = ZoneInfo("Africa/Casablanca")
    _TZ_METHOD = "zoneinfo"
except ImportError:
    try:
        import pytz
        MAROC_TZ = pytz.timezone("Africa/Casablanca")
        _TZ_METHOD = "pytz"
    except ImportError:
        MAROC_TZ = timezone(timedelta(hours=1))  # UTC+1 fallback
        _TZ_METHOD = "fallback_utc+1"

print(f"[TZ] méthode : {_TZ_METHOD}", file=sys.stderr)


def to_maroc(d_input):
    """
    Convertit n'importe quelle date en datetime aware avec fuseau Maroc.

    Cas 1 : ISO string avec offset ("+01:00") — vient de Node.js après conversion
            → parse directement, tzinfo déjà présent, PAS de double conversion
    Cas 2 : ISO string sans offset — vient d'un ancien appel (fallback)
            → on suppose que c'est UTC, on convertit vers Maroc
    Cas 3 : datetime aware → convertit vers Maroc si nécessaire
    Cas 4 : datetime naive → suppose UTC, convertit vers Maroc
    """
    if d_input is None:
        return None

    try:
        if isinstance(d_input, str):
            # Nettoyer le Z
            s = d_input.strip().replace('Z', '+00:00')

            # ✅ FIX : détecter si offset présent dans la string
            # Un offset ressemble à +HH:MM ou -HH:MM après la partie temps
            # Exemples: "2026-03-10T23:22:46+01:00" ou "2026-03-10 22:22:46"
            has_offset = False
            if len(s) > 19:
                tail = s[19:]  # partie après "YYYY-MM-DDTHH:MM:SS"
                if '+' in tail or (tail.startswith('-') and ':' in tail):
                    has_offset = True

            dt = datetime.fromisoformat(s)

            if dt.tzinfo is not None:
                # ✅ Offset présent (cas Node.js) → PAS de conversion supplémentaire
                # La date est déjà en heure Maroc envoyée par Node.js
                # On l'attache au fuseau Maroc pour cohérence des affichages
                if _TZ_METHOD == "zoneinfo":
                    return dt.astimezone(MAROC_TZ)
                elif _TZ_METHOD == "pytz":
                    return dt.astimezone(MAROC_TZ)
                else:
                    return dt  # Garder l'offset tel quel
            else:
                # Pas d'offset → supposer UTC (ancien comportement fallback)
                dt_utc = dt.replace(tzinfo=timezone.utc)
                if _TZ_METHOD == "zoneinfo":
                    return dt_utc.astimezone(MAROC_TZ)
                elif _TZ_METHOD == "pytz":
                    return dt_utc.astimezone(MAROC_TZ)
                else:
                    # Fallback : UTC+1
                    return dt_utc.astimezone(timezone(timedelta(hours=1)))

        elif isinstance(d_input, datetime):
            if d_input.tzinfo is not None:
                if _TZ_METHOD == "zoneinfo":
                    return d_input.astimezone(MAROC_TZ)
                elif _TZ_METHOD == "pytz":
                    return d_input.astimezone(MAROC_TZ)
                else:
                    return d_input
            else:
                # Naive → supposer UTC
                dt_utc = d_input.replace(tzinfo=timezone.utc)
                if _TZ_METHOD == "zoneinfo":
                    return dt_utc.astimezone(MAROC_TZ)
                elif _TZ_METHOD == "pytz":
                    return dt_utc.astimezone(MAROC_TZ)
                else:
                    return dt_utc.astimezone(timezone(timedelta(hours=1)))
        else:
            return None

    except Exception as e:
        print(f"[TZ] to_maroc erreur: {e} — input: {repr(d_input)}", file=sys.stderr)
        return None


def now_maroc():
    """Retourne datetime.now() en heure Maroc réelle."""
    return to_maroc(datetime.now(timezone.utc))


import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    Image as RLImage, PageBreak
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT

# ── Palette ──────────────────────────────────────────────────────────────────
BLEU         = colors.HexColor('#003087')
BLEU_LIGHT   = colors.HexColor('#D6E4F3')
BLEU_MID     = colors.HexColor('#1565C0')
VERT         = colors.HexColor('#2E7D32')
VERT_LIGHT   = colors.HexColor('#E8F5E9')
VERT_MID     = colors.HexColor('#4CAF50')
ORANGE       = colors.HexColor('#F57C00')
ORANGE_LIGHT = colors.HexColor('#FFF3E0')
ROUGE        = colors.HexColor('#C62828')
ROUGE_LIGHT  = colors.HexColor('#FFEBEE')
GRIS         = colors.HexColor('#757575')
GRIS_LIGHT   = colors.HexColor('#F5F5F5')
NOIR         = colors.HexColor('#212121')
VIOLET       = colors.HexColor('#6A1B9A')
VIOLET_LIGHT = colors.HexColor('#F3E5F5')
JAUNE        = colors.HexColor('#F9A825')
BLANC        = colors.white


# ── Helpers dates ─────────────────────────────────────────────────────────────
def fmt_date(d_input):
    dt = to_maroc(d_input)
    if not dt:
        return '—'
    return dt.strftime('%d/%m/%Y')


def fmt_heure(d_input):
    dt = to_maroc(d_input)
    if not dt:
        return '—'
    return dt.strftime('%H:%M:%S')


def fmt_date_heure(d_input):
    dt = to_maroc(d_input)
    if not dt:
        return '—'
    return dt.strftime('%d/%m/%Y %H:%M')


def duree_min(debut_input, fin_input):
    """
    ✅ FIX : calcul correct de durée entre deux datetime aware.
    Les deux objets sont dans le même fuseau (Maroc), la différence est correcte
    même si l'offset change (ex: Ramadan). Aucune double conversion.
    """
    d1 = to_maroc(debut_input)
    d2 = to_maroc(fin_input)
    if not d1 or not d2:
        return None
    diff_sec = (d2 - d1).total_seconds()
    if diff_sec < 0:
        return None  # Données incohérentes (sortie avant entrée)
    return round(diff_sec / 60)


def fmt_duree(minutes):
    if minutes is None or minutes < 0:
        return '—'
    if minutes < 60:
        return f'{int(minutes)} min'
    h = int(minutes // 60)
    m = int(minutes % 60)
    return f'{h}h{str(m).zfill(2)}' if m > 0 else f'{h}h00'


# ── Styles ReportLab ──────────────────────────────────────────────────────────
def build_styles():
    styles = getSampleStyleSheet()

    styles.add(ParagraphStyle(
        'TitreSection',
        parent=styles['Heading2'],
        fontSize=10,
        textColor=BLANC,
        backColor=BLEU,
        spaceBefore=8,
        spaceAfter=4,
        leftIndent=6,
        leading=16,
    ))

    styles.add(ParagraphStyle(
        'CelluleNormal',
        parent=styles['Normal'],
        fontSize=8,
        textColor=NOIR,
        leading=10,
    ))

    styles.add(ParagraphStyle(
        'CelluleBold',
        parent=styles['Normal'],
        fontSize=8,
        textColor=BLEU,
        fontName='Helvetica-Bold',
        leading=10,
    ))

    styles.add(ParagraphStyle(
        'Header',
        parent=styles['Normal'],
        fontSize=13,
        textColor=BLANC,
        fontName='Helvetica-Bold',
        alignment=TA_CENTER,
        leading=16,
    ))

    styles.add(ParagraphStyle(
        'HeaderSub',
        parent=styles['Normal'],
        fontSize=8,
        textColor=BLEU_LIGHT,
        alignment=TA_CENTER,
    ))

    styles.add(ParagraphStyle(
        'FooterNote',
        parent=styles['Normal'],
        fontSize=7,
        textColor=GRIS,
        fontName='Helvetica-Oblique',
        alignment=TA_CENTER,
    ))

    return styles


# ── Graphique 1 : Barres durée par membre ────────────────────────────────────
def gen_bar_chart(membres):
    donnees = []
    for m in membres:
        # ✅ FIX 5 : ignorer les membres sans heure d'entrée
        if not m.get('heure_entree'):
            continue
        d = duree_min(m.get('heure_entree'), m.get('heure_sortie'))
        if d is not None and d >= 0:
            donnees.append((m.get('nom', '?'), d))

    donnees.sort(key=lambda x: x[1], reverse=True)

    if not donnees:
        return None

    noms   = [d[0][:18] for d in donnees]
    durees = [d[1] for d in donnees]
    max_d  = max(durees) if durees else 1

    couleurs = []
    for d in durees:
        ratio = d / max_d if max_d > 0 else 0
        if ratio > 0.75:
            couleurs.append('#C62828')
        elif ratio > 0.5:
            couleurs.append('#F57C00')
        else:
            couleurs.append('#4CAF50')

    hauteur = max(2.2, len(noms) * 0.42)
    fig, ax = plt.subplots(figsize=(7.2, hauteur))
    fig.patch.set_facecolor('#F9F9F9')
    ax.set_facecolor('#F9F9F9')

    bars = ax.barh(noms, durees, color=couleurs, height=0.55,
                   edgecolor='white', linewidth=0.5)

    for bar, d in zip(bars, durees):
        ax.text(bar.get_width() + max_d * 0.01,
                bar.get_y() + bar.get_height() / 2,
                fmt_duree(d), va='center', ha='left',
                fontsize=7.5, fontweight='bold', color='#424242')

    ax.set_xlabel('Durée', fontsize=8, color='#616161')
    ax.set_xlim(0, max_d * 1.22)
    ax.xaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: fmt_duree(int(x))))
    ax.tick_params(axis='y', labelsize=8, colors='#424242')
    ax.tick_params(axis='x', labelsize=7, colors='#9E9E9E')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['left'].set_color('#E0E0E0')
    ax.spines['bottom'].set_color('#E0E0E0')
    ax.grid(axis='x', linestyle='--', alpha=0.4, color='#BDBDBD')
    ax.invert_yaxis()

    plt.tight_layout(pad=0.4)
    buf = io.BytesIO()
    plt.savefig(buf, format='png', dpi=130, bbox_inches='tight')
    plt.close(fig)
    buf.seek(0)
    return buf


# ── Graphique 2 : Camembert statuts ──────────────────────────────────────────
def gen_pie_chart(membres):
    total    = len(membres)
    sortis   = sum(1 for m in membres if m.get('statut') == 'sortie')
    sur_site = sum(1 for m in membres if m.get('statut') == 'sur_site')
    attente  = sum(1 for m in membres if m.get('statut') == 'en_attente')

    slices = []
    if sortis   > 0: slices.append(('Sortis',     sortis,    '#4CAF50'))
    if sur_site > 0: slices.append(('Sur site',   sur_site,  '#F57C00'))
    if attente  > 0: slices.append(('En attente', attente,   '#C62828'))

    if not slices or total == 0:
        return None

    vals  = [s[1] for s in slices]
    lbls  = [f"{s[0]}\n{s[1]} ({round(s[1]/total*100)}%)" for s in slices]
    clrs  = [s[2] for s in slices]

    fig, ax = plt.subplots(figsize=(4.2, 3.0))
    fig.patch.set_facecolor('#F9F9F9')

    wedges, _ = ax.pie(
        vals, colors=clrs, startangle=90,
        wedgeprops=dict(width=0.55, edgecolor='white', linewidth=2)
    )

    ax.text(0, 0, str(total), ha='center', va='center',
            fontsize=18, fontweight='bold', color='#1565C0')
    ax.text(0, -0.22, 'membres', ha='center', va='center',
            fontsize=7, color='#9E9E9E')

    legend_patches = [mpatches.Patch(color=s[2], label=lbls[i])
                      for i, s in enumerate(slices)]
    ax.legend(handles=legend_patches, loc='center left',
              bbox_to_anchor=(1.05, 0.5), fontsize=8, frameon=False)

    ax.set_aspect('equal')
    plt.tight_layout(pad=0.3)
    buf = io.BytesIO()
    plt.savefig(buf, format='png', dpi=130, bbox_inches='tight')
    plt.close(fig)
    buf.seek(0)
    return buf


# ── Graphique 3 : Timeline ────────────────────────────────────────────────────
def gen_timeline(membres):
    """
    ✅ FIX MAJEUR 2 — Suppression du double décalage timezone.

    ANCIEN code (bugué) :
        ts = dt.timestamp()  ← timestamp POSIX (secondes depuis epoch UTC)
        # ... plus tard ...
        datetime.fromtimestamp(ts, tz=timezone.utc)  ← ré-interprète en UTC
        to_maroc(...)                                  ← convertit vers Maroc (double !)

    NOUVEAU code :
        On travaille directement avec les objets datetime aware retournés par to_maroc().
        Les timestamps POSIX ne sont utilisés que pour les calculs de position (ratios).
        Les labels de l'axe X sont formatés directement depuis les datetime Maroc.
    """
    # Filtrer les membres ayant au moins une heure d'entrée
    avec_entree = [m for m in membres if m.get('heure_entree') and to_maroc(m['heure_entree'])]

    if not avec_entree:
        return None

    # Convertir toutes les dates en datetime aware Maroc
    def get_dt_entree(m):
        return to_maroc(m['heure_entree'])

    def get_dt_sortie(m):
        if m.get('heure_sortie'):
            return to_maroc(m['heure_sortie'])
        return now_maroc()  # Membre encore sur site → jusqu'à maintenant

    # Bornes de la timeline
    dt_min = min(get_dt_entree(m) for m in avec_entree)
    dt_max = max(get_dt_sortie(m) for m in avec_entree)

    # Éviter division par zéro
    total_seconds = (dt_max - dt_min).total_seconds()
    if total_seconds <= 0:
        total_seconds = 1

    def ratio(dt):
        """Position relative [0, 1] dans la timeline."""
        return (dt - dt_min).total_seconds() / total_seconds

    noms    = [m.get('nom', '?')[:18] for m in avec_entree]
    n       = len(avec_entree)
    hauteur = max(2.0, n * 0.45)

    fig, ax = plt.subplots(figsize=(7.2, hauteur))
    fig.patch.set_facecolor('#F9F9F9')
    ax.set_facecolor('#F9F9F9')

    for i, m in enumerate(avec_entree):
        dt_ent = get_dt_entree(m)
        dt_sor = get_dt_sortie(m)

        x_s = ratio(dt_ent)
        x_e = ratio(dt_sor)

        clr = '#4CAF50' if m.get('statut') == 'sortie' else '#F57C00'
        ax.barh(i, x_e - x_s, left=x_s, height=0.5, color=clr,
                edgecolor='white', linewidth=0.5)

        ax.text(x_s, i + 0.35, fmt_heure(m['heure_entree']),
                fontsize=5.5, color='#388E3C', ha='left')
        if m.get('heure_sortie'):
            ax.text(x_e, i + 0.35, fmt_heure(m['heure_sortie']),
                    fontsize=5.5, color='#C62828', ha='right')

    # ✅ FIX : Labels de l'axe X directement depuis les datetime Maroc
    #          Plus de datetime.fromtimestamp() → pas de double conversion
    tick_positions = np.linspace(0, 1, 5)
    tick_labels = []
    for p in tick_positions:
        # Interpoler le datetime correspondant à cette position
        dt_tick = dt_min + timedelta(seconds=p * total_seconds)
        # dt_tick est déjà un datetime aware Maroc → strftime correct
        tick_labels.append(dt_tick.strftime('%H:%M'))

    ax.set_xticks(tick_positions)
    ax.set_xticklabels(tick_labels, fontsize=6.5, color='#9E9E9E')
    ax.set_yticks(range(n))
    ax.set_yticklabels(noms, fontsize=7.5, color='#424242')
    ax.set_xlim(0, 1)
    ax.invert_yaxis()
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['left'].set_color('#E0E0E0')
    ax.spines['bottom'].set_color('#E0E0E0')
    ax.grid(axis='x', linestyle='--', alpha=0.35, color='#BDBDBD')

    plt.tight_layout(pad=0.4)
    buf = io.BytesIO()
    plt.savefig(buf, format='png', dpi=130, bbox_inches='tight')
    plt.close(fig)
    buf.seek(0)
    return buf


# ── Section titre ─────────────────────────────────────────────────────────────
def section_titre(texte, couleur=BLEU):
    style = ParagraphStyle(
        'SecTitre',
        fontSize=9,
        textColor=BLANC,
        backColor=couleur,
        fontName='Helvetica-Bold',
        leading=14,
        leftIndent=6,
        spaceBefore=6,
        spaceAfter=4,
    )
    return Paragraph(texte, style)


# ── Tableau récap demande ─────────────────────────────────────────────────────
def table_recap(demande, chef, styles):
    now_str = fmt_date_heure(now_maroc())

    # ✅ FIX 3 — Utiliser date_deconsignation RÉELLE si présente
    #            sinon now() (cas où le rapport est généré pendant la déconsignation)
    date_decons_str = demande.get('date_deconsignation')
    date_decons_fmt = fmt_date_heure(date_decons_str) if date_decons_str else now_str

    rows = [
        ['N° Ordre',         demande.get('numero_ordre', '—')],
        ['Equipement (TAG)',  f"{demande.get('equipement_nom','—')} ({demande.get('tag','—')})"],
        ['LOT',              demande.get('lot_code', '—')],
        ['Raison',           demande.get('raison', '—')],
        ['Statut final',     demande.get('statut', '—')],
        ['Date consignation',fmt_date_heure(demande.get('date_validation'))],
        # ✅ Date réelle de déconsignation (pas now())
        ['Date déconsignation', date_decons_fmt],
        ['Chef équipe',      f"{chef.get('prenom','')} {chef.get('nom','')}"],
        ['Métier équipe',    chef.get('metier_label', chef.get('type_metier', '—'))],
    ]

    data = []
    for label, val in rows:
        data.append([
            Paragraph(label, styles['CelluleBold']),
            Paragraph(str(val), styles['CelluleNormal']),
        ])

    t = Table(data, colWidths=[110, 318])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), BLANC),
        ('ROWBACKGROUNDS', (0, 0), (-1, -1), [GRIS_LIGHT, BLANC]),
        ('GRID', (0, 0), (-1, -1), 0.4, colors.HexColor('#BDBDBD')),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
    ]))
    return t


# ── Cartes statistiques ───────────────────────────────────────────────────────
def table_stats(membres, stats, styles):
    durees = [
        duree_min(m.get('heure_entree'), m.get('heure_sortie'))
        for m in membres
        if m.get('heure_entree') and m.get('heure_sortie')
    ]
    durees = [d for d in durees if d is not None and d >= 0]

    total    = len(membres)
    sortis   = sum(1 for m in membres if m.get('statut') == 'sortie')
    sur_site = sum(1 for m in membres if m.get('statut') == 'sur_site')
    attente  = sum(1 for m in membres if m.get('statut') == 'en_attente')
    dur_moy  = round(sum(durees) / len(durees)) if durees else None
    dur_max  = max(durees) if durees else None
    dur_mini = min(durees) if durees else None

    # Durée totale depuis stats (calculée côté Node) ou durée max locale
    dur_total = stats.get('duree_totale_min') or (max(durees) if durees else None)

    cards = [
        ('Total membres', str(total),          '#1565C0', '#E3F2FD'),
        ('Sortis',        str(sortis),          '#2E7D32', '#E8F5E9'),
        ('Sur site',      str(sur_site),        '#F57C00', '#FFF3E0'),
        ('En attente',    str(attente),         '#757575', '#F5F5F5'),
        ('Durée totale',  fmt_duree(dur_total), '#6A1B9A', '#F3E5F5'),
        ('Durée moyenne', fmt_duree(dur_moy),   '#C62828', '#FFEBEE'),
        ('Durée max',     fmt_duree(dur_max),   '#F57C00', '#FFF3E0'),
        ('Durée min',     fmt_duree(dur_mini),  '#2E7D32', '#E8F5E9'),
    ]

    row1 = []
    row2 = []
    for i, (label, val, clr, bg) in enumerate(cards):
        cell_style = ParagraphStyle('Card', fontSize=7, fontName='Helvetica-Bold',
                                    textColor=colors.HexColor(clr), alignment=TA_CENTER)
        val_style  = ParagraphStyle('CardVal', fontSize=16, fontName='Helvetica-Bold',
                                    textColor=colors.HexColor(clr), alignment=TA_CENTER)
        cell = [Paragraph(label, cell_style), Paragraph(val, val_style)]
        if i < 4:
            row1.append(cell)
        else:
            row2.append(cell)

    def make_row_table(row, bgs):
        col_w = 107
        t = Table([row], colWidths=[col_w] * 4)
        style_cmds = [
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#E0E0E0')),
        ]
        for j, bg in enumerate(bgs):
            style_cmds.append(('BACKGROUND', (j, 0), (j, 0), colors.HexColor(bg)))
        t.setStyle(TableStyle(style_cmds))
        return t

    t1 = make_row_table(row1, [c[3] for c in cards[:4]])
    t2 = make_row_table(row2, [c[3] for c in cards[4:]])
    return [t1, t2]


# ── Tableau chronologie ───────────────────────────────────────────────────────
def table_chronologie(membres, styles):
    actions = []
    for m in membres:
        if m.get('heure_entree'):
            actions.append({
                'heure':   m['heure_entree'],
                'type':    'ENTREE',
                'membre':  m.get('nom', '—'),
                'badge':   m.get('badge_ocp_id', '—') or '—',
                'cadenas': m.get('cad_id') or m.get('numero_cadenas', '—') or '—',
                'couleur': '#2E7D32',
                'bg':      '#E8F5E9',
            })
        if m.get('heure_sortie'):
            actions.append({
                'heure':   m['heure_sortie'],
                'type':    'SORTIE',
                'membre':  m.get('nom', '—'),
                'badge':   m.get('badge_ocp_id', '—') or '—',
                'cadenas': m.get('scan_cadenas_sortie') or m.get('numero_cadenas', '—') or '—',
                'couleur': '#C62828',
                'bg':      '#FFEBEE',
            })

    if not actions:
        return Paragraph('Aucune action enregistrée.', styles['CelluleNormal'])

    # Trier par heure réelle (ISO string avec offset → tri lexicographique correct)
    actions.sort(key=lambda a: a['heure'] or '')

    header = [
        Paragraph('#',          styles['CelluleBold']),
        Paragraph('Heure',      styles['CelluleBold']),
        Paragraph('Action',     styles['CelluleBold']),
        Paragraph('Membre',     styles['CelluleBold']),
        Paragraph('Badge OCP',  styles['CelluleBold']),
        Paragraph('Cadenas',    styles['CelluleBold']),
    ]

    data = [header]
    row_bgs = [BLEU]
    for i, a in enumerate(actions):
        clr      = colors.HexColor(a['couleur'])
        num_st   = ParagraphStyle('n', fontSize=7.5, alignment=TA_CENTER)
        act_st   = ParagraphStyle('a', fontSize=7.5, fontName='Helvetica-Bold',
                                   textColor=clr, alignment=TA_CENTER)
        cel_st   = ParagraphStyle('c', fontSize=7.5, alignment=TA_CENTER)

        data.append([
            Paragraph(str(i + 1),           num_st),
            Paragraph(fmt_heure(a['heure']),cel_st),
            Paragraph(a['type'],            act_st),
            Paragraph(str(a['membre']),     cel_st),
            Paragraph(str(a['badge']),      cel_st),
            Paragraph(str(a['cadenas']),    cel_st),
        ])
        row_bgs.append(colors.HexColor(a['bg']))

    col_w = [20, 55, 45, 120, 100, 88]
    t = Table(data, colWidths=col_w)

    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), BLEU),
        ('TEXTCOLOR',  (0, 0), (-1, 0), BLANC),
        ('FONTNAME',   (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE',   (0, 0), (-1, 0), 7.5),
        ('ALIGN',      (0, 0), (-1, -1), 'CENTER'),
        ('VALIGN',     (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID',       (0, 0), (-1, -1), 0.4, colors.HexColor('#BDBDBD')),
        ('TOPPADDING',    (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]
    for i, bg in enumerate(row_bgs[1:], start=1):
        style_cmds.append(('BACKGROUND', (0, i), (-1, i), bg))

    t.setStyle(TableStyle(style_cmds))
    return t


# ── Tableau membres détaillé ──────────────────────────────────────────────────
def table_membres(membres, styles):
    header = [
        Paragraph('Nom',       styles['CelluleBold']),
        Paragraph('Badge OCP', styles['CelluleBold']),
        Paragraph('Cadenas',   styles['CelluleBold']),
        Paragraph('Entrée',    styles['CelluleBold']),
        Paragraph('Sortie',    styles['CelluleBold']),
        Paragraph('Durée',     styles['CelluleBold']),
        Paragraph('Statut',    styles['CelluleBold']),
    ]

    data = [header]
    for m in membres:
        dur    = duree_min(m.get('heure_entree'), m.get('heure_sortie'))
        statut = (m.get('statut') or '—').replace('_', ' ')
        clr_s  = '#2E7D32' if 'sortie' in statut else '#F57C00' if 'site' in statut else '#9E9E9E'

        cel   = ParagraphStyle('c',  fontSize=7, alignment=TA_CENTER)
        cel_g = ParagraphStyle('cg', fontSize=7, alignment=TA_CENTER,
                                textColor=colors.HexColor('#2E7D32'), fontName='Helvetica-Bold')
        cel_r = ParagraphStyle('cr', fontSize=7, alignment=TA_CENTER,
                                textColor=colors.HexColor('#C62828'), fontName='Helvetica-Bold')
        cel_v = ParagraphStyle('cv', fontSize=7, alignment=TA_CENTER,
                                textColor=colors.HexColor('#6A1B9A'), fontName='Helvetica-Bold')
        cel_s = ParagraphStyle('cs', fontSize=7, alignment=TA_CENTER,
                                textColor=colors.HexColor(clr_s), fontName='Helvetica-Bold')
        cel_l = ParagraphStyle('cl', fontSize=7, alignment=TA_LEFT)

        data.append([
            Paragraph(str(m.get('nom', '—')),                    cel_l),
            Paragraph(str(m.get('badge_ocp_id', '—') or '—'),   cel),
            Paragraph(str(m.get('numero_cadenas', '—') or '—'), cel),
            Paragraph(fmt_heure(m.get('heure_entree')),          cel_g),
            Paragraph(fmt_heure(m.get('heure_sortie')),          cel_r),
            Paragraph(fmt_duree(dur),                            cel_v),
            Paragraph(statut,                                    cel_s),
        ])

    col_w = [90, 75, 70, 58, 58, 45, 32]
    t = Table(data, colWidths=col_w)

    style_cmds = [
        ('BACKGROUND', (0, 0), (-1, 0), BLEU_MID),
        ('TEXTCOLOR',  (0, 0), (-1, 0), BLANC),
        ('FONTNAME',   (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE',   (0, 0), (-1, 0), 7.5),
        ('ALIGN',      (0, 0), (-1, -1), 'CENTER'),
        ('ALIGN',      (0, 1), (0, -1),  'LEFT'),
        ('VALIGN',     (0, 0), (-1, -1), 'MIDDLE'),
        ('GRID',       (0, 0), (-1, -1), 0.4, colors.HexColor('#BDBDBD')),
        ('TOPPADDING',    (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING',   (0, 1), (0, -1),  6),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [GRIS_LIGHT, BLANC]),
    ]
    t.setStyle(TableStyle(style_cmds))
    return t


# ── En-tête du document ───────────────────────────────────────────────────────
def make_header_table(demande, chef, logo_path, styles):
    now_str  = fmt_date(now_maroc())
    chef_nom = f"{chef.get('prenom','')} {chef.get('nom','')}"

    info_rows = [
        ['Réf.',  demande.get('numero_ordre', '—')],
        ['TAG',   demande.get('tag', '—')],
        ['LOT',   demande.get('lot_code', '—')],
        ['Date',  now_str],
        ['Chef',  chef_nom],
    ]
    info_data = []
    for lbl, val in info_rows:
        info_data.append([
            Paragraph(f'<b>{lbl} :</b>',
                      ParagraphStyle('li', fontSize=6.5, textColor=BLEU)),
            Paragraph(str(val),
                      ParagraphStyle('lv', fontSize=6.5, textColor=NOIR)),
        ])

    info_t = Table(info_data, colWidths=[28, 80])
    info_t.setStyle(TableStyle([
        ('ROWBACKGROUNDS', (0, 0), (-1, -1), [colors.HexColor('#EBF3FB'), BLANC]),
        ('GRID',    (0, 0), (-1, -1), 0.3, colors.HexColor('#BDBDBD')),
        ('VALIGN',  (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING',    (0, 0), (-1, -1), 2),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
        ('LEFTPADDING',   (0, 0), (-1, -1), 3),
    ]))

    titre_style = ParagraphStyle('Titre', fontSize=11, textColor=BLANC,
                                  fontName='Helvetica-Bold',
                                  alignment=TA_CENTER, leading=15)
    sub_style   = ParagraphStyle('Sub', fontSize=7.5,
                                  textColor=BLEU_LIGHT, alignment=TA_CENTER)

    titre_cell = [
        Paragraph("RAPPORT DE FIN D'INTERVENTION", titre_style),
        Paragraph('Consignation / Déconsignation — Équipe de travail', sub_style),
    ]

    logo_cell = ''
    if logo_path and os.path.exists(logo_path):
        try:
            logo_cell = RLImage(logo_path, width=65, height=52)
        except Exception:
            logo_cell = Paragraph('OCP',
                                   ParagraphStyle('logo', fontSize=10,
                                                   fontName='Helvetica-Bold',
                                                   textColor=BLEU,
                                                   alignment=TA_CENTER))
    else:
        logo_cell = Paragraph('OCP',
                               ParagraphStyle('logo', fontSize=10,
                                               fontName='Helvetica-Bold',
                                               textColor=BLEU,
                                               alignment=TA_CENTER))

    header_data = [[logo_cell, titre_cell, info_t]]
    header_t = Table(header_data, colWidths=[75, 280, 113])
    header_t.setStyle(TableStyle([
        ('BACKGROUND', (1, 0), (1, 0), BLEU),
        ('BACKGROUND', (0, 0), (0, 0), BLANC),
        ('VALIGN',     (0, 0), (-1, -1), 'MIDDLE'),
        ('ALIGN',      (1, 0), (1, 0),  'CENTER'),
        ('TOPPADDING',    (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING',   (0, 0), (0, 0),   4),
        ('BOX', (0, 0), (-1, -1), 0.5, NOIR),
    ]))
    return header_t


# ── Pied de page ──────────────────────────────────────────────────────────────
def make_footer(chef, styles):
    chef_nom = f"{chef.get('prenom','')} {chef.get('nom','')}"
    now_str  = fmt_date_heure(now_maroc())

    data = [[
        Paragraph(f"<b>Signature du Chef d'Équipe :</b><br/>{chef_nom}",
                  ParagraphStyle('fp', fontSize=8, textColor=BLEU)),
        Paragraph(f'<b>Rapport généré le :</b><br/>{now_str}',
                  ParagraphStyle('fr', fontSize=8, textColor=BLEU)),
    ]]
    t = Table(data, colWidths=[234, 234])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), GRIS_LIGHT),
        ('BOX',        (0, 0), (-1, -1), 0.5, colors.HexColor('#BDBDBD')),
        ('INNERGRID',  (0, 0), (-1, -1), 0.5, colors.HexColor('#BDBDBD')),
        ('VALIGN',     (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING',    (0, 0), (-1, -1), 10),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 10),
        ('LEFTPADDING',   (0, 0), (-1, -1), 10),
    ]))
    return t


# ── FONCTION PRINCIPALE ───────────────────────────────────────────────────────
def generer_rapport(input_json_path, output_pdf_path):
    with open(input_json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    demande   = data['demande']
    membres   = data['membres']
    chef      = data['chef']
    stats     = data.get('stats', {})
    logo_path = data.get('logo_path', '')

    styles = build_styles()

    doc = SimpleDocTemplate(
        output_pdf_path,
        pagesize=A4,
        leftMargin=20*mm,
        rightMargin=20*mm,
        topMargin=15*mm,
        bottomMargin=15*mm,
    )

    story = []

    # En-tête
    story.append(make_header_table(demande, chef, logo_path, styles))
    story.append(Spacer(1, 6))

    # Récap demande
    story.append(section_titre('RÉCAPITULATIF DE LA DEMANDE'))
    story.append(table_recap(demande, chef, styles))
    story.append(Spacer(1, 6))

    # Stats
    story.append(section_titre('STATISTIQUES GLOBALES', VERT))
    for t in table_stats(membres, stats, styles):
        story.append(t)
    story.append(Spacer(1, 6))

    # Graphique durées
    story.append(section_titre("DURÉE D'INTERVENTION PAR MEMBRE", ORANGE))
    buf_bar = gen_bar_chart(membres)
    if buf_bar:
        img = RLImage(buf_bar, width=468, height=None)
        img.drawHeight = img.imageHeight * (468 / img.imageWidth)
        story.append(img)
    else:
        story.append(Paragraph('Aucune donnée de durée disponible.', styles['CelluleNormal']))
    story.append(Spacer(1, 6))

    # Pie + Timeline côte à côte
    story.append(section_titre('RÉPARTITION PAR STATUT ET TIMELINE', VIOLET))
    buf_pie  = gen_pie_chart(membres)
    buf_time = gen_timeline(membres)

    pie_img  = RLImage(buf_pie,  width=200, height=145) if buf_pie  else Paragraph('—', styles['CelluleNormal'])
    time_img = RLImage(buf_time, width=250, height=145) if buf_time else Paragraph('—', styles['CelluleNormal'])

    side_data = [[pie_img, time_img]]
    side_t = Table(side_data, colWidths=[220, 248])
    side_t.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('ALIGN',  (0, 0), (-1, -1), 'CENTER'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(side_t)
    story.append(Spacer(1, 6))

    # Page 2 : Chronologie + détail membres
    story.append(PageBreak())
    story.append(section_titre('CHRONOLOGIE DES ACTIONS', NOIR))
    story.append(table_chronologie(membres, styles))
    story.append(Spacer(1, 8))

    story.append(section_titre('DÉTAIL PAR MEMBRE', BLEU_MID))
    story.append(table_membres(membres, styles))
    story.append(Spacer(1, 10))

    # Footer
    story.append(make_footer(chef, styles))
    story.append(Spacer(1, 4))
    story.append(Paragraph(
        "Ce rapport est généré automatiquement par le système de consignation OCP. "
        "Il constitue un document officiel de traçabilité.",
        styles['FooterNote']
    ))

    doc.build(story)
    print(f'[PDF] Généré avec succès : {output_pdf_path}', file=sys.stderr)
    print(output_pdf_path)


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: python3 rapportEquipe_pdf_service.py <input.json> <output.pdf>',
              file=sys.stderr)
        sys.exit(1)
    generer_rapport(sys.argv[1], sys.argv[2])