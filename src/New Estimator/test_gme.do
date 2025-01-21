********************************************************************************
* 1) Clear, set seed
********************************************************************************
clear all
set more off
set seed 123456

********************************************************************************
* 2) Define the simulation program for comparison
********************************************************************************
capture program drop sim_compare
program define sim_compare, rclass
    drop _all
    set obs 30
    
    // Covariates
*	matrix C = (1, 0.95, 0.90 \ 0.95, 1,    0.92 \ 0.90, 0.92, 1   )
*	drawnorm x1 x2 x3, corr(C) means(0 0 0) sds(1 1 1)
    gen x1 = rnormal(0,1)
    gen x2 = runiform()
    gen x3 = rnormal(2,1)

    
    // True coefficients
    local beta0 = 0.50
    local beta1 = 0.30
    local beta2 = -0.50
    local beta3 = 0.80
    
    // Generate linear predictor, probability, outcome
    gen linear_index = `beta0' + `beta1'*x1 + `beta2'*x2 + `beta3'*x3
    gen p = exp(linear_index)/(1 + exp(linear_index))
    
    gen u = runiform()
    gen y = (u < p)
    
    // Estimate via gmentropylogit
    quietly gmentropylogit y x1 x2 x3
    return scalar b0_ment = _b[_cons]
    return scalar b1_ment = _b[x1]
    return scalar b2_ment = _b[x2]
    return scalar b3_ment = _b[x3]
    
    // Estimate via logit
    quietly logit y x1 x2 x3
    return scalar b0_log = _b[_cons]
    return scalar b1_log = _b[x1]
    return scalar b2_log = _b[x2]
    return scalar b3_log = _b[x3]
end

********************************************************************************
* 3) Simulate 5,000 replications
********************************************************************************
simulate ///
    b0_ment = r(b0_ment) b1_ment = r(b1_ment) b2_ment = r(b2_ment) b3_ment = r(b3_ment) ///
    b0_log  = r(b0_log)  b1_log  = r(b1_log)  b2_log  = r(b2_log)  b3_log  = r(b3_log), ///
    reps(5000) nodots: sim_compare

********************************************************************************
* 4) Compare the distributions of the estimates
********************************************************************************
summarize b0_ment b1_ment b2_ment b3_ment ///
           b0_log  b1_log  b2_log  b3_log

* True values
local true_b0 = 0.50
local true_b1 = 0.30
local true_b2 = -0.50
local true_b3 = 0.80

foreach est in ment log {
    di "------------------------------------------------------------"
    di " Estimator: `est'"
    foreach v in b0 b1 b2 b3 {
        quietly summarize `v'_`est'
        local mean_ = r(mean)
        local sd_   = r(sd)
        
        // Identify the true value
        if "`v'" == "b0" {
            local true_val = `true_b0'
        }
        else if "`v'" == "b1" {
            local true_val = `true_b1'
        }
        else if "`v'" == "b2" {
            local true_val = `true_b2'
        }
        else if "`v'" == "b3" {
            local true_val = `true_b3'
        }

        local bias = `mean_' - `true_val'
        local var  = `sd_'^2
        
        di "  Parameter: `v' (true = `true_val')"
        di "    Mean estimate: `mean_'"
        di "    Bias         : `bias'"
        di "    Variance     : `var'"
        di " "
    }
}
di "------------------------------------------------------------"
