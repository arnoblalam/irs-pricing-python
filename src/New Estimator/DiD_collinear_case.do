set seed 12345
capture program drop baseline_case
program define baseline_case, rclass
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
    gen Y1 = base + trend + 2*D + eps1
    gen diff = Y1 - Y0

    * Logit estimate of ATT
    logit D X1 X2
    predict p_logit
	estat classification
	scalar correct_logit = r(P_corr)
	roctab D p_logit, nod
	scalar auc_logit  = r(area)
	return scalar b0_logit = _b[_cons]
    return scalar b1_logit = _b[X1]
    return scalar b2_logit = _b[X2]
    scalar b_rmse_logit = sqrt( (_b[_cons] - 0.0)^2 + (_b[X1]-0.5)^2 + (_b[X2]+0.8)^2 )
    return scalar b_rmse_logit = b_rmse_logit

	gen w_logit = (D - p_logit) / (1 - p_logit)
	gen double num = diff * w_logit
	summarize num
	scalar lambda = r(mean)
	summ D, meanonly
	scalar att_logit = lambda / r(mean)
    return scalar att_logit = att_logit
    return scalar auc_logit   = auc_logit
	return scalar miss_logit = 100 - correct_logit

    * GME estimate of ATT
    gmentropylogit D X1 X2, generate(p_gme)
	scalar correct_gme = e(pred)
	roctab D p_gme, nod
	scalar auc_gme   = r(area)
    return scalar b0_gme = _b[_cons]
    return scalar b1_gme = _b[X1]
    return scalar b2_gme = _b[X2]
    scalar b_rmse_gme = sqrt( (_b[_cons]-0.0)^2 + (_b[X1]-0.5)^2 + (_b[X2]+0.8)^2 )
    return scalar b_rmse_gme = b_rmse_gme
    gen w_gme = (D - p_gme) / (1 - p_gme)
	gen double num2 = diff * w_gme
	summarize num2
	scalar lambda = r(mean)
	summ D, meanonly
	scalar att_gme = lambda / r(mean)
    return scalar att_gme = att_gme
    return scalar auc_gme     = auc_gme
	return scalar miss_gme = 100 - correct_gme
	
    * Unconditional (classical DiD-style) ATT
    summarize diff if D==1
    scalar m1 = r(mean)
    summarize diff if D==0
    scalar m0 = r(mean)
    return scalar att_classical = m1 - m0
end


simulate b0_logit = r(b0_logit) b1_logit=r(b1_logit) b2_logit=r(b2_logit) ///
	b_rmse_logit=r(b_rmse_logit)  b0_gme = r(b0_gme) b1_gme=r(b1_gme) b2_gme=r(b2_gme) ///
	b_rmse_gme=r(b_rmse_gme) att_classical = r(att_classical) ///
	miss_gme = r(miss_gme) auc_gme = r(auc_gme) att_gme = r(att_gme) ///
	miss_logit = r(miss_logit) att_logit = r(att_logit) auc_logit = r(auc_logit), ///
	reps(5000): baseline_case

gen bias_logit = att_logit - 2
gen bias_gme   = att_gme   - 2
gen bias_classical = att_classical - 2

* Logit metrics
summarize bias_logit
scalar bias_logit = r(mean)
scalar var_logit  = r(Var)
scalar mse_logit  = bias_logit^2 + var_logit

* GME metrics
summarize bias_gme
scalar bias_gme = r(mean)
scalar var_gme  = r(Var)
scalar mse_gme  = bias_gme^2 + var_gme

* classical DiD metrics
summarize bias_classical
scalar bias_classical = r(mean)
scalar var_classical  = r(Var)
scalar mse_classical  = bias_classical^2 + var_classical

display "Logit: Bias = " bias_logit ", Variance = " var_logit ", MSE = " mse_logit
display "GME:   Bias = " bias_gme   ", Variance = " var_gme   ", MSE = " mse_gme
display "Classical:   Bias = " bias_classical   ", Variance = " var_classical   ", MSE = " mse_classical

* Calculate bias and MSE for logit coefficients
gen bias_b0_logit = b0_logit - 0.0
gen bias_b1_logit = b1_logit - 0.5
gen bias_b2_logit = b2_logit - (-0.8)
summarize bias_b0_logit
scalar bias_b0_logit = r(mean)
scalar var_b0_logit = r(Var)
scalar mse_b0_logit = bias_b0_logit^2 + var_b0_logit
summarize bias_b1_logit
scalar bias_b1_logit = r(mean)
scalar var_b1_logit = r(Var)
scalar mse_b1_logit = bias_b1_logit^2 + var_b1_logit
summarize bias_b2_logit
scalar bias_b2_logit = r(mean)
scalar var_b2_logit = r(Var)
scalar mse_b2_logit = bias_b2_logit^2 + var_b2_logit
scalar mse_logit_combined = mse_b0_logit + mse_b1_logit + mse_b2_logit

* Calculate bias and MSE for GME coefficients
gen bias_b0_gme = b0_gme - 0.0
gen bias_b1_gme = b1_gme - 0.5
gen bias_b2_gme = b2_gme - (-0.8)
summarize bias_b0_gme
scalar bias_b0_gme = r(mean)
scalar var_b0_gme = r(Var)
scalar mse_b0_gme = bias_b0_gme^2 + var_b0_gme
summarize bias_b1_gme
scalar bias_b1_gme = r(mean)
scalar var_b1_gme = r(Var)
scalar mse_b1_gme = bias_b1_gme^2 + var_b1_gme
summarize bias_b2_gme
scalar bias_b2_gme = r(mean)
scalar var_b2_gme = r(Var)
scalar mse_b2_gme = bias_b2_gme^2 + var_b2_gme
scalar mse_gme_combined = mse_b0_gme + mse_b1_gme + mse_b2_gme

* Display results
display "Logit Coefficients:"
display "Cons: Bias =" bias_b0_logit ", Variance = " var_b0_logit ", MSE = " mse_b0_logit
display "X1: Bias = " bias_b1_logit ", Variance = " var_b1_logit ", MSE = " mse_b1_logit
display "X2: Bias = " bias_b2_logit ", Variance = " var_b2_logit ", MSE = " mse_b2_logit
display "Combined MSE (sum of individual MSEs) = " mse_logit_combined

display "GME Coefficients:"
display "Cons: Bias = " bias_b0_gme ", Variance = " var_b0_gme ", MSE = " mse_b0_gme
display "X1: Bias = " bias_b1_gme ", Variance = " var_b1_gme ", MSE = " mse_b1_gme
display "X2: Bias = " bias_b2_gme ", Variance = " var_b2_gme ", MSE = " mse_b2_gme
display "Combined MSE (sum of individual MSEs) = " mse_gme_combined

twoway (kdensity att_classical) ///
       (kdensity att_gme) /// 
	   (kdensity att_logit), ///
       legend(label(1 "Unweighted") label(2 "Weighted using GME Logit") label(3 "Weighted using logit")) ///
	   xline(2) ///
	   text(0.4 2 "True ATT", orientation(vertical) place(ne)) ///
	   ytitle("Density") ///
	   xtitle("Estimated ATT") ///
	   title("Sampling Distributions of ATT Estimators (collinear case)")
