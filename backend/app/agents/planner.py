from typing import Dict, Any
from .states import AgentState

async def planner_node(state: AgentState) -> Dict[str, Any]:
    """
    Planner Agent Node.
    Analyzes intent and establishes the multi-step execution chain.
    """
    user_input = state["user_input"].lower()
    session_id = state.get("session_id", "demo")
    
    # 🔍 TRACE: Advanced Logging for Debugging
    print(f"--- [PLANNER] ---")
    print(f"Session: {session_id}")
    print(f"Input: {user_input}")
    print(f"Last Property: {state.get('last_property_id')}")
    
    plan = []
    
    # Heuristics for intent detection
    if any(k in user_input for k in ["direction", "navigate", "how to go", "where is", "map", "take me", "ارشادات", "طريق", "خريطة", "وصول", "كيف اصل", "اين", "موقع", "اتجاهات", "خذني"]):
        print(f"[Planner] Intent: NAVIGATION")
        plan.append("query_sql_db") # Need to get property coords if they aren't in memory
        
    elif any(k in user_input for k in ["rent", "price", "property", "available", "show me", "al sadd", "west bay", "lusail", "عقار", "عقارات", "ايجار", "سعر", "متوفر", "ارني"]):
        print(f"[Planner] Intent: PROPERTY_SEARCH")
        plan.append("query_sql_db")
        
    elif any(k in user_input for k in ["rule", "policy", "lease", "agreement", "contract", "terms", "pet", "smoking"]):
        print(f"[Planner] Intent: KNOWLEDGE_RETRIEVAL")
        plan.append("query_vector_db")
        
    if not plan:
        print(f"[Planner] Intent: GENERAL_CONVERSATION")
        plan = ["query_sql_db"] # Always keep SQL for context matching
        
    print(f"Active Plan: {plan}")
    return {
        "plan": plan,
        "current_step": 0,
        "tool_outputs": []
    }
