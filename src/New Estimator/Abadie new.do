set seed 123456
capture program drop simdid
*--- Write a simulation program ---*
program define simdid, rclass
    clear
    set obs 500

    /* 1. Generate covariate X */
    gen X1 = rnormal()
	gen X2 = X1 + rnormal(0, 0.001)

    /* 2. Generate treatment D with probability p_true = invlogit(0.2+0.5*X) */
	gen double u = rnormal(0,1)
    gen p_true = invlogit(3*X1 - 5*X2 + 2*u)
    gen D = (runiform() < p_true)

    /* 3. Generate outcomes 
           - Y0 is the baseline outcome at time 0
           - Y1_control is the counterfactual at time 1 if untreated;
             note the extra trend term (0.5*X) that makes trends nonparallel.
           - Y1 is the observed outcome at time 1.
       --------------
       Here, we set the treatment effect tau = 2.
    */
    gen e0 = rnormal(0.5*X1, 1)
    gen e1 = rnormal(0.5*X1, 1)
    gen Y0 = 1 + 0.3*X1 + 0.3*X2 + 0.2*D + e0
    gen trend = 0.5*X1      // additional trend component depending on X
    gen Y1_control = 1 + 2*X1 -2.5*X2 + trend + e1
    gen tau_i = 2 + 0.5*X1
    gen Y1 = Y1_control + D*tau_i
    
    /* Compute the difference in outcomes */
    gen dY = Y1 - Y0
	/* Calculate the trueATT */
	quietly summarize tau_i if D==1
	local trueATT = r(mean) - 0.2
    /* 4. Compute the naive DID estimator:
           naive = mean(dY | D=1) - mean(dY | D=0)
    */
    quietly summarize dY if D==1
    local dY_treated = r(mean)
    quietly summarize dY if D==0
    local dY_control = r(mean)
    local naive = `dY_treated' - `dY_control'

    /* 5. Estimate p(X) using logistic regression */
    quietly logit D X1 X2
    predict p_hat, pr

    /* 6. Compute the weight rho = (D - p_hat)/(1-p_hat) */
    gen rho = (D - p_hat)/(1 - p_hat)

    /* 7. Compute Abadie's semiparametric DID estimator:
           sp = [ (1/N) * sum_i { dY_i * rho_i } ] / (mean(D))
       (The denominator mean(D) is the sample analog of Pr(D=1)).
    */
    quietly summarize D
    local p_bar = r(mean)
	gen dydrho = dY * rho
    quietly summarize dydrho
    local sp_est = r(mean) / `p_bar'
	
	/* Estimate p(X) using GME */
	quietly gmentropylogit D X1 X2, gen(p_gme)
	gen rho_gme = (D - p_gme)/(1 - p_gme)
	gen dydrho_gme = dY * rho_gme
	quietly summarize dydrho_gme
	local sp_est_gme = r(mean) / `p_bar'

    /* Return the two estimators */
    return scalar sp = `sp_est'
    return scalar naive = `naive'
	return scalar gme = `sp_est_gme'
	return scalar trueATT = `trueATT'
end

/*--- Run the simulation (1000 replications) ---*/
simulate sp = r(sp) naive = r(naive) gme = r(gme) trueATT = r(trueATT), reps(1000) nodots: simdid

/*--- Now compare the performance ---*/
* For the semiparametric estimator:
quietly summarize trueATT
local mean_trueatt = r(mean)

summarize sp
local mean_sp = r(mean)
local var_sp  = r(Var)
local bias_sp =  `mean_sp' - `mean_trueatt'
local mse_sp  = (`bias_sp'^2) + `var_sp'
display "Semiparametric DID estimator:"
display "  Bias     = " %9.4f `bias_sp'
display "  Variance = " %9.4f `var_sp'
display "  MSE      = " %9.4f `mse_sp'

* For the naive DID estimator:
summarize naive
local mean_naive = r(mean)
local var_naive  = r(Var)
local bias_naive = `mean_naive' - `mean_trueatt'
local mse_naive  = (`bias_naive'^2) + `var_naive'
display "Naive DID estimator:"
display "  Bias     = " %9.4f `bias_naive'
display "  Variance = " %9.4f `var_naive'
display "  MSE      = " %9.4f `mse_naive'

*--- Kernel density plot for both estimators with a line at the true effect (2) ---
twoway (kdensity gme, range(0 4)) ///
       (kdensity sp, range(0 4)) ///
       (kdensity naive, range(0 4)) ///
       (function y = 0, range(0 4)), ///
       xline(`mean_trueatt', lpattern(dash)) ///
       text(1.5 1.4 "True ATT", placement(n) orientation(vertical) size(small)) ///
       scheme(lean2) ///
       legend(order(1 2 3) label(1 "GME") label(2 "Logit") ///
              label(3 "Uncorrected")) ///
       title("Estimator Performance: Baseline Case")

