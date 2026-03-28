SELECT --[spdItem]
    [spdWarehouse] AS [Warehouse]
    -- ,[ITEMCLASS]
-- ,[ComponentFlag]
    ,[WeekEnding]
    ,SUM([PurchaseOrderPcs]) AS [PurchaseOrderPcs]
	,FORMAT(SUM(POCubes) / 2400, 'N0') AS [Containers]
    ,FORMAT(SUM([ProductionPcs]), 'N0') AS [ProductionPcs]
  --  ,SUM([POCubes]) AS [POCubes]
    ,FORMAT(SUM([TransferInPcs]), 'N0') AS [TransferInPcs]
    ,FORMAT(SUM([TransferInCubes]), 'N0') AS [TransferInCubes]
	,FORMAT(SUM(TransferInCubes) / 3200, 'N0') AS [TransferInTrucks]
    ,SUM([TransferOutPcs]) AS [TransferOutPcs]
    ,FORMAT(SUM([TransferOutCubes]), 'N0') AS [TransferOutCubes]
	,FORMAT(SUM(TransferOutCubes) / 3300, 'N0') AS [TranferOutTrucks]
   --,SUM([Cubes]) AS [Cubes]
    ,[FinancialDivision]
-- ,[GeneralDescription]
FROM [PowerBI_SupplyChain].[TotalReceipts]
WHERE spdWarehouse IN ('1', '15', 'ECR', '17', '5', '42', '28', '335')
	 AND ITEMCLASS like 'z%'
	 AND ITEMCLASS not like '%k'
GROUP BY
	spdWarehouse
	,WeekEnding
	,FinancialDivision
ORDER BY CAST(WeekEnding  AS DATE), warehouse, FinancialDivision