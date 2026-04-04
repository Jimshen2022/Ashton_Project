import os
import pandas as pd
import glob

# ==========================================
# Power BI Semantic Model Integration Script
# ==========================================
# This script consolidates the 76 scattered CSV extracts into 
# clean Master Fact Tables and automatically injects them into 
# the Power BI .pbip Semantic Model using TMDL.

input_dir = 'D:/GitHub/Ashley_Project/excel_extracts'
output_dir = 'D:/GitHub/Ashley_Project/pbi_source_data'
tmdl_dir = 'D:/GitHub/Ashley_Project/DCsLaborPlanning/Network Labor Planning File (DC Version).SemanticModel/definition/tables'
model_tmdl_path = 'D:/GitHub/Ashley_Project/DCsLaborPlanning/Network Labor Planning File (DC Version).SemanticModel/definition/model.tmdl'

os.makedirs(output_dir, exist_ok=True)

def generate_tmdl(table_name, df, csv_path):
    """Generates Power BI TMDL table definition mapping Pandas dtypes to PBI types"""
    lines = [f"table {table_name}", ""]
    
    for col in df.columns:
        # Determine basic type
        if pd.api.types.is_numeric_dtype(df[col]):
            t = "double"
        else:
            t = "string"
            
        safe_col = col.replace("'", "''")
        lines.append(f"\tcolumn '{safe_col}'")
        lines.append(f"\t\tdataType: {t}")
        lines.append(f"\t\tsourceColumn: {col}")
        lines.append("")
        
    lines.append(f"\tpartition {table_name} = m")
    lines.append(f"\t\tmode: import")
    lines.append(f"\t\tsource = ")
    lines.append(f"\t\t\t\tlet")
    lines.append(f"\t\t\t\t    Source = Csv.Document(File.Contents(\"{csv_path.replace('/', '\\\\')}\"),[Delimiter=\",\", Encoding=1252, QuoteStyle=QuoteStyle.None]),")
    lines.append(f"\t\t\t\t    #\"Promoted Headers\" = Table.PromoteHeaders(Source, [PromoteAllScalars=true])")
    lines.append(f"\t\t\t\tin")
    lines.append(f"\t\t\t\t    #\"Promoted Headers\"")
    
    with open(os.path.join(tmdl_dir, f"{table_name}.tmdl"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f" [+] Generated TMDL for {table_name}")

def update_model_tmdl(new_tables):
    """Appends table references to the core model.tmdl file"""
    with open(model_tmdl_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    for tb in new_tables:
        ref_str = f"ref table {tb}"
        if ref_str not in content:
            content += f"\n{ref_str}"
            
    with open(model_tmdl_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(" [+] Updated model.tmdl references")

if __name__ == "__main__":
    print("Starting Data Consolidation & PBI Injection...\n")
    new_tables = []

    # 1. Consolidate Master HC Review
    hc_files = [f for f in glob.glob(f"{input_dir}/* HC Review.csv") if "7 Main" not in f]
    hc_list = []
    for f in hc_files:
        site = os.path.basename(f).replace(" HC Review.csv", "")
        try:
            df = pd.read_csv(f, skiprows=1) # Skip the title row
            df = df.dropna(subset=['Week', 'Period'], how='all')
            df['Site'] = site
            cols_to_keep = ['Week', 'Period', 'Dept HC', 'Terminations', 'Hires', 'WC/LOA', 'Labor Share', 'Final HC', 'HC Need', 'Site']
            cols = [c for c in cols_to_keep if c in df.columns]
            hc_list.append(df[cols])
        except Exception as e:
            print(f"Skipping {f}: {e}")

    if hc_list:
        master_hc = pd.concat(hc_list, ignore_index=True)
        csv_path = f"{output_dir}/Master_HC_Review.csv"
        master_hc.to_csv(csv_path, index=False)
        generate_tmdl("Master_HC_Review", master_hc, csv_path)
        new_tables.append("Master_HC_Review")

    # 2. Consolidate Master Outbound
    ob_files = [f for f in glob.glob(f"{input_dir}/* Outbound.csv")]
    ob_list = []
    for f in ob_files:
        site = os.path.basename(f).replace(" Outbound.csv", "")
        try:
            df = pd.read_csv(f)
            df = df.dropna(subset=['Week', 'Period'], how='all')
            df['Site'] = site
            ob_list.append(df)
        except Exception as e:
            pass

    if ob_list:
        master_ob = pd.concat(ob_list, ignore_index=True)
        csv_path = f"{output_dir}/Master_Outbound.csv"
        master_ob.to_csv(csv_path, index=False)
        generate_tmdl("Master_Outbound", master_ob, csv_path)
        new_tables.append("Master_Outbound")
        
    # 3. Other Global Files (e.g. HR KPMs, OT Dashboard)
    # Just copying a couple directly to PBI source
    global_files = {"HR_KPMs": "HR KPMs.csv", "OT_Dashboard": "OT Dashboard.csv"}
    for tb_name, file_name in global_files.items():
        src_path = os.path.join(input_dir, file_name)
        if os.path.exists(src_path):
            try:
                df = pd.read_csv(src_path, skiprows=1) # Some have titles on row 0
                dest_path = f"{output_dir}/{file_name}"
                df.to_csv(dest_path, index=False)
                generate_tmdl(tb_name, df, dest_path)
                new_tables.append(tb_name)
            except Exception as e:
                pass

    if new_tables:
        update_model_tmdl(new_tables)
        print("\n✅ Success! The Power BI Semantic Model has been upgraded.")
        print("Open 'Network Labor Planning File (DC Version).pbip' in Power BI Desktop to see the new tables.")
    else:
        print("\n⚠️ No tables were processed.")