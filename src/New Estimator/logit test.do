// Step 1: Set up the environment
set seed 12345
set obs 500

// Step 2: Generate predictor variables
gen x1 = rnormal()
gen x2 = rnormal()

// Step 3: Specify the logistic model parameters
local beta0 = 0      // Intercept
local beta1 = 1      // Coefficient for x1
local beta2 = -0.5   // Coefficient for x2

// Step 4: Calculate linear predictor and probability
gen eta = `beta0' + `beta1' * x1 + `beta2' * x2
gen p = invlogit(eta)  // Alternatively: gen p = exp(eta) / (1 + exp(eta))

// Step 5: Generate binary outcome variable
gen y = (runiform() < p)

// Step 6: Review the data
list in 1/10
