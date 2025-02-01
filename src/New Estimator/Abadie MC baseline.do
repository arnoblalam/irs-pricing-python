capture program drop mc_abadie
program define mc_abadie, rclass

    // 0. Clear and set obs
    clear
    set obs 500

    // 1. DATA GENERATION
    // -------------------
    // Generate two covariates
    gen X1 = rnormal(0,1)
    gen X2 = rnormal(0, 1)

    // True propensity to treat
	gen double u = rnormal(0,1)
	gen D = (runiform() < invlogit(3*X1 - 5*X2 + 2*u))

    // Generate pre/post outcomes
    gen double e_pre  = rnormal(0,1)
    gen double e_post = rnormal(0,1)

    *gen Ypre  = 1 + 0.3*X1 + 0.3*X2 + e_pre
	gen Ypre  = 1 + 0.3*X1 + 0.3*X2 + 0.2*D + e_pre
    ** gen Ypost = 3 + 0.3*X1 + 0.3*X2 + 2*D + e_post
	gen Ypost = 3 + 0.3*X1 + 0.3*X2 + (1.5 + 0.5*X1)*D + e_post


    gen double diffY = Ypost - Ypre

    // 2. ESTIMATE ABADIE ATT USING LOGIT FIRST STAGE
    // -----------------------------------------------
    quietly logit D X1 X2
    predict double ps_logit, pr  // predicted P(D=1|X) from logit
    summarize D, meanonly
    scalar pd1 = r(mean)  // fraction treated

    // Construct Abadie weights and Weighted diff
    gen double rho0_logit = (D - ps_logit)/(ps_logit*(1 - ps_logit))
    gen double intermediate_logit = rho0_logit * diffY * ps_logit
    
    summarize intermediate_logit, meanonly
    scalar unscaled_logit = r(mean)
    scalar ATT_logit = (1/pd1) * unscaled_logit

    // 3. ESTIMATE ABADIE ATT USING GME (MaxEnt) FIRST STAGE
    // ---------------------------------------------------------------
    quietly gmentropylogit D X1 X2, gen(ps_gme)

    gen double rho0_gme = (D - ps_gme)/(ps_gme*(1 - ps_gme))
    gen double intermediate_gme = rho0_gme * diffY * ps_gme
	
	/// 4. Simple DiD
    summarize diffY if D==1, meanonly
    scalar diff_treated = r(mean)

    summarize diffY if D==0, meanonly
    scalar diff_control = r(mean)

    scalar did_trad = diff_treated - diff_control

    summarize intermediate_gme, meanonly
    scalar unscaled_gme = r(mean)
    scalar ATT_gme = (1/pd1) * unscaled_gme

    // 4. RETURN THE TWO ESTIMATES
    return scalar att_logit = ATT_logit
    return scalar att_gme   = ATT_gme
	return scalar did_trad  = did_trad
	

end


simulate att_logit = r(att_logit) ///
         att_gme   = r(att_gme) ///
		 att_did = r(did_trad), ///
         reps(5000) nodots: mc_abadie

twoway (kdensity att_gme, range(0 4)) ///
	(kdensity att_logit, range(0 4))  ///
	(kdensity att_did, range(0 4)) ///
	(function y = 0, range(0 4) xline(2, lpattern(dash)) ///
	text(1.5 2.1 "True ATT", place(north) orientation(vertical) size(small))) ///
	,scheme(lean2) ///
	legend(order (1 2 3) label(1 "GME") label(2 "Logit") label(3 "Uncorrected")) ///
	title("Estimator Performance: Baseline Case")
	
graph export "reports/figures/estimator_baseline.png", replace

* 1. Define the true ATT for your DGP
scalar true_att = 2

* 2. Generate bias variables
gen double bias_logit = att_logit - true_att
gen double bias_gme   = att_gme   - true_att
gen double bias_did   = att_did  - true_att

* 3. For convenience, also label them
label var bias_logit "ATT(Logit) - True"
label var bias_gme   "ATT(GME) - True"
label var bias_did   "Traditional DiD - True"

summarize bias_logit
scalar mean_bias_logit = r(mean)
scalar sd_bias_logit   = r(sd)
scalar mse_logit = mean_bias_logit^2 + sd_bias_logit^2   // MSE = Var + (Bias)^2

summarize bias_gme
scalar mean_bias_gme = r(mean)
scalar sd_bias_gme   = r(sd)
scalar mse_gme = mean_bias_gme^2 + sd_bias_gme^2

summarize bias_did
scalar mean_bias_did = r(mean)
scalar sd_bias_did   = r(sd)
scalar mse_did = mean_bias_did^2 + sd_bias_did^2


* Create a 3 x 3 matrix initialized with missing
matrix Perf = J(3, 3, .)

* Row names = estimator labels
matrix rownames Perf = "Abadie (Logit)" "Abadie (GME)" "Traditional DiD"

* Column names = statistic labels
matrix colnames Perf = "MeanBias" "StdDev" "MSE"

* Fill matrix for Logit
matrix Perf[1,1] = mean_bias_logit
matrix Perf[1,2] = sd_bias_logit
matrix Perf[1,3] = mse_logit

* Fill matrix for OLS
matrix Perf[2,1] = mean_bias_gme
matrix Perf[2,2] = sd_bias_gme
matrix Perf[2,3] = mse_gme

* Fill matrix for Traditional DID
matrix Perf[3,1] = mean_bias_did
matrix Perf[3,2] = sd_bias_did
matrix Perf[3,3] = mse_did

* View it in Stata's matrix window
matrix list Perf


esttab matrix(Perf) using "reports/tables/Baseline_Abadie.html", ///
    mlabels("Abadie (Logit)" "Abadie (GME)" "Traditional DiD") ///
    varlabels("Mean Bias" "Std. Dev." "MSE") ///
    unstack html noobs ///
	replace
