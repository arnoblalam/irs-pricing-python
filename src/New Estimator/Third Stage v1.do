/***********************************************************************
*  0.  HOUSE-KEEPING
***********************************************************************/
clear all
set seed 12345
set obs 2000

/***********************************************************************
*  1.  DATA-GENERATING PROCESS
***********************************************************************/
gen double x1 = rnormal()
gen double x2 = rnormal()

* true propensity score
gen double ps_true = invlogit(-.2 + 1.2*x1 -.8*x2)
gen byte   D       = rbinomial(1 , ps_true)

* potential-outcome shocks
gen double u0 = rnormal()
gen double u1 = rnormal()

gen double Y0  = 2 + .8*x1 + .4*x2 + u0
scalar  tau    = 1.5                     //
gen double tr  = .5*x1 - .2*x2           // untreated trend

gen double Y1  = Y0 + tr + tau*D + u1
gen double diff = Y1 - Y0

/***********************************************************************
*  2.  FIRST-STAGE WEIGHTS (ABADIE Eq. 10)
***********************************************************************/
logit D x1 x2
predict double phat, pr
gen double rho0 = phat/(1-phat)

/***********************************************************************
*  3.  SECOND-STAGE  —  GME PROJECTION
***********************************************************************/
preserve                       // ***keep the full sample for later***
    keep if D==0               // only controls enter the projection

    * transform y and X by √ weight
    gen double w       = phat
    gen double y_tilde = rho0*diff
    gen double y_w     = sqrt(w)*y_tilde

    foreach v of varlist x1 x2 {
        gen double w_`v' = sqrt(w)*`v'
    }

    * 3-point symmetric support (no intercept)
    matrix bsupp = (-5,0,5 \ -5,0,5)

    gmentropylinear                            ///
        y_w  w_x1  w_x2 ,                      ///
        support(bsupp)  nocons  sigmavalue(3)    // <- correct option names

    * store the coefficients **before** leaving the preserved frame
    matrix b  = e(b)            // 1×2 : (β₁ β₂)
restore                           // original dataset (treated + controls)

/***********************************************************************
*  4.  PREDICT ĝ(X)=X'β̂  AND AVERAGE OVER THE TREATED
***********************************************************************/
scalar b1 = b[1,1]
scalar b2 = b[1,2]

generate double ghat = b1*x1 + b2*x2

quietly mean ghat if D==1
display as text "Projected ATT (GME) = " %8.4f e(b)[1,1]
