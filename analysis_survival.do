version 17.0

/**************************************************************************
Project: Mammography adherence and five-year survival in Colombia
Purpose: Repository-ready Stata do-file for main and supplementary analyses
Notes:
1) This script is prepared for public sharing.
2) Raw or derived individual-level data are NOT included in the repository.
3) Place the restricted source dataset in the local data folder before running.
4) Adapt the root path below to your local environment.
**************************************************************************/

clear all
macro drop _all
set more off
set linesize 255
capture log close _all

*==========================================================================*
* 0. PROJECT SETUP                                                         *
*==========================================================================*

* Set your local project root here before running.
global PROJECT_DIR "."

* Standard subfolders for a public repository.
global DATA_DIR    "$PROJECT_DIR/data"
global OUTPUT_DIR  "$PROJECT_DIR/output"
global FIG_DIR     "$OUTPUT_DIR/figures"
global LOG_DIR     "$OUTPUT_DIR/logs"

capture mkdir "$OUTPUT_DIR"
capture mkdir "$FIG_DIR"
capture mkdir "$LOG_DIR"

* Restricted source dataset expected locally (not shared in the repository).
global DATA_FILE   "$DATA_DIR/mam_def_15_16.dta"

capture confirm file "$DATA_FILE"
if _rc {
    di as error "Required file not found: $DATA_FILE"
    di as error "Place the restricted dataset in the local data folder before running this script."
    exit 601
}

* Required user-written commands.
cap which psmatch2
if _rc {
    di as error "Command psmatch2 not found. Install it with: ssc install psmatch2"
    exit 199
}

cap which asdoc
if _rc {
    di as txt "Command asdoc not found. Descriptive output will still run, but asdoc tables will be skipped."
}

log using "$LOG_DIR/analysis_main.log", replace text name(analysis_main)

*==========================================================================*
* 1. LOAD DATA AND PREPARE VARIABLES                                       *
*==========================================================================*

use "$DATA_FILE", clear

* Age categories for descriptive analyses.
capture drop edad_cat
gen byte edad_cat = .
replace edad_cat = 0 if edad_tto < 60
replace edad_cat = 1 if inrange(edad_tto, 60, 64.999999)
replace edad_cat = 2 if edad_tto >= 65
label define lbl_edad_cat 0 "Younger than 60 years" ///
                          1 "60-64 years" ///
                          2 "65 years or older", replace
label values edad_cat lbl_edad_cat

* Region regrouping: merge Orinoquia into Eastern.
capture drop reg_r_ajustada
clonevar reg_r_ajustada = reg_r
recode reg_r_ajustada (6 = 4)
label variable reg_r_ajustada "Region"
label define lbl_reg_en 1 "Caribbean" ///
                        2 "Bogota" ///
                        3 "Central" ///
                        4 "Eastern/Orinoquia" ///
                        5 "Pacific", replace
capture label values reg_r_ajustada lbl_reg_en

* Additional variable labels for plots and tables.
label variable edad_tto  "Age at treatment"
label variable iam       "Myocardial infarction"
label variable icc       "Heart failure"
label variable evp       "Peripheral vascular disease"
label variable acv       "Stroke"
label variable deme      "Dementia"
label variable epc       "COPD"
label variable enf_conec "Connective tissue disease"
label variable ulc_pep   "Peptic ulcer disease"
label variable enf_hep   "Liver disease"
label variable dm        "Diabetes mellitus"
label variable dm_compl  "Diabetes with complications"
label variable paraple   "Paraplegia"
label variable enf_ren   "Renal disease"
label variable vih       "HIV/AIDS"
label variable y_tto     "Treatment year"
label variable est       "Cancer stage"
label variable eps       "Health insurer (EPS)"
label define lbl_estadio_en 0 "Local" 1 "Advanced" 2 "Metastatic", replace
capture label values est lbl_estadio_en

* Follow-up time and mortality indicators.
format t_1 %td
capture drop t mort_1y mort_3y mort_5y
 gen double t = (t_1 - f_tto) / 365.25
 gen byte mort_1y = mort if t <= 1
 gen byte mort_3y = mort if t <= 3
 gen byte mort_5y = mort if t <= 5
 replace mort_1y = 0 if missing(mort_1y)
 replace mort_3y = 0 if missing(mort_3y)
 replace mort_5y = 0 if missing(mort_5y)

