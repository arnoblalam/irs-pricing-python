***************************************************************
***   Example: Abadie's Two-Step DiD with X-dependent P(D=1) ***
***************************************************************

clear all
set more off

***************************************************************
* 1. CREATE A DATASET OF 500 OBSERVATIONS
*    WITH TREATMENT PROBABILITY THAT DEPENDS ON X0, X1, X2
***************************************************************
set seed 12345
set obs 500

gen id = _n

* Generate two covariates X1, X2
gen X1 = rnormal(0,1)
gen X2 = rnormal(0,1)

* Define the true propensity to treat as logistic in X1, X2:
* p_i = 1 / (1 + exp( -[beta0 + beta1*X1 + beta2*X2] ))
* Let's pick some betas, e.g. beta0 = 0, beta1=0.7, beta2=-0.7
gen double p = invlogit(0.7*X1 - 0.7*X2)

* Randomly assign D from the Bernoulli(p)
gen D = (runiform() < p)

* Now we have ~some fraction~ of treated units, depending on X1, X2.

***************************************************************
* 2. GENERATE PRE AND POST OUTCOMES
***************************************************************
* Let's define a 'true' post-period treatment effect of +2 for D=1.
* The baseline depends on X1, X2, plus random noise.

gen double e_pre  = rnormal(0,1)
gen double e_post = rnormal(0,1)

* Pre-treatment outcome: Ypre = 1 + 0.3*X1 + 0.3*X2 + error
gen Ypre  = 1 + 0.3*X1 + 0.3*X2 + e_pre

* Post-treatment outcome:
*   Ypost = (same structure) + 2*D + error
gen Ypost = 3 + 0.3*X1 + 0.3*X2 + 2*D + e_post

* Difference between pre and post
gen double diffY = Ypost - Ypre


* Quick look at first 10 observations
list id D p X1 X2 Ypre Ypost diffY in 1/10, abbrev(16)

***************************************************************
* 3. FIRST STAGE: ESTIMATE PROPENSITY SCORE Pr(D=1 | X)
***************************************************************
* gmentropylogit D X1 X2, gen(ps)

logit D X1 X2
predict double ps, pr   // Store predicted P(D=1|X) in 'ps'

***************************************************************
* 4. SECOND STAGE: ABADIE'S DID ESTIMATOR UNCONDTIONAL
***************************************************************

* 4a) Sample estimate of Pr(D=1)
summarize D, mean
scalar pd1 = r(mean)  // fraction treated in sample

* 4b) Abadie weighting function: (D - ps) / (1 - ps)
gen double rho0 = (D - ps)/(ps*(1 - ps))

gen double rho0_w = (D - ps) / max(ps*(1-ps), 0.1)

* 4c) Form product of w_abadie and Y
gen double intermediate = rho0 * diffY * ps

summarize intermediate, mean
scalar unscaled = r(mean)
scalar ATT = (1/pd1) * unscaled
di ATT

* Alternative calculation technique
gen psi = (D-ps)/(1-ps)
gen itermediate_ = (diffY)/pd1 * psi
summarize itermediate_, mean
scalar ATT_alt = r(mean)
di ATT_alt

/*
* 4d) Weighted mean of diffY, scaled by 1 / pd1
summarize diffY [iw=w_abadie], mean
scalar unscaled = r(mean)
scalar ATT_Abadie = (1/pd1)*unscaled

display "=============================================="
display "Abadie's semiparametric DiD estimate of ATT = " ATT_Abadie
display "=============================================="
*/

***********************************************************************
* 5. SECOND STAGE: ABADIE'S DID ESTIMATOR CONDITIONAL ON COVARIATES   *
************************************************************************
gen double A = rho0*diffY
gen double A_w = rho0_w * diffY
* regress A X1 X2
matrix my_support = 	///
(-3, -1.5, 0, 1.5, 3)\	///
(-3, -1.5, 0, 1.5, 3) \	///
(-3, -1.5, 0, 1.5, 3)
my_gmentropylinear A_w X1 X2, sup(my_support) end(5)
predict double Ahat, xb
summarize Ahat, mean
scalar conditional_ATT = r(mean)
di conditional_ATT

*****************************************************************************
* 7. Summary                                                                *
*****************************************************************************
di "Unconditional ATT"
di ATT
di "Conditional ATT"
di conditional_ATT