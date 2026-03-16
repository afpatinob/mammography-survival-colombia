# mammography-survival-colombia

Stata code and documentation for the analysis of biennial mammography adherence and five-year survival among women over 50 with breast cancer in Colombia.

## Overview

This repository contains the analytic code and supporting documentation used in a study evaluating the association between biennial mammography adherence and five-year survival among Colombian women aged over 50 years with breast cancer.

The repository is intended to improve transparency and reproducibility of the analytical workflow. It does not contain raw or derived individual-level data.

## Study summary

The study used restricted administrative health databases from Colombia to assemble a cohort of women with breast cancer and evaluate the association between adherence to biennial mammography and all-cause mortality using propensity score matching and survival analysis.

## Repository contents

- `analysis_survival.do`  
  Main Stata script used for data preparation, propensity score matching, descriptive analyses, and survival analyses.

- `reproducibility_notes.md`  
  Technical notes describing software requirements, data restrictions, workflow, and execution considerations.

- `LICENSE`  
  MIT License.

Additional documentation files may be added, including a variable dictionary and supporting methodological notes.

## Software

- Stata 17.0 MP—Parallel Edition

## Data availability

The raw administrative data used in this study are third-party data owned by the Colombian Ministry of Health and Social Protection and cannot be publicly shared by the authors.

Other researchers may request access to these data through the same official procedures used by the authors, subject to the Ministry’s legal and administrative requirements. The authors did not receive special access privileges.

This repository does not include raw data, analytic datasets, or any individual-level health information. It only provides the analytic code and documentation required to understand and reproduce the analytical workflow.

## Reproducibility

Because the source data are restricted, this repository does not allow direct rerunning of the full analysis without prior authorization to access the underlying administrative databases. However, it provides the code structure, variable logic, and analytical workflow used in the study.

Users who obtain authorized access to the original source data may adapt the scripts to their local environment and reproduce the analysis.

## Notes for users

- File paths in the original analytical environment were removed or generalized for public release.
- Users may need to adapt directory structure and input/output paths before running the scripts.
- User-written Stata commands may be required depending on the analysis step and local implementation.

## Citation

If you use or adapt this repository, please cite the corresponding manuscript when available.

## Contact

For questions regarding the code and repository contents, contact the corresponding study authors through the manuscript record or repository profile.

For access to the restricted source data, contact the Colombian Ministry of Health and Social Protection through its official data access procedures.
