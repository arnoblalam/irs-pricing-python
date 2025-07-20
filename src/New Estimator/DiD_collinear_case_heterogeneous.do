set seed 12345
capture program drop collinear_case_h
program define collinear_case_h, rclass
    version 17.0
    syntax, [n(integer 500)]

    * Simulate data
    clear
    set obs `n'
    gen X1 = rnormal()
    gen X2 = X1 + rnormal(0, 0.01)
	gen eps0 = rnormal()
	gen eps1 = rnormal()
	gen base = 5 + 0.5*X1 - 0.3*X2
    gen Y0 =  base + eps0
	gen trend = 0.4*X1 - 0.1*X2   // untreated change depends on X's
    gen linpred = 0.5*X1 - 0.8*X2
    gen pscore = invlogit(linpred)
    gen D = rbinomial(1, pscore)
	gen tau = 2.0 + 0.8*X1 - 0.5*X2
    gen Y1 = base + trend + tau*D + eps1
    gen diff = Y1 - Y0

    * GME estimate of ATT
    gmentropylogit D X1 X2, generate(p_gme)
    gen w_gme = (D - p_gme) / (1 - p_gme)
	gen double num2 = diff * w_gme
	summarize num2
	scalar lambda = r(mean)
	summ D, meanonly
	scalar att_gme = lambda / r(mean)
	return scalar att_gme = att_gme

	* LS Projection
	gen double p0_gme = (D - p_gme)/(p_gme*(1 - p_gme))
	gen double y_tilde  = p0_gme * diff
	regress y_tilde X1 X2 [aw = p_gme]
	predict ghat_ls, xb
	return scalar coef_X1_ls = _b[X1]
	return scalar coef_X2_ls = _b[X2]
	return scalar intercept_ls = _b[_cons]
	summarize ghat_ls if D==1, meanonly
	scalar att_ls_proj = r(mean)
	return scalar att_ls_proj = att_ls_proj

	* GME projection
	gen double sqrt_p_gme = sqrt(p_gme)
	gen double y_tilde_star = y_tilde * sqrt_p_gme
	gen double X1_star = X1 * sqrt_p_gme
	gen double X2_star = X2 * sqrt_p_gme
	gen double c_star = sqrt_p_gme
	
	// Define support matrix (adjust bounds based on expected coefficients)
	matrix support = (-100, 0, 100 \ -100, 0, 100 \ -100,  0, 100)
	
	// Run GME linear regression
	gmentropylinear y_tilde_star X1_star X2_star c_star, ///
		nocons support(support) endpoint(25) nosigma sigmavalue(100)
	
	// Predict and compute ATT
	predict ghat_gme_, xb
	return scalar coef_X1_gme = _b[X1]
	return scalar coef_X2_gme = _b[X2]
	return scalar intercept_gme = _b[c_star]	
	gen ghat_gme = ghat_gme_ / sqrt_p_gme
	summarize ghat_gme if D==1, meanonly
	scalar att_gme_proj = r(mean)
	return scalar att_gme_proj = att_gme_proj

	
	summarize tau if D==1, meanonly
	scalar att_true = r(mean)
	return scalar att_true = att_true
end

simulate                                ///
    intercept_ls  = r(intercept_ls)    ///
    coef_X1_ls    = r(coef_X1_ls)       ///
    coef_X2_ls    = r(coef_X2_ls)       ///
    intercept_gme = r(intercept_gme)   ///
    coef_X1_gme   = r(coef_X1_gme)      ///
    coef_X2_gme   = r(coef_X2_gme),     ///
    reps(5000): collinear_case_h

* Compute bias and MSE for each coefficient
foreach est in ls gme {
    foreach coef in intercept coef_X1 coef_X2 {
        if "`coef'" == "intercept" {
            local true = 2.0
        }
        else if "`coef'" == "coef_X1" {
            local true = 0.8
        }
        else if "`coef'" == "coef_X2" {
            local true = -0.5
        }
        gen err_`coef'_`est' = `coef'_`est' - `true'
        summ err_`coef'_`est', meanonly
        scalar bias_`coef'_`est' = r(mean)
        gen sq_err_`coef'_`est' = (err_`coef'_`est')^2
        summ sq_err_`coef'_`est', meanonly
        scalar mse_`coef'_`est' = r(mean)
    }
}

* Display results in a table
display _newline "Coefficient Estimation Performance (50 reps)"
display "Estimator       Coefficient  Bias        MSE"
display "------------------------------------------"
foreach est in ls gme {
    if "`est'" == "ls" {
        local est_name "WLS"
    }
    else {
        local est_name "Weighted GME"
    }
    foreach coef in intercept coef_X1 coef_X2 {
        if "`coef'" == "intercept" {
            local coef_name "Intercept"
        }
        else if "`coef'" == "coef_X1" {
            local coef_name "X1"
        }
        else if "`coef'" == "coef_X2" {
            local coef_name "X2"
        }
        display "`est_name'       `coef_name'       " %9.5f bias_`coef'_`est' "  " %9.5f mse_`coef'_`est'
    }
}
