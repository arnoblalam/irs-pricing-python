*****************************************************
* Example: Generating ill-conditioned data for GME  *
*****************************************************
clear all
set more off

* 1. Create a small dataset with near-collinear X1, X2
set seed 12345
set obs 50

* X1 ~ N(0,1)
gen double X1 = rnormal(0,1)

* X2 is almost the same as X1, with tiny added noise
gen double X2 = X1 + rnormal(0, 1e-4)

* 2. Create a "dependent" variable, A, with very little net variation
*    so the design is nearly singular.
gen double A = X1 + X2 + rnormal(0,1)*1e-10

* 3. Define a 2 x 5 support matrix in Stata
mat define my_support = ///
(-5, -2.5, 0, 2.5, 5) \   ///
(-5, -2.5, 0, 2.5, 5) \ ///
(-5, -2.5, 0, 2.5, 5)

*****************************************************
* 4. Run your gmentropylinear command
*    (assuming gmentropylinear.ado is in ADOPATH)
*****************************************************
gmentropylinear A X1 X2, support(my_support) end(5)

* 5. Generate predictions and look at mean predicted "Ahat"
predict double Ahat, xb
summarize Ahat, mean
di "Mean predicted A: " r(mean)

*****************************************************
* 6. Compare outputs across Stata 15 vs Stata 17
*****************************************************
* You may see large or inconsistent coefficients, 
* or no convergence in one version versus the other.
