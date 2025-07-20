set seed 12345
capture program drop gen_data
program gen_data
	version 17.0
    syntax [, nobs(integer 100) c s(real 0.01)]
	clear
    set obs `nobs'
    gen x1 = runiform(0,1)
    if "`c'" != "" {
        gen x2 = x1 + rnormal(0,`s')
    }
    else {
        gen x2 = runiform(0,1)
    }
    gen epsilon = rnormal(0, sqrt(1 + 5*x1))
    gen y = 1 - 2*x1 + 3*x2 + epsilon
    gen weight = 1 / (1 + 5*x1)
end

capture program drop test_metrics
program define test_metrics, rclass
	version 17.0
	clear
	gen_data, c
	gen y_star = sqrt(weight) * y
	gen x1_star = sqrt(weight) * x1
	gen x2_star = sqrt(weight) * x2
	gen c_star = sqrt(weight)
	matrix define sup = (-5, 0, 5 \ -5, 0, 5 \ -5, 0, 5)
	gmentropylinear y_star x1_star x2_star c_star, support(sup) nocons
	return scalar b0_gme = e(b)["y1", "c_star"]
	return scalar b1_gme = e(b)["y1", "x1_star"]
	return scalar b2_gme = e(b)["y1", "x2_star"]
	reg y x1 x2 [aw=w]
	return scalar b0_wls = _b[_cons]
	return scalar b1_wls = _b[x1]
	return scalar b2_wls = _b[x2]
end


simulate b0_gme = r(b0_gme) b1_gme = r(b1_gme) b2_gme = r(b2_gme) ///
	b0_wls = r(b0_wls) b1_wls = r(b1_wls) b2_wls = r(b2_wls), reps(500): test_metrics
	
