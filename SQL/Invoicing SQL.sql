SELECT
Invoice_Date
,Fiscal_WeekEnding
,Warehouse
,SUM([Other_Total_Invoice]) AS [Billable Invoicing]
,SUM([Express_Total_Invoice]) AS [Ecommerce Invoicing]
,SUM(Other_QTY_Shipped) AS [Billable Volume]
,SUM(Express_QTY_Shipped) AS [Ecommerce Volume]

FROM PowerBI_Distribution.InvoiceAmount_WarehouseLevel
WHERE YEAR(Fiscal_WeekEnding)>=2020
GROUP BY
Invoice_Date
,Fiscal_WeekEnding
,Warehouse
