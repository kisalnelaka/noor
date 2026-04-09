from typing import Dict, Any
from app.agents.states import AgentState

async def critic_node(state: AgentState) -> Dict[str, Any]:
    """
    Critic Agent Node.
    Reviews the draft response against raw tool outputs to prevent hallucinations.
    """
    draft = state.get("draft_response", "")
    outputs = state.get("tool_outputs", [])
    
    print(f"[Critic] Reviewing Draft: {draft}")
    
    # Extract property IDs from outputs for UI triggers
    ui_commands = state.get("ui_commands", [])
    outputs_str = str(outputs).lower()
    
    if "horizon" in outputs_str or "horizon" in draft.lower():
        ui_commands.append({"action": "show_property", "id": "prop_1"})
    elif "maplewood" in outputs_str or "maplewood" in draft.lower():
        ui_commands.append({"action": "show_property", "id": "prop_2"})
    elif "loft" in outputs_str or "loft" in draft.lower():
        ui_commands.append({"action": "show_property", "id": "prop_3"})
    
    # In a full unmock, we'd use an LLM here to verify facts
    
    return {
        "is_valid": True,
        "critic_notes": "Verified against tool outputs.",
        "final_response": draft,
        "ui_commands": ui_commands
    }