* Analysis covariates.
global V_CONT edad_tto
global V_BIN  iam icc evp acv deme epc enf_conec ulc_pep enf_hep dm dm_compl paraple enf_ren vih
global V_CAT  eps reg_r_ajustada est y_tto

*==========================================================================*
* 2. DESCRIPTIVE ANALYSES                                                  *
*==========================================================================*

cap which asdoc
if !_rc {
    asdoc sum edad_tto, detail save("$OUTPUT_DIR/descriptive_statistics.doc") replace
    asdoc sum edad_tto if mamg_2 == 0, detail save("$OUTPUT_DIR/descriptive_statistics.doc") append
    asdoc sum edad_tto if mamg_2 == 1, detail save("$OUTPUT_DIR/descriptive_statistics.doc") append
    asdoc sum ind_char, detail save("$OUTPUT_DIR/descriptive_statistics.doc") append
    asdoc sum ind_char if mamg_2 == 0, detail save("$OUTPUT_DIR/descriptive_statistics.doc") append
    asdoc sum ind_char if mamg_2 == 1, detail save("$OUTPUT_DIR/descriptive_statistics.doc") append
}

quietly ttest edad_tto, by(mamg_2)
quietly ranksum ind_char, by(mamg_2)

foreach var in eps reg_r iam icc evp acv deme epc enf_conec ulc_pep enf_hep dm dm_compl paraple enf_ren can_meta enf_hep_seve est mamg_2 mort y_tto {
    quietly tab `var'
}

foreach var in eps reg_r iam icc evp acv deme epc enf_conec ulc_pep enf_hep dm dm_compl paraple enf_ren can_meta enf_hep_seve est mamg_2 mort y_tto {
    quietly tab `var' mamg_2, row
}

quietly tab mort_1y mamg_2, chi2
quietly tab mort_3y mamg_2, chi2
quietly tab mort_5y mamg_2, chi2

*==========================================================================*
* 3. PROPENSITY SCORE MATCHING                                             *
*==========================================================================*

psmatch2 mamg_2 i.eps i.reg_r_ajustada enf_conec i.est, outcome(mort) radius caliper(0.05) common

capture drop w_match
 gen double w_match = cond(_treated == 1, 1, _weight)

capture confirm variable _support
if _rc gen byte _support = 1

*==========================================================================*
* 4. LOVE PLOT: COVARIATE BALANCE                                          *
*==========================================================================*

capture program drop _onebias
program define _onebias, rclass
    syntax varname(numeric)
    tempname mt mc sdt sdc sdp mtm mcm

    quietly summarize `varlist' if _support == 1 & _treated == 1
    scalar `mt'  = r(mean)
    scalar `sdt' = r(sd)

    quietly summarize `varlist' if _support == 1 & _treated == 0
    scalar `mc'  = r(mean)
    scalar `sdc' = r(sd)

    scalar `sdp' = sqrt((`sdt'^2 + `sdc'^2)/2)
    return scalar U = cond(`sdp' > 0, 100 * (`mt' - `mc') / `sdp', .)

    quietly summarize `varlist' [aw = w_match] if _support == 1 & _treated == 1
    scalar `mtm' = r(mean)

    quietly summarize `varlist' [aw = w_match] if _support == 1 & _treated == 0
    scalar `mcm' = r(mean)

    return scalar M = cond(`sdp' > 0, 100 * (`mtm' - `mcm') / `sdp', .)
end

tempname H
tempfile biasdat
postfile `H' int ord str60 cov str150 covlab double Unmatched Matched using `biasdat', replace

local ord = 0

foreach v in $V_CONT $V_BIN {
    local ++ord
    local vlbl : variable label `v'
    if "`vlbl'" == "" local vlbl "`v'"
    _onebias `v'
    post `H' (`ord') ("`v'") ("`vlbl'") (r(U)) (r(M))
}

