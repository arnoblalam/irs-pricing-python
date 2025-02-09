** Recreate results from experimental setup
* load the original data set and create some additional variables
clear
use "data/new_estimator/nsw.dta"
gen age2 = age*age
gen earnings_growth = re78 - re75


* Difference between control and experimental group earnings in 1978
reg re78 treat //unadjusted
reg re78 treat age age2 education nodegree black hispanic, robust //adjusted

* Difference in differences wth control group
reg earnings_growth treat, robust // not age unadjusted
reg earnings_growth treat age age2, robust // age adjusted

* Unrestriceted difference-in-differences (quasi earnings growth)
reg re78 treat re75 // unadjusted
reg re78 treat age age2 education nodegree black hispanic re75, robust // adjusted


clear
use "data/new_estimator/nsw.dta" // Load LaLonde's original experimental data
append using "data/new_estimator/psid_controls.dta" //Append the data Current Population Sample (CPS) pseudo-control

* Drop the experimental control group (use the CPS sample as control instead)
drop if data_id == "Lalonde Sample" & treat == 0

* Generate earnings growth and age^2 columns
gen earnings_growth = re78 - re75
gen age2 = age*age

* Difference between experimental and PSID group earnings in 1978
reg re78 treat //unadjusted
reg re78 treat age age2 education nodegree black hispanic, robust //adjusted

* Difference in differences wth PSID group
reg earnings_growth treat, robust // not age unadjusted
reg earnings_growth treat age age2, robust // age adjusted

* Unrestriceted difference-in-differences (quasi earnings growth)
reg re78 treat re75 // unadjusted
reg re78 treat age age2 education nodegree black hispanic re75, robust // adjusted

* Matching
capture program drop att_gme_boot
program define att_gme_boot, rclass
	gmentropylogit treat age age2 education black hispanic married nodegree, gen(ps_gme)
	gen double rho0_gme = (treat - ps_gme)/(ps_gme*(1 - ps_gme))
	gen double intermediate_gme = rho0_gme * earnings_growth  * ps_gme
	summarize intermediate_gme, meanonly
	scalar unscaled_gme = r(mean)
	summarize treat, meanonly
	scalar pd1 = r(mean)
	scalar ATT_gme = (1/pd1) * unscaled_gme
	return scalar att = ATT_gme
	drop rho0_gme intermediate_gme ps_gme  // Clean up generated variables
end

bootstrap ATT_gme = r(att), reps(1000) seed(12345): att_gme_boot
estat bootstrap, all
