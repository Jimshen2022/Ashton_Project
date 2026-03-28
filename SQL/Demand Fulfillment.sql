SELECT
A.spdWarehouse,
A.spdWeekEnding,
SUM(A.spdDemandFulfillment) AS spdDemandFulfillment,
A.AFIFinanceDivision,
SUM(A.FOBDemandFullfilment) AS FOBDemandFullfilment

FROM
(
SELECT

spd.spdItem,
spd.spdWarehouse,
spd.spdWeekEnding,
spd.spdDemandFulfillment,
itm.AFIFinanceDivision,
spd.spdDemandFulfillment*FOB.BZANVA AS FOBDemandFullfilment

FROM Wholesale_DemandPlanning_AFI.SupplyPlanDetail AS spd
JOIN

(SELECT
MAX(spd.dtea) AS dtea
FROM Wholesale_DemandPlanning_AFI.SupplyPlanDetail AS spd) AS spd1 ON spd1.dtea = spd.dtea

LEFT JOIN Enterprise_DW.DimItemMaster AS itm ON itm.Item = spd.spdItem
LEFT JOIN MasterData_ItemMaster_AFI.MBBZREP AS fob ON FOB.BZAITX = SPD.spdItem

WHERE itm.SellableItemFlag = 'Y' AND spd.spdWarehouse NOT IN ('C','60','215','242') AND spd.spdWeekEnding <= DATEADD(mm,6,GETDATE())

) AS A

GROUP BY A.spdWarehouse,
A.spdWeekEnding,
A.AFIFinanceDivision