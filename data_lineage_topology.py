import networkx as nx
import sys

def build_digital_lineage_graph():
    """
    Builds a Directed Acyclic Graph (DAG) representing the Data & Business Lineage 
    of the Ashley Network Labor Planning ecosystem based on First Principles.
    """
    G = nx.DiGraph()

    # =========================================================================
    # L1: Raw Data & System Feeds (Source of Truth)
    # =========================================================================
    G.add_node("L1: Labor Rollups (SQL)", desc="Payroll Hours, OT, Gross Units")
    G.add_node("L1: Receipts/Invoicing/Demand (SQL)", desc="WMS Volume Activity")
    G.add_node("L1: HR System (Manual Input)", desc="Active WC/LOA, Requested Hires")
    
    # =========================================================================
    # L2: Aggregation & Historical Parameters
    # =========================================================================
    G.add_node("L2: PPH (Pieces Per Hour)", desc="L1 Units / L1 Total Hours")
    G.add_node("L2: 13-Week Avg TO (Terminations)", desc="Rolling 13-week avg of actual terms from L1 Labor Rollups")
    G.add_node("L2: 5-Week Avg Absenteeism", desc="Rolling 5-week avg from L1 Labor Rollups")
    
    # =========================================================================
    # L3: Site-Level Calculations (Business Engine)
    # =========================================================================
    G.add_node("L3: Required Total Hours", desc="L1 Forecasted Volume / L2 PPH")
    G.add_node("L3: Target Headcount (Dept HC)", desc="L3 Required Total Hours / Weekly Capacity (40/45/55)")
    G.add_node("L3: Forecasted Terminations", desc="L2 13-Week Avg TO + Manual Override")
    G.add_node("L3: Working HC (Available Labor)", desc="[Dept HC] - ([Forecasted Terms] + [WC/LOA]) + [Requested Hires]")
    G.add_node("L3: HC Need (Gap)", desc="[Target Headcount] - [Working HC]")
    
    # =========================================================================
    # L4: Global Dashboards & Actions (Outputs)
    # =========================================================================
    G.add_node("L4: 7 Main DCs HC Review", desc="Aggregated HC Need across all 7 sites")
    G.add_node("L4: 60-Day Recruiting Needs", desc="[L3 HC Need] + (8 Weeks * [L2 13-Week Avg TO])")
    G.add_node("L4: OT Dashboard (Overtime %)", desc="L1 OT Hours / L1 Total Hours")
    G.add_node("L4: Cost Per Piece", desc="L1 Total Labor Dollars / L1 Gross Units")

    # =========================================================================
    # Defining the Edges (Data Flow / Mathematical Dependencies)
    # =========================================================================
    edges = [
        # To Parameters
        ("L1: Labor Rollups (SQL)", "L2: PPH (Pieces Per Hour)"),
        ("L1: Labor Rollups (SQL)", "L2: 13-Week Avg TO (Terminations)"),
        ("L1: Labor Rollups (SQL)", "L2: 5-Week Avg Absenteeism"),
        
        # To Site Level
        ("L1: Receipts/Invoicing/Demand (SQL)", "L3: Required Total Hours"),
        ("L2: PPH (Pieces Per Hour)", "L3: Required Total Hours"),
        ("L3: Required Total Hours", "L3: Target Headcount (Dept HC)"),
        ("L2: 13-Week Avg TO (Terminations)", "L3: Forecasted Terminations"),
        
        # To Working HC & Gap
        ("L3: Target Headcount (Dept HC)", "L3: Working HC (Available Labor)"),
        ("L3: Forecasted Terminations", "L3: Working HC (Available Labor)"),
        ("L1: HR System (Manual Input)", "L3: Working HC (Available Labor)"), # Hires & LOA
        ("L3: Target Headcount (Dept HC)", "L3: HC Need (Gap)"),
        ("L3: Working HC (Available Labor)", "L3: HC Need (Gap)"),
        
        # To Dashboards
        ("L3: HC Need (Gap)", "L4: 7 Main DCs HC Review"),
        ("L3: HC Need (Gap)", "L4: 60-Day Recruiting Needs"),
        ("L2: 13-Week Avg TO (Terminations)", "L4: 60-Day Recruiting Needs"),
        ("L1: Labor Rollups (SQL)", "L4: OT Dashboard (Overtime %)"),
        ("L1: Labor Rollups (SQL)", "L4: Cost Per Piece"),
    ]
    
    G.add_edges_from(edges)
    return G

def trace_lineage(metric_name_keyword):
    G = build_digital_lineage_graph()
    
    # Find the exact node matching the keyword
    target_node = None
    for node in G.nodes():
        if metric_name_keyword.lower() in node.lower():
            target_node = node
            break
            
    if not target_node:
        print(f"❌ Error: Metric '{metric_name_keyword}' not found in the Digital Lineage Graph.")
        return
        
    print(f"\n" + "="*70)
    print(f"🔍 DIGITAL LINEAGE TRACE FOR: {target_node}")
    print(f"   Definition: {G.nodes[target_node]['desc']}")
    print("="*70)
    
    # 1. Upstream Dependencies (Root Causes)
    ancestors = list(nx.ancestors(G, target_node))
    if ancestors:
        print("\n⬆️ ROOT CAUSES (What data feeds this metric?):")
        # Sort to show L1 -> L2 -> L3
        ancestors.sort()
        for a in ancestors:
            print(f"   ├─ {a} [{G.nodes[a]['desc']}]")
    else:
        print("\n⬆️ ROOT CAUSES: This is a foundational Root Source. No upstream dependencies.")

    # 2. Mathematical Formula / Direct Parents
    parents = list(G.predecessors(target_node))
    if parents:
        print("\n🧮 DIRECT FORMULA INPUTS (How is it calculated?):")
        for p in parents:
            print(f"   → Depends directly on: {p}")

    # 3. Downstream Impacts (Where is it used?)
    descendants = list(nx.descendants(G, target_node))
    if descendants:
        print("\n⬇️ DOWNSTREAM IMPACTS (What dashboards/KPIs break if this is wrong?):")
        descendants.sort()
        for d in descendants:
            print(f"   ├─ {d}")
    else:
        print("\n⬇️ DOWNSTREAM IMPACTS: This is a Terminal KPI. No downstream dependencies.")
        
    print("\n" + "="*70 + "\n")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        search_term = " ".join(sys.argv[1:])
        trace_lineage(search_term)
    else:
        print("💡 Usage: python data_lineage_topology.py <metric_keyword>")
        print("   Example: python data_lineage_topology.py 'Working HC'")
        print("   Example: python data_lineage_topology.py 'Recruiting Needs'")