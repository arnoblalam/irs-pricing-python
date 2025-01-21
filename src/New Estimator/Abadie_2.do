***************************************************************************
* Synthetic repeated cross-sections to illustrate Abadie (2005) semiparam DiD
***************************************************************************
clear all
set seed 12345
set obs 100

********************************************************************************
* 1. Data generation
********************************************************************************
gen X = rnormal(0,1)

// Probability of being treated
gen double pD_X = 1/(1 + exp(-0.5*X))
gen double uD   = runiform()
gen byte   D    = (uD < pD_X)

// Fraction of post observations = lambda
local lambda = 0.40
gen double uT = runiform()
gen byte T    = (uT < `lambda')

// Potential outcomes
gen double e     = rnormal(0,1)
gen double gamma = 1
gen double tau   = 2

gen double Y0_0 = 5 + 0.8*X + e
gen double Y0_1 = Y0_0 + gamma
gen double Y1_1 = Y0_1 + tau

gen double Y = .
replace Y = Y0_0 if T==0
replace Y = Y0_1 if T==1 & D==0
replace Y = Y1_1 if T==1 & D==1

********************************************************************************
* 2. First step: estimate Pr(D=1|X) via gmentropylogit
********************************************************************************
gmentropylogit D X, generate(phat)

********************************************************************************
* 3. Construct Abadie's rho_0 = [(T-lambda)/(lambda*(1-lambda))]*[(D-phat)/(phat*(1-phat))]
********************************************************************************
gen double rho_0 = (T - `lambda') / (`lambda'*(1 - `lambda')) * (D - phat)/(phat*(1-phat))

********************************************************************************
* 4. Multiply by [p(X)/p] and take mean with Y
*    => E( wvar * Y ) = E[Y^1(1)-Y^0(1)|D=1].
********************************************************************************
summarize D, meanonly
local pD = r(mean)

gen double wvar = (phat / `pD') * rho_0
gen double wY   = wvar * Y
summarize wY

di as txt "Estimated DiD effect among the treated = " as result r(mean)

****************************************************************************
* 0. We assume you have these variables from your data:
*    - T, D, X, Y
*    - phat = Pr(D=1|X) from gmentropylogit
*    - lambda   (the fraction of post obs in your sample)
*    - rho_0    = (T-lambda)/(lambda(1-lambda)) * (D - phat)/(phat*(1-phat))
****************************************************************************

* Let’s define the weight as w = p(X) = phat
gen double w = phat
summarize w

* For demonstration, define the dependent variable as (rho_0 - Y)
* (One might use (rho_0 - Y) or (rho_0 - something) based on Abadie’s derivations)
gen double depvar = rho_0 - Y

****************************************************************************
* 1. Create polynomials in X
****************************************************************************
gen double X2 = X^2
* you could go higher order if you like, or do splines, interactions, etc.

****************************************************************************
* 2. Now define the sqrt-weight
****************************************************************************
gen double sqrt_w = sqrt(w)

****************************************************************************
* 3. Multiply the dependent variable and the regressors by sqrt_w
*    We also create a 'cons_w' for the intercept (since we’ll use nocons).
****************************************************************************
gen double depvar_w = depvar * sqrt_w
gen double X_w      = X      * sqrt_w
gen double X2_w     = X2     * sqrt_w
gen double cons_w   = sqrt_w

****************************************************************************
* 4. Provide a support() matrix to gmentropylinear
*    Suppose we have 3 coefficients: (Intercept, Beta1, Beta2).
*    We choose a 3 x M matrix of supports, e.g., M=3 with points (-10,0,10).
****************************************************************************
matrix mysupport = ( -10, 0, 10 \  ///
                     -10, 0, 10 \  ///
                     -10, 0, 10 )

****************************************************************************
* 5. Run gmentropylinear with no constant, but including cons_w as if it were a regressor
****************************************************************************
gmentropylinear depvar_w cons_w X_w X2_w, ///
    support(mysupport) nocons

* The output will be GME estimates of [cons_w, X_w, X2_w] coefficients,
* which correspond to (Intercept, Beta1, Beta2) once we adjust for the scale in sqrt_w.

****************************************************************************
* 6. Interpret the results
****************************************************************************
* The fitted values from this model: 
*   fitted_g(X) = Beta0 + Beta1*X + Beta2*X^2
* approximate E[(rho_0 - Y) | X,D=1].
*
* Rearranging can give you an estimate of E[Y^1(1) - Y^0(1)| X,D=1],
* depending on which side you put Y or rho_0 in Abadie’s formula.
*
* You might predict from gmentropylinear to get the predicted function:
predict double ghat, xb
* but remember it’s in the weighted space. Typically we reconstruct
* the unweighted “g(X)” by just using the raw Beta’s from the coefficient table.

