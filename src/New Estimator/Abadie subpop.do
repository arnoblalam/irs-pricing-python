capture program drop att_subpop
program define att_subpop, rclass
    version 17.0
    syntax varlist(min=2 max=2)                /* varlist = pre post */
           [if] [in], Xk(string)               /* Xk = list of sub-pop vars */

    gettoken Y0 Y1 : varlist                   /* first var = pre, second = post */

    tempvar diff pscore rho ytilde ghat
    qui {
        /* 0. keep estimation sample */
        marksample touse

        /* 1. treatment indicator must already exist as D */
        gen double `diff' = `Y1' - `Y0'                 if `touse'
        /* 1. propensity ------------------------------------------------*/
        logit D X1 X2 `Xk'                              if `touse'
        predict double `pscore'                         if `touse', pr

        /* 2. pseudo-outcome for controls ------------------------------*/
        gen double `rho'    = `pscore'/(1-`pscore')     if `touse' & D==0
        gen double `ytilde' = `rho' * `diff'            if `touse' & D==0

        /* 3. weighted LS on controls ----------------------------------*/
        regress `ytilde' `Xk' [aw=`pscore']             if `touse' & D==0
        predict double `ghat'                           if `touse', xb

        /* 4. sub-population effects -----------------------------------*/
        tempvar subatt
        egen       `subatt' = mean(`ghat')              if `touse' & D==1
        scalar ATT_overall = `subatt'
        return scalar att_overall = ATT_overall

        /* If Xk contains dummies you can loop: */
        foreach g of varlist `Xk' {
            qui levelsof `g' if `touse', local(vals)
            foreach v of local vals {
                scalar att_`g'_`v' = ///
                       mean(`ghat'      ) if `touse' & D==1 & `g'==`v'
                return scalar att_`g'_`v' = att_`g'_`v'
            }
        }
    }
end

* variables:  Y_pre  Y_post  D  X1  X2  female
att_subpop Y_pre Y_post , xk(female)
return list   // shows overall ATT and ATT by gender

bootstrap r(att_overall) r(att_female_1) r(att_female_0)  ///
         , reps(999) seed(20250605): ///
         att_subpop Y_pre Y_post , xk(female)
