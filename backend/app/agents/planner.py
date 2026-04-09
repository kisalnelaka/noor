from typing import Dict, Any
from .states import AgentState

async def planner_node(state: AgentState) -> Dict[str, Any]:
    """
    Planner Agent Node.
    Analyzes user input and creates a step-by-step execution plan.
    Currently mocked for architectural setup.
    """
    user_input = state["user_input"].lower()
    
    print(f"[Planner] Analyzing: {user_input}")
    
    plan = []
    
    # 🧠 Context Resolution (V2 Memory)
    if any(k in user_input for k in ["it", "that", "its", "there", "this property"]):
        if state.get("last_property_id"):
            print(f"[Planner] Context found: resolving 'it' to {state['last_property_id']}")
            # Force SQL or Vector based on typical context queries
            if any(k in user_input for k in ["rent", "price", "where", "address"]):
                plan.append("query_sql_db")
            if any(k in user_input for k in ["permit", "lease", "policy", "rules"]):
                plan.append("query_vector_db")

    # SQL Heuristics (Structured Data)
    sql_keywords = [
        "rent", "price", "property", "list", "available", "where", "doha", "west bay", "lusail",
        "address", "location", "floor", "sqft", "area", "bedroom", "bathroom", "amenities",
        "gym", "pool", "parking", "view", "balcony", "furnished", "near", "street", "building"
    ]
    if any(k in user_input for k in sql_keywords) and "query_sql_db" not in plan:
        plan.append("query_sql_db")
        
    # Vector Heuristics (Unstructured Data)
    vector_keywords = [
        "permit", "lease", "policy", "rule", "pet", "termination", "penalty", "zoning", "terms",
        "agreement", "contract", "obligation", "deposit", "notice", "period", "maintenance",
        "repair", "late fee", "guest", "smoking", "sublet", "renovation", "summary"
    ]
    if any(k in user_input for k in vector_keywords) and "query_vector_db" not in plan:
        plan.append("query_vector_db")
        
    if not plan:
        # Default fallback
        plan = ["query_sql_db"]
        
    return {
        "plan": plan,
        "current_step": 0,
        "tool_outputs": []
    }
