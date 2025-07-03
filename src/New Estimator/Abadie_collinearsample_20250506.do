*----------------------------
* Program: one simulation
*----------------------------
capture program drop did_sim
program define did_sim, rclass
    version 17
    clear
    set obs 500

    * Simulate covariates
    gen x1 = rnormal()
    gen x2 = x1+rnormal(0, 1e-5)

    * Generate true propensity score
    gen ps = invlogit(0.5*x1 - 0.3*x2)

    * Assign treatment based on ps
    gen D = (runiform() < ps)

    * Generate fixed and transitory components
    gen eta = rnormal()
    gen v0 = rnormal()
    gen v1 = rnormal()

    * Outcome under control and treated
    gen Y0_pre = 2 + 0.5*x1 - 0.3*x2 + eta + v0
    gen Y0_post = 2.5 + 0.5*x1 - 0.3*x2 + x1 + eta + v1
    gen Y1_post = Y0_post + 1    // Treatment effect = 1

    * Observed outcomes
    gen Y_pre = Y0_pre
    gen Y_post = D*Y1_post + (1 - D)*Y0_post

    * Difference in outcomes
    gen diff_Y = Y_post - Y_pre

    * --- Unweighted DID ---
    reg diff_Y D
    return scalar unweighted = _b[D]

    * --- PS Weighted DID ---
    logit D x1 x2
    predict ps_hat, pr

    gen w = D + (1 - D)*(ps_hat / (1 - ps_hat))

    reg diff_Y D [pw=w]
    return scalar weighted = _b[D]
	
	* --- info-metrics did ---
	gmentropylogit D x1 x2, gen(p_gme)
	gen rho_gme = D + (1 - D)*(p_gme / (1 - p_gme))
	reg diff_Y D [pw=rho_gme]
	return scalar gme = _b[D]
end

*----------------------------
* Run 1000 simulations
*----------------------------
simulate unweighted=r(unweighted) weighted=r(weighted) gme=r(gme), reps(1000): did_sim

*----------------------------
* Evaluate performance
*----------------------------
gen true_effect = 1
gen bias_unw = unweighted - true_effect
gen bias_wgt = weighted - true_effect
gen bias_gme = gme - true_effect

twoway ///
    (kdensity unweighted,  lcolor(navy)   lwidth(medthick)) ///
    (kdensity weighted,    lcolor(maroon) lpattern(dash) lwidth(medthick)) ///
	(kdensity gme,         lcolor(cyan) lpattern(medthick) lwidth(medthick)) ///
    , legend(order(1 "Unweighted DiD" 2 "Weighted DiD" 3 "GME DiD")) ///
      title("Sampling distributions of DiD estimators with highly collinear covariates") ///
      xtitle("Estimated treatment effect") ytitle("Density") ///
      name(kden_did, replace)

gen mse_unw = (bias_unw)^2
gen mse_wgt = (bias_wgt)^2
gen mse_gme = (bias_gme)^2


* Summary table
estpost summarize unweighted weighted gme bias_unw bias_wgt bias_gme mse_unw mse_wgt mse_gme
esttab ., ///
    cells("mean(fmt(3)) sd(fmt(3))") ///
    label title("Performance of DID Estimators over 1000 Simulations with highly collinear covariates") ///
    varlabels(unweighted "Unweighted DiD" weighted "Weighted DiD" gme "GME" bias_unw "Bias (Unw)" bias_wgt "Bias (Wgt)" bias_gme "Bias (GME)" mse_unw "MSE (Unw)" mse_wgt "MSE (Wgt)" mse_gme "MSE (GME)") ///
    nonumber

