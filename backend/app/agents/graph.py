from langgraph.graph import StateGraph, END
from .states import AgentState
from .planner import planner_node
from .executor import executor_node
from .critic import critic_node

def should_execute_more(state: AgentState) -> str:
    """Router to determine if we continue executing plan or go to Critic"""
    plan = state.get("plan", [])
    current_step = state.get("current_step", 0)
    
    if current_step < len(plan):
        return "executor"
    return "critic"

def should_end(state: AgentState) -> str:
    """Router to determine if Critic approved or if we need to replan/re-execute"""
    if state.get("is_valid", False):
        return END
    return "planner" # Back to drawing board if hallucinated

# Build the Graph
workflow = StateGraph(AgentState)

# Add Nodes
workflow.add_node("planner", planner_node)
workflow.add_node("executor", executor_node)
workflow.add_node("critic", critic_node)

# Set Entry
workflow.set_entry_point("planner")

# Add Edges
workflow.add_edge("planner", "executor")
workflow.add_conditional_edges("executor", should_execute_more, {
    "executor": "executor",
    "critic": "critic"
})
workflow.add_conditional_edges("critic", should_end, {
    END: END,
    "planner": "planner"
})

aura_app = workflow.compile()
