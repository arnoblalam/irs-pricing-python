*! gmentropylogit 1.0.3 Feb 20, 2017
* Paul Corral (World Bank Group - Poverty and Equity Global Practice)
* Daniel Kuehn (Urban Institute)
* Ermengarde Jabir (American University)

program define gmentropylinear, eclass
	version 11.2
	syntax varlist(min=2 numeric fv) [if] [in], SUPport(string) [SIGMAvalue(real 3.0) ///
	ENDpoint(integer 3) LAMbda(string) wmat(string)  RESidual(string) NOSigma NOCons]
	
//Mark the estimation sample

marksample touse

	tokenize `varlist'
	
// Local for dependent variable
local depvars `1'

// obtain the independent variables
macro shift 
local indeps `*'
local Ind `*'

//Remove collinear exolanatory vars
_rmcoll `indeps' if `touse', forcedrop
local indeps  `r(varlist)'

if "`support'"=="" {

	display as error "A support matrix for the coefficients must be specified"
	exit
	}
if (`sigmavalue'<0){
	display as error "Sigma value must only be positive, I made it positive"
}
	
// Check if Esupport is an odd number
tempname u1 u2 u3

if "`nosigma'"==""{
scalar `u3'=0
}
else{
scalar `u3'=1
}

if `endpoint'<3{
	display as error "Minimum number of supports for error is 3"
	exit
	}
	
//Get number of weights for errors	
scalar `u2'=mod(`endpoint',2)

if `u2'!=1{
	
	display "error: support space must be odd numbered to include 0, I added 1 to make it odd"
	scalar `u2'=`endpoint'+1
	}
	else{
	scalar `u2'=`endpoint'
		}
	local endpoint=`u2'
	
//Get value of multiplier for sigma value
scalar `u1' = `sigmavalue'
			
	
//Weight matrix requested	
if "`wmat'"!=""{
cap confirm variable `wmat'
	if !_rc{
		display as error "Please specify a variable name that does not exist for option wmat"
		exit
	}
	else{
		forval x=1/`endpoint'{
			qui:gen double `wmat'_`x' = .
				label var `wmat'_`x' "Weight for error support `x'"
			local wmats `wmats' `wmat'_`x'
		}	
	}
local wmat = 1 
}
else{
local wmat = 0
}
//Lambdas requested
if "`lambda'"!=""{
cap confirm variable `lambda'
	if !_rc{
		display as error "Please specify a variable name that does not exist for option lambda"
		exit
	}
	else{
		qui:gen double `lambda' = .
				label var `lambda' "Lambda for this constraint"
			local lambdas `lambda'
	}
local lambda = 1 
}
else{
local lambda = 0
}
//residual requested
if "`residual'"!=""{
cap confirm variable `residual'
	if !_rc{
		display as error "Please specify a variable name that does not exist for option residual"
		exit
	}
	else{
		qui:gen double `residual' = .
				label var `residual' "predicted residual"
			local residuals `residual'
	}
local residual = 1 
}
else{
local residual = 0
}
	
// Number of indep vars
local wc=wordcount("`Ind'")
local wc=`wc'+1

local r=rowsof("`support'")

if (`wc'!=`r' & "`nocons'"=="") {

	display as error "Number of rows in support matrix must match number of independent varaibles"
	
	}
	
