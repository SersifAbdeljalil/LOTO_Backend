-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Hôte : db
-- Généré le : mar. 24 mars 2026 à 11:32
-- Version du serveur : 8.0.45
-- Version de PHP : 8.3.26

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `consignation_ocp`
--

-- --------------------------------------------------------

--
-- Structure de la table `autorisations_travail`
--

CREATE TABLE `autorisations_travail` (
  `id` int NOT NULL,
  `plan_id` int NOT NULL,
  `generee_le` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_debut_prevue` datetime DEFAULT NULL,
  `date_debut_reel` datetime DEFAULT NULL,
  `date_fin_prevue` datetime DEFAULT NULL,
  `date_fin_reel` datetime DEFAULT NULL,
  `statut` enum('generee','en_signature','signee','en_cours','terminee') COLLATE utf8mb4_unicode_ci DEFAULT 'generee',
  `notes` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `deconsignations`
--

CREATE TABLE `deconsignations` (
  `id` int NOT NULL,
  `point_id` int NOT NULL,
  `numero_cadenas` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `deconsigne_par` int NOT NULL,
  `date_deconsigne` datetime NOT NULL,
  `verifie_par` int DEFAULT NULL,
  `date_verifie` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `deconsignations`
--

INSERT INTO `deconsignations` (`id`, `point_id`, `numero_cadenas`, `deconsigne_par`, `date_deconsigne`, `verifie_par`, `date_verifie`, `created_at`) VALUES
(1, 305, 'EL-3101', 15, '2026-03-19 10:27:10', NULL, NULL, '2026-03-19 10:27:10'),
(2, 306, 'CAD-000002', 13, '2026-03-19 10:28:15', NULL, NULL, '2026-03-19 10:28:15'),
(3, 334, 'Cad-mec-100', 15, '2026-03-22 13:40:25', NULL, NULL, '2026-03-22 13:40:25'),
(4, 333, 'Cad-mec-100', 15, '2026-03-22 13:45:56', NULL, NULL, '2026-03-22 13:45:56');

-- --------------------------------------------------------

--
-- Structure de la table `deconsignation_metier`
--

CREATE TABLE `deconsignation_metier` (
  `id` int NOT NULL,
  `demande_id` int NOT NULL,
  `type_metier` enum('genie_civil','mecanique','electrique') COLLATE utf8mb4_unicode_ci NOT NULL,
  `chef_equipe_id` int DEFAULT NULL,
  `statut` enum('en_attente','valide') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en_attente',
  `heure_validation` datetime DEFAULT NULL,
  `pdf_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `deconsignation_metier`
--

INSERT INTO `deconsignation_metier` (`id`, `demande_id`, `type_metier`, `chef_equipe_id`, `statut`, `heure_validation`, `pdf_path`, `created_at`, `updated_at`) VALUES
(1, 69, 'genie_civil', 11, 'valide', '2026-03-19 11:26:09', 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0001_genie_civil_11_1773915965705.pdf', '2026-03-19 10:26:08', '2026-03-19 10:26:08'),
(2, 72, 'genie_civil', 11, 'valide', '2026-03-22 11:47:56', 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0004_genie_civil_11_1774176470586.pdf', '2026-03-22 10:47:55', '2026-03-22 10:47:55'),
(3, 74, 'genie_civil', 11, 'valide', '2026-03-22 11:52:56', 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0006_genie_civil_11_1774180376780.pdf', '2026-03-22 11:53:00', '2026-03-22 11:53:00'),
(4, 73, 'genie_civil', 11, 'valide', '2026-03-22 11:56:28', 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0005_genie_civil_11_1774180588008.pdf', '2026-03-22 11:56:30', '2026-03-22 11:56:30'),
(5, 81, 'genie_civil', 11, 'valide', '2026-03-22 13:37:06', 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0013_genie_civil_11_1774186626501.pdf', '2026-03-22 13:37:10', '2026-03-22 13:37:10'),
(6, 80, 'genie_civil', 11, 'valide', '2026-03-22 13:44:33', 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0012_genie_civil_11_1774187073571.pdf', '2026-03-22 13:44:36', '2026-03-22 13:44:36');

-- --------------------------------------------------------

--
-- Structure de la table `demandes_consignation`
--

CREATE TABLE `demandes_consignation` (
  `id` int NOT NULL,
  `numero_ordre` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `lot` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lot_id` int DEFAULT NULL,
  `equipement_id` int NOT NULL,
  `agent_id` int NOT NULL,
  `raison` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `types_intervenants` text COLLATE utf8mb4_unicode_ci,
  `date_souhaitee` datetime DEFAULT NULL,
  `statut` enum('en_attente','validee','rejetee','en_cours','consigne_charge','consigne_process','consigne','deconsigne_gc','deconsigne_mec','deconsigne_elec','deconsigne_intervent','deconsigne_charge','deconsigne_process','deconsignee','cloturee') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `commentaire_rejet` text COLLATE utf8mb4_unicode_ci,
  `note_suspension` text COLLATE utf8mb4_unicode_ci,
  `heure_reprise_prevue` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `chef_prod_id` int DEFAULT NULL,
  `date_validation` datetime DEFAULT NULL,
  `deconsignation_demandee` tinyint(1) NOT NULL DEFAULT '0',
  `date_deconsignation` datetime DEFAULT NULL,
  `date_validation_charge` datetime DEFAULT NULL,
  `date_validation_process` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `photo_path` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pdf_path_charge` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pdf_path_process` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pdf_path_final` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Chemin du PDF unifié (chargé + process), mis à jour à chaque validation',
  `pdf_path_decons_charge` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pdf_path_decons_process` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `charge_id` int DEFAULT NULL,
  `charge_id_process` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `demandes_consignation`
--

INSERT INTO `demandes_consignation` (`id`, `numero_ordre`, `lot`, `lot_id`, `equipement_id`, `agent_id`, `raison`, `types_intervenants`, `date_souhaitee`, `statut`, `commentaire_rejet`, `note_suspension`, `heure_reprise_prevue`, `chef_prod_id`, `date_validation`, `deconsignation_demandee`, `date_deconsignation`, `date_validation_charge`, `date_validation_process`, `created_at`, `updated_at`, `photo_path`, `pdf_path_charge`, `pdf_path_process`, `pdf_path_final`, `pdf_path_decons_charge`, `pdf_path_decons_process`, `charge_id`, `charge_id_process`) VALUES
(69, 'CONS-2026-0001', '601A', 3, 36, 3, 'Changement de  la bride de drain', '[\"process\",\"genie_civil\"]', NULL, 'deconsignee', NULL, NULL, NULL, NULL, '2026-03-19 10:22:43', 1, '2026-03-19 10:28:20', '2026-03-19 10:22:43', '2026-03-19 10:21:25', '2026-03-19 10:20:43', '2026-03-19 10:28:20', 'uploads/consignations/69/photo_1773915753703.jpg', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0001_unifie_1773915763198.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0001_unifie_1773915684938.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0001_decons_process_1773916100493.pdf', NULL, NULL, 15, NULL),
(70, 'CONS-2026-0002', '601A', 3, 37, 3, 'Intervention au niveau de la vanne  à ventelle 601HV 121', '[\"process\",\"genie_civil\"]', NULL, 'consigne', NULL, NULL, NULL, NULL, '2026-03-22 10:10:02', 0, NULL, '2026-03-22 10:09:24', '2026-03-22 10:10:02', '2026-03-22 09:56:38', '2026-03-22 10:10:02', 'uploads/consignations/70/photo_1774173526066.jpg', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0002_unifie_1774174163613.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0002_unifie_1774174202167.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0002_unifie_1774174202167.pdf', NULL, NULL, 15, NULL),
(71, 'CONS-2026-0003', 'Rechauffeur de soufre', 4, 43, 3, 'Montage et démontage de réchauffeur', '[\"process\",\"genie_civil\"]', NULL, 'consigne', NULL, NULL, NULL, NULL, '2026-03-22 10:32:26', 0, NULL, NULL, '2026-03-22 10:32:26', '2026-03-22 10:31:24', '2026-03-22 10:32:26', NULL, NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0003_unifie_1774175545648.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0003_unifie_1774175545648.pdf', NULL, NULL, NULL, NULL),
(72, 'CONS-2026-0004', '601A', 3, 22, 3, 'intervention sur la moto-soufflante 601AAC01', '[\"genie_civil\"]', NULL, 'deconsigne_intervent', NULL, NULL, NULL, NULL, '2026-03-22 10:38:41', 0, NULL, '2026-03-22 10:38:41', NULL, '2026-03-22 10:37:16', '2026-03-22 10:47:55', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0004_unifie_1774175920972.pdf', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0004_unifie_1774175920972.pdf', NULL, NULL, 15, NULL),
(73, 'CONS-2026-0005', '601A', 3, 33, 3, 'changement des èliminateurs de brumes', '[\"process\",\"genie_civil\"]', NULL, 'deconsigne_intervent', NULL, NULL, NULL, NULL, '2026-03-22 11:25:34', 0, NULL, '2026-03-22 11:24:55', '2026-03-22 11:25:34', '2026-03-22 11:23:52', '2026-03-22 11:56:30', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0005_unifie_1774178694946.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0005_unifie_1774178734045.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0005_unifie_1774178734045.pdf', NULL, NULL, 15, NULL),
(74, 'CONS-2026-0006', '601A', 3, 11, 3, 'intervention sur la moto-pompe', '[\"process\",\"genie_civil\"]', NULL, 'deconsigne_intervent', NULL, NULL, NULL, NULL, '2026-03-22 11:48:40', 0, NULL, '2026-03-22 11:48:40', '2026-03-22 11:48:04', '2026-03-22 11:46:52', '2026-03-22 11:53:00', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0006_unifie_1774180120366.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0006_unifie_1774180084252.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0006_unifie_1774180120366.pdf', NULL, NULL, 15, NULL),
(75, 'CONS-2026-0007', '601A', 3, 9, 3, 'Intervention sur La  moto-pompe 601AAP01', '[\"process\",\"genie_civil\"]', NULL, 'consigne', NULL, NULL, NULL, NULL, '2026-03-22 12:14:33', 0, NULL, '2026-03-22 12:14:02', '2026-03-22 12:14:33', '2026-03-22 12:12:37', '2026-03-22 12:14:33', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0007_unifie_1774181642866.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0007_unifie_1774181673519.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0007_unifie_1774181673519.pdf', NULL, NULL, 15, NULL),
(76, 'CONS-2026-0008', '601A', 3, 33, 3, 'changement des èliminateurs de brumes', '[\"process\",\"genie_civil\"]', NULL, 'consigne', NULL, NULL, NULL, NULL, '2026-03-22 12:34:31', 0, NULL, '2026-03-22 12:34:31', '2026-03-22 12:33:22', '2026-03-22 12:31:19', '2026-03-22 12:34:31', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0008_unifie_1774182871130.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0008_unifie_1774182802604.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0008_unifie_1774182871130.pdf', NULL, NULL, 15, NULL),
(77, 'CONS-2026-0009', '601A', 3, 34, 3, 'Intervention sur cérveau moteur', '[\"genie_civil\"]', NULL, 'consigne', NULL, NULL, NULL, NULL, '2026-03-22 12:39:25', 0, NULL, '2026-03-22 12:39:25', NULL, '2026-03-22 12:38:50', '2026-03-22 12:39:25', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0009_unifie_1774183165491.pdf', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0009_unifie_1774183165491.pdf', NULL, NULL, 15, NULL),
(78, 'CONS-2026-0010', '601A', 3, 46, 3, 'Demontage', '[\"genie_civil\"]', NULL, 'consigne', NULL, NULL, NULL, NULL, '2026-03-22 12:51:30', 0, NULL, '2026-03-22 12:51:30', NULL, '2026-03-22 12:50:58', '2026-03-22 12:51:30', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0010_unifie_1774183890340.pdf', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0010_unifie_1774183890340.pdf', NULL, NULL, 15, NULL),
(79, 'CONS-2026-0011', '611A', 1, 1, 3, 'Démontage de la moto- pompe 611AKP01', '[\"process\",\"genie_civil\"]', NULL, 'consigne', NULL, NULL, NULL, NULL, '2026-03-22 13:00:33', 0, NULL, '2026-03-22 12:59:49', '2026-03-22 13:00:33', '2026-03-22 12:59:23', '2026-03-22 13:00:33', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0011_unifie_1774184389314.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0011_unifie_1774184433694.pdf', 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0011_unifie_1774184433694.pdf', NULL, NULL, 15, NULL),
(80, 'CONS-2026-0012', '601A', 3, 22, 3, 'intervention sur la moto-soufflante 601AAC01', '[\"genie_civil\"]', NULL, 'deconsignee', NULL, NULL, NULL, NULL, '2026-03-22 13:15:10', 1, '2026-03-22 13:46:03', '2026-03-22 13:15:10', NULL, '2026-03-22 13:14:13', '2026-03-22 13:46:03', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0012_unifie_1774185310591.pdf', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0012_decons_charge_1774187163147.pdf', NULL, NULL, 15, NULL),
(81, 'CONS-2026-0013', '601A', 3, 22, 3, 'intervention sur la moto-soufflante 601AAC01', '[\"genie_civil\"]', NULL, 'deconsignee', NULL, NULL, NULL, NULL, '2026-03-22 13:22:06', 1, '2026-03-22 13:40:39', '2026-03-22 13:22:06', NULL, '2026-03-22 13:21:01', '2026-03-22 13:40:39', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0013_unifie_1774185726553.pdf', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0013_decons_charge_1774186839779.pdf', NULL, NULL, 15, NULL),
(82, 'CONS-2026-0014', '601A', 3, 46, 3, 'Demontage', '[\"genie_civil\"]', NULL, 'en_attente', NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, '2026-03-22 13:33:22', '2026-03-22 13:33:22', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(83, 'CONS-2026-0015', '601A', 3, 36, 3, 'Changement de  la bride de drain', '[\"process\",\"genie_civil\"]', NULL, 'consigne_charge', NULL, NULL, NULL, NULL, NULL, 0, NULL, '2026-03-24 09:48:09', NULL, '2026-03-24 09:46:26', '2026-03-24 09:48:09', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0015_unifie_1774345688370.pdf', NULL, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0015_unifie_1774345688370.pdf', NULL, NULL, 15, NULL),
(84, 'CONS-2026-0016', '625A', 6, 47, 3, 'Démontage de la pompe pour révision et changement de la vanne de refoulement', '[\"process\",\"mecanique\",\"electrique\"]', NULL, 'en_attente', NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, '2026-03-24 10:01:14', '2026-03-24 10:01:14', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Structure de la table `dossiers_archives`
--

CREATE TABLE `dossiers_archives` (
  `id` int NOT NULL,
  `demande_id` int NOT NULL,
  `pdf_path` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_cloture` datetime DEFAULT CURRENT_TIMESTAMP,
  `cloture_par` int DEFAULT NULL,
  `remarques` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `dossiers_archives`
--

INSERT INTO `dossiers_archives` (`id`, `demande_id`, `pdf_path`, `date_cloture`, `cloture_par`, `remarques`) VALUES
(1, 69, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0001_decons_process_1773916100493.pdf', '2026-03-19 10:28:20', 13, 'PDF déconsignation process — deconsignee'),
(2, 70, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0002_unifie_1774174202167.pdf', '2026-03-22 10:10:02', 13, 'Consignation complète — Process validé EN SECOND (chargé déjà validé) — PDF unifié final'),
(3, 71, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0003_unifie_1774175545648.pdf', '2026-03-22 10:32:26', 13, 'Consignation complète — PDF unifié final'),
(4, 72, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0004_unifie_1774175920972.pdf', '2026-03-22 10:38:41', 15, 'Consignation complète — PDF final'),
(5, 73, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0005_unifie_1774178734045.pdf', '2026-03-22 11:25:34', 13, 'Consignation complète — Process EN SECOND — PDF unifié final'),
(6, 74, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0006_unifie_1774180120366.pdf', '2026-03-22 11:48:40', 15, 'Consignation complète — Chargé EN SECOND — PDF final'),
(7, 75, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0007_unifie_1774181673519.pdf', '2026-03-22 12:14:33', 13, 'Consignation complète — Process EN SECOND — PDF unifié final'),
(8, 76, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0008_unifie_1774182871130.pdf', '2026-03-22 12:34:31', 15, 'Consignation complète — Chargé EN SECOND — PDF final'),
(9, 77, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0009_unifie_1774183165491.pdf', '2026-03-22 12:39:25', 15, 'Consignation complète — PDF final'),
(10, 78, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0010_unifie_1774183890340.pdf', '2026-03-22 12:51:30', 15, 'Consignation complète — PDF final'),
(11, 79, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0011_unifie_1774184433694.pdf', '2026-03-22 13:00:33', 13, 'Consignation complète — Process EN SECOND — PDF unifié final'),
(12, 80, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0012_decons_charge_1774187163147.pdf', '2026-03-22 13:46:03', 15, 'PDF déconsignation — deconsignee'),
(13, 81, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0013_decons_charge_1774186839779.pdf', '2026-03-22 13:40:39', 15, 'PDF déconsignation — deconsignee'),
(14, 82, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0014_initial_1774186402592.pdf', '2026-03-22 13:33:22', 3, 'PDF initial — en attente de consignation'),
(15, 83, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0015_unifie_1774345688370.pdf', '2026-03-24 09:48:09', 15, 'Consignation chargé EN PREMIER — en attente process'),
(16, 84, 'uploads/pdfs/F-HSE-SEC-22-01_CONS-2026-0016_initial_1774346474363.pdf', '2026-03-24 10:01:15', 3, 'PDF initial — en attente de consignation');

-- --------------------------------------------------------

--
-- Structure de la table `equipements`
--

CREATE TABLE `equipements` (
  `id` int NOT NULL,
  `code_equipement` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nom` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `localisation` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `entite` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lot_id` int DEFAULT NULL,
  `zone_id` int DEFAULT NULL,
  `schema_ref` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `actif` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `raison_predefinie` text COLLATE utf8mb4_unicode_ci,
  `photo_schema` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `equipements`
--

INSERT INTO `equipements` (`id`, `code_equipement`, `nom`, `type`, `localisation`, `entite`, `lot_id`, `zone_id`, `schema_ref`, `actif`, `created_at`, `raison_predefinie`, `photo_schema`) VALUES
(1, '611AAP01', 'La pompe 611AKP01', 'equipement', 'JFT/P/S', 'JFT/P/S', 1, 1, NULL, 1, '2026-02-27 12:11:00', 'Démontage de la moto- pompe 611AKP01', NULL),
(2, '611AKP01', 'La pompe 611AKP01', 'equipement', 'JFT/P/S', 'JFT/P/S', 1, 1, NULL, 1, '2026-02-27 12:11:00', 'intervention sur  La  moto-pompe 611AKP01', NULL),
(3, '611AAP02', 'La pompe 611AAP02', 'equipement', 'JFT/P/S', 'JFT/P/S', 1, 1, NULL, 1, '2026-02-27 12:11:00', 'Démontage la  moto-pompe 611AAP02', NULL),
(4, '611AKP02', '611A', 'equipement', 'JFT/P/S', 'JFT/P/S', 1, 1, NULL, 1, '2026-02-27 12:11:00', 'Changement de la manchette conduite recéption soufre', NULL),
(5, '612AAP01', 'la pompe 612AAP01', 'equipement', 'JFT/P/S', 'JFT/P/S', 2, 1, NULL, 1, '2026-02-27 12:11:00', 'Démontage du moteur eléctrique', NULL),
(6, '612AKP01', 'la pompe 612AKP01', 'equipement', 'JFT/P/S', 'JFT/P/S', 2, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur moto-pompe', NULL),
(7, '612AAP02', 'la pompe 612AAP02', 'equipement', 'JFT/P/S', 'JFT/P/S', 2, 1, NULL, 1, '2026-02-27 12:11:00', 'Démontage du moteur eléctrique', NULL),
(8, '612AKP02', 'la pompe 612AKP02', 'equipement', 'JFT/P/S', 'JFT/P/S', 2, 1, NULL, 1, '2026-02-27 12:11:00', 'démontage moteur eléctrique', NULL),
(9, '601AAP01', 'La pompe  601AAP01', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur La  moto-pompe 601AAP01', NULL),
(10, '601AAP02', 'La pompe  601AAP02', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur La  moto-pompe 601AAP02', NULL),
(11, '601AAP03', 'la pompe 601AAP03', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'intervention sur la moto-pompe', NULL),
(12, 'recép soufre', '611A', 'equipement', 'JFT/P/S', 'JFT/P/S', 1, 1, NULL, 1, '2026-02-27 12:11:00', 'Changement de la manchette du circuit recéption du soufre', NULL),
(13, '601ABP04', 'La pompe 601ABP04/AAP04', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur la moto- pompe 601ABP04/AAP04', NULL),
(14, '601AAP06', 'Pompe 601AAP06', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'intervention sur la moto pompe', NULL),
(15, '601AKP06', 'Pompe  601AKP06', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur la moto-pompe', NULL),
(16, '601AAP09', 'Pompe d\'eau alimentaire 601AKP09', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur la moto-pompe', NULL),
(17, '601AKP09', 'Pompe d\'eau alimentaire 601AKP09', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur la moto-pompe', NULL),
(18, '601ABP09', 'Pompe d\'eau alimentaire 601ABP09', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur la moto-pompe', NULL),
(19, '601AAC01', 'motosoufflante 601AAC01', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Changement des tompons 601AAC01', NULL),
(20, '601AAP11', 'Pompe d\'eau alimentaire 601AAP11', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur la moto- pompe', NULL),
(21, '601AKP11', 'Pompe d\'eau alimentaire 601AKP11', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur la moto-pompe', NULL),
(22, '601ABC01', 'motosoufflante 601AAC01', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'intervention sur la moto-soufflante 601AAC01', NULL),
(23, 'interven sur circuit HRS', 'CIRCUIT HRS DN 600', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur circuit  HRS DN600', NULL),
(24, 'purgeur automatique BP', 'Purgeur automatique', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Etanchement de fuite de vapeur', NULL),
(25, '601AKP14 phosphate trisodique', 'Pompe de phosphate trisodique 601AKP14', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Montage ou remontage de la pompe', NULL),
(26, '601AAP14 phosphate trisodique', 'Pompe de phosphate trisodique 601AAP14', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Montage ou remontage de la pompe', NULL),
(27, '601PV666', 'Vanne d\'alimentation de vapeur vers bache alimentaire 601 PV666', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'intervention sur la vanne', NULL),
(28, 'purgeur HP', 'purgeur automatique  devapeur HP', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Etanchement de fuite de vapeur BP', NULL),
(29, 'Filter d\'eau de mer', 'Filtre d\'eau de mer 601AAS06/AKS06', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur le coffret et les moteurs électriques des filtres EDM', NULL),
(30, 'Indicateur de niveau à glass', 'niveau à glace', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Changement', NULL),
(31, 'bac de stockage d\'acide', 'Bac de stockage d\'acide (612ABR01)', 'equipement', 'JFT/P/S', 'JFT/P/S', 2, 1, NULL, 1, '2026-02-27 12:11:00', 'Traveaux de soudure', NULL),
(32, 'Bac pompage commun', 'Bac pompage commun', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'inspection et nettoyage/Travaux de génie de civil ,mécanique et chauderenie', NULL),
(33, 'Tour final', 'Tour de séchage', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'changement des èliminateurs de brumes', NULL),
(34, 'Changement de la vanne 360', 'Vanne d\'eau alimentaire 601AHV187', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention sur cérveau moteur', NULL),
(35, 'Nettoyage de filtre HRS', 'purgeur automatique', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'nettoyage de filtre', NULL),
(36, 'chgt debridededraindefiltreHRS', 'filtre de deuxième étage HRS', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Changement de  la bride de drain', NULL),
(37, '601AC02', 'Motosoufflante 601AC02', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Intervention au niveau de la vanne  à ventelle 601HV 121', NULL),
(38, 'purgeur automatique de vapeur', 'purge automatique de vapeur', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'intervention sur la pompe', NULL),
(39, '601AC01', 'Motosoufflante 601AC01', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'changement des tompons', NULL),
(40, '601AAP17', 'Pompe de phosphate trisodique 601AAP17', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Montage ou remontage de la pompe', NULL),
(41, 'refroidisseur E03-04', 'Refroidisseur E03/04', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Interventionsur  au niveau du refroidisseur d\'acide', NULL),
(42, 'Changement de buse de bruleur à', 'Bruleur à gasoil', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'changement de buse du bruleur à gasoil', NULL),
(43, 'Rechauffeur de soufre', 'Réchauffeur de soufre', 'equipement', 'JFT/P/S', 'JFT/P/S', 4, 1, NULL, 1, '2026-02-27 12:11:00', 'Montage et démontage de réchauffeur', NULL),
(44, '611ALV081', 'Stockage de soufre', 'equipement', 'JFT/P/S', 'JFT/P/S', 1, 1, NULL, 1, '2026-02-27 12:11:00', 'Démontage et remontage des vannes d\'isolement de la vanne 611ALV081', NULL),
(45, 'debitmettre soufre reception', '611A', 'equipement', 'JFT/P/S', 'JFT/P/S', 1, 1, NULL, 1, '2026-02-27 12:11:00', 'Changement 611FI003', NULL),
(46, '601AHV187', 'Vanne HV187', 'equipement', 'JFT/P/S', 'JFT/P/S', 3, 1, NULL, 1, '2026-02-27 12:11:00', 'Demontage', NULL),
(47, '625AKP01', 'POMPES D\'EAU BRUTE', 'equipement', 'MCC', 'KOFERT', 6, 3, NULL, 1, '2026-03-24 09:53:03', 'Démontage de la pompe pour révision et changement de la vanne de refoulement', NULL);

-- --------------------------------------------------------

--
-- Structure de la table `equipe_intervention`
--

CREATE TABLE `equipe_intervention` (
  `id` int NOT NULL,
  `demande_id` int NOT NULL,
  `chef_equipe_id` int NOT NULL,
  `nom` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `matricule` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `badge_ocp_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero_cadenas` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `photo_path` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Photo prise lors de l''ajout du membre',
  `cad_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Identifiant unique QR Code cadenas (contenu scanné)',
  `equipe_validee` tinyint(1) DEFAULT '0',
  `heure_entree` datetime DEFAULT NULL,
  `heure_scan_cadenas` datetime DEFAULT NULL COMMENT 'Horodatage scan cadenas à l''entrée',
  `heure_sortie` datetime DEFAULT NULL,
  `heure_scan_sortie` datetime DEFAULT NULL COMMENT 'Horodatage précis hh:mm:ss de la sortie',
  `scan_cadenas_sortie` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'cad_id vérifié au moment de la sortie',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `statut` enum('en_attente','sur_site','sortie') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en_attente'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `equipe_intervention`
--

INSERT INTO `equipe_intervention` (`id`, `demande_id`, `chef_equipe_id`, `nom`, `matricule`, `badge_ocp_id`, `numero_cadenas`, `photo_path`, `cad_id`, `equipe_validee`, `heure_entree`, `heure_scan_cadenas`, `heure_sortie`, `heure_scan_sortie`, `scan_cadenas_sortie`, `created_at`, `statut`) VALUES
(1, 80, 11, 'BADGE-OCP-001', NULL, 'BADGE-OCP-001', NULL, 'uploads/membres/membre_1773915936673_z4rmzl.jpg', 'CAD-000001', 1, '2026-03-22 13:44:15', '2026-03-22 13:44:15', '2026-03-22 13:44:29', '2026-03-22 13:44:29', 'CAD-000001', '2026-03-19 10:25:36', 'sortie');

-- --------------------------------------------------------

--
-- Structure de la table `executions_consignation`
--

CREATE TABLE `executions_consignation` (
  `id` int NOT NULL,
  `point_id` int NOT NULL,
  `numero_cadenas` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `consigne_par` int NOT NULL,
  `date_consigne` datetime NOT NULL,
  `verifie_par` int DEFAULT NULL,
  `date_verifie` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `mcc_ref` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `charge_type` enum('electricien','process') COLLATE utf8mb4_unicode_ci DEFAULT 'electricien'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `executions_consignation`
--

INSERT INTO `executions_consignation` (`id`, `point_id`, `numero_cadenas`, `consigne_par`, `date_consigne`, `verifie_par`, `date_verifie`, `created_at`, `mcc_ref`, `charge_type`) VALUES
(1, 306, 'CAD-000002', 13, '2026-03-19 10:21:08', NULL, NULL, '2026-03-19 10:21:08', '', 'process'),
(2, 305, 'EL-3101', 15, '2026-03-19 10:22:24', NULL, NULL, '2026-03-19 10:22:24', '', 'electricien'),
(3, 307, 'exp://192.168.1.158:8081', 15, '2026-03-22 09:58:19', NULL, NULL, '2026-03-22 09:58:19', '', 'electricien'),
(4, 308, 'EL-3101', 13, '2026-03-22 10:09:54', NULL, NULL, '2026-03-22 10:09:54', '', 'process'),
(5, 309, 'OCP-CHG-0001', 13, '2026-03-22 10:32:11', NULL, NULL, '2026-03-22 10:32:11', '', 'process'),
(6, 310, 'ME-4201', 13, '2026-03-22 10:32:13', NULL, NULL, '2026-03-22 10:32:13', '', 'process'),
(7, 311, 'CAD-000003', 13, '2026-03-22 10:32:17', NULL, NULL, '2026-03-22 10:32:17', '', 'process'),
(8, 312, 'OCP-CHG-0001', 15, '2026-03-22 10:38:31', NULL, NULL, '2026-03-22 10:38:31', '', 'electricien'),
(9, 313, 'BADGE-OCP-001', 15, '2026-03-22 11:24:23', NULL, NULL, '2026-03-22 11:24:23', '', 'electricien'),
(10, 314, 'BADGE-OCP-002', 15, '2026-03-22 11:24:25', NULL, NULL, '2026-03-22 11:24:25', '', 'electricien'),
(11, 315, 'BADGE-OCP-003', 15, '2026-03-22 11:24:27', NULL, NULL, '2026-03-22 11:24:27', '', 'electricien'),
(12, 316, 'Cad-mec-100', 13, '2026-03-22 11:25:24', NULL, NULL, '2026-03-22 11:25:24', '', 'process'),
(13, 318, 'Cad-elc-100', 13, '2026-03-22 11:47:46', NULL, NULL, '2026-03-22 11:47:46', '', 'process'),
(14, 319, 'CAD-000003', 13, '2026-03-22 11:47:51', NULL, NULL, '2026-03-22 11:47:51', '', 'process'),
(15, 320, 'ME-4201', 13, '2026-03-22 11:47:54', NULL, NULL, '2026-03-22 11:47:54', '', 'process'),
(16, 317, 'Cad-elc-100', 15, '2026-03-22 11:48:32', NULL, NULL, '2026-03-22 11:48:32', '', 'electricien'),
(17, 321, 'CAD-000002', 15, '2026-03-22 12:13:47', NULL, NULL, '2026-03-22 12:13:47', '', 'electricien'),
(18, 322, 'BADGE-OCP-002', 13, '2026-03-22 12:14:22', NULL, NULL, '2026-03-22 12:14:22', '', 'process'),
(19, 326, 'Cad-mec-100', 13, '2026-03-22 12:33:11', NULL, NULL, '2026-03-22 12:33:11', '', 'process'),
(20, 323, 'Cad-mec-100', 15, '2026-03-22 12:34:16', NULL, NULL, '2026-03-22 12:34:16', '', 'electricien'),
(21, 324, 'ME-4201', 15, '2026-03-22 12:34:19', NULL, NULL, '2026-03-22 12:34:19', '', 'electricien'),
(22, 325, 'Cad-elc-100', 15, '2026-03-22 12:34:22', NULL, NULL, '2026-03-22 12:34:22', '', 'electricien'),
(23, 327, 'CAD-000002', 15, '2026-03-22 12:39:10', NULL, NULL, '2026-03-22 12:39:10', '', 'electricien'),
(24, 328, 'Cad-elc-100', 15, '2026-03-22 12:51:23', NULL, NULL, '2026-03-22 12:51:23', '', 'electricien'),
(25, 329, 'CAD-000001', 15, '2026-03-22 12:59:37', NULL, NULL, '2026-03-22 12:59:37', '', 'electricien'),
(26, 330, 'EL-3101', 13, '2026-03-22 13:00:20', NULL, NULL, '2026-03-22 13:00:20', '', 'process'),
(27, 331, 'Cad-mec-100', 13, '2026-03-22 13:00:22', NULL, NULL, '2026-03-22 13:00:22', '', 'process'),
(28, 332, 'CAD-000003', 13, '2026-03-22 13:00:25', NULL, NULL, '2026-03-22 13:00:24', '', 'process'),
(29, 333, 'Cad-mec-100', 15, '2026-03-22 13:15:01', NULL, NULL, '2026-03-22 13:15:01', '', 'electricien'),
(30, 334, 'Cad-mec-100', 15, '2026-03-22 13:21:56', NULL, NULL, '2026-03-22 13:21:56', '', 'electricien'),
(31, 336, 'EL-3101', 15, '2026-03-24 09:47:33', NULL, NULL, '2026-03-24 09:47:32', '', 'electricien');

-- --------------------------------------------------------

--
-- Structure de la table `intervenants`
--

CREATE TABLE `intervenants` (
  `id` int NOT NULL,
  `autorisation_id` int NOT NULL,
  `nom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prenom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `matricule` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `badge_ocp_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `type_metier` enum('mecanicien','gc','electricien','autre') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `chef_equipe_id` int NOT NULL,
  `heure_entree` datetime DEFAULT NULL,
  `heure_sortie` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `lots`
--

CREATE TABLE `lots` (
  `id` int NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zone_id` int DEFAULT NULL,
  `actif` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `lots`
--

INSERT INTO `lots` (`id`, `code`, `description`, `zone_id`, `actif`, `created_at`) VALUES
(1, '611A', 'LOT 611A', 1, 1, '2026-02-27 12:11:00'),
(2, '612A', 'LOT 612A', 1, 1, '2026-02-27 12:11:00'),
(3, '601A', 'LOT 601A', 1, 1, '2026-02-27 12:11:00'),
(4, 'Rechauffeur de soufre', 'LOT Rechauffeur de soufre', 1, 1, '2026-02-27 12:11:00'),
(5, '615A', 'Lot 615A', 4, 1, '2026-03-24 09:05:41'),
(6, '625A', 'L’EAU BRUT', 3, 1, '2026-03-24 09:51:16');

-- --------------------------------------------------------

--
-- Structure de la table `notifications`
--

CREATE TABLE `notifications` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `titre` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` enum('demande','validation','rejet','plan','execution','autorisation','intervention','deconsignation','remise_service') COLLATE utf8mb4_unicode_ci NOT NULL,
  `lu` tinyint(1) DEFAULT '0',
  `lien_ref` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `titre`, `message`, `type`, `lu`, `lien_ref`, `created_at`) VALUES
(1, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 1, 'demande/69', '2026-03-19 10:20:43'),
(3, 21, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/69', '2026-03-19 10:20:44'),
(4, 22, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/69', '2026-03-19 10:20:44'),
(5, 23, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/69', '2026-03-19 10:20:44'),
(6, 24, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/69', '2026-03-19 10:20:44'),
(7, 25, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/69', '2026-03-19 10:20:44'),
(8, 26, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/69', '2026-03-19 10:20:44'),
(9, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ chgt debridededraindefiltreHRS (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/69', '2026-03-19 10:20:44'),
(10, 3, '⚙️ Consignation process effectuée', 'Points process consignés par Abdelajlil SERSIF. En attente de la validation du chargé.', 'execution', 1, 'demande/69', '2026-03-19 10:21:25'),
(11, 15, '🔔 Validation électrique requise', 'Le process a validé ses points en premier sur le départ chgt debridededraindefiltreHRS. C\'est votre tour.', 'intervention', 1, 'demande/69', '2026-03-19 10:21:25'),
(12, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0001 — TAG chgt debridededraindefiltreHRS est entièrement consignée.', 'execution', 1, 'demande/69', '2026-03-19 10:22:43'),
(13, 11, '🔓 Autorisation de travail disponible', 'Le départ chgt debridededraindefiltreHRS (LOT 601A) est consigné. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/69', '2026-03-19 10:22:43'),
(14, 11, '👷 Entrez vos équipes SVP', 'Le départ chgt debridededraindefiltreHRS est consigné. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/69', '2026-03-19 10:22:43'),
(15, 3, '👷 Équipe validée — en attente d\'entrée', 'L\'équipe Génie Civil de Civil Genie (1 membre(s)) est validée — CONS-2026-0001 / TAG chgt debridededraindefiltreHRS.', 'intervention', 1, 'demande/69', '2026-03-19 10:25:41'),
(16, 3, '👷 Membres entrés sur chantier', '1 membre(s) équipe Génie Civil de Civil Genie — chgt debridededraindefiltreHRS.', 'intervention', 1, 'demande/69', '2026-03-19 10:25:45'),
(17, 3, '🔓 Équipe sortie — déconsignation possible', 'Toute l\'équipe de Civil Genie a quitté — CONS-2026-0001 / TAG chgt debridededraindefiltreHRS.', 'deconsignation', 1, 'demande/69', '2026-03-19 10:26:02'),
(18, 3, '🔓 Déconsignation Génie Civil effectuée', 'L\'équipe Génie Civil (1 membre) a terminé sur TAG chgt debridededraindefiltreHRS — CONS-2026-0001. Sortie à 19/03/2026 à 10:26.', 'deconsignation', 1, 'demande/69', '2026-03-19 10:26:08'),
(19, 3, '✅ Toutes les équipes ont terminé — Demandez la déconsignation', 'Toutes les équipes (Génie Civil) ont quitté le chantier pour CONS-2026-0001 / TAG chgt debridededraindefiltreHRS.\nVous pouvez maintenant demander la déconsignation finale.', 'deconsignation', 1, 'demande/69', '2026-03-19 10:26:08'),
(20, 15, '🔓 Demande de déconsignation — Action requise', 'L\'agent Hicham ELAMOUD demande la déconsignation du départ chgt debridededraindefiltreHRS (CONS-2026-0001 — LOT : 601A).\nToutes les équipes ont quitté le chantier. Veuillez déconsigner les points électriques.', 'deconsignation', 1, 'demande/69', '2026-03-19 10:26:32'),
(22, 21, '🔓 Demande de déconsignation process — Action requise', 'L\'agent Hicham ELAMOUD demande la déconsignation du départ chgt debridededraindefiltreHRS (CONS-2026-0001).\nVeuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:26:32'),
(23, 22, '🔓 Demande de déconsignation process — Action requise', 'L\'agent Hicham ELAMOUD demande la déconsignation du départ chgt debridededraindefiltreHRS (CONS-2026-0001).\nVeuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:26:32'),
(24, 23, '🔓 Demande de déconsignation process — Action requise', 'L\'agent Hicham ELAMOUD demande la déconsignation du départ chgt debridededraindefiltreHRS (CONS-2026-0001).\nVeuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:26:32'),
(25, 24, '🔓 Demande de déconsignation process — Action requise', 'L\'agent Hicham ELAMOUD demande la déconsignation du départ chgt debridededraindefiltreHRS (CONS-2026-0001).\nVeuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:26:32'),
(26, 25, '🔓 Demande de déconsignation process — Action requise', 'L\'agent Hicham ELAMOUD demande la déconsignation du départ chgt debridededraindefiltreHRS (CONS-2026-0001).\nVeuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:26:32'),
(27, 26, '🔓 Demande de déconsignation process — Action requise', 'L\'agent Hicham ELAMOUD demande la déconsignation du départ chgt debridededraindefiltreHRS (CONS-2026-0001).\nVeuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:26:32'),
(28, 3, '⚡ Déconsignation électrique validée', 'Déconsignation électrique effectuée par Chef Consignation. En attente du process.', 'deconsignation', 1, 'demande/69', '2026-03-19 10:27:29'),
(30, 21, '🔔 Déconsignation process requise', 'Le chargé a déconsigné ses points sur chgt debridededraindefiltreHRS (CONS-2026-0001). Veuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:27:29'),
(31, 22, '🔔 Déconsignation process requise', 'Le chargé a déconsigné ses points sur chgt debridededraindefiltreHRS (CONS-2026-0001). Veuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:27:29'),
(32, 23, '🔔 Déconsignation process requise', 'Le chargé a déconsigné ses points sur chgt debridededraindefiltreHRS (CONS-2026-0001). Veuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:27:29'),
(33, 24, '🔔 Déconsignation process requise', 'Le chargé a déconsigné ses points sur chgt debridededraindefiltreHRS (CONS-2026-0001). Veuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:27:29'),
(34, 25, '🔔 Déconsignation process requise', 'Le chargé a déconsigné ses points sur chgt debridededraindefiltreHRS (CONS-2026-0001). Veuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:27:29'),
(35, 26, '🔔 Déconsignation process requise', 'Le chargé a déconsigné ses points sur chgt debridededraindefiltreHRS (CONS-2026-0001). Veuillez déconsigner vos vannes process.', 'deconsignation', 0, 'demande/69', '2026-03-19 10:27:29'),
(36, 3, '🔓 Déconsignation complète — PDF disponible', 'Votre demande CONS-2026-0001 — TAG chgt debridededraindefiltreHRS est entièrement déconsignée.', 'deconsignation', 1, 'demande/69', '2026-03-19 10:28:20'),
(37, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : 601AC02 — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 1, 'demande/70', '2026-03-22 09:56:38'),
(39, 21, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AC02 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/70', '2026-03-22 09:56:39'),
(40, 22, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AC02 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/70', '2026-03-22 09:56:39'),
(41, 23, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AC02 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/70', '2026-03-22 09:56:39'),
(42, 24, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AC02 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/70', '2026-03-22 09:56:39'),
(43, 25, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AC02 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/70', '2026-03-22 09:56:39'),
(44, 26, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AC02 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/70', '2026-03-22 09:56:39'),
(45, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 601AC02 (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/70', '2026-03-22 09:56:39'),
(46, 3, '⚡ Consignation électrique effectuée', 'Points électriques consignés par Chef Consignation. En attente de la validation process.', 'execution', 1, 'demande/70', '2026-03-22 10:09:24'),
(48, 21, '🔔 Validation process requise', 'Le chargé a validé les points électriques du départ 601AC02. Veuillez valider vos points process.', 'intervention', 0, 'demande/70', '2026-03-22 10:09:24'),
(49, 22, '🔔 Validation process requise', 'Le chargé a validé les points électriques du départ 601AC02. Veuillez valider vos points process.', 'intervention', 0, 'demande/70', '2026-03-22 10:09:24'),
(50, 23, '🔔 Validation process requise', 'Le chargé a validé les points électriques du départ 601AC02. Veuillez valider vos points process.', 'intervention', 0, 'demande/70', '2026-03-22 10:09:24'),
(51, 24, '🔔 Validation process requise', 'Le chargé a validé les points électriques du départ 601AC02. Veuillez valider vos points process.', 'intervention', 0, 'demande/70', '2026-03-22 10:09:24'),
(52, 25, '🔔 Validation process requise', 'Le chargé a validé les points électriques du départ 601AC02. Veuillez valider vos points process.', 'intervention', 0, 'demande/70', '2026-03-22 10:09:24'),
(53, 26, '🔔 Validation process requise', 'Le chargé a validé les points électriques du départ 601AC02. Veuillez valider vos points process.', 'intervention', 0, 'demande/70', '2026-03-22 10:09:24'),
(54, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0002 — TAG 601AC02 est entièrement consignée.', 'execution', 1, 'demande/70', '2026-03-22 10:10:02'),
(55, 11, '🔓 Autorisation de travail disponible', 'Le départ 601AC02 (LOT 601A) est consigné. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/70', '2026-03-22 10:10:02'),
(56, 11, '👷 Entrez vos équipes SVP', 'Le départ 601AC02 est consigné. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/70', '2026-03-22 10:10:02'),
(57, 13, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Rechauffeur de soufre — LOT : Rechauffeur de soufre\nVeuillez valider et consigner les points process.', 'demande', 1, 'demande/71', '2026-03-22 10:31:25'),
(58, 21, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Rechauffeur de soufre — LOT : Rechauffeur de soufre\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/71', '2026-03-22 10:31:25'),
(59, 22, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Rechauffeur de soufre — LOT : Rechauffeur de soufre\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/71', '2026-03-22 10:31:25'),
(60, 23, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Rechauffeur de soufre — LOT : Rechauffeur de soufre\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/71', '2026-03-22 10:31:25'),
(61, 24, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Rechauffeur de soufre — LOT : Rechauffeur de soufre\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/71', '2026-03-22 10:31:25'),
(62, 25, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Rechauffeur de soufre — LOT : Rechauffeur de soufre\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/71', '2026-03-22 10:31:25'),
(63, 26, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Rechauffeur de soufre — LOT : Rechauffeur de soufre\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/71', '2026-03-22 10:31:25'),
(64, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ Rechauffeur de soufre (LOT : Rechauffeur de soufre) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/71', '2026-03-22 10:31:26'),
(65, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0003 — TAG Rechauffeur de soufre est entièrement consignée.', 'execution', 1, 'demande/71', '2026-03-22 10:32:26'),
(66, 11, '🔓 Autorisation de travail disponible', 'Le départ Rechauffeur de soufre (LOT Rechauffeur de soufre) est consigné. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/71', '2026-03-22 10:32:26'),
(67, 11, '👷 Entrez vos équipes SVP', 'Le départ Rechauffeur de soufre est consigné. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/71', '2026-03-22 10:32:26'),
(68, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : 601ABC01 — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 1, 'demande/72', '2026-03-22 10:37:16'),
(69, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 601ABC01 (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/72', '2026-03-22 10:37:17'),
(70, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0004 — TAG 601ABC01 est entièrement consignée à 11:38. PDF F-HSE-SEC-22-01 disponible.', 'execution', 1, 'demande/72', '2026-03-22 10:38:41'),
(71, 11, '🔓 Autorisation de travail disponible', 'Le départ 601ABC01 (LOT 601A) est consigné depuis 11:38. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/72', '2026-03-22 10:38:41'),
(72, 11, '👷 Entrez vos équipes SVP', 'Le départ 601ABC01 est consigné à 11:38. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/72', '2026-03-22 10:38:41'),
(73, 3, '👷 Équipe validée — en attente d\'entrée', 'L\'équipe Génie Civil de Civil Genie (1 membre(s)) est validée — CONS-2026-0004 / TAG 601ABC01.', 'intervention', 1, 'demande/72', '2026-03-22 10:47:37'),
(74, 3, '👷 Membres entrés sur chantier', '1 membre(s) équipe Génie Civil de Civil Genie — 601ABC01.', 'intervention', 1, 'demande/72', '2026-03-22 10:47:40'),
(75, 3, '🔓 Équipe sortie — déconsignation possible', 'Toute l\'équipe de Civil Genie a quitté — CONS-2026-0004 / TAG 601ABC01.', 'deconsignation', 1, 'demande/72', '2026-03-22 10:47:47'),
(76, 3, '🔓 Déconsignation Génie Civil effectuée', 'L\'équipe Génie Civil (1 membre) a terminé sur TAG 601ABC01 — CONS-2026-0004. Sortie à 22/03/2026 à 11:47.', 'deconsignation', 1, 'demande/72', '2026-03-22 10:47:55'),
(77, 3, '✅ Toutes les équipes ont terminé — Demandez la déconsignation', 'Toutes les équipes (Génie Civil) ont quitté le chantier pour CONS-2026-0004 / TAG 601ABC01.\nVous pouvez maintenant demander la déconsignation finale.', 'deconsignation', 1, 'demande/72', '2026-03-22 10:47:55'),
(78, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 1, 'demande/73', '2026-03-22 11:23:53'),
(79, 13, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 1, 'demande/73', '2026-03-22 11:23:54'),
(80, 21, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/73', '2026-03-22 11:23:54'),
(81, 22, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/73', '2026-03-22 11:23:54'),
(82, 23, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/73', '2026-03-22 11:23:54'),
(83, 24, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/73', '2026-03-22 11:23:54'),
(84, 25, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/73', '2026-03-22 11:23:54'),
(85, 26, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/73', '2026-03-22 11:23:54'),
(86, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ Tour final (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/73', '2026-03-22 11:23:54'),
(87, 3, '⚡ Consignation électrique effectuée', 'Points électriques consignés par Chef Consignation à 12:24. En attente validation process.', 'execution', 1, 'demande/73', '2026-03-22 11:24:55'),
(88, 13, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ Tour final à 12:24. Veuillez valider vos points process.', 'intervention', 1, 'demande/73', '2026-03-22 11:24:55'),
(89, 21, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ Tour final à 12:24. Veuillez valider vos points process.', 'intervention', 0, 'demande/73', '2026-03-22 11:24:55'),
(90, 22, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ Tour final à 12:24. Veuillez valider vos points process.', 'intervention', 0, 'demande/73', '2026-03-22 11:24:55'),
(91, 23, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ Tour final à 12:24. Veuillez valider vos points process.', 'intervention', 0, 'demande/73', '2026-03-22 11:24:55'),
(92, 24, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ Tour final à 12:24. Veuillez valider vos points process.', 'intervention', 0, 'demande/73', '2026-03-22 11:24:55'),
(93, 25, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ Tour final à 12:24. Veuillez valider vos points process.', 'intervention', 0, 'demande/73', '2026-03-22 11:24:55'),
(94, 26, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ Tour final à 12:24. Veuillez valider vos points process.', 'intervention', 0, 'demande/73', '2026-03-22 11:24:55'),
(95, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0005 — TAG Tour final est entièrement consignée à 12:25. PDF F-HSE-SEC-22-01 disponible.', 'execution', 1, 'demande/73', '2026-03-22 11:25:34'),
(96, 11, '🔓 Autorisation de travail disponible', 'Le départ Tour final (LOT 601A) est consigné depuis 12:25. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/73', '2026-03-22 11:25:34'),
(97, 11, '👷 Entrez vos équipes SVP', 'Le départ Tour final est consigné à 12:25. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/73', '2026-03-22 11:25:34'),
(98, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : 601AAP03 — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 1, 'demande/74', '2026-03-22 11:46:53'),
(99, 13, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP03 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 1, 'demande/74', '2026-03-22 11:46:54'),
(100, 21, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP03 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/74', '2026-03-22 11:46:54'),
(101, 22, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP03 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/74', '2026-03-22 11:46:54'),
(102, 23, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP03 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/74', '2026-03-22 11:46:54'),
(103, 24, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP03 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/74', '2026-03-22 11:46:54'),
(104, 25, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP03 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/74', '2026-03-22 11:46:54'),
(105, 26, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP03 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/74', '2026-03-22 11:46:54'),
(106, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 601AAP03 (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/74', '2026-03-22 11:46:59'),
(107, 3, '⚙️ Consignation process effectuée', 'Points process consignés par Abdelajlil SERSIF à 12:48. En attente validation chargé.', 'execution', 1, 'demande/74', '2026-03-22 11:48:04'),
(108, 15, '🔔 Validation électrique requise', 'Le process a validé ses points en premier sur le départ 601AAP03 à 12:48. C\'est votre tour.', 'intervention', 1, 'demande/74', '2026-03-22 11:48:04'),
(109, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0006 — TAG 601AAP03 est entièrement consignée à 12:48. PDF F-HSE-SEC-22-01 disponible.', 'execution', 1, 'demande/74', '2026-03-22 11:48:40'),
(110, 11, '🔓 Autorisation de travail disponible', 'Le départ 601AAP03 (LOT 601A) est consigné depuis 12:48. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/74', '2026-03-22 11:48:40'),
(111, 11, '👷 Entrez vos équipes SVP', 'Le départ 601AAP03 est consigné à 12:48. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/74', '2026-03-22 11:48:40'),
(112, 3, '👷 Équipe validée — en attente d\'entrée', 'L\'équipe Génie Civil de Civil Genie (1 membre(s)) est validée — CONS-2026-0006 / TAG 601AAP03.', 'intervention', 1, 'demande/74', '2026-03-22 11:52:32'),
(113, 3, '👷 Membres entrés sur chantier', '1 membre(s) équipe Génie Civil de Civil Genie — 601AAP03.', 'intervention', 1, 'demande/74', '2026-03-22 11:52:35'),
(114, 3, '🔓 Équipe sortie — déconsignation possible', 'Toute l\'équipe de Civil Genie a quitté — CONS-2026-0006 / TAG 601AAP03.', 'deconsignation', 1, 'demande/74', '2026-03-22 11:52:52'),
(115, 3, '🔓 Déconsignation Génie Civil effectuée', 'L\'équipe Génie Civil (1 membre) a terminé sur TAG 601AAP03 — CONS-2026-0006. Sortie à 22/03/2026 à 11:52.', 'deconsignation', 1, 'demande/74', '2026-03-22 11:53:00'),
(116, 3, '✅ Toutes les équipes ont terminé — Demandez la déconsignation', 'Toutes les équipes (Génie Civil) ont quitté le chantier pour CONS-2026-0006 / TAG 601AAP03.\nVous pouvez maintenant demander la déconsignation finale.', 'deconsignation', 1, 'demande/74', '2026-03-22 11:53:00'),
(117, 3, '👷 Équipe validée — en attente d\'entrée', 'L\'équipe Génie Civil de Civil Genie (1 membre(s)) est validée — CONS-2026-0005 / TAG Tour final.', 'intervention', 1, 'demande/73', '2026-03-22 11:53:45'),
(118, 3, '👷 Membres entrés sur chantier', '1 membre(s) équipe Génie Civil de Civil Genie — Tour final.', 'intervention', 1, 'demande/73', '2026-03-22 11:53:49'),
(119, 3, '🔓 Équipe sortie — déconsignation possible', 'Toute l\'équipe de Civil Genie a quitté — CONS-2026-0005 / TAG Tour final.', 'deconsignation', 1, 'demande/73', '2026-03-22 11:56:19'),
(120, 3, '🔓 Déconsignation Génie Civil effectuée', 'L\'équipe Génie Civil (1 membre) a terminé sur TAG Tour final — CONS-2026-0005. Sortie à 22/03/2026 à 11:56.', 'deconsignation', 1, 'demande/73', '2026-03-22 11:56:30'),
(121, 3, '✅ Toutes les équipes ont terminé — Demandez la déconsignation', 'Toutes les équipes (Génie Civil) ont quitté le chantier pour CONS-2026-0005 / TAG Tour final.\nVous pouvez maintenant demander la déconsignation finale.', 'deconsignation', 1, 'demande/73', '2026-03-22 11:56:30'),
(122, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : 601AAP01 — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 1, 'demande/75', '2026-03-22 12:12:38'),
(123, 13, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP01 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 1, 'demande/75', '2026-03-22 12:12:38'),
(124, 21, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP01 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/75', '2026-03-22 12:12:38'),
(125, 22, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP01 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/75', '2026-03-22 12:12:38'),
(126, 23, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP01 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/75', '2026-03-22 12:12:38'),
(127, 24, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP01 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/75', '2026-03-22 12:12:38'),
(128, 25, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP01 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/75', '2026-03-22 12:12:38'),
(129, 26, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 601AAP01 — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/75', '2026-03-22 12:12:38'),
(130, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 601AAP01 (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/75', '2026-03-22 12:12:38'),
(131, 3, '⚡ Consignation électrique effectuée', 'Points électriques consignés par Chef Consignation à 13:14. En attente validation process.', 'execution', 1, 'demande/75', '2026-03-22 12:14:03'),
(132, 13, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 601AAP01 à 13:14. Veuillez valider vos points process.', 'intervention', 1, 'demande/75', '2026-03-22 12:14:03'),
(133, 21, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 601AAP01 à 13:14. Veuillez valider vos points process.', 'intervention', 0, 'demande/75', '2026-03-22 12:14:03'),
(134, 22, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 601AAP01 à 13:14. Veuillez valider vos points process.', 'intervention', 0, 'demande/75', '2026-03-22 12:14:03'),
(135, 23, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 601AAP01 à 13:14. Veuillez valider vos points process.', 'intervention', 0, 'demande/75', '2026-03-22 12:14:03'),
(136, 24, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 601AAP01 à 13:14. Veuillez valider vos points process.', 'intervention', 0, 'demande/75', '2026-03-22 12:14:03'),
(137, 25, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 601AAP01 à 13:14. Veuillez valider vos points process.', 'intervention', 0, 'demande/75', '2026-03-22 12:14:03'),
(138, 26, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 601AAP01 à 13:14. Veuillez valider vos points process.', 'intervention', 0, 'demande/75', '2026-03-22 12:14:03'),
(139, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0007 — TAG 601AAP01 est entièrement consignée à 13:14. PDF F-HSE-SEC-22-01 disponible.', 'execution', 1, 'demande/75', '2026-03-22 12:14:34'),
(140, 11, '🔓 Autorisation de travail disponible', 'Le départ 601AAP01 (LOT 601A) est consigné depuis 13:14. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/75', '2026-03-22 12:14:34'),
(141, 11, '👷 Entrez vos équipes SVP', 'Le départ 601AAP01 est consigné à 13:14. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/75', '2026-03-22 12:14:34'),
(142, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 1, 'demande/76', '2026-03-22 12:31:19'),
(143, 13, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/76', '2026-03-22 12:31:21'),
(144, 21, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/76', '2026-03-22 12:31:21'),
(145, 22, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/76', '2026-03-22 12:31:21'),
(146, 23, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/76', '2026-03-22 12:31:21'),
(147, 24, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/76', '2026-03-22 12:31:21'),
(148, 25, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/76', '2026-03-22 12:31:21'),
(149, 26, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : Tour final — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/76', '2026-03-22 12:31:21'),
(150, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ Tour final (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/76', '2026-03-22 12:31:21'),
(151, 3, '⚙️ Consignation process effectuée', 'Points process consignés par Abdelajlil SERSIF à 13:33. En attente validation chargé.', 'execution', 1, 'demande/76', '2026-03-22 12:33:22'),
(152, 15, '🔔 Validation électrique requise', 'Le process a validé ses points en premier sur le départ Tour final à 13:33. C\'est votre tour.', 'intervention', 1, 'demande/76', '2026-03-22 12:33:22'),
(153, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0008 — TAG Tour final est entièrement consignée à 13:34. PDF F-HSE-SEC-22-01 disponible.', 'execution', 1, 'demande/76', '2026-03-22 12:34:31'),
(154, 11, '🔓 Autorisation de travail disponible', 'Le départ Tour final (LOT 601A) est consigné depuis 13:34. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/76', '2026-03-22 12:34:31'),
(155, 11, '👷 Entrez vos équipes SVP', 'Le départ Tour final est consigné à 13:34. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/76', '2026-03-22 12:34:31'),
(156, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : Changement de la vanne 360 — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 0, 'demande/77', '2026-03-22 12:38:51'),
(157, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ Changement de la vanne 360 (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/77', '2026-03-22 12:38:52'),
(158, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0009 — TAG Changement de la vanne 360 est entièrement consignée à 13:39. PDF F-HSE-SEC-22-01 disponible.', 'execution', 1, 'demande/77', '2026-03-22 12:39:25'),
(159, 11, '🔓 Autorisation de travail disponible', 'Le départ Changement de la vanne 360 (LOT 601A) est consigné depuis 13:39. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/77', '2026-03-22 12:39:25'),
(160, 11, '👷 Entrez vos équipes SVP', 'Le départ Changement de la vanne 360 est consigné à 13:39. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/77', '2026-03-22 12:39:25'),
(161, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : 601AHV187 — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 0, 'demande/78', '2026-03-22 12:50:58'),
(162, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 601AHV187 (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/78', '2026-03-22 12:50:59'),
(163, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0010 — TAG 601AHV187 est entièrement consignée à 13:51. PDF F-HSE-SEC-22-01 disponible.', 'execution', 1, 'demande/78', '2026-03-22 12:51:30'),
(164, 11, '🔓 Autorisation de travail disponible', 'Le départ 601AHV187 (LOT 601A) est consigné depuis 13:51. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/78', '2026-03-22 12:51:30'),
(165, 11, '👷 Entrez vos équipes SVP', 'Le départ 601AHV187 est consigné à 13:51. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/78', '2026-03-22 12:51:30'),
(166, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : 611AAP01 — LOT : 611A\nVeuillez valider le plan de consignation électrique.', 'demande', 0, 'demande/79', '2026-03-22 12:59:23'),
(167, 13, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 611AAP01 — LOT : 611A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/79', '2026-03-22 12:59:24'),
(168, 21, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 611AAP01 — LOT : 611A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/79', '2026-03-22 12:59:24'),
(169, 22, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 611AAP01 — LOT : 611A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/79', '2026-03-22 12:59:24'),
(170, 23, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 611AAP01 — LOT : 611A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/79', '2026-03-22 12:59:24'),
(171, 24, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 611AAP01 — LOT : 611A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/79', '2026-03-22 12:59:24'),
(172, 25, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 611AAP01 — LOT : 611A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/79', '2026-03-22 12:59:24'),
(173, 26, '🔔 Nouvelle demande de consignation process', 'Hicham ELAMOUD — TAG : 611AAP01 — LOT : 611A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/79', '2026-03-22 12:59:24'),
(174, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 611AAP01 (LOT : 611A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/79', '2026-03-22 12:59:24'),
(175, 3, '⚡ Consignation électrique effectuée', 'Points électriques consignés par Chef Consignation à 13:59. En attente validation process.', 'execution', 1, 'demande/79', '2026-03-22 12:59:49'),
(176, 13, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 611AAP01 à 13:59. Veuillez valider vos points process.', 'intervention', 0, 'demande/79', '2026-03-22 12:59:49'),
(177, 21, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 611AAP01 à 13:59. Veuillez valider vos points process.', 'intervention', 0, 'demande/79', '2026-03-22 12:59:49'),
(178, 22, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 611AAP01 à 13:59. Veuillez valider vos points process.', 'intervention', 0, 'demande/79', '2026-03-22 12:59:49'),
(179, 23, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 611AAP01 à 13:59. Veuillez valider vos points process.', 'intervention', 0, 'demande/79', '2026-03-22 12:59:49'),
(180, 24, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 611AAP01 à 13:59. Veuillez valider vos points process.', 'intervention', 0, 'demande/79', '2026-03-22 12:59:49'),
(181, 25, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 611AAP01 à 13:59. Veuillez valider vos points process.', 'intervention', 0, 'demande/79', '2026-03-22 12:59:49'),
(182, 26, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ 611AAP01 à 13:59. Veuillez valider vos points process.', 'intervention', 0, 'demande/79', '2026-03-22 12:59:49'),
(183, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0011 — TAG 611AAP01 est entièrement consignée à 14:00. PDF F-HSE-SEC-22-01 disponible.', 'execution', 1, 'demande/79', '2026-03-22 13:00:34'),
(184, 11, '🔓 Autorisation de travail disponible', 'Le départ 611AAP01 (LOT 611A) est consigné depuis 14:00. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/79', '2026-03-22 13:00:34'),
(185, 11, '👷 Entrez vos équipes SVP', 'Le départ 611AAP01 est consigné à 14:00. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/79', '2026-03-22 13:00:34'),
(186, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : 601ABC01 — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 0, 'demande/80', '2026-03-22 13:14:13'),
(187, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 601ABC01 (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/80', '2026-03-22 13:14:14'),
(188, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0012 — TAG 601ABC01 est entièrement consignée à 14:15. PDF F-HSE-SEC-22-01 disponible.', 'execution', 1, 'demande/80', '2026-03-22 13:15:10'),
(189, 11, '🔓 Autorisation de travail disponible', 'Le départ 601ABC01 (LOT 601A) est consigné depuis 14:15. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/80', '2026-03-22 13:15:10'),
(190, 11, '👷 Entrez vos équipes SVP', 'Le départ 601ABC01 est consigné à 14:15. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/80', '2026-03-22 13:15:10'),
(191, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : 601ABC01 — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 0, 'demande/81', '2026-03-22 13:21:02'),
(192, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 601ABC01 (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/81', '2026-03-22 13:21:02'),
(193, 3, '✅ Consignation complète', 'Votre demande CONS-2026-0013 — TAG 601ABC01 est entièrement consignée à 14:22. PDF F-HSE-SEC-22-01 disponible.', 'execution', 1, 'demande/81', '2026-03-22 13:22:06'),
(194, 11, '🔓 Autorisation de travail disponible', 'Le départ 601ABC01 (LOT 601A) est consigné depuis 14:22. Vos équipes peuvent intervenir.', 'autorisation', 0, 'demande/81', '2026-03-22 13:22:06'),
(195, 11, '👷 Entrez vos équipes SVP', 'Le départ 601ABC01 est consigné à 14:22. Enregistrez les membres de votre équipe.', 'intervention', 0, 'equipe/81', '2026-03-22 13:22:06'),
(196, 15, '🔔 Nouvelle demande de consignation', 'Hicham ELAMOUD — TAG : 601AHV187 — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 0, 'demande/82', '2026-03-22 13:33:23'),
(197, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 601AHV187 (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/82', '2026-03-22 13:33:24'),
(198, 3, '👷 Équipe validée — en attente d\'entrée', 'L\'équipe Génie Civil de Civil Genie (1 membre(s)) est validée — CONS-2026-0013 / TAG 601ABC01.', 'intervention', 1, 'demande/81', '2026-03-22 13:35:43'),
(199, 3, '👷 Membres entrés sur chantier', '1 membre(s) équipe Génie Civil de Civil Genie — 601ABC01.', 'intervention', 1, 'demande/81', '2026-03-22 13:35:46'),
(200, 3, '🔓 Équipe sortie — déconsignation possible', 'Toute l\'équipe de Civil Genie a quitté — CONS-2026-0013 / TAG 601ABC01.', 'deconsignation', 1, 'demande/81', '2026-03-22 13:37:03'),
(201, 3, '🔓 Déconsignation Génie Civil effectuée', 'L\'équipe Génie Civil (1 membre) a terminé sur TAG 601ABC01 — CONS-2026-0013. Sortie à 22/03/2026 à 14:37.', 'deconsignation', 1, 'demande/81', '2026-03-22 13:37:10'),
(202, 3, '✅ Toutes les équipes ont terminé — Demandez la déconsignation', 'Toutes les équipes (Génie Civil) ont quitté le chantier pour CONS-2026-0013 / TAG 601ABC01.\nVous pouvez maintenant demander la déconsignation finale.', 'deconsignation', 1, 'demande/81', '2026-03-22 13:37:10'),
(203, 15, '🔓 Demande de déconsignation — Action requise', 'L\'agent Hicham ELAMOUD demande la déconsignation du départ 601ABC01 (CONS-2026-0013 — LOT : 601A).\nToutes les équipes ont quitté le chantier. Veuillez déconsigner les points électriques.', 'deconsignation', 0, 'demande/81', '2026-03-22 13:38:47'),
(204, 3, '🔓 Déconsignation complète — PDF disponible', 'Votre demande CONS-2026-0013 — TAG 601ABC01 est entièrement déconsignée à 14:40. Le PDF est disponible.', 'deconsignation', 1, 'demande/81', '2026-03-22 13:40:40'),
(205, 3, '👷 Équipe validée — en attente d\'entrée', 'L\'équipe Génie Civil de Civil Genie (1 membre(s)) est validée — CONS-2026-0012 / TAG 601ABC01.', 'intervention', 1, 'demande/80', '2026-03-22 13:44:12'),
(206, 3, '👷 Membres entrés sur chantier', '1 membre(s) équipe Génie Civil de Civil Genie — 601ABC01.', 'intervention', 1, 'demande/80', '2026-03-22 13:44:15'),
(207, 3, '🔓 Équipe sortie — déconsignation possible', 'Toute l\'équipe de Civil Genie a quitté — CONS-2026-0012 / TAG 601ABC01.', 'deconsignation', 1, 'demande/80', '2026-03-22 13:44:29'),
(208, 3, '🔓 Déconsignation Génie Civil effectuée', 'L\'équipe Génie Civil (1 membre) a terminé sur TAG 601ABC01 — CONS-2026-0012. Sortie à 22/03/2026 à 14:44.', 'deconsignation', 1, 'demande/80', '2026-03-22 13:44:36'),
(209, 3, '✅ Toutes les équipes ont terminé — Demandez la déconsignation', 'Toutes les équipes (Génie Civil) ont quitté le chantier pour CONS-2026-0012 / TAG 601ABC01.\nVous pouvez maintenant demander la déconsignation finale.', 'deconsignation', 1, 'demande/80', '2026-03-22 13:44:36'),
(210, 15, '🔓 Demande de déconsignation — Action requise', 'L\'agent Hicham ELAMOUD demande la déconsignation du départ 601ABC01 (CONS-2026-0012 — LOT : 601A).\nToutes les équipes ont quitté le chantier. Veuillez déconsigner les points électriques.', 'deconsignation', 0, 'demande/80', '2026-03-22 13:45:22'),
(211, 3, '🔓 Déconsignation complète — PDF disponible', 'Votre demande CONS-2026-0012 — TAG 601ABC01 est entièrement déconsignée à 14:46. Le PDF est disponible.', 'deconsignation', 1, 'demande/80', '2026-03-22 13:46:03'),
(212, 15, '🔔 Nouvelle demande de consignation', 'Hicham EL-AMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider le plan de consignation électrique.', 'demande', 0, 'demande/83', '2026-03-24 09:46:27'),
(213, 13, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/83', '2026-03-24 09:46:28'),
(214, 21, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/83', '2026-03-24 09:46:28'),
(215, 22, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/83', '2026-03-24 09:46:28'),
(216, 23, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/83', '2026-03-24 09:46:28'),
(217, 24, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/83', '2026-03-24 09:46:28'),
(218, 25, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/83', '2026-03-24 09:46:28'),
(219, 26, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : chgt debridededraindefiltreHRS — LOT : 601A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/83', '2026-03-24 09:46:28'),
(220, 11, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ chgt debridededraindefiltreHRS (LOT : 601A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/83', '2026-03-24 09:46:28'),
(221, 3, '⚡ Consignation électrique effectuée', 'Points électriques consignés par Chef Consignation à 10:48. En attente validation process.', 'execution', 0, 'demande/83', '2026-03-24 09:48:08'),
(222, 13, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ chgt debridededraindefiltreHRS à 10:48. Veuillez valider vos points process.', 'intervention', 0, 'demande/83', '2026-03-24 09:48:08'),
(223, 21, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ chgt debridededraindefiltreHRS à 10:48. Veuillez valider vos points process.', 'intervention', 0, 'demande/83', '2026-03-24 09:48:08'),
(224, 22, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ chgt debridededraindefiltreHRS à 10:48. Veuillez valider vos points process.', 'intervention', 0, 'demande/83', '2026-03-24 09:48:08'),
(225, 23, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ chgt debridededraindefiltreHRS à 10:48. Veuillez valider vos points process.', 'intervention', 0, 'demande/83', '2026-03-24 09:48:08'),
(226, 24, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ chgt debridededraindefiltreHRS à 10:48. Veuillez valider vos points process.', 'intervention', 0, 'demande/83', '2026-03-24 09:48:08'),
(227, 25, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ chgt debridededraindefiltreHRS à 10:48. Veuillez valider vos points process.', 'intervention', 0, 'demande/83', '2026-03-24 09:48:08'),
(228, 26, '🔔 Validation process requise', 'Chef Consignation a validé les points électriques du départ chgt debridededraindefiltreHRS à 10:48. Veuillez valider vos points process.', 'intervention', 0, 'demande/83', '2026-03-24 09:48:08'),
(229, 15, '🔔 Nouvelle demande de consignation', 'Hicham EL-AMOUD — TAG : 625AKP01 — LOT : 625A\nVeuillez valider le plan de consignation électrique.', 'demande', 0, 'demande/84', '2026-03-24 10:01:14'),
(230, 13, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : 625AKP01 — LOT : 625A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/84', '2026-03-24 10:01:15'),
(231, 21, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : 625AKP01 — LOT : 625A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/84', '2026-03-24 10:01:15'),
(232, 22, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : 625AKP01 — LOT : 625A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/84', '2026-03-24 10:01:15'),
(233, 23, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : 625AKP01 — LOT : 625A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/84', '2026-03-24 10:01:15'),
(234, 24, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : 625AKP01 — LOT : 625A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/84', '2026-03-24 10:01:15'),
(235, 25, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : 625AKP01 — LOT : 625A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/84', '2026-03-24 10:01:15'),
(236, 26, '🔔 Nouvelle demande de consignation process', 'Hicham EL-AMOUD — TAG : 625AKP01 — LOT : 625A\nVeuillez valider et consigner les points process.', 'demande', 0, 'demande/84', '2026-03-24 10:01:15'),
(237, 14, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 625AKP01 (LOT : 625A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/84', '2026-03-24 10:01:15'),
(238, 12, '🔔 Consignation en cours — Préparez vos équipes', 'Le départ 625AKP01 (LOT : 625A) va être consigné. Préparez vos intervenants.', 'intervention', 0, 'demande/84', '2026-03-24 10:01:15');

-- --------------------------------------------------------

--
-- Structure de la table `plans_consignation`
--

CREATE TABLE `plans_consignation` (
  `id` int NOT NULL,
  `demande_id` int NOT NULL,
  `etabli_par` int NOT NULL,
  `approuve_par` int DEFAULT NULL,
  `date_etabli` datetime DEFAULT CURRENT_TIMESTAMP,
  `date_approuve` datetime DEFAULT NULL,
  `remarques` text COLLATE utf8mb4_unicode_ci,
  `schema_ref` text COLLATE utf8mb4_unicode_ci,
  `statut` enum('brouillon','approuve','en_execution','execute','deconsigne') COLLATE utf8mb4_unicode_ci DEFAULT 'brouillon',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `plans_consignation`
--

INSERT INTO `plans_consignation` (`id`, `demande_id`, `etabli_par`, `approuve_par`, `date_etabli`, `date_approuve`, `remarques`, `schema_ref`, `statut`, `created_at`, `updated_at`) VALUES
(69, 69, 3, 3, '2026-03-19 10:20:43', '2026-03-19 10:20:43', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-19 10:20:43', '2026-03-19 10:22:43'),
(70, 70, 3, 3, '2026-03-22 09:56:38', '2026-03-22 09:56:38', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 09:56:38', '2026-03-22 10:10:02'),
(71, 71, 3, 3, '2026-03-22 10:31:24', '2026-03-22 10:31:24', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 10:31:24', '2026-03-22 10:32:26'),
(72, 72, 3, 3, '2026-03-22 10:37:16', '2026-03-22 10:37:16', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 10:37:16', '2026-03-22 10:38:41'),
(73, 73, 3, 3, '2026-03-22 11:23:52', '2026-03-22 11:23:52', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 11:23:52', '2026-03-22 11:25:34'),
(74, 74, 3, 3, '2026-03-22 11:46:51', '2026-03-22 11:46:51', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 11:46:52', '2026-03-22 11:48:40'),
(75, 75, 3, 3, '2026-03-22 12:12:37', '2026-03-22 12:12:37', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 12:12:38', '2026-03-22 12:14:33'),
(76, 76, 3, 3, '2026-03-22 12:31:19', '2026-03-22 12:31:19', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 12:31:19', '2026-03-22 12:34:31'),
(77, 77, 3, 3, '2026-03-22 12:38:50', '2026-03-22 12:38:50', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 12:38:50', '2026-03-22 12:39:25'),
(78, 78, 3, 3, '2026-03-22 12:50:58', '2026-03-22 12:50:58', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 12:50:58', '2026-03-22 12:51:30'),
(79, 79, 3, 3, '2026-03-22 12:59:23', '2026-03-22 12:59:23', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 12:59:23', '2026-03-22 13:00:33'),
(80, 80, 3, 3, '2026-03-22 13:14:13', '2026-03-22 13:14:13', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 13:14:13', '2026-03-22 13:15:10'),
(81, 81, 3, 3, '2026-03-22 13:21:01', '2026-03-22 13:21:01', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'execute', '2026-03-22 13:21:01', '2026-03-22 13:22:06'),
(82, 82, 3, 3, '2026-03-22 13:33:22', '2026-03-22 13:33:22', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'approuve', '2026-03-22 13:33:22', '2026-03-22 13:33:22'),
(83, 83, 3, 3, '2026-03-24 09:46:27', '2026-03-24 09:46:27', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'approuve', '2026-03-24 09:46:26', '2026-03-24 09:46:26'),
(84, 84, 3, 3, '2026-03-24 10:01:15', '2026-03-24 10:01:15', 'Plan créé automatiquement depuis plan prédéfini', NULL, 'approuve', '2026-03-24 10:01:14', '2026-03-24 10:01:14');

-- --------------------------------------------------------

--
-- Structure de la table `plans_predefinis`
--

CREATE TABLE `plans_predefinis` (
  `id` int NOT NULL,
  `equipement_id` int NOT NULL,
  `numero_ligne` int NOT NULL,
  `repere_point` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `localisation` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dispositif_condamnation` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `etat_requis` enum('ouvert','ferme') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ouvert',
  `charge_type` enum('electricien','process') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'electricien',
  `role_id_requis` int NOT NULL DEFAULT '21'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `plans_predefinis`
--

INSERT INTO `plans_predefinis` (`id`, `equipement_id`, `numero_ligne`, `repere_point`, `localisation`, `dispositif_condamnation`, `etat_requis`, `charge_type`, `role_id_requis`) VALUES
(1, 1, 1, '611AKP01', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(2, 1, 2, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(3, 1, 3, 'V2', 'Vanne de décharge', 'dispositif+cadenas', 'ferme', 'process', 19),
(4, 1, 4, 'V3', 'Vanne vapeur de chemisage', 'dispositif+cadenas', 'ferme', 'process', 19),
(5, 2, 1, '611AKP01', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(6, 2, 2, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(7, 2, 3, 'V2', 'Vanne de décharge', 'dispositif+cadenas', 'ferme', 'process', 19),
(8, 2, 4, 'V3', 'Vanne vapeur chemisage', 'dispositif+cadenas', 'ferme', 'process', 19),
(9, 3, 1, '611AAP02', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(10, 3, 2, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(11, 3, 3, 'V2', 'Vanne vapeur chemisage', 'dispositif+cadenas', 'ferme', 'process', 19),
(12, 4, 1, 'V1', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(13, 4, 2, 'V2', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(14, 4, 3, 'V3', 'Vanne vapeur de chemisage', 'dispositif+cadenas', 'ferme', 'process', 19),
(15, 5, 1, '612AAP01', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(16, 5, 2, 'Va', 'Vanne d\'aspiration', 'dispositif+cadenas', 'ferme', 'process', 19),
(17, 5, 3, 'Vr', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(18, 5, 4, 'Vp', 'Vanne de purge', 'cadenas', 'ouvert', 'process', 19),
(19, 6, 1, '612AKP01', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(20, 6, 2, 'Va', 'Vanne d\'aspiration', 'dispositif+cadenas', 'ferme', 'process', 19),
(21, 6, 3, 'Vr', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(22, 6, 4, 'Vp', 'Vanne de purge', 'dispositif+cadenas', 'ouvert', 'process', 19),
(23, 7, 1, '612AAP02', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(24, 7, 2, 'Va', 'Vanne d\'aspiration', 'dispositif+cadenas', 'ferme', 'process', 19),
(25, 7, 3, 'Vr', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(26, 7, 4, 'Vp', 'Vanne de purge', 'cadenas', 'ouvert', 'process', 19),
(27, 8, 1, '612AKP02', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(28, 8, 2, 'VA', 'vanne d\'aspiration', 'cadenas+dispositif', 'ferme', 'process', 19),
(29, 8, 3, 'VR', 'vanne de refoulement', 'cadenas+dispositif', 'ferme', 'process', 19),
(30, 8, 4, 'VP', 'vanne de purge', 'cadenas', 'ouvert', 'process', 19),
(31, 9, 1, '601AAP01', 'MT', 'cadenas', 'ouvert', 'electricien', 21),
(32, 9, 6, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(33, 10, 1, '601AAP02', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(34, 10, 6, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(35, 11, 1, '601AAP03', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(36, 11, 2, 'Va', 'Vanne d\'aspiration', 'dispositif+cadenas', 'ferme', 'process', 19),
(37, 11, 3, 'Vr', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(38, 11, 4, 'Vp', 'Vanne de purge', 'dispositif+cadenas', 'ouvert', 'process', 19),
(39, 12, 1, 'V1', 'Vanne recéption limite baterie', 'cadenas+dispositif', 'ferme', 'process', 19),
(40, 12, 2, 'V2', 'vanne recéption 611AAR01', 'cadenas+dispositif', 'ferme', 'process', 19),
(41, 12, 3, 'V3', 'vanne recéption 611AAB01', 'cadenas+dispositif', 'ferme', 'process', 19),
(42, 12, 4, 'V4', 'Vanne de Vidange', 'cadenas+dispositif', 'ouvert', 'process', 19),
(43, 12, 5, 'V5', 'Vanne vapeur BP', 'cadenas+dispositif', 'ferme', 'process', 19),
(44, 13, 1, '601AP04', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(45, 13, 2, '601BP04', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(46, 14, 1, '601AAP06', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(47, 14, 2, 'Va', 'aspiration pompe', 'Cadenas+dispositif', 'ferme', 'process', 19),
(48, 14, 3, 'VR', 'refoulement pompe', 'Cadenas+dispositif', 'ferme', 'process', 19),
(49, 14, 4, 'Vp1', 'purge pompe', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(50, 14, 5, 'Vp2', 'purge pompe', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(51, 15, 1, '601AKP06', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(52, 15, 2, 'Va', 'aspiration pompe', 'Cadenas+dispositif', 'ferme', 'process', 19),
(53, 15, 3, 'VR', 'refoulement pompe', 'Cadenas+dispositif', 'ferme', 'process', 19),
(54, 15, 4, 'Vp1', 'purge pompe', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(55, 15, 6, 'Vp2', 'purge pompe', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(56, 16, 1, '601AKP09', 'MT', 'cadenas', 'ouvert', 'electricien', 21),
(57, 16, 2, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(58, 16, 3, 'V2', 'vanne aspiration', 'dispositif+cadenas', 'ferme', 'process', 19),
(59, 16, 4, 'V3', 'vanne décharge', 'dispositif+cadenas', 'ferme', 'process', 19),
(60, 16, 5, 'V4', 'vanne de purge', 'dispositif+cadenas', 'ouvert', 'process', 19),
(61, 17, 1, '601AKP09', 'MT', 'cadenas', 'ouvert', 'electricien', 21),
(62, 17, 2, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(63, 17, 3, 'V2', 'vanne aspiration', 'dispositif+cadenas', 'ferme', 'process', 19),
(64, 17, 4, 'V3', 'vanne décharge', 'dispositif+cadenas', 'ferme', 'process', 19),
(65, 17, 5, 'V4', 'vanne de purge', 'dispositif+cadenas', 'ouvert', 'process', 19),
(66, 18, 1, '601ABP09', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(67, 18, 2, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(68, 18, 3, 'V2', 'vanne aspiration', 'dispositif+cadenas', 'ferme', 'process', 19),
(69, 18, 4, 'V3', 'vanne décharge', 'dispositif+cadenas', 'ferme', 'process', 19),
(70, 18, 5, 'V4', 'vanne de purge', 'dispositif+cadenas', 'ouvert', 'process', 19),
(71, 19, 1, '601AAC01', 'MT', 'cadenas', 'ouvert', 'electricien', 21),
(72, 19, 2, 'SIV HV046', 'CHANIER', 'cadenas', 'ferme', 'electricien', 21),
(73, 19, 3, 'DIV HV054', 'CHANIER', 'cadenas', 'ferme', 'electricien', 21),
(74, 19, 4, 'RV FV055', 'CHANIER', 'cadenas', 'ferme', 'electricien', 21),
(75, 20, 1, '601AKP11', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(76, 20, 2, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(77, 20, 3, 'V2', 'vanne aspiration', 'dispositif+cadenas', 'ferme', 'process', 19),
(78, 20, 4, 'V3', 'vanne décharge', 'dispositif+cadenas', 'ferme', 'process', 19),
(79, 20, 5, 'V4', 'vanne de purge', 'dispositif+cadenas', 'ouvert', 'process', 19),
(80, 21, 1, '601AKP11', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(81, 21, 2, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(82, 21, 3, 'V2', 'vanne aspiration', 'dispositif+cadenas', 'ferme', 'process', 19),
(83, 21, 4, 'V3', 'vanne décharge', 'dispositif+cadenas', 'ferme', 'process', 19),
(84, 21, 5, 'V4', 'vanne de purge', 'dispositif+cadenas', 'ouvert', 'process', 19),
(85, 22, 1, '601AAC01', 'MT', 'cadenas', 'ouvert', 'electricien', 21),
(86, 23, 1, '601AAP04', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(87, 23, 2, 'VR', 'refoulement AP04', 'Cadenas+dispositif', 'ferme', 'process', 19),
(88, 23, 3, 'Vvid(A)', 'Vidange circuit A', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(89, 23, 4, '', '', '', 'ferme', 'electricien', 21),
(90, 23, 5, '601ABP04', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(91, 23, 6, 'VR', 'refoulement BP04', 'Cadenas+dispositif', 'ferme', 'process', 19),
(92, 23, 7, 'Vvid(B)', 'Vidange circuit B', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(93, 23, 8, '', '', '', 'ferme', 'electricien', 21),
(94, 24, 1, 'V1', 'Vanne d\'isolement de purgeur', 'Dispositif + Cadenas', 'ferme', 'process', 19),
(95, 25, 1, '601AKP14', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(96, 25, 2, 'Va', 'Aspiration pompe', 'Cadenas+dispositif', 'ferme', 'process', 19),
(97, 25, 3, 'Vr', 'Refoulement pompe', 'Cadenas+dispositif', 'ferme', 'process', 19),
(98, 25, 4, 'Vp1', 'Purge', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(99, 25, 5, 'Vp2', 'Purge', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(100, 26, 1, '601AAP14', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(101, 26, 2, 'Va', 'Aspiration pompe', 'Cadenas+dispositif', 'ferme', 'process', 19),
(102, 26, 3, 'Vr', 'Refoulement pompe', 'Cadenas+dispositif', 'ferme', 'process', 19),
(103, 26, 4, 'Vp1', 'Purge', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(104, 26, 5, 'Vp2', 'Purge', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(105, 27, 1, 'V1', 'Vanne d\'isolement en amont', 'Dispositif +cadenas', 'ferme', 'process', 19),
(106, 27, 2, 'V2', 'Vanne d\'isolement en aval', 'Dispositif +cadenas', 'ferme', 'process', 19),
(107, 27, 3, 'V3', 'Vanne de purge en aval', 'Dispositif +cadenas', 'ouvert', 'process', 19),
(108, 27, 4, 'V4', 'Vanne de purge en amont', 'Dispositif +cadenas', 'ouvert', 'process', 19),
(109, 27, 5, 'V5', 'Vanne de by pass', 'Dispositif +cadenas', 'ouvert', 'process', 19),
(110, 28, 1, 'V1', 'Vanne d\'isolement de purgeur', 'Dispositif +cadenas', 'ferme', 'process', 19),
(111, 29, 1, 'G1', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(112, 29, 2, 'G2', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(113, 30, 5, 'V1', 'Vanne d\'entrée', 'dispositif+cadenas', 'ferme', 'process', 19),
(114, 30, 6, 'V2', 'Vanne de sortie', 'dispositif+cadenas', 'ferme', 'process', 19),
(115, 30, 7, 'V3', 'Vanne de purge', 'dispositif+cadenas', 'ouvert', 'process', 19),
(116, 31, 1, 'JP1', 'conduite réception /renforcage', 'joint plein', 'ferme', 'electricien', 21),
(117, 31, 2, 'JP2', 'sortie sécheur', 'joint plein', 'ferme', 'electricien', 21),
(118, 31, 3, 'JP3', 'Conduite réception', 'joint plein', 'ferme', 'electricien', 21),
(119, 31, 4, 'JP4', 'Conduite soutirage', 'joint plein', 'ferme', 'electricien', 21),
(120, 31, 5, 'V1', 'Vanne de production', 'dispositif+cadenas', 'ferme', 'process', 19),
(121, 31, 6, 'V2', 'Vanne d\'alimentation sécheur', 'dispositif+cadenas', 'ferme', 'process', 19),
(122, 32, 1, '601AP01', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(123, 32, 2, '601AP02', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(124, 32, 3, '601AP03', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(125, 32, 4, '601AP04', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(126, 32, 5, '601BP04', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(127, 32, 6, '601AP06', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(128, 32, 7, '601KP06', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(129, 32, 8, 'V1', 'Vanne de refoulement de la pompe TS', 'Cadenas +dispositif', 'ferme', 'process', 19),
(130, 32, 9, 'V2', 'Vanne de refoulement de la pompe TF', 'Cadenas +dispositif', 'ferme', 'process', 19),
(131, 32, 10, 'V3', 'vanne de vidange', 'Cadenas +dispositif', 'ferme', 'process', 19),
(132, 32, 11, 'V4', 'Vannne de production d\'HRS', 'Cadenas +dispositif', 'ferme', 'process', 19),
(133, 32, 12, 'V5', 'Vanne de réception de stockage', 'Cadenas +dispositif', 'ferme', 'process', 19),
(134, 32, 13, 'V6', 'Vanne de circuit de vidange d HRS vers BPC', 'Cadenas +dispositif', 'ferme', 'process', 19),
(135, 33, 1, '601AAC01', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(136, 33, 2, '601ABC01', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(137, 33, 3, '601AAP01', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(138, 33, 4, 'V1', 'Vanne refoulement pompe', 'cadenas+dispositif', 'ferme', 'process', 19),
(139, 34, 1, '601AHV187', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(140, 35, 1, 'V1', 'Vanne d\'isolement\r\nen ament', 'Dispositif + cadenas', 'ferme', 'process', 19),
(141, 35, 2, 'V2', 'Vanne d\'isolement\r\nen aval', 'Dispositif + cadenas', 'ferme', 'process', 19),
(142, 35, 3, 'V3', 'Vanne de purge', 'Dispositif + cadenas', 'ferme', 'process', 19),
(143, 36, 1, '601AAP01', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(144, 36, 2, 'V1', 'Vanne d\'isolement', 'Dispositif +cadenas', 'ferme', 'process', 19),
(145, 37, 1, '601AC02', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(146, 37, 2, 'Vp', 'Vannne de purge', 'Dispositif+cadenas', 'ouvert', 'process', 19),
(147, 38, 1, 'Va', 'Vanne d\'alimentation', 'Cadenas', 'ferme', 'process', 19),
(148, 38, 2, 'V1', 'Vanne d\'isolement en ament', 'Cadenas', 'ferme', 'process', 19),
(149, 38, 3, 'V2', 'Vanne d\'isolement en aval', 'Cadenas', 'ferme', 'process', 19),
(150, 39, 1, '601AC01', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(151, 39, 2, 'Vp', 'Vannne de purge', 'Dispositif+cadenas', 'ouvert', 'process', 19),
(152, 40, 1, '601AAP17', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(153, 40, 2, 'Va', 'Aspiration pompe', 'Cadenas+dispositif', 'ferme', 'process', 19),
(154, 40, 3, 'Vr', 'Refoulement pompe', 'Cadenas+dispositif', 'ferme', 'process', 19),
(155, 40, 4, 'Vp1', 'Purge', 'Cadenas+dispositif', 'ouvert', 'process', 19),
(156, 41, 1, '601AAP04', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(157, 41, 2, '601ABP04', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(158, 41, 3, 'V1', 'Vanne de drainnage entré acide', 'cadenas + dispositif', 'ouvert', 'process', 19),
(159, 41, 4, 'V2', 'Vanne de drainnage sortie acide', 'cadenas + dispositif', 'ouvert', 'process', 19),
(160, 41, 5, 'V3', 'Vanne de prise d\'air', 'cadenas + dispositif', 'ouvert', 'process', 19),
(161, 41, 6, '625BAP014', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(162, 41, 7, '625BKP014', 'MCC', 'Cadenas', 'ouvert', 'electricien', 21),
(163, 41, 8, 'V4', 'Vanne de drainnage d\'eau', 'cadenas + dispositif', 'ouvert', 'electricien', 21),
(164, 41, 9, 'V5', 'vanne isolement manomètre (prise d\'air)', 'cadenas + dispositif', 'ouvert', 'process', 19),
(165, 42, 1, '601BC01', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(166, 42, 3, '601AC01', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(167, 42, 6, '601AP20', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(168, 42, 7, 'V1', 'vanne isolement air', 'cadenas +dispositif', 'ferme', 'process', 19),
(169, 43, 1, 'V1', 'Vanne disolement de circuit d\'alimentation', 'cadenas + dispositif', 'ferme', 'process', 19),
(170, 43, 2, 'V2', 'Vanne d\'isolement retour condensat', 'cadenas + dispositif', 'ferme', 'process', 19),
(171, 43, 3, 'V3', 'Vanne de bypass du purgeur', 'cadenas + dispositif', 'ferme', 'process', 19),
(172, 44, 1, 'V1', 'Vanne de soutirage bac 611AAR01', 'cadenas + dispositif', 'ferme', 'process', 19),
(173, 44, 3, 'V2', 'Vanne tracage  conduite soutirage de bac 611AAR01 vers fosse filtration', 'cadenas + dispositif', 'ferme', 'process', 19),
(174, 44, 2, 'V3', 'Vanne de soutirage bac 611ABR01', 'cadenas + dispositif', 'ferme', 'process', 19),
(175, 44, 4, 'V4', 'Vanne tracage  conduite soutirage de bac 611ABR01 vers fosse filtration', 'cadenas + dispositif', 'ferme', 'process', 19),
(176, 45, 1, 'V1', 'Vanne recéption limite baterie', 'cadenas+dispositif', 'ferme', 'process', 19),
(177, 45, 2, 'V2', 'Vanne de Vidange', 'cadenas+dispositif', 'ouvert', 'process', 19),
(178, 45, 3, 'V3', 'Vanne vapeur BP', 'cadenas+dispositif', 'ferme', 'process', 19),
(179, 46, 1, '601AHV187', 'MCC', 'cadenas', 'ouvert', 'electricien', 21),
(180, 47, 1, 'moteur électrique', 'Mcc', 'cadenas', 'ouvert', 'electricien', 21),
(181, 47, 2, 'V-302-300', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', 'process', 19),
(182, 47, 3, 'V703-50', 'Vanne de purge', 'Cadenas+dispositif', 'ouvert', 'process', 19);

-- --------------------------------------------------------

--
-- Structure de la table `points_consignation`
--

CREATE TABLE `points_consignation` (
  `id` int NOT NULL,
  `plan_id` int NOT NULL,
  `numero_ligne` int NOT NULL,
  `repere_point` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `localisation` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dispositif_condamnation` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `etat_requis` enum('ouvert','ferme') COLLATE utf8mb4_unicode_ci NOT NULL,
  `electricien_id` int DEFAULT NULL,
  `statut` enum('en_attente','consigne','verifie','deconsigne') COLLATE utf8mb4_unicode_ci DEFAULT 'en_attente',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `charge_type` enum('electricien','process') COLLATE utf8mb4_unicode_ci DEFAULT 'electricien',
  `role_id_requis` int DEFAULT '21'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `points_consignation`
--

INSERT INTO `points_consignation` (`id`, `plan_id`, `numero_ligne`, `repere_point`, `localisation`, `dispositif_condamnation`, `etat_requis`, `electricien_id`, `statut`, `created_at`, `charge_type`, `role_id_requis`) VALUES
(305, 69, 1, '601AAP01', 'MCC', 'Cadenas', 'ouvert', NULL, 'deconsigne', '2026-03-19 10:20:43', 'electricien', 21),
(306, 69, 2, 'V1', 'Vanne d\'isolement', 'Dispositif +cadenas', 'ferme', NULL, 'deconsigne', '2026-03-19 10:20:43', 'process', 19),
(307, 70, 1, '601AC02', 'MCC', 'Cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 09:56:38', 'electricien', 21),
(308, 70, 2, 'Vp', 'Vannne de purge', 'Dispositif+cadenas', 'ouvert', NULL, 'consigne', '2026-03-22 09:56:38', 'process', 19),
(309, 71, 1, 'V1', 'Vanne disolement de circuit d\'alimentation', 'cadenas + dispositif', 'ferme', NULL, 'consigne', '2026-03-22 10:31:25', 'process', 19),
(310, 71, 2, 'V2', 'Vanne d\'isolement retour condensat', 'cadenas + dispositif', 'ferme', NULL, 'consigne', '2026-03-22 10:31:25', 'process', 19),
(311, 71, 3, 'V3', 'Vanne de bypass du purgeur', 'cadenas + dispositif', 'ferme', NULL, 'consigne', '2026-03-22 10:31:25', 'process', 19),
(312, 72, 1, '601AAC01', 'MT', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 10:37:16', 'electricien', 21),
(313, 73, 1, '601AAC01', 'MCC', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 11:23:53', 'electricien', 21),
(314, 73, 2, '601ABC01', 'MCC', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 11:23:53', 'electricien', 21),
(315, 73, 3, '601AAP01', 'MCC', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 11:23:53', 'electricien', 21),
(316, 73, 4, 'V1', 'Vanne refoulement pompe', 'cadenas+dispositif', 'ferme', NULL, 'consigne', '2026-03-22 11:23:53', 'process', 19),
(317, 74, 1, '601AAP03', 'MCC', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 11:46:52', 'electricien', 21),
(318, 74, 2, 'Va', 'Vanne d\'aspiration', 'dispositif+cadenas', 'ferme', NULL, 'consigne', '2026-03-22 11:46:52', 'process', 19),
(319, 74, 3, 'Vr', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', NULL, 'consigne', '2026-03-22 11:46:52', 'process', 19),
(320, 74, 4, 'Vp', 'Vanne de purge', 'dispositif+cadenas', 'ouvert', NULL, 'consigne', '2026-03-22 11:46:52', 'process', 19),
(321, 75, 1, '601AAP01', 'MT', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 12:12:38', 'electricien', 21),
(322, 75, 6, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', NULL, 'consigne', '2026-03-22 12:12:38', 'process', 19),
(323, 76, 1, '601AAC01', 'MCC', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 12:31:19', 'electricien', 21),
(324, 76, 2, '601ABC01', 'MCC', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 12:31:19', 'electricien', 21),
(325, 76, 3, '601AAP01', 'MCC', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 12:31:19', 'electricien', 21),
(326, 76, 4, 'V1', 'Vanne refoulement pompe', 'cadenas+dispositif', 'ferme', NULL, 'consigne', '2026-03-22 12:31:19', 'process', 19),
(327, 77, 1, '601AHV187', 'MCC', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 12:38:50', 'electricien', 21),
(328, 78, 1, '601AHV187', 'MCC', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 12:50:58', 'electricien', 21),
(329, 79, 1, '611AKP01', 'MCC', 'cadenas', 'ouvert', NULL, 'verifie', '2026-03-22 12:59:23', 'electricien', 21),
(330, 79, 2, 'V1', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', NULL, 'consigne', '2026-03-22 12:59:23', 'process', 19),
(331, 79, 3, 'V2', 'Vanne de décharge', 'dispositif+cadenas', 'ferme', NULL, 'consigne', '2026-03-22 12:59:23', 'process', 19),
(332, 79, 4, 'V3', 'Vanne vapeur de chemisage', 'dispositif+cadenas', 'ferme', NULL, 'consigne', '2026-03-22 12:59:23', 'process', 19),
(333, 80, 1, '601AAC01', 'MT', 'cadenas', 'ouvert', NULL, 'deconsigne', '2026-03-22 13:14:13', 'electricien', 21),
(334, 81, 1, '601AAC01', 'MT', 'cadenas', 'ouvert', NULL, 'deconsigne', '2026-03-22 13:21:01', 'electricien', 21),
(335, 82, 1, '601AHV187', 'MCC', 'cadenas', 'ouvert', NULL, 'en_attente', '2026-03-22 13:33:22', 'electricien', 21),
(336, 83, 1, '601AAP01', 'MCC', 'Cadenas', 'ouvert', NULL, 'verifie', '2026-03-24 09:46:26', 'electricien', 21),
(337, 83, 2, 'V1', 'Vanne d\'isolement', 'Dispositif +cadenas', 'ferme', NULL, 'en_attente', '2026-03-24 09:46:26', 'process', 19),
(338, 84, 1, 'moteur électrique', 'Mcc', 'cadenas', 'ouvert', NULL, 'en_attente', '2026-03-24 10:01:14', 'electricien', 21),
(339, 84, 2, 'V-302-300', 'Vanne de refoulement', 'dispositif+cadenas', 'ferme', NULL, 'en_attente', '2026-03-24 10:01:14', 'process', 19),
(340, 84, 3, 'V703-50', 'Vanne de purge', 'Cadenas+dispositif', 'ouvert', NULL, 'en_attente', '2026-03-24 10:01:14', 'process', 19);

-- --------------------------------------------------------

--
-- Structure de la table `push_tokens`
--

CREATE TABLE `push_tokens` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `token` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `push_tokens`
--

INSERT INTO `push_tokens` (`id`, `user_id`, `token`, `created_at`, `updated_at`) VALUES
(1, 15, 'ExponentPushToken[B96TnIJu7CW3DXYB5vQLqF]', '2026-02-27 15:25:06', '2026-03-12 21:50:22');

-- --------------------------------------------------------

--
-- Structure de la table `rapport_consignation`
--

CREATE TABLE `rapport_consignation` (
  `id` int NOT NULL,
  `demande_id` int NOT NULL,
  `chef_equipe_id` int NOT NULL,
  `pdf_path` varchar(400) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Chemin relatif vers le PDF généré (/uploads/rapports_equipe/...)',
  `statut_final` enum('intervention_terminee','deconsignee') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'intervention_terminee',
  `nb_membres_total` int NOT NULL DEFAULT '0',
  `nb_membres_sortis` int NOT NULL DEFAULT '0',
  `duree_totale_min` int DEFAULT NULL,
  `heure_debut` datetime DEFAULT NULL,
  `heure_fin` datetime DEFAULT NULL,
  `actions_json` longtext COLLATE utf8mb4_unicode_ci COMMENT 'JSON chronologie : [{type,membre,horodatage,badge?,cadenas?}]',
  `stats_json` longtext COLLATE utf8mb4_unicode_ci COMMENT 'JSON stats : {total_membres,membres_sortis,duree_moy_min,...}',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `rapport_consignation`
--

INSERT INTO `rapport_consignation` (`id`, `demande_id`, `chef_equipe_id`, `pdf_path`, `statut_final`, `nb_membres_total`, `nb_membres_sortis`, `duree_totale_min`, `heure_debut`, `heure_fin`, `actions_json`, `stats_json`, `created_at`) VALUES
(21, 69, 11, 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0001_genie_civil_11_1773915965705.pdf', 'deconsignee', 1, 1, 60, '2026-03-19 09:25:45', '2026-03-19 10:26:03', '[{\"type\":\"entree\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas\":null,\"cad_id\":\"CAD-000001\",\"horodatage\":\"2026-03-19 09:25:45\"},{\"type\":\"sortie\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas_sortie\":\"CAD-000001\",\"horodatage\":\"2026-03-19 10:26:03\",\"duree_min\":60}]', '{\"total_membres\":1,\"membres_sortis\":1,\"duree_totale_min\":60,\"duree_moyenne_min\":60,\"heure_debut\":\"2026-03-19 09:25:45\",\"heure_fin\":\"2026-03-19 10:26:03\",\"chef\":\"Civil Genie\",\"metier\":\"Génie Civil\",\"par_membre\":[{\"nom\":\"BADGE-OCP-001\",\"duree\":60}]}', '2026-03-19 10:26:08'),
(22, 72, 11, 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0004_genie_civil_11_1774176470586.pdf', 'deconsignee', 1, 1, 60, '2026-03-22 10:47:40', '2026-03-22 11:47:48', '[{\"type\":\"entree\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas\":null,\"cad_id\":\"CAD-000001\",\"horodatage\":\"2026-03-22 10:47:40\"},{\"type\":\"sortie\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas_sortie\":\"CAD-000001\",\"horodatage\":\"2026-03-22 11:47:48\",\"duree_min\":60}]', '{\"total_membres\":1,\"membres_sortis\":1,\"duree_totale_min\":60,\"duree_moyenne_min\":60,\"heure_debut\":\"2026-03-22 10:47:40\",\"heure_fin\":\"2026-03-22 11:47:48\",\"chef\":\"Civil Genie\",\"metier\":\"Génie Civil\",\"par_membre\":[{\"nom\":\"BADGE-OCP-001\",\"duree\":60}]}', '2026-03-22 10:47:55'),
(23, 74, 11, 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0006_genie_civil_11_1774180376780.pdf', 'deconsignee', 1, 1, 0, '2026-03-22 11:52:35', '2026-03-22 11:52:52', '[{\"type\":\"entree\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas\":null,\"cad_id\":\"CAD-000001\",\"horodatage\":\"2026-03-22 11:52:35\"},{\"type\":\"sortie\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas_sortie\":\"CAD-000001\",\"horodatage\":\"2026-03-22 11:52:52\",\"duree_min\":0}]', '{\"total_membres\":1,\"membres_sortis\":1,\"duree_totale_min\":0,\"duree_moyenne_min\":0,\"heure_debut\":\"2026-03-22 11:52:35\",\"heure_fin\":\"2026-03-22 11:52:52\",\"chef\":\"Civil Genie\",\"metier\":\"Génie Civil\",\"par_membre\":[{\"nom\":\"BADGE-OCP-001\",\"duree\":0}]}', '2026-03-22 11:53:00'),
(24, 73, 11, 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0005_genie_civil_11_1774180588008.pdf', 'deconsignee', 1, 1, 3, '2026-03-22 11:53:49', '2026-03-22 11:56:19', '[{\"type\":\"entree\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas\":null,\"cad_id\":\"CAD-000001\",\"horodatage\":\"2026-03-22 11:53:49\"},{\"type\":\"sortie\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas_sortie\":\"CAD-000001\",\"horodatage\":\"2026-03-22 11:56:19\",\"duree_min\":3}]', '{\"total_membres\":1,\"membres_sortis\":1,\"duree_totale_min\":3,\"duree_moyenne_min\":3,\"heure_debut\":\"2026-03-22 11:53:49\",\"heure_fin\":\"2026-03-22 11:56:19\",\"chef\":\"Civil Genie\",\"metier\":\"Génie Civil\",\"par_membre\":[{\"nom\":\"BADGE-OCP-001\",\"duree\":3}]}', '2026-03-22 11:56:30'),
(25, 81, 11, 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0013_genie_civil_11_1774186626501.pdf', 'deconsignee', 1, 1, 1, '2026-03-22 14:35:46', '2026-03-22 14:37:03', '[{\"type\":\"entree\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas\":null,\"cad_id\":\"CAD-000001\",\"horodatage\":\"2026-03-22 14:35:46\"},{\"type\":\"sortie\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas_sortie\":\"CAD-000001\",\"horodatage\":\"2026-03-22 14:37:03\",\"duree_min\":1}]', '{\"total_membres\":1,\"membres_sortis\":1,\"duree_totale_min\":1,\"duree_moyenne_min\":1,\"heure_debut\":\"2026-03-22 14:35:46\",\"heure_fin\":\"2026-03-22 14:37:03\",\"chef\":\"Civil Genie\",\"metier\":\"Génie Civil\",\"par_membre\":[{\"nom\":\"BADGE-OCP-001\",\"duree\":1}]}', '2026-03-22 13:37:10'),
(26, 80, 11, 'uploads/rapports_equipe/rapport_equipe_CONS-2026-0012_genie_civil_11_1774187073571.pdf', 'deconsignee', 1, 1, 0, '2026-03-22 14:44:15', '2026-03-22 14:44:29', '[{\"type\":\"entree\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas\":null,\"cad_id\":\"CAD-000001\",\"horodatage\":\"2026-03-22 14:44:15\"},{\"type\":\"sortie\",\"membre\":\"BADGE-OCP-001\",\"badge\":\"BADGE-OCP-001\",\"cadenas_sortie\":\"CAD-000001\",\"horodatage\":\"2026-03-22 14:44:29\",\"duree_min\":0}]', '{\"total_membres\":1,\"membres_sortis\":1,\"duree_totale_min\":0,\"duree_moyenne_min\":0,\"heure_debut\":\"2026-03-22 14:44:15\",\"heure_fin\":\"2026-03-22 14:44:29\",\"chef\":\"Civil Genie\",\"metier\":\"Génie Civil\",\"par_membre\":[{\"nom\":\"BADGE-OCP-001\",\"duree\":0}]}', '2026-03-22 13:44:36');

-- --------------------------------------------------------

--
-- Structure de la table `remises_en_service`
--

CREATE TABLE `remises_en_service` (
  `id` int NOT NULL,
  `demande_id` int NOT NULL,
  `confirme_par` int NOT NULL,
  `date_remise` datetime DEFAULT CURRENT_TIMESTAMP,
  `observations` text COLLATE utf8mb4_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `reset_password_demandes`
--

CREATE TABLE `reset_password_demandes` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `email_demande` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Email saisi au moment de la demande (audit)',
  `statut` enum('en_attente','approuvee','rejetee') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'en_attente',
  `motif_rejet` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `traite_par` int DEFAULT NULL,
  `traite_le` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `reset_password_demandes`
--

INSERT INTO `reset_password_demandes` (`id`, `user_id`, `email_demande`, `statut`, `motif_rejet`, `traite_par`, `traite_le`, `created_at`, `updated_at`) VALUES
(1, 13, 'abdosarsif28@gmail.com', 'approuvee', NULL, 2, '2026-03-23 17:25:16', '2026-03-23 17:24:41', '2026-03-23 17:25:16'),
(2, 13, 'abdosarsif28@gmail.com', 'approuvee', NULL, 2, '2026-03-23 17:41:17', '2026-03-23 17:40:49', '2026-03-23 17:41:17'),
(3, 31, 'hisheem4@gmail.com', 'approuvee', NULL, 2, '2026-03-24 10:31:38', '2026-03-24 10:30:47', '2026-03-24 10:31:38');

-- --------------------------------------------------------

--
-- Structure de la table `roles`
--

CREATE TABLE `roles` (
  `id` int NOT NULL,
  `nom` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `roles`
--

INSERT INTO `roles` (`id`, `nom`, `description`, `created_at`) VALUES
(1, 'agent_production', 'Opérateur terrain — soumet les demandes de consignation', '2026-02-21 13:38:37'),
(2, 'chef_prod', 'Chef équipe production — valide les demandes et remise en service', '2026-02-21 13:38:37'),
(3, 'hse', 'Responsable HSE — crée et approuve les plans de consignation', '2026-02-21 13:38:37'),
(4, 'electricien', 'Électricien — exécute la consignation et déconsignation terrain', '2026-02-21 13:38:37'),
(5, 'chef_electricien', 'Chef électricien — vérifie la consignation et déconsignation', '2026-02-21 13:38:37'),
(7, 'admin', 'Administrateur — gestion complète du système', '2026-02-21 13:38:37'),
(16, 'chef_genie_civil', 'Chef Équipe Génie Civil — gère les intervenants travaux civils', '2026-02-23 22:05:48'),
(17, 'chef_mecanique', 'Chef Équipe Mécanique — gère les intervenants mécaniques', '2026-02-23 22:05:48'),
(18, 'chef_electrique', 'Chef Équipe Électrique — gère les intervenants électriques', '2026-02-23 22:05:48'),
(19, 'chef_process', 'Chef Équipe Process — gère les intervenants process', '2026-02-23 22:05:48'),
(21, 'charge_consignation', 'Chargé de consignation — exécute la consignation terrain NFC', '2026-02-24 20:55:58');

-- --------------------------------------------------------

--
-- Structure de la table `signatures_autorisation`
--

CREATE TABLE `signatures_autorisation` (
  `id` int NOT NULL,
  `autorisation_id` int NOT NULL,
  `user_id` int NOT NULL,
  `role_signataire` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_signature` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `nom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prenom` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mot_de_passe` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `matricule` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telephone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `badge_ocp_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero_cadenas` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `photo` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `role_id` int NOT NULL,
  `entite` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zone` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zone_id` int DEFAULT NULL,
  `type_metier` enum('genie_civil','mecanique','electrique','process') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `actif` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `otp_code` varchar(6) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `otp_expire` datetime DEFAULT NULL,
  `otp_telephone` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mot_passe_temp` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`id`, `nom`, `prenom`, `username`, `mot_de_passe`, `matricule`, `telephone`, `badge_ocp_id`, `numero_cadenas`, `photo`, `role_id`, `entite`, `zone`, `zone_id`, `type_metier`, `actif`, `created_at`, `updated_at`, `otp_code`, `otp_expire`, `otp_telephone`, `email`, `mot_passe_temp`) VALUES
(2, 'Admin', 'Système', 'ADMIN', '$2b$10$AKeHrk7CcMO8vCpKL/yjFukePpc9NgUXbRozofZnnhinAxyCgRMeq', 'ADM-001', NULL, NULL, NULL, NULL, 7, 'KOFERT', NULL, NULL, NULL, 1, '2026-02-21 15:28:21', '2026-03-02 00:58:13', NULL, NULL, NULL, NULL, 0),
(3, 'EL-AMOUD', 'Hicham', 'ELAMOUD', '$2b$10$NewjAvQ9nfWPxLkKaFpkreeCdT1BaMWK55k9.18v7C/P2BcL.nsqe', '41241', '+212678737365', NULL, '12345Cad', 'uploads/photos_membres/user_1774343629908_r8ri8y.jpg', 1, 'SAP/OSBL', NULL, 1, 'electrique', 1, '2026-02-21 15:47:15', '2026-03-24 11:05:30', '528476', '2026-03-16 04:27:16', '+212776867058', NULL, 0),
(4, 'Benali', 'Hassan', 'HBENALI', '$2b$10$cFW/r4CiNREYVMlFBoqXleLjRQ10V/UD4dOhGSiFIdQIxtJaqrZ/O', 'CP-001', NULL, NULL, NULL, NULL, 2, 'Usine A', NULL, 1, NULL, 1, '2026-02-21 15:48:24', '2026-03-24 10:28:03', NULL, NULL, NULL, NULL, 0),
(5, 'GUERRAOUI', 'Youssef', 'GUERRAOUI', '$2b$10$/wh2FXrph3i1asKNWb5sk.n5g73CqL3R2hBV0JDDwDAHyTgJiFdHW', 'HSE-001', NULL, NULL, NULL, NULL, 3, 'KOFERT', NULL, 1, NULL, 1, '2026-02-21 15:49:17', '2026-03-16 11:53:53', NULL, NULL, NULL, NULL, 0),
(11, 'Genie', 'Civil', 'GC001', '$2b$10$r2GA3LgLPiz5GGAx4CXpAuqFun2bGP1HyRe5qHeR9jHNVI1ksxxEK', 'CGC-001', '+2120776867058', 'OCP-GC-7841', NULL, NULL, 16, 'KOFERT', 'Zone A - Génie Civil', 1, 'genie_civil', 1, '2026-02-24 10:09:03', '2026-03-16 11:53:53', '258604', '2026-03-02 02:20:35', '+2120776867058', NULL, 0),
(12, 'Mecanique', 'Tech', 'MC001', '$2b$10$7e2Fr5w.nLzxUZmAKb2QSu4/Dd8VQ7togLM.Jt9R5UE5HnqVc6nUi', 'CMC-001', '+212661234502', 'OCP-MC-5523', NULL, NULL, 17, 'KOFERT', 'Zone B - Mecanique', 1, 'mecanique', 1, '2026-02-24 10:10:07', '2026-03-16 11:53:53', NULL, NULL, NULL, NULL, 0),
(13, 'SERSIF', 'Abdelajlil', 'SERSIF', '$2b$10$Vt/5itG195u3EqXM0oovgOntbMDEG7lBGyDfE8rWHfhbivU2dePvm', 'CPR-001', '+21266123450', 'OCP-PR-9901', NULL, 'uploads/photos_membres/user_1774282769758_bu8uo8.jpg', 19, 'KOFERT', 'Zone D - Process', 1, 'process', 1, '2026-02-24 10:10:49', '2026-03-24 11:03:53', NULL, NULL, NULL, 'abdosarsif28@gmail.com', 0),
(14, 'el bakezzi', 'yassine', 'ybakezzi', '$2b$10$J4pyfnV.70YQQw8LAxrVv.p7aPHqJebEYJ9ANtuJbVJb5SHKiv72W', 'CEL-0020', '+212669180055', 'CAD-000001', NULL, NULL, 18, 'KOFERT', 'Zone C - Electrique', 1, 'electrique', 1, '2026-02-24 10:57:49', '2026-03-24 10:09:04', NULL, NULL, NULL, 'yassine.elbakezzi@jesagroup.com', 0),
(15, 'Consignation', 'Chef', 'CHG001', '$2b$10$ywtM0C0jRCDk/ApCRrguauBaiWBQaeRKu9e9z4pUO.7Yxxvja2IAS', 'CHG-001', '+212661234510', 'OCP-CHG-0001', NULL, NULL, 21, 'KOFERT', 'Zone Consignation', NULL, NULL, 1, '2026-02-24 20:59:36', '2026-03-09 11:22:31', NULL, NULL, NULL, NULL, 0),
(16, 'TALAI', 'Amin', 'TALAI', '$2b$10$TLNzRHid9gLddAXNkNCIHuQ.FaJA0oOkPFtNTg9auTszM/lfhz41K', 'AP-SAP-001', NULL, NULL, NULL, NULL, 1, 'SAP', 'SAP', 1, NULL, 1, '2026-03-16 12:20:35', '2026-03-16 12:25:01', NULL, NULL, NULL, NULL, 0),
(17, 'TARIK', 'Nabil', 'TARIK', '$2b$10$.//hWRVi2mUfjBugWXJEp.n.C3vUx7KNZimceE57QxILxWVT8fNVa', 'AP-SAP-002', NULL, NULL, NULL, NULL, 1, 'SAP', 'SAP', 1, NULL, 1, '2026-03-16 12:21:26', '2026-03-16 12:25:01', NULL, NULL, NULL, NULL, 0),
(18, 'HNINI', 'Nourdin', 'HNINI', '$2b$10$oYGEGBWUeCTVlW6IBTdQw.gCnmVGxrtK.LQ.ybtdNyFwOU3dNH.yG', 'AP-SAP-003', NULL, NULL, NULL, NULL, 1, 'SAP', 'SAP', 1, NULL, 1, '2026-03-16 12:21:35', '2026-03-16 12:25:01', NULL, NULL, NULL, NULL, 0),
(19, 'ZAMAN', 'Younes', 'ZAMAN', '$2b$10$pAm8yKoJv807uD5GU6D28u5GiCGq02nTFJ2e77jsd4FLAWmZbPsUK', 'AP-SAP-004', NULL, NULL, NULL, NULL, 1, 'SAP', 'SAP', 1, NULL, 1, '2026-03-16 12:21:43', '2026-03-23 16:10:55', NULL, NULL, NULL, NULL, 0),
(20, 'AKIBI', 'Mohammed', 'AKIBI', '$2b$10$ndajlIV5J3hMNnDeJM08AedFv2yP2aM7U8bZjb999wOnwwZAAYog2', 'AP-SAP-005', NULL, NULL, NULL, NULL, 2, 'SAP', 'SAP', 1, 'process', 1, '2026-03-16 12:21:52', '2026-03-24 09:12:17', NULL, NULL, NULL, NULL, 0),
(21, 'RAISSANI', 'Samir', 'RAISSANI', '$2b$10$kL4QJwOkZrGMthg8zUpFQu59kAORELh4yv.5CLvc7v1XdEm5kh.zq', 'PR-SAP-001', NULL, NULL, NULL, NULL, 19, 'SAP', 'SAP', 1, NULL, 1, '2026-03-16 12:22:01', '2026-03-16 12:25:01', NULL, NULL, NULL, NULL, 0),
(22, 'WARD', 'Ward', 'WARD', '$2b$10$.G2IfpzW.G5YCzQDng78YOnijoN9GLivoxRM9gW9RHskld6dUe8oa', 'PR-SAP-002', NULL, NULL, NULL, NULL, 19, 'SAP', 'SAP', 1, NULL, 1, '2026-03-16 12:22:15', '2026-03-23 16:11:59', NULL, NULL, NULL, NULL, 0),
(23, 'BENBCHINA', 'Benbchina', 'BENBCHINA', '$2b$10$uTAbeSxzHyeDCKcLFffoDOAbdjd7yaWE91l4U9lwOkc4xOvX7DuRa', 'PR-SAP-003', NULL, NULL, NULL, NULL, 19, 'SAP', 'SAP', 1, NULL, 1, '2026-03-16 12:22:23', '2026-03-16 12:25:01', NULL, NULL, NULL, NULL, 0),
(24, 'MAMI', 'Mami', 'MAMI', '$2b$10$Znco6pDU61Byk9s8.tDFke.yVir0ELtxDN16WgXUWiHSDTQaDSPO6', 'PR-SAP-004', NULL, NULL, NULL, NULL, 19, 'SAP', 'SAP', 1, NULL, 1, '2026-03-16 12:22:40', '2026-03-24 11:03:27', NULL, NULL, NULL, NULL, 0),
(25, 'CHMICHI', 'Chmichi', 'CHMICHI', '$2b$10$wv.DtoF93RHrLOzuRAW4re1MlmYUE9CzwBvHPiLSIIXLQuVyBzHZm', 'PR-SAP-006', NULL, NULL, NULL, NULL, 19, 'SAP', 'SAP', 1, NULL, 1, '2026-03-16 12:22:54', '2026-03-16 12:25:01', NULL, NULL, NULL, NULL, 0),
(26, 'JADIR', 'Jadir', 'JADIR', '$2b$10$TIo8oKklgCOEN07PF5KieO7EL8YLmo8czMgvocGWAyTs4CNwAkuYW', 'PR-SAP-007', NULL, NULL, NULL, NULL, 1, 'SAP', 'SAP', 1, 'process', 1, '2026-03-16 12:23:07', '2026-03-24 10:21:29', NULL, NULL, NULL, NULL, 0),
(28, 'AITMAMMA', 'ABDELGHANI', 'AITMAMMA', '$2b$10$4UsvS4bBRr0tN4FoUuVBQOJ3nRo5E8YZ7z0pFlzqlMs.YmLn.aWxq', NULL, NULL, NULL, NULL, NULL, 4, 'ACTEMIUM', 'OSBL', 4, 'electrique', 1, '2026-03-24 09:32:39', '2026-03-24 09:32:39', NULL, NULL, NULL, NULL, 0),
(29, 'SIHRY', 'TAOUFIK', 'SIHRY', '$2b$10$n4rqK2Lijr/6eTx/0mRyXeoauPjv/ODW0qlgEG4RxyXNWhI9YP23y', '52411', NULL, NULL, NULL, NULL, 1, 'kofert', 'OSBL', 4, 'process', 1, '2026-03-24 09:49:43', '2026-03-24 10:00:54', NULL, NULL, NULL, NULL, 0),
(30, 'MOUFID', 'moufid', 'MOUFID', '$2b$10$cGTyeDp86IyAccQlnG08hO5Ioo6b9MYa9KaQjY1OrrBgTueoLZGqq', NULL, NULL, NULL, NULL, NULL, 1, 'TANSSIFT', 'TED', 3, 'process', 1, '2026-03-24 09:50:38', '2026-03-24 09:50:38', NULL, NULL, NULL, NULL, 0),
(31, 'ELHANSSALI', 'AMIN', 'Elhansali', '$2b$10$rjuv9CM8YyzhxL/RPH1fu.RTvD5CdW1asVgkSbJvUIb.fUOJh6WZy', NULL, NULL, '1000', NULL, NULL, 18, 'kofert/MEI', 'OSBL', 4, 'electrique', 1, '2026-03-24 10:16:45', '2026-03-24 10:40:58', NULL, NULL, NULL, 'hisheem4@gmail.com', 1);

-- --------------------------------------------------------

--
-- Structure de la table `zones`
--

CREATE TABLE `zones` (
  `id` int NOT NULL,
  `code` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `actif` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `zones`
--

INSERT INTO `zones` (`id`, `code`, `description`, `actif`, `created_at`) VALUES
(1, 'SAP', 'Zone SAP', 1, '2026-03-16 11:53:52'),
(2, 'DAP', 'Zone DAP', 1, '2026-03-16 11:53:52'),
(3, 'TED', 'Zone TED', 1, '2026-03-16 11:53:52'),
(4, 'OSBL', 'Zone OSBL', 1, '2026-03-16 11:53:52');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `autorisations_travail`
--
ALTER TABLE `autorisations_travail`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `plan_id` (`plan_id`);

--
-- Index pour la table `deconsignations`
--
ALTER TABLE `deconsignations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `point_id` (`point_id`),
  ADD KEY `deconsigne_par` (`deconsigne_par`),
  ADD KEY `verifie_par` (`verifie_par`);

--
-- Index pour la table `deconsignation_metier`
--
ALTER TABLE `deconsignation_metier`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_demande_metier` (`demande_id`,`type_metier`),
  ADD KEY `idx_demande_id` (`demande_id`),
  ADD KEY `idx_chef_equipe` (`chef_equipe_id`);

--
-- Index pour la table `demandes_consignation`
--
ALTER TABLE `demandes_consignation`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `numero_ordre` (`numero_ordre`),
  ADD KEY `equipement_id` (`equipement_id`),
  ADD KEY `chef_prod_id` (`chef_prod_id`),
  ADD KEY `idx_demandes_statut` (`statut`),
  ADD KEY `idx_demandes_agent` (`agent_id`),
  ADD KEY `fk_demande_lot` (`lot_id`),
  ADD KEY `fk_demande_charge` (`charge_id`);

--
-- Index pour la table `dossiers_archives`
--
ALTER TABLE `dossiers_archives`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `demande_id` (`demande_id`),
  ADD KEY `cloture_par` (`cloture_par`);

--
-- Index pour la table `equipements`
--
ALTER TABLE `equipements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code_equipement` (`code_equipement`),
  ADD KEY `fk_equipement_lot` (`lot_id`),
  ADD KEY `fk_equipement_zone` (`zone_id`);

--
-- Index pour la table `equipe_intervention`
--
ALTER TABLE `equipe_intervention`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_equipe_demande` (`demande_id`),
  ADD KEY `idx_equipe_chef` (`chef_equipe_id`),
  ADD KEY `idx_ei_cad_id` (`cad_id`),
  ADD KEY `idx_ei_statut` (`statut`),
  ADD KEY `idx_ei_demande` (`demande_id`);

--
-- Index pour la table `executions_consignation`
--
ALTER TABLE `executions_consignation`
  ADD PRIMARY KEY (`id`),
  ADD KEY `consigne_par` (`consigne_par`),
  ADD KEY `verifie_par` (`verifie_par`),
  ADD KEY `idx_executions_point` (`point_id`);

--
-- Index pour la table `intervenants`
--
ALTER TABLE `intervenants`
  ADD PRIMARY KEY (`id`),
  ADD KEY `chef_equipe_id` (`chef_equipe_id`),
  ADD KEY `idx_intervenants_auto` (`autorisation_id`);

--
-- Index pour la table `lots`
--
ALTER TABLE `lots`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `fk_lot_zone` (`zone_id`);

--
-- Index pour la table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notifications_user` (`user_id`,`lu`);

--
-- Index pour la table `plans_consignation`
--
ALTER TABLE `plans_consignation`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `demande_id` (`demande_id`),
  ADD KEY `etabli_par` (`etabli_par`),
  ADD KEY `approuve_par` (`approuve_par`);

--
-- Index pour la table `plans_predefinis`
--
ALTER TABLE `plans_predefinis`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_predefini_eq` (`equipement_id`);

--
-- Index pour la table `points_consignation`
--
ALTER TABLE `points_consignation`
  ADD PRIMARY KEY (`id`),
  ADD KEY `electricien_id` (`electricien_id`),
  ADD KEY `idx_points_plan` (`plan_id`);

--
-- Index pour la table `push_tokens`
--
ALTER TABLE `push_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `user_id` (`user_id`);

--
-- Index pour la table `rapport_consignation`
--
ALTER TABLE `rapport_consignation`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_rapport_demande` (`demande_id`),
  ADD KEY `idx_rapport_chef` (`chef_equipe_id`);

--
-- Index pour la table `remises_en_service`
--
ALTER TABLE `remises_en_service`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `demande_id` (`demande_id`),
  ADD KEY `confirme_par` (`confirme_par`);

--
-- Index pour la table `reset_password_demandes`
--
ALTER TABLE `reset_password_demandes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_reset_user` (`user_id`),
  ADD KEY `idx_reset_statut` (`statut`),
  ADD KEY `idx_reset_traite_par` (`traite_par`);

--
-- Index pour la table `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nom` (`nom`);

--
-- Index pour la table `signatures_autorisation`
--
ALTER TABLE `signatures_autorisation`
  ADD PRIMARY KEY (`id`),
  ADD KEY `autorisation_id` (`autorisation_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `matricule` (`matricule`),
  ADD UNIQUE KEY `badge_ocp_id` (`badge_ocp_id`),
  ADD UNIQUE KEY `uq_users_email` (`email`),
  ADD KEY `role_id` (`role_id`),
  ADD KEY `idx_users_username` (`username`),
  ADD KEY `idx_users_badge_ocp` (`badge_ocp_id`),
  ADD KEY `fk_user_zone` (`zone_id`);

--
-- Index pour la table `zones`
--
ALTER TABLE `zones`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `autorisations_travail`
--
ALTER TABLE `autorisations_travail`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `deconsignations`
--
ALTER TABLE `deconsignations`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT pour la table `deconsignation_metier`
--
ALTER TABLE `deconsignation_metier`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT pour la table `demandes_consignation`
--
ALTER TABLE `demandes_consignation`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=85;

--
-- AUTO_INCREMENT pour la table `dossiers_archives`
--
ALTER TABLE `dossiers_archives`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT pour la table `equipements`
--
ALTER TABLE `equipements`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=48;

--
-- AUTO_INCREMENT pour la table `equipe_intervention`
--
ALTER TABLE `equipe_intervention`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `executions_consignation`
--
ALTER TABLE `executions_consignation`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT pour la table `intervenants`
--
ALTER TABLE `intervenants`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `lots`
--
ALTER TABLE `lots`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT pour la table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=239;

--
-- AUTO_INCREMENT pour la table `plans_consignation`
--
ALTER TABLE `plans_consignation`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=85;

--
-- AUTO_INCREMENT pour la table `plans_predefinis`
--
ALTER TABLE `plans_predefinis`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=183;

--
-- AUTO_INCREMENT pour la table `points_consignation`
--
ALTER TABLE `points_consignation`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=341;

--
-- AUTO_INCREMENT pour la table `push_tokens`
--
ALTER TABLE `push_tokens`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=116;

--
-- AUTO_INCREMENT pour la table `rapport_consignation`
--
ALTER TABLE `rapport_consignation`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT pour la table `remises_en_service`
--
ALTER TABLE `remises_en_service`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `reset_password_demandes`
--
ALTER TABLE `reset_password_demandes`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `roles`
--
ALTER TABLE `roles`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT pour la table `signatures_autorisation`
--
ALTER TABLE `signatures_autorisation`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT pour la table `zones`
--
ALTER TABLE `zones`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `autorisations_travail`
--
ALTER TABLE `autorisations_travail`
  ADD CONSTRAINT `autorisations_travail_ibfk_1` FOREIGN KEY (`plan_id`) REFERENCES `plans_consignation` (`id`);

--
-- Contraintes pour la table `deconsignations`
--
ALTER TABLE `deconsignations`
  ADD CONSTRAINT `deconsignations_ibfk_1` FOREIGN KEY (`point_id`) REFERENCES `points_consignation` (`id`),
  ADD CONSTRAINT `deconsignations_ibfk_2` FOREIGN KEY (`deconsigne_par`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `deconsignations_ibfk_3` FOREIGN KEY (`verifie_par`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `deconsignation_metier`
--
ALTER TABLE `deconsignation_metier`
  ADD CONSTRAINT `fk_decons_metier_chef` FOREIGN KEY (`chef_equipe_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_decons_metier_demande` FOREIGN KEY (`demande_id`) REFERENCES `demandes_consignation` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `demandes_consignation`
--
ALTER TABLE `demandes_consignation`
  ADD CONSTRAINT `demandes_consignation_ibfk_1` FOREIGN KEY (`equipement_id`) REFERENCES `equipements` (`id`),
  ADD CONSTRAINT `demandes_consignation_ibfk_2` FOREIGN KEY (`agent_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `demandes_consignation_ibfk_3` FOREIGN KEY (`chef_prod_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_demande_charge` FOREIGN KEY (`charge_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_demande_lot` FOREIGN KEY (`lot_id`) REFERENCES `lots` (`id`);

--
-- Contraintes pour la table `dossiers_archives`
--
ALTER TABLE `dossiers_archives`
  ADD CONSTRAINT `dossiers_archives_ibfk_1` FOREIGN KEY (`demande_id`) REFERENCES `demandes_consignation` (`id`),
  ADD CONSTRAINT `dossiers_archives_ibfk_2` FOREIGN KEY (`cloture_par`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `equipements`
--
ALTER TABLE `equipements`
  ADD CONSTRAINT `fk_equipement_lot` FOREIGN KEY (`lot_id`) REFERENCES `lots` (`id`),
  ADD CONSTRAINT `fk_equipement_zone` FOREIGN KEY (`zone_id`) REFERENCES `zones` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `equipe_intervention`
--
ALTER TABLE `equipe_intervention`
  ADD CONSTRAINT `fk_equipe_chef` FOREIGN KEY (`chef_equipe_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_equipe_demande` FOREIGN KEY (`demande_id`) REFERENCES `demandes_consignation` (`id`);

--
-- Contraintes pour la table `executions_consignation`
--
ALTER TABLE `executions_consignation`
  ADD CONSTRAINT `executions_consignation_ibfk_1` FOREIGN KEY (`point_id`) REFERENCES `points_consignation` (`id`),
  ADD CONSTRAINT `executions_consignation_ibfk_2` FOREIGN KEY (`consigne_par`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `executions_consignation_ibfk_3` FOREIGN KEY (`verifie_par`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `intervenants`
--
ALTER TABLE `intervenants`
  ADD CONSTRAINT `intervenants_ibfk_1` FOREIGN KEY (`autorisation_id`) REFERENCES `autorisations_travail` (`id`),
  ADD CONSTRAINT `intervenants_ibfk_2` FOREIGN KEY (`chef_equipe_id`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `lots`
--
ALTER TABLE `lots`
  ADD CONSTRAINT `fk_lot_zone` FOREIGN KEY (`zone_id`) REFERENCES `zones` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `plans_consignation`
--
ALTER TABLE `plans_consignation`
  ADD CONSTRAINT `plans_consignation_ibfk_1` FOREIGN KEY (`demande_id`) REFERENCES `demandes_consignation` (`id`),
  ADD CONSTRAINT `plans_consignation_ibfk_2` FOREIGN KEY (`etabli_par`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `plans_consignation_ibfk_3` FOREIGN KEY (`approuve_par`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `plans_predefinis`
--
ALTER TABLE `plans_predefinis`
  ADD CONSTRAINT `fk_predefini_eq` FOREIGN KEY (`equipement_id`) REFERENCES `equipements` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `points_consignation`
--
ALTER TABLE `points_consignation`
  ADD CONSTRAINT `points_consignation_ibfk_1` FOREIGN KEY (`plan_id`) REFERENCES `plans_consignation` (`id`),
  ADD CONSTRAINT `points_consignation_ibfk_2` FOREIGN KEY (`electricien_id`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `push_tokens`
--
ALTER TABLE `push_tokens`
  ADD CONSTRAINT `push_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `rapport_consignation`
--
ALTER TABLE `rapport_consignation`
  ADD CONSTRAINT `fk_rapport_chef` FOREIGN KEY (`chef_equipe_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_rapport_demande` FOREIGN KEY (`demande_id`) REFERENCES `demandes_consignation` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `remises_en_service`
--
ALTER TABLE `remises_en_service`
  ADD CONSTRAINT `remises_en_service_ibfk_1` FOREIGN KEY (`demande_id`) REFERENCES `demandes_consignation` (`id`),
  ADD CONSTRAINT `remises_en_service_ibfk_2` FOREIGN KEY (`confirme_par`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `reset_password_demandes`
--
ALTER TABLE `reset_password_demandes`
  ADD CONSTRAINT `fk_reset_traite` FOREIGN KEY (`traite_par`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_reset_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `signatures_autorisation`
--
ALTER TABLE `signatures_autorisation`
  ADD CONSTRAINT `signatures_autorisation_ibfk_1` FOREIGN KEY (`autorisation_id`) REFERENCES `autorisations_travail` (`id`),
  ADD CONSTRAINT `signatures_autorisation_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Contraintes pour la table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_user_zone` FOREIGN KEY (`zone_id`) REFERENCES `zones` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
