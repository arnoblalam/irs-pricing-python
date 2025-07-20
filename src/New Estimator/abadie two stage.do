************************************************************************
*  baseline_case  —  now with second-stage projections                 *
************************************************************************
capture program drop baseline_case
program define baseline_case, rclass
    version 17.0
    syntax, [n(integer 500) SIGma(real 5)]     // sigma = GME support half-width

    *-----------------------------
    * 0.  SIMULATE THE DATA
    *-----------------------------
    clear
    set obs `n'
    gen double X1 = rnormal()
    gen double X2 = rnormal()
    gen double eps0 = rnormal()
    gen double eps1 = rnormal()

    gen double base   = 5  + .5*X1 -.3*X2
    gen double Y0     = base + eps0
    gen double trend  = .4*X1 -.1*X2
    gen double linpred = .5*X1 -.8*X2
    gen double pscore  = invlogit(linpred)
    gen byte   D       = rbinomial(1, pscore)

    gen double Y1   = base + trend + 2*D + eps1   // TE = 2
    gen double diff = Y1 - Y0                     // ΔY

    *-------------------------------------------------
    * 1.  ABADIE FIRST-STAGE  (logit & GME weights)
    *-------------------------------------------------
    *-------- logit weights
    logit D X1 X2
    predict double p_logit
    gen double rho0_logit = p_logit/(1-p_logit)          // ρ₀(X)

    gen double w_logit = (D - p_logit)/(p_logit*(1-p_logit))
    regress diff X1 X2 [pw=w_logit]
    return scalar att_logit = _b[_cons]

    *-------- GME weights  (first-stage prop score via gmentropylogit)
    gmentropylogit D X1 X2, generate(p_gme)
    gen double rho0_gme = p_gme/(1-p_gme)

    gen double w_gme = (D - p_gme)/(p_gme*(1-p_gme))
    regress diff X1 X2 [pw=w_gme]
    return scalar att_gme = _b[_cons]

    *-------- classical diff-in-means
    summarize diff if D==1, meanonly
    scalar m1 = r(mean)
    summarize diff if D==0, meanonly
    scalar m0 = r(mean)
    return scalar att_classical = m1 - m0

    ******************************************************************
    * 2.  SECOND-STAGE "HETEROGENEITY" PROJECTION
    ******************************************************************
    * 2A.  OLS projection (built on the logit scores)  ---------------
    preserve
        keep if D==0                       // only controls enter regression
        gen double wP  = p_logit
        gen double y_t = rho0_logit*diff
        gen double y_w = sqrt(wP)*y_t
        foreach v of varlist X1 X2 {
            gen double w_`v' = sqrt(wP)*`v'
        }
        regress y_w w_X1 w_X2, noconstant
        matrix bls = e(b)
    restore
    gen double ghat_ls = bls[1,1]*X1 + bls[1,2]*X2
    quietly summarize ghat_ls if D==1, meanonly
    return scalar att_lsproj = r(mean)

    * 2B.  GME projection (information-theoretic)  -------------------
    preserve
        keep if D==0
        gen double wP  = p_gme
        gen double y_t = rho0_gme*diff
        gen double y_w = sqrt(wP)*y_t
        foreach v of varlist X1 X2 {
            gen double w_`v' = sqrt(wP)*`v'
        }

        * 3-point symmetric support ±`sigma`
        matrix bsupp = (-`sigma',0,`sigma' \ -`sigma',0,`sigma')
        gmentropylinear y_w w_X1 w_X2, support(bsupp) nocons
        matrix bgme = e(b)
    restore
    gen double ghat_gme = bgme[1,1]*X1 + bgme[1,2]*X2
    quietly summarize ghat_gme if D==1, meanonly
    return scalar att_gmeproj = r(mean)
end
set seed 12345
simulate                         ///
       att_logit   = r(att_logit) ///
       att_gme     = r(att_gme)   ///
       att_classic = r(att_classical) ///
       att_lsproj  = r(att_lsproj) ///
       att_gmeproj = r(att_gmeproj), ///
       reps(50): baseline_case, n(500)
	   
local trueATT 2

foreach v of varlist att_* {
    * bias
    gen double bias_`v' = `v' - `trueATT'
    summarize bias_`v', meanonly
    scalar b_`v'   = r(mean)

    * variance
    summarize `v', meanonly
    scalar var_`v' = r(Var)

    * MSE = bias^2 + var
    scalar mse_`v' = (b_`v')^2 + var_`v'

    * single‐line display with properly balanced quotes
    di "`v':  Bias=" %9.4f b_`v' "  Var=" %9.4f var_`v' "  MSE=" %9.4f mse_`v'"
}