if ((`wc'-1)!=`r' & "`nocons'"=="nocons") {
display as error "Number of rows in support matrix must match number of independent varaibles"
exit
}
	
if "`nocons'"=="nocons"{
mata:gme_linear("`depvars'", "`indeps'", "`support'", "`u1'", "`u2'","`u3'","`touse'", 1, `wmat', `lambda', `residual')
//  Matrix for  results
tempname b V 
mat `b' = r(beta)
	mat coln `b' = `indeps'
mat `V' = r(V)
	mat coln `V' = `indeps' 
	mat rown `V' = `indeps' 
local N=r(N)
}
else{	
mata:gme_linear("`depvars'", "`indeps'", "`support'", "`u1'", "`u2'","`u3'","`touse'",0,`wmat', `lambda', `residual')
//  Matrix for  results
tempname b V 
mat `b' = r(beta)
	mat coln `b' = `indeps' _cons
mat `V' = r(V)
	mat coln `V' = `indeps' _cons
	mat rown `V' = `indeps' _cons
local N=r(N)
}


ereturn post `b' `V', depname(`depvars') obs(`N') esample(`touse')

// Statistics
//Number of observations
ereturn scalar N = r(N)
//Degs of freedom
ereturn scalar d_fm = (r(K)-1)
//entropy
ereturn scalar entropy = r(L)
//Initial entropy
ereturn scalar int_entropy =r(L0)
//pseudo r2
ereturn scalar pseudoR2 = r(pseudoR2)
//Normalized entropy
ereturn scalar sign_entropy = r(norm_entro)
//Noise entropy
ereturn scalar noise_entropy = r(noiseent)
//Ent. ratio stat.
//ereturn scalar ERS = r(entratio)
//Ereturn matrix probs
if ("`nocons'"=="nocons") mat rown probs = `indeps' 
else mat rown probs = `indeps' _cons
ereturn matrix betaprobs = probs
//Ereturn matrix V
ereturn matrix esupport = esupport



display _newline in gr "Generalized Maximum Entropy (Linear)" _col(52) in gr "Number of obs" _col(71) in gr "=" _col(72) in ye %7.0f e(N)
display _col(52) in gr "Degrees of freedom" _col(71) in gr "=" _col(72) in ye %7.0f e(d_fm)
display _col(52) in gr "Model Entropy" _col(71) in gr "=" _col(72) in ye %7.1f e(entropy)
display _col(52) in gr "Pseudo R2" _col(71) in gr "="  _col(72) in ye %7.4f e(pseudoR2)
display _col(52) in gr "Signal entropy" _col(71) in gr "="  _col(72) in ye %7.4f e(sign_entropy)
display _col(52) in gr "Noise entropy" _col(71) in gr "="  _col(72) in ye %7.4f  e(noise_entropy)

//display _col(52) in gr "Ent. ratio stat." _col(71) in gr "="  _col(72) in ye %7.1f e(ERS)



ereturn display



end

mata:mata clear
version 11.2
mata: mata set matastrict on
mata:
// Linear GME 1.0.0  Nov. 21, 2014
void gme_linear(string scalar yname, 
                string scalar xname, 
                string scalar betasupport,
				string scalar tope,
				string scalar soporte,
				string scalar sig,
				string scalar touse,
				real scalar nc,
				real scalar wmat,
				real scalar lout,
				real scalar epsilon)
				
{

		real matrix Y, X, sigmaz, sigmav, lambda, Z, v, p, w, numerator, omegas, num_w, psi, beta, cons, B, psi_sum, omega_sum, grad, H, bold, sigma2, omega2, V, pseudoR2, p0, w0, H0, HB
		real scalar sdy, K, N, s, R, a, b, lnp, cha, iter, lhs, L, L0, norment, entratio, top, esupport,i, s1, noiseent
		
					  
	// Use st_data to import variables from stata

	Y=st_data(., tokens(yname), touse)
	X=st_data(., tokens(xname), touse)
	
	if (nc==0){
	cons = J(rows(X),1,1)
	X=X, cons
	}
	
	top=st_numscalar(tope)
	esupport=st_numscalar(soporte)
	s1=st_numscalar(sig)

	
	// Import matrix from stata, user must provide
	Z=st_matrix(betasupport)

	
		if (s1==0){
			//endogenous error support
			sdy=sqrt(quadvariance(Y))
		}
		else{
			sdy=1
		}
		

	v=J(1,esupport,0)
	v[1,1]=-top
		
		for(i=2; i<=esupport; i++){
			v[1,i]=v[1,(i-1)]+(top/((esupport-1)/2))
		}
		
		v=v*sdy

		// Observations
			N=rows(X)
		// Variables
			K=cols(X)
			
	// Optimization
		
		cha=1
		
		iter=1
		
		B=J(1,rows(Y), 0)
		
	//Beginning of NR -> use of optimize command is not giving valid results (results are compared to GAMS)
	while (abs(cha)>1e-24) { //while the change between the old beta(lambdas) and new one is greater than the value we continue looping
	
			lhs=quadcross(B',Y)
			
			numerator = exp(-((quadcross(B',X))':*Z))
			omegas    = quadrowsum(numerator)
			
			num_w = exp(-quadcross(B,v))
			psi   = quadrowsum(num_w)
			
			psi_sum    = quadsum(ln(psi))
			omega_sum  = quadsum(ln(omegas))
			
	
	
		L = lhs+omega_sum+psi_sum
	
			if (iter==1){
			L0=L
			}
			
			p  = numerator:/omegas
			w=num_w:/psi
			
				sigmaz = quadrowsum(p:*(Z:^2)) - quadrowsum(p:*Z):*quadrowsum(p:*Z)
				sigmav = diag(quadrowsum(w:*(v:^2)) - quadrowsum(w:*v):*quadrowsum(w:*v))
			
			//Gradient
						
			grad = Y' - (quadcross(X',rowsum(p:*Z)))' - quadcross(v',w')
		
			//Hessian
			H=quadcross(X',sigmaz,X')+sigmav
			
			
			printf("{txt}Iteration %f", iter)
			printf("{txt}:    Entropy = %f\n", L)
			iter = iter+1  //Count number of iterations
			bold=B	  //set b old equal to the current b in order to estimate the new b
			
			B = bold - quadcross(grad',luinv(H)) // This is the essence of the Newton Rhapson
			
			cha = quadcross((bold-B)',(bold-B)')/ quadcross(bold',bold') 	// Change between the old beta and new
	
	} 	//end of newton rhapson
	
	beta = quadrowsum(p:*Z)
	
	sigma2=quadcross(B',B')/cols(B)
	omega2=((quadcolsum((quadrowsum((v:^2):*w)-((quadrowsum(v:*w)):^2)):^(-1)))/cols(B))^2
	
	V=(sigma2/omega2)*invsym(quadcross(X,X))
	
	p0 = J(rows(p), cols(p),(1/cols(p)))
	w0 = J(rows(w),cols(w), (1/cols(w)))
	H0 = -(quadsum(p0:*(log(p0))))-(quadsum(w0:*(log(w0))))
	HB = -quadsum(p:*(log(p)))-quadsum(w:*(log(w)))
	
	pseudoR2=1-((-quadsum(p:*(log(p))))/(-(quadsum(p0:*(log(p0))))))
	
	norment =-quadsum(p:*(log(p)))/(cols(X)*log(cols(Z)))
	noiseent=-quadsum(w:*(log(w)))/-(quadsum(w0:*(log(w0))))
	
	entratio=(2*omega2/sigma2)*abs(HB-H0)
	
	if (wmat==1) st_store(.,st_varindex(tokens(st_local("wmats"))),touse,w)
	if (lout==1) st_store(.,st_varindex(tokens(st_local("lambdas"))),touse,B')
	if (epsilon==1) st_store(.,st_varindex(tokens(st_local("residuals"))),touse,quadcross(v',w')')
	
	
	// Return results to stata
	
		st_matrix("r(beta)", beta')
		st_matrix("probs", p)
		st_matrix("esupport", v)
		st_numscalar("r(N)", N)
		st_numscalar("r(K)", K)
		st_matrix("r(sigma2)", sigma2)
		st_matrix("r(omega2)", omega2)
		st_matrix("r(V)", V)
		st_numscalar("r(L)", L)
		st_numscalar("r(L0)", L0)
		st_numscalar("r(pseudoR2)", pseudoR2)
		st_numscalar("r(norm_entro)", norment)
		st_numscalar("r(entratio)", entratio)
		st_numscalar("r(noiseent)", noiseent)
		
	
	
}
end
