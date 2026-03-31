SELECT
    -- 1. 基础维度映射 (1:1 直接抓取)
    WeekEnding,
    Warehouse,
    Warehouse_Desc,
    Department,
    Department_Desc,
    Activity_Desc,

    -- 2. 换马甲的“工时与人数” (财务名称重命名为运营名称)
    FinProll_Hours_Regular AS Hours_Reg_Total,
    FinProll_Hours_OT AS Hours_OT_Total,

    -- 高能预警：还原真实的“系统总工时” (正式常规 + 正式加班 + 外包临时工时)
    (COALESCE(FinProll_Hours_Regular, 0) +
     COALESCE(FinProll_Hours_OT, 0) +
     COALESCE(Hours_TempLumper_In, 0)) AS Hours_Total,

    -- 动态计算推导：加班率 (防止除以 0 报错)
    CASE
        WHEN (COALESCE(FinProll_Hours_Regular, 0) + COALESCE(FinProll_Hours_OT, 0) + COALESCE(Hours_TempLumper_In, 0)) = 0 THEN 0
        ELSE FinProll_Hours_OT / (COALESCE(FinProll_Hours_Regular, 0) + COALESCE(FinProll_Hours_OT, 0) + COALESCE(Hours_TempLumper_In, 0))
    END AS [OT %],

    FinProll_HeadCount AS Headcount_Total,

    -- 3. 业务量明细映射
    Units_BED,
    Units_DOM,
    Units_IMP,
    Units_IMPUP,
    Units_UPH,
    Units_RTA,
    Units_Gross,
    NonYard_PPH,

    -- 动态计算推导：软体产品出库/跨仓转移占比
    CASE
        WHEN COALESCE(Units_Gross, 0) = 0 THEN 0
        ELSE CAST(Units_UPH AS FLOAT) / Units_Gross
    END AS [% UPH Shipped/Trans],

    -- 4. 财务薪酬重命名
    FinProll_Pay_Regular AS LaborDollars_Reg_Total,
    FinProll_Pay_OT AS LaborDollars_OT_Total,
    FinProll_LaborDollars_Total AS LaborDollars_Total,
    GrossAmount_NoFreight,
    GrossAmount_WithFreight,

    -- 财务开票转化映射
    NonYard_SalesPerUnit AS ASP_WithFreight,

    -- 动态计算推导：不含运费客单价
    CASE
        WHEN COALESCE(Units_Gross, 0) = 0 THEN 0
        ELSE GrossAmount_NoFreight / Units_Gross
    END AS ASP_NoFreight,

    -- 5. 绩效与场站指标 (1:1 抓取)
    [NonYard_Pieces/HC_Ratio],
    NonYard_CostPerPiece,
    NonYard_SalesPerEmployee,
    NonYard_SalesPerLaborHour,
    NonYard_SalesPerUnit,
    Yard_CostPerMove,
    Yard_DirMovesFrom,
    Yard_DirMovesTo,
    [Yard_Moves/HC_Ratio],
    Yard_MPH,
    Yard_SalesPerMove,
    Yard_TotalMoves,
    Yard_UndirMoves,
    Yard_UnitsSoldPerMove

FROM
    CostAccounting.DC_LaborRollups_CalculatedData

-- 6. 应用您刚才提到的业务筛选器
WHERE
    WeekEnding >= '2026-01-24' AND WeekEnding < '2026-03-22'
    AND Warehouse IN ('1', '15', '17', '28', '5', 'ECR')
    AND Activity_Desc IN (
        'CG - Receiving',
        'DOM Line Clearing',
        'Ecomm Shipments',
        'Outbound Xfers',
        'Shipping - Non-Ecomm',
        'UPH - Receiving',
        'UPH Line Clearing'
    );