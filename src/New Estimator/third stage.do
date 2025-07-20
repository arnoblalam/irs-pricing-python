*****************************************************
* 1.  CREATE A DATA SET -------------------------
*****************************************************
clear all
set seed 12345
set obs 2000                       // # individuals

* -- covariates ----------------------------------------------------
gen x1 = rnormal()
gen x2 = rnormal()

* -- treatment assignment -----------------------------------------
*   true propensity score (logit link) – feel free to change
gen ps_true = invlogit(-0.2 + 1.2*x1 - 0.8*x2)
gen D       = rbinomial(1, ps_true)

* -- potential outcomes & realised outcomes -----------------------
gen  u0  = rnormal()
gen  u1  = rnormal()
gen  Y0  = 2 + 0.8*x1 + 0.4*x2 + u0                 // baseline
gen  τ   = 1.5                                      // constant TE
gen  trd = 0.5*x1 - 0.2*x2                          // untreated trend

gen  Y1  = Y0 + trd + τ*D + u1                      // post-period outcome
gen  diff = Y1 - Y0                                 // ΔY  (observed)

*****************************************************
* 2.  ESTIMATE THE OVERALL ATT  (Eq. 10 in Abadie) --
*****************************************************
* 2a. first-step: propensity score
logit D x1 x2
predict phat, pr

* 2b. ρ₀(X)  ≡ P(D=1|X) / (1−P(D=1|X))   for the untreated          (Abadie, p. 8)  
gen rho0 = phat/(1-phat)

* 2c. ATT̂  = E[ΔY | D=1]  –  E[ρ₀(X)·ΔY | D=0]                      (Eq. 10)  
quietly sum diff if D==1
scalar ATT_treated = r(mean)

quietly sum diff if D==0 [aw = rho0]              // weight *only* controls
scalar ATT_controls = r(mean)

scalar ATT_abadie = ATT_treated - ATT_controls
di as txt "Abadie (2005) ATT estimate = " as res %8.4f ATT_abadie

*****************************************************
* 3.  HETEROGENEOUS EFFECTS  (Proposition 3.1) -----
*     Least-squares projection g(X;θ)=X'θ on the treated support
*****************************************************
* 3a. construct the transformed outcome    ρ₀(X)·ΔY   (only for D==0)
gen y_star = rho0*diff
* 3b. weight by P(D=1|X)  (phat) and keep *untreated* obs only
reg y_star x1 x2 if D==0 [aw = phat]

* 3c. β̂ contains θ̂  – use it to get the effect for any sub-group.
predict ghat, xb                           // ĝ(X)=X'β̂
* average effect for the treated sub-sample
quietly summarize ghat if D==1
local todis r(mean)
di as txt "Projected ATT for the treated = "  as res %8.4f r(mean)

* example: ATT for females vs males, if x2 is gender  (swap as needed)
* quietly mean ghat if D==1 & x2==0
* quietly mean ghat if D==1 & x2==1
*****************************************************
* DONE
*****************************************************