foreach cat in $V_CAT {
    local catlbl : variable label `cat'
    local vallab : value label `cat'

    quietly summarize `cat' if _support == 1, meanonly
    local base = r(min)

    levelsof `cat' if _support == 1, local(levs)
    foreach L of local levs {
        if (`L' == `base') continue

        tempvar d
        gen byte `d' = (`cat' == `L') if _support == 1
        _onebias `d'

        local ++ord
        local levlbl "`L'"
        if "`vallab'" != "" {
            local tmp : label `vallab' `L'
            if "`tmp'" != "" local levlbl "`tmp'"
        }

        post `H' (`ord') ("`L'.`cat'") ("`catlbl': `levlbl'") (r(U)) (r(M))
        drop `d'
    }
}
postclose `H'

preserve
use `biasdat', clear
drop if missing(Unmatched)
sort ord
gen y = _n

label define ylab 0 "", replace
count
local N_obs = r(N)
forvalues j = 1/`N_obs' {
    local lab = covlab[`j']
    label define ylab `j' `"`lab'"', add
}
label values y ylab

set scheme s2color

twoway ///
    (scatter y Unmatched, msymbol(Oh) msize(medium) mcolor(navy) mlcolor(navy)) ///
    (scatter y Matched,   msymbol(X)  msize(medium) mcolor(dkorange) mlcolor(dkorange) mlwidth(medthick)) ///
    , ///
    ytitle("") ///
    xtitle("Standardized % bias", size(small)) ///
    xline(0, lpattern(solid) lcolor(gs12)) ///
    xline(-10 10, lpattern(dash) lcolor(gs8)) ///
    xlabel(-30(10)30, labsize(small) grid) ///
    ylabel(1(1)`N_obs', valuelabel angle(0) labsize(vsmall) nogrid) ///
    yscale(reverse range(0.5 `=`N_obs'+0.5')) ///
    legend(order(1 "Unmatched" 2 "Matched") pos(6) rows(1) region(lcolor(none)) size(small)) ///
    title("Covariate Balance", size(medium)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(balance_plot_english, replace)

graph export "$FIG_DIR/fig2_standardized_bias.png", as(png) width(3000) replace
restore

*==========================================================================*
* 5. SURVIVAL ANALYSIS: TOTAL AND MATCHED SAMPLES                          *
*==========================================================================*

use "$DATA_FILE", clear
capture drop reg_r_ajustada
clonevar reg_r_ajustada = reg_r
recode reg_r_ajustada (6 = 4)

* 5A. Total sample.
stset t_1, id(PersonaBasicaID) origin(time f_tto) failure(mort) scale(365.25)
stcox mamg_2
lincom mamg_2, hr
local hr_A : display %4.2f r(estimate)
local lb_A : display %4.2f r(lb)
local ub_A : display %4.2f r(ub)

stcurve, survival ///
    at1(mamg_2 = 0) at2(mamg_2 = 1) ///
    graphregion(color(white)) ///
    legend(label(1 "Non-adherent") label(2 "Adherent") region(lcolor(white))) ///
    title("Cox proportional hazards regression" "Total sample") ///
    ylabel(0.80(0.05)1, angle(0) format(%3.2f)) ///
    xtitle("Time (years)") ///
    ytitle("Survival probability") ///
    text(0.82 1 "HR `hr_A'" "95% CI `lb_A' to `ub_A'", box fcolor(white) margin(small) place(c)) ///
    name(fig_3a, replace) nodraw

* 5B. Matched sample.
psmatch2 mamg_2 i.eps i.reg_r_ajustada enf_conec i.est, outcome(mort) radius caliper(0.05) common
pstest $V_CONT i.eps i.reg_r_ajustada iam icc evp acv deme epc enf_conec ulc_pep enf_hep dm dm_compl paraple enf_ren vih i.est i.y_tto, t(mamg_2) both

stset t_1 [pweight = _weight], id(PersonaBasicaID) failure(mort) origin(time f_tto) scale(365.25)
stcox mamg_2, robust
lincom mamg_2, hr
local hr_B : display %4.2f r(estimate)
local lb_B : display %4.2f r(lb)
local ub_B : display %4.2f r(ub)

stcurve, survival ///
    at1(mamg_2 = 0) at2(mamg_2 = 1) ///
    graphregion(color(white)) ///
    legend(label(1 "Non-adherent") label(2 "Adherent") region(lcolor(white))) ///
    xtitle("Time (years)") ///
    ytitle("Survival probability") ///
    title("Cox proportional hazards regression" "Matched sample") ///
    ylabel(0.80(0.05)1, angle(0) format(%3.2f)) ///
    text(0.82 1 "HR `hr_B'" "95% CI `lb_B' to `ub_B'", box fcolor(white) margin(small) place(c)) ///
    name(fig_3b, replace) nodraw

graph combine fig_3a fig_3b, ///
    col(2) ///
    xsize(14) ysize(6) ///
    graphregion(color(white)) ///
    ycommon ///
    title("Survival analysis")

graph export "$FIG_DIR/fig3_survival.png", as(png) width(3000) replace

*==========================================================================*
* 6. PROPORTIONAL HAZARDS ASSUMPTION                                       *
*==========================================================================*

noi di _n _dup(25) "-"
noi di "Schoenfeld residuals test"
noi di _dup(25) "-"
estat phtest, detail

estat phtest, plot(mamg_2) ///
    title("Schoenfeld residuals: mammography adherence") ///
    ytitle("Scaled Schoenfeld residuals") ///
    xtitle("Time (years)") ///
    scheme(s1mono)

graph export "$FIG_DIR/assumption_ph_schoenfeld.png", as(png) width(2000) replace

*==========================================================================*
* 7. SUPPLEMENTARY ANALYSES: PARAMETRIC SURVIVAL MODELS                    *
*==========================================================================*

use "$DATA_FILE", clear
capture drop reg_r_ajustada
clonevar reg_r_ajustada = reg_r
recode reg_r_ajustada (6 = 4)

stset t_1, id(PersonaBasicaID) origin(time f_tto) failure(mort) scale(365.25)

stcox i.mamg_2 edad_tto i.eps i.reg_r_ajustada iam icc evp acv deme epc enf_conec ulc_pep enf_hep dm dm_compl paraple enf_ren vih i.est i.y_tto
estat phtest, detail

streg i.mamg_2 edad_tto i.eps i.reg_r_ajustada iam icc evp acv deme epc enf_conec ulc_pep enf_hep dm dm_compl paraple enf_ren vih i.est i.y_tto, dist(exponential)
estimates store m_exponential

streg i.mamg_2 edad_tto i.eps i.reg_r_ajustada iam icc evp acv deme epc enf_conec ulc_pep enf_hep dm dm_compl paraple enf_ren vih i.est i.y_tto, dist(weibull)
estimates store m_weibull

streg i.mamg_2 edad_tto i.eps i.reg_r_ajustada iam icc evp acv deme epc enf_conec ulc_pep enf_hep dm dm_compl paraple enf_ren vih i.est i.y_tto, dist(gompertz)
estimates store m_gompertz

estimates stats m_exponential m_weibull m_gompertz

* Supplementary Weibull plot.
streg i.mamg_2 edad_tto i.eps i.reg_r_ajustada iam icc evp acv deme epc enf_conec ulc_pep enf_hep dm dm_compl paraple enf_ren vih i.est i.y_tto, dist(weibull)
lincom 1.mamg_2, hr
local ahr_w : display %4.2f r(estimate)
local lb_w  : display %4.2f r(lb)
local ub_w  : display %4.2f r(ub)

stcurve, survival ///
    at1(mamg_2 = 0) at2(mamg_2 = 1) ///
    graphregion(color(white)) ///
    legend(label(1 "Non-adherent") label(2 "Adherent") region(lcolor(white))) ///
    xtitle("Time (years)") ///
    ytitle("Survival probability") ///
    title("Supplementary Weibull model") ///
    ylabel(0.80(0.05)1, angle(0) format(%3.2f)) ///
    text(0.82 1 "aHR `ahr_w'" "95% CI `lb_w' to `ub_w'", box fcolor(white) margin(small) place(c)) ///
    name(fig_supp_weibull, replace)

graph export "$FIG_DIR/supplementary_weibull_survival.png", as(png) width(3000) replace

*==========================================================================*
* 8. END                                                                   *
*==========================================================================*

log close analysis_main
