# %%
import QuantLib as ql
import pandas as pd
import os



# %%

# Load the yield curve data
# Replace 'path_to_your_file.xlsx' with the actual path to your Excel file
file_path = 'data/raw/curves/EUR/EUR_Curve_20130225.xlsx'
curve_data = pd.read_excel(file_path)

# Trade, effective, and maturity dates
trade_date = ql.Date(25, 2, 2013)
effective_date = ql.Date(27, 2, 2013)
maturity_date = ql.Date(27, 2, 2024)
ql.Settings.instance().evaluationDate = trade_date

# Convert yields to decimal form
curve_data['Yield'] = curve_data['Yield'] / 100



# %%
# Preparation for yield curve construction
day_count = ql.Actual360()
calendar = ql.TARGET()
settlement_days = 2
deposit_day_count = ql.Actual360()
swap_day_count = ql.Thirty360(ql.Thirty360.European)
euribor_index = ql.Euribor6M()

rate_helpers = []

# Iterate through the curve data to create appropriate rate helpers
for _, row in curve_data.iterrows():
    tenor, cusip, rate = row['Tenor'], row['CUSIP'], row['Yield']
    
    if "EUR" in cusip and "M" in tenor:  # Assuming these are deposit rates
        months = int(tenor.replace('M', ''))
        helper = ql.DepositRateHelper(ql.QuoteHandle(ql.SimpleQuote(rate)),
                                      ql.Period(months, ql.Months), settlement_days,
                                      calendar, ql.ModifiedFollowing, False, deposit_day_count)
        rate_helpers.append(helper)
    elif "EUFR" in cusip:  # FRA
        months = int(tenor.replace('M', ''))
        helper = ql.FraRateHelper(ql.QuoteHandle(ql.SimpleQuote(rate)),
                                  months - settlement_days, months,
                                  settlement_days, calendar, ql.ModifiedFollowing,
                                  False, deposit_day_count)
        rate_helpers.append(helper)
    elif "EUSA" in cusip:  # Swap rates
        years = int(tenor.replace('Y', ''))
        helper = ql.SwapRateHelper(ql.QuoteHandle(ql.SimpleQuote(rate)),
                                   ql.Period(years, ql.Years), calendar,
                                   ql.Annual, ql.Unadjusted, swap_day_count, euribor_index)
        rate_helpers.append(helper)

# Construct the yield curve
yield_curve = ql.PiecewiseLogCubicDiscount(0, calendar, rate_helpers, deposit_day_count)

# Continue with swap setup and calculation...


# %%
# Swap details
notional = 50000000  # 50M
fixed_rate = 0.0  # Initial guess, will find the fair rate
fixed_rate_day_count = ql.Thirty360(ql.Thirty360.European)
fixed_rate_frequency = ql.Semiannual
float_rate_frequency = ql.Annual

# Define the fixed and floating leg schedules
fixed_schedule = ql.Schedule(effective_date, maturity_date,
                             ql.Period(fixed_rate_frequency),
                             calendar, ql.ModifiedFollowing, ql.ModifiedFollowing,
                             ql.DateGeneration.Forward, False)

float_schedule = ql.Schedule(effective_date, maturity_date,
                             ql.Period(float_rate_frequency),
                             calendar, ql.ModifiedFollowing, ql.ModifiedFollowing,
                             ql.DateGeneration.Forward, False)

# EURIBOR index for the floating leg
euribor_index = ql.Euribor1Y(ql.YieldTermStructureHandle(yield_curve))
floating_leg_spread = 0.0

# Instantiate the swap
interest_rate_swap = ql.VanillaSwap(ql.VanillaSwap.Payer, notional, fixed_schedule,
                                    fixed_rate, fixed_rate_day_count, float_schedule,
                                    euribor_index, floating_leg_spread, day_count)

# Set up the pricing engine
swap_engine = ql.DiscountingSwapEngine(ql.YieldTermStructureHandle(yield_curve))
interest_rate_swap.setPricingEngine(swap_engine)

# Calculate the fair rate
fair_rate = interest_rate_swap.fairRate()

print(f"Fair Fixed Rate: {fair_rate*100:.4f}%")


