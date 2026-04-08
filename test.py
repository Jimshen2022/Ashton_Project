import pandas as pd
df = pd.read_csv('D:/GitHub/Ashley_Project/excel_extracts/Demand Fulfillment SQL.csv')
df['Warehouse'] = df['Warehouse'].str.strip()
res = df[(df['Warehouse'] == '17') & (df['WeekEnding'] == '2026-03-28')]
print(res)
print('sum:', res['DemandFulfillment'].sum())
