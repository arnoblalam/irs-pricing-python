
*************Manuscript title: Green finance and job creation: Analyzing employment effects in China's manufacturing industry within green finance innovation and reform pilot zones************
*************Authors: Bowen Fu, Yixiang Zhang, Sholeh Maani, Le Wen****************

use "Data.dta"
gen treat = inlist( City , "昌吉回族自治州", "湖州市", "广州市","衢州市","赣江新区","贵安新区","哈密市","克拉玛依市")
gen t=year>=2017
gen did=t*treat
xtset id year
gen Em=ln(Numberofemployee)

******Table 1
sum Em did Size Age ROE Lev Tobin OC FAR

******Table 2
xtreg Em did Size Age ROE Lev Tobin OC FAR, r
xtreg Em did Size Age ROE Lev Tobin OC FAR,fe r
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year,fe r
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic,fe r
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov,fe r

******Fig. 1
gen Dyear = year-2017
gen Before5 = (Dyear==-5&treat==1)
gen Before4 = (Dyear==-4&treat==1)
gen Before3 = (Dyear==-3&treat==1)
gen Before2 = (Dyear==-2&treat==1)
gen Before1 = (Dyear==-1&treat==1)
gen Current = (Dyear==0&treat==1)
gen After1 = (Dyear==1&treat==1)
gen After2 = (Dyear==2&treat==1)
gen After3 = (Dyear==3&treat==1)
gen After4 = (Dyear==4&treat==1)

global KZ "Size Age ROE Lev Tobin OC FAR"
xtreg Em Before4 Before3 Before2 Current After1 After2 After3 After4 $KZ i.year i.sic i.Prov,fe robust
est sto reg
coefplot reg,keep(Before4 Before3 Before2 Current After1 After2 After3 After4) vertical recast(connect) yline(0)

******Table 3 and Fig. 2
set seed 10101
gen tmp = runiform()
sort tmp
psmatch2 treat Size Age ROE Lev Tobin OC FAR,outcome(Em) kernel ate ties logit common quietly
pstest Size Age ROE Lev Tobin OC FAR, both graph
psgraph

******Table 4
gen common=_support
drop if common==0
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov, fe r

winsor2 Em Size Age ROE Lev Tobin OC FAR, cut(1 99) replace
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov, fe r

******Fig. 3
clear all
use "Data.dta"
gen treat = inlist( City , "昌吉回族自治州", "湖州市", "广州市","衢州市","赣江新区","贵安新区","哈密市","克拉玛依市")
gen t=year>=2017
gen did=t*treat
xtset id year
gen Em=ln(Numberofemployee)
xtset id year
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov,fe r
cap erase "simulations.dta"
permute did beta = _b[did] se = _se[did] df = e(df_r), reps(500) rseed(150) saving("simulations.dta"): xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov, fe r
use "simulations.dta", clear
gen t_value  = beta / se
gen p_value = 2 * ttail(df, abs(beta/se))
dpplot beta, xline(0, lc(black*0.5) lp(dash)) xline(0, lc(black*0.5) lp(solid))xtitle("estimator", size(*0.8)) ytitle("Density",size(*0.8))
dpplot t_value, xtitle("t-value", size(*0.8)) ytitle("Density",size(*0.8))
twoway (scatter p_value beta)(kdensity beta, yaxis(2)), xline(0) yline(0.1)

******Table 5
clear all
use "Data.dta"
gen treat = inlist( City , "昌吉回族自治州", "湖州市", "广州市","衢州市","赣江新区","贵安新区","哈密市","克拉玛依市")
gen t=year>=2017
gen did=t*treat
xtset id year
gen Em=ln(Numberofemployee)
xtset id year
xtreg FC_index did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov, fe r
xtreg Em did FC_index Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov, fe r

******Table 6
clear all
use "Data.dta"
gen treat = inlist( City , "昌吉回族自治州", "湖州市", "广州市","衢州市","赣江新区","贵安新区","哈密市","克拉玛依市")
gen t=year>=2017
gen did=t*treat
xtset id year
gen Em=ln(Numberofemployee)
xtset id year
drop if Stateowned == 1
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov,fe r

clear all
use "Data.dta"
gen treat = inlist( City , "昌吉回族自治州", "湖州市", "广州市","衢州市","赣江新区","贵安新区","哈密市","克拉玛依市")
gen t=year>=2017
gen did=t*treat
xtset id year
gen Em=ln(Numberofemployee)
xtset id year
drop if Stateowned == 0
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov,fe r

clear all
use "Data.dta"
gen treat = inlist( City , "昌吉回族自治州", "湖州市", "广州市","衢州市","赣江新区","贵安新区","哈密市","克拉玛依市")
gen t=year>=2017
gen did=t*treat
xtset id year
gen Em=ln(Numberofemployee)
xtset id year
keep if sic == 4 | sic == 8 | sic == 11 | sic == 13 | sic == 14 | sic == 15 | sic == 16 | sic == 17
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov,fe r

clear all
use "Data.dta"
gen treat = inlist( City , "昌吉回族自治州", "湖州市", "广州市","衢州市","赣江新区","贵安新区","哈密市","克拉玛依市")
gen t=year>=2017
gen did=t*treat
xtset id year
gen Em=ln(Numberofemployee)
xtset id year
drop if sic == 4 | sic == 8 | sic == 11 | sic == 13 | sic == 14 | sic == 15 | sic == 16 | sic == 17
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov,fe r

clear all
use "Data.dta"
gen treat = inlist( City , "昌吉回族自治州", "湖州市", "广州市","衢州市","赣江新区","贵安新区","哈密市","克拉玛依市")
gen t=year>=2017
gen did=t*treat
xtset id year
gen Em=ln(Numberofemployee)
xtset id year
keep if sic == 11 | sic == 12 | sic == 13 | sic == 14 | sic == 16 | sic == 17 | sic == 19 | sic == 20 | sic == 21 | sic == 22 | sic == 23 | sic == 24 | sic == 25 | sic == 26
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov,fe r

clear all
use "Data.dta"
gen treat = inlist( City , "昌吉回族自治州", "湖州市", "广州市","衢州市","赣江新区","贵安新区","哈密市","克拉玛依市")
gen t=year>=2017
gen did=t*treat
xtset id year
gen Em=ln(Numberofemployee)
xtset id year
drop if sic == 11 | sic == 12 | sic == 13 | sic == 14 | sic == 16 | sic == 17 | sic == 19 | sic == 20 | sic == 21 | sic == 22 | sic == 23 | sic == 24 | sic == 25 | sic == 26
xtreg Em did Size Age ROE Lev Tobin OC FAR i.year i.sic i.Prov,fe r


