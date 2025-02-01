clear
use "/data/new_estimator/nsw.dta"
append using "/data/new_estimator/cps_controls3.dta"
gen wg_growth = re78 - re75
gen age2 = age*age
drop if data_id == "Lalonde Sample" & treat == 0
reg wg_growth treat age age2 education black hispanic married nodegree, robust
gmentropylogit treat age age2 education black hispanic married nodegree, gen(ps_gme)
gen double rho0_gme = (treat - ps_gme)/(ps_gme*(1 - ps_gme))
gen double intermediate_gme = rho0_gme * wg_growth  * ps_gme
summarize intermediate_gme, meanonly
scalar unscaled_gme = r(mean)
summarize treat, meanonly
scalar pd1 = r(mean)
scalar ATT_gme = (1/pd1) * unscaled_gme
di ATT_gme
reg wg_growth treat
