set seed 12345
capture program drop baseline_rand
program define baseline_rand, rclass
    version 17.0
    syntax, [n(integer 500)]

    /* 1.  Draw one set of true coefficients --------------------------- */
    * ranges are illustrative – tweak to taste
    local bX1_base   = 0.3  + 0.4*runiform()        // U(0.3 , 0.7)
    local bX2_base   = -0.5 + 0.4*runiform()        // U(-0.5, -0.1)
    local bX1_trend  = 0.2  + 0.4*runiform()        // U(0.2 , 0.6)
    local bX2_trend  = -0.3 + 0.4*runiform()        // U(-0.3,  0.1)
    local bX1_sel    = 0.3  + 0.4*runiform()        // U(0.3 , 0.7)
    local bX2_sel    = -1.0 + 0.4*runiform()        // U(-1.0, -0.6)

    /* 2.  Generate one sample ----------------------------------------- */
    clear
    set obs `n'
    gen X1 = rnormal()
    gen X2 = rnormal()
    gen eps0 = rnormal()
    gen eps1 = rnormal()

    gen base   = 5 + `bX1_base'*X1 + `bX2_base'*X2
    gen Y0     = base + eps0
    gen trend  = `bX1_trend'*X1 + `bX2_trend'*X2
    gen linpred = `bX1_sel'*X1  + `bX2_sel'*X2
    gen pscore  = invlogit(linpred)
    gen D       = rbinomial(1, pscore)

    gen Y1   = base + trend + 2*D + eps1
    gen diff = Y1 - Y0

    /* 3.  Estimators --------------------------------------------------- */
    logit D X1 X2
    predict p_logit
    gen w_logit = (D-p_logit)/(p_logit*(1-p_logit))
    regress diff X1 X2 [pw=w_logit]
    return scalar att_logit = _b[_cons]

    gmentropylogit D X1 X2, generate(p_gme)
    gen w_gme = (D-p_gme)/(p_gme*(1-p_gme))
    regress diff X1 X2 [pw=w_gme]
    return scalar att_gme = _b[_cons]

    summarize diff if D==1
    scalar m1 = r(mean)
    summarize diff if D==0
    scalar m0 = r(mean)
    return scalar att_classical = m1 - m0
end

simulate att_logit=r(att_logit) att_gme=r(att_gme) att_classical=r(att_classical), reps(5000): baseline_rand

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
	   title("Sampling Distributions of ATT Estimators (random params)")
