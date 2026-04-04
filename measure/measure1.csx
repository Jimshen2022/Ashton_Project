// 锁定目标表 (如果没有找到名字，就用您鼠标选中的表)
var targetTable = Model.Tables["_Measures_LaborPlanning"];
if (targetTable == null) {
    targetTable = Selected.Table; 
}

if (targetTable != null) {
    
    // ==========================================
    // 📁 文件夹 1：核心基础指标 (01. Core Base)
    // ==========================================
    
    var mPPH = targetTable.AddMeasure("Actual_PPH_Avg", 
        @"CALCULATE(
            AVERAGE('Fct_LaborRollups'[NonYard_PPH]),
            REMOVEFILTERS('Dim_Calendar')
        )", "01. Core Base");
    mPPH.FormatString = "0.00";

    var mHC = targetTable.AddMeasure("Current_Working_HC", 
        @"VAR Max_Actual_Date = CALCULATE(MAX('Fct_LaborRollups'[WeekEnding]), REMOVEFILTERS('Dim_Calendar'))
        RETURN
        CALCULATE(
            SUM('Fct_LaborRollups'[Headcount_Total]),
            REMOVEFILTERS('Dim_Calendar'),
            'Dim_Calendar'[Date] = Max_Actual_Date
        )", "01. Core Base");
    mHC.FormatString = "#,0";

    var mOB = targetTable.AddMeasure("Total_OB_Volume", 
        @"CALCULATE(
            SUM('OB Delta Split'[Bill-ECOMM]) + 
            SUM('OB Delta Split'[Ecomm])
        )", "01. Core Base");
    mOB.FormatString = "#,0";

    var mIB = targetTable.AddMeasure("Total_IB_Volume", 
        @"CALCULATE(
            SUM('Fct_ReceiptsSQL'[PurchaseOrderPcs]) + 
            SUM('Fct_ReceiptsSQL'[TransferInPcs])
        )", "01. Core Base");
    mIB.FormatString = "#,0";


    // ==========================================
    // 📁 文件夹 2：计算引擎 (02. Core Engines)
    // ==========================================
    
    var mReqHC = targetTable.AddMeasure("Required_HC_Target", 
        @"SUMX(
            VALUES('Fct_LaborRollups'[Department_Desc]),
            
            VAR Current_Dept = MAX('Fct_LaborRollups'[Department_Desc])
            
            VAR Avg_Weekly_OB_Volume = AVERAGEX(VALUES('Dim_Calendar'[SaturdayDate]), [Total_OB_Volume])
            VAR Avg_Weekly_IB_Volume = AVERAGEX(VALUES('Dim_Calendar'[SaturdayDate]), [Total_IB_Volume])
            VAR Dept_PPH = [Actual_PPH_Avg]
            
            VAR Target_HC = 
                SWITCH(TRUE(),
                    Current_Dept = ""Shipping"" || Current_Dept = ""Ecomm"", DIVIDE(Avg_Weekly_OB_Volume, (Dept_PPH * 40)),
                    Current_Dept = ""Receiving"" || Current_Dept = ""Inbound"", DIVIDE(Avg_Weekly_IB_Volume, (Dept_PPH * 40)),
                    BLANK()
                )
            RETURN Target_HC
        )", "02. Core Engines");
    mReqHC.FormatString = "#,0.0";

    var mNetGap = targetTable.AddMeasure("Net_HC_Gap", 
        @"VAR Current_Site = MAX('Fct_DCs'[wh_id]) 
        VAR Avg_Site_Absenteeism = CALCULATE(
            AVERAGE('Fct_Location_Dept_HR_Parameters'[Target_Absenteeism_Pct]),
            'Fct_Location_Dept_HR_Parameters'[wh_id] = Current_Site
        )
        VAR Final_Absenteeism = COALESCE(Avg_Site_Absenteeism, 0.10) 
        VAR Site_Effective_HC = [Current_Working_HC] * (1 - Final_Absenteeism)
        
        RETURN [Required_HC_Target] - Site_Effective_HC", "02. Core Engines");
    mNetGap.FormatString = "#,0.0";


    // ==========================================
    // 📁 文件夹 3：单仓深度透视 (03. DC Quickviews)
    // ==========================================
    
    int[] hours = { 40, 45, 50, 55 };
    foreach (int h in hours) {
        var mCap = targetTable.AddMeasure(
            "Capacity_" + h + "_Hrs", 
            string.Format("[Current_Working_HC] * [Actual_PPH_Avg] * {0}", h), 
            "03. DC Quickviews"
        );
        mCap.FormatString = "#,0";
    }

    var mRatio = targetTable.AddMeasure("Ratio_OB_vs_IB", 
        @"DIVIDE([Total_OB_Volume], [Total_IB_Volume], BLANK())", "03. DC Quickviews");
    mRatio.FormatString = "0.0%";

} else {
    Error("请先在左侧树状图选中 _Measures_LaborPlanning 表！");
}