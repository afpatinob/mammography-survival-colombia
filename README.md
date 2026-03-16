# Reproducibility notes

## Purpose of this repository

This repository provides the Stata code and documentation used in the analysis of biennial mammography adherence and five-year survival among women over 50 with breast cancer in Colombia.

The repository was prepared to support transparency and reproducibility of the analytic workflow while respecting the legal and administrative restrictions applicable to the underlying health databases.

## Analytical environment

- Software: Stata 17.0 MP—Parallel Edition
- Operating system used in the original analysis: Windows
- Original analysis date reflected in the log: 16 March 2026

## Source data

The original analysis used a restricted Stata dataset derived from anonymized Colombian administrative health databases. In the analytical log, the input file was:

- `mam_def_15_16.dta`

This file is not included in the repository because the underlying data are third-party data owned by the Colombian Ministry of Health and Social Protection and cannot be publicly redistributed by the authors.

The study used the following source databases:

- PILA: Wages Database
- UPC: Capitation Unit Sufficiency Study Database
- BDUA: Unique Enrollees Database
- RUAF: Mortality Registry Module

## Access to data

The raw data used in this study are third-party anonymized administrative databases owned by the Colombian Ministry of Health and Social Protection, including PILA, UPC, BDUA, and RUAF. These data were provided for research purposes and are subject to legal and administrative restrictions, so they cannot be publicly shared by the authors. Researchers may request access directly from the Ministry’s Office of Information Technologies at correo@minsalud.gov.co. The authors did not receive special access privileges.

## Publicly shared materials

This repository may include:

- Main Stata analysis script
- README documentation
- Reproducibility notes
- Additional supporting methodological documents

This repository does not include:

- Raw data
- Derived analytic datasets
- Any file containing directly identifiable personal information
- Local logs with sensitive file paths

## Main analytical workflow

The main script performs the following general steps:

1. Opens the analytic dataset.
2. Produces descriptive information for the cohort.
3. Generates baseline descriptive analyses.
4. Implements propensity score matching.
5. Evaluates post-matching balance.
6. Fits survival analyses for mortality outcomes.
7. Produces model outputs and supporting results.

## Key variables documented in the codebook

Selected variables documented in the shared codebook include:

- `PersonaBasicaID`: subject identifier
- `eps`: insurer category
- `edad_tto`: age at treatment
- `edad11`: age at baseline/reference period
- `depto_r`: department
- `reg_r`: region
- `iam`, `icc`, `evp`, `acv`, `deme`, `epc`, `enf_conec`, `ulc_pep`, `enf_hep`, `dm`, `dm_compl`, `paraple`, `enf_ren`, `can_meta`, `enf_hep_seve`, `vih`: comorbidity indicators
- `ind_char`: comorbidity summary score
- `icc_cat`: grouped comorbidity category
- `est`: cancer stage category
- `f_tto`: treatment date
- `mamg_2`: biennial mammography adherence exposure
- `mort`: mortality indicator
- `f_mort`: date of death
- `f_dx`: diagnosis date
- `mamg`: mammography count
- `t_1`: time-to-event variable

## Cohort structure documented in the codebook

The codebook provided for the analytic dataset reports:

- 2,452 observations
- treatment years concentrated in 2015 and 2016
- binary exposure variable `mamg_2`
- binary mortality outcome `mort`

These details are included only to describe the analytical structure and not to redistribute underlying data.

## Execution notes

Before running the script:

1. Place the authorized input dataset in a local working directory that is not publicly shared.
2. Review and adapt all directory globals or local paths.
3. Confirm that required Stata user-written commands are installed.
4. Review output destinations for logs, tables, and figures.

## User-written Stata commands

The analysis workflow uses propensity score matching procedures. If needed, install:

- `psmatch2`

Example:

```stata
ssc install psmatch2
