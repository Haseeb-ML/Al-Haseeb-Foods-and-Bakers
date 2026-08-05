import os

file_path = r'c:\erp\lib\screens\admin\sales_history_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = {
    'TodaySalesScreen': 'SalesHistoryScreen',
    '_TodaySalesScreenState': '_SalesHistoryScreenState',
    '_todayInvoicesStream': '_allInvoicesStream',
    'getTodayInvoices': 'getInvoices',
    "Today's Sales": 'Sales History',
    "Today's revenue": 'Total revenue',
    "Today's invoices": 'All invoices',
    'No Sales Today': 'No Sales Found',
    'currentRoute: "Sales History"': 'currentRoute: "Sales History"' # handled above
}

for k, v in replacements.items():
    content = content.replace(k, v)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
