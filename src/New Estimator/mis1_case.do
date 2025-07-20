capture program drop altlink_case
program define altlink_case, rclass
    version 17.0
    syntax, [n(integer 500)]

    /* ---------- 1. DGP ---------- */
    clear
    set obs `n'
    gen X1 = rnormal()
    gen X2 = rnormal()

    gen eps0 = rnormal()
    gen eps1 = rnormal()
    gen base   = 5 + 0.5*X1 - 0.3*X2
    gen Y0     = base + eps0
    gen trend  = 0.4*X1 - 0.1*X2

    /* *** true link: complementary log-log *** */
    gen linpred = 0.5*X1 - 0.8*X2
    gen pscore  = 1 - exp(-exp(linpred))   // clog-log CDF
    gen D       = rbinomial(1, pscore)

    gen Y1   = base + trend + 2*D + eps1
    gen diff = Y1 - Y0

    /* ---------- 2. Estimation block ---------- */
    logit D X1 X2
    predict p_logit
    gen w_logit = (D-p_logit)/(p_logit*(1-p_logit))
    reg diff X1 X2 [pw=w_logit]
    return scalar att_logit = _b[_cons]

    gmentropylogit D X1 X2, generate(p_gme)
    gen w_gme = (D-p_gme)/(p_gme*(1-p_gme))
    reg diff X1 X2 [pw=w_gme]
    return scalar att_gme = _b[_cons]

    summarize diff if D
    scalar m1 = r(mean)
    summarize diff if !D
    scalar m0 = r(mean)
    return scalar att_classical = m1-m0
end



simulate att_logit=r(att_logit) att_gme=r(att_gme) att_classical=r(att_classical), reps(5000): altlink_case

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


twoway (kdensity att_classical) ///
       (kdensity att_gme) /// 
	   (kdensity att_logit), ///
       legend(label(1 "Unweighted") label(2 "Weighted using GME Logit") label(3 "Weighted using logit")) ///
	   xline(2) ///
	   text(0.4 2 "True ATT", orientation(vertical) place(ne)) ///
	   ytitle("Density") ///
	   xtitle("Estimated ATT") ///
	   title("ATT Estimators (clog-log link)")

