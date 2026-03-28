import pandas as pd
import os

def extract_excel():
    file_path = 'D:/GitHub/Ashley_Project/Network Labor Planning File_DC Version.xlsx'
    output_dir = 'D:/GitHub/Ashley_Project/excel_extracts'
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    print(f"Reading {file_path}...")
    try:
        xls = pd.ExcelFile(file_path)
    except Exception as e:
        print(f"Failed to read excel file: {e}")
        return
        
    for sheet_name in xls.sheet_names:
        print(f"Extracting sheet: {sheet_name}")
        df = pd.read_excel(xls, sheet_name=sheet_name)
        
        # Clean up sheet names to be valid file names
        safe_sheet_name = "".join([c for c in sheet_name if c.isalpha() or c.isdigit() or c==' ']).rstrip()
        output_path = os.path.join(output_dir, f"{safe_sheet_name}.csv")
        
        # Save as CSV
        df.to_csv(output_path, index=False, encoding='utf-8')
        
    print(f"\nExtraction complete! All data saved as separate CSV files in:\n{output_dir}")

if __name__ == "__main__":
    extract_excel()