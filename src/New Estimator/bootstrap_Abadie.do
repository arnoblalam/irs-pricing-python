***************************************************************
* 5. (OPTIONAL) BOOTSTRAP THE STANDARD ERRORS
***************************************************************
capture program drop my_abadie_estimator
program define my_abadie_estimator, rclass
    quietly {
        * Re-run the first-stage
        logit D X1 X2
        predict double ps, pr

        gen double diffY = Ypost - Ypre
        summarize D
        scalar pd1 = r(mean)

        gen double w_abadie = (D - ps)/(1 - ps)
        summarize diffY [aw=w_abadie], mean
        scalar ATT_Abadie = (1/pd1)*r(mean)

        drop diffY w_abadie ps

        return scalar att = ATT_Abadie
    }
end

bootstrap r(att), reps(200) nodots seed(20230101:100): ///
    my_abadie_estimator

display "Bootstrap-based estimate of ATT in r(att)."
display "Use 'return list' to see the stored results." */
