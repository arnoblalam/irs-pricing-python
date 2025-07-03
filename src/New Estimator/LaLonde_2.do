** Recreate results from experimental setup
* load the original data set and create some additional variables
clear
use "data/new_estimator/nsw.dta"
gen age2 = age*age
gen earnings_growth = re78 - re75

* Difference in differences wth control group
reg earnings_growth i.treat##(c.age c.age2 c.education i.nodegree i.married i.black i.hispanic), robust
