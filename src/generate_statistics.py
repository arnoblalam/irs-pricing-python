#!/usr/bin/env python3

import pandas as pd

def calculate_statistics(file_path, currency):
    df = pd.read_excel(file_path)

    # 1. Filter out transactions of type 'IRS Fix-Fix'
    df = df[df['Type'] != 'IRS Fix-Fix']

    # 2. Calculate the number of transactions
    num_transactions = len(df)

    # 3. Calculate the total gross notional value of the transactions
    total_notional_value = df['Not.'].sum()

    # 4. Calculate notional value for different floating leg references
    floating_legs = df.loc[df['Leg 1'] != 'FIXED', 'Leg 1'].append(df.loc[df['Leg 2'] != 'FIXED', 'Leg 2'])
    notional_value_by_floating_leg = floating_legs.value_counts()

    # 5. Calculate total number and total notional value of cleared and uncleared swaps
    cleared = df[df['Clr'] == 'C']
    uncleared = df[df['Clr'] == 'U']

    total_cleared = len(cleared)
    total_uncleared = len(uncleared)
    total_notional_cleared = cleared['Not.'].sum()
    total_notional_uncleared = uncleared['Not.'].sum()

    return {
        'currency': currency,
        'num_transactions': num_transactions,
        'total_notional_value': total_notional_value,
        'notional_value_by_floating_leg': notional_value_by_floating_leg,
        'total_cleared': total_cleared,
        'total_uncleared': total_uncleared,
        'total_notional_cleared': total_notional_cleared,
        'total_notional_uncleared': total_notional_uncleared
    }

def create_excel_table(stats_usd, stats_cad, output_file):
    # Combine statistics into a single DataFrame
    stats = pd.DataFrame([stats_usd, stats_cad])

    # Write DataFrame to Excel
    with pd.ExcelWriter(output_file) as writer:
        stats.to_excel(writer, index=False, sheet_name='Summary')
        stats_usd['notional_value_by_floating_leg'].to_excel(writer, index=True, sheet_name='USD Floating Legs')
        stats_cad['notional_value_by_floating_leg'].to_excel(writer, index=True, sheet_name='CAD Floating Legs')

if __name__ == "__main__":
    usd_file = 'data/raw/trades/USD/USD_20130223-20130310.xlsx'
    cad_file = 'data/raw/trades/CAD/CAD_20130223-20130310.xlsx'
    output_file = 'results/tab3_phase_1_descriptive.xlsx'

    stats_usd = calculate_statistics(usd_file, 'USD')
    stats_cad = calculate_statistics(cad_file, 'CAD')

    create_excel_table(stats_usd, stats_cad, output_file)
