set seed 12345

capture program drop gen_data

program define gen_data, rclass
	version 17.0
	syntax [, n(integer 500) corr s(real 0.01) rare]
	clear
	set obs `n'
	gen x1 = rnormal()
    if "`corr'" != "" {
        gen x2 = x1 + runiform(0, `s')
        di "Generated x2 = x1 + runiform(0, `s') (correlated)"
    }
    else {
        gen x2 = rnormal()
        di "Generated independent x1 and x2"
    }
	if "`rare'" ! = "" {
		local beta_0 = -3.0
	}
	else {
		local beta_0 = -1.0
	}
	local beta_1 = 2.0
	local beta_2 = -0.5
	gen y_star = `beta_0' + `beta_1'*x1 - `beta_2'*x2
	gen p = invlogit(y_star)
	gen y = rbinomial(1, p)
	di "True equation is `beta_0' + `beta_1' * x1 + `beta_2' * x2"
	capture logit y x1 x2
    if _rc != 0 {
        di as error "logit failed with error code " _rc
        error _rc
    }
	return scalar b0_logit = _b[_cons]
	return scalar b1_logit = _b[x1]
	return scalar b2_logit = _b[x2]
    capture gmentropylogit y x1 x2
    if _rc != 0 {
        di as error "gmentropylogit failed with error code " _rc
        error _rc
    }
	return scalar b0_gme = e(b)[1, "_cons"]
	return scalar b1_gme = e(b)[1, "x1"]
	return scalar b2_gme = e(b)[1, "x2"]
end

simulate b0_logit = r(b0_logit) ///
	b1_logit = r(b1_logit) ///
	b2_logit = r(b2_logit) ///
	b0_gme = r(b0_gme) ///
	b1_gme = r(b1_gme) ///
	b2_gme = r(b2_gme), ///
	reps(500): gen_data, corr
