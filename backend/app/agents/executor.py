from typing import Dict, Any
from app.agents.states import AgentState
from app.tools.sql_tool import query_sql_database
from app.tools.rag_tool import query_vector_database
import json
import re

async def executor_node(state: AgentState) -> Dict[str, Any]:
    """
    Executor Agent Node (NOOR).
    Strictly enforced concierge logic with native language response.
    """
    plan = state["plan"]
    current_step = state.get("current_step", 0)
    user_input = state["user_input"].lower()
    session_id = state.get("session_id", "demo")
    
    # Language Context
    lang_match = re.search(r'\[Language: (ar|en)\]', state["user_input"])
    detected_lang = lang_match.group(1) if lang_match else "en"
    
    print(f"\n--- [EXECUTOR] Step {current_step+1}/{len(plan)} (Lang: {detected_lang}) ---", flush=True)
    
    context_property_id = state.get("last_property_id")
    tool_output = ""
    step_type = plan[current_step]
    ui_commands = [] 
    
    is_navigation = any(w in user_input for w in ["direction", "navigate", "map", "take me", "how to go", "where is", "assist me", "ارشادات", "طريق", "خريطة", "وصول", "كيف اصل", "اين", "موقع", "اتجاهات", "خذني"])
    dist_map = {"west bay": "west bay", "lusail": "lusail", "lucille": "lusail", "pearl": "pearl", "the pearl": "pearl", "al sadd": "al sadd", "al sad": "al sadd", "mushaireb": "mushaireb", "msheireb": "mushaireb"}
    district = None
    for k, v in dist_map.items():
        if k in user_input:
            district = v
            break

    if step_type == "query_sql_db":
        base_select = "'prop_' || p.id as id, p.name, p.address as location, p.latitude as lat, p.longitude as lng, min(u.rent_price) as price, 'Elite Amenities' as pois"
        
        if is_navigation:
            target_id = context_property_id or "prop_1"
            raw_id = target_id.split("_")[1] if "_" in target_id else target_id
            sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id WHERE p.id = '{raw_id}' GROUP BY p.id"
            tool_output = query_sql_database.run(sql)
            try:
                p_data = json.loads(tool_output)[0]
                ui_commands.append({"action": "show_directions", "id": target_id, "lat": p_data["lat"], "lng": p_data["lng"], "name": p_data["name"]})
                tool_output = f"TRIGGERED_NAVIGATION: {p_data['name']}"
            except: tool_output = "Property found but coordinates unavailable."
        elif district:
            sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id WHERE LOWER(p.address) LIKE '%{district}%' GROUP BY p.id LIMIT 3"
            tool_output = query_sql_database.run(sql)
        elif context_property_id and not district:
            # Handle generic follow-up queries that implicitly reference the active property
            raw_id = context_property_id.split("_")[1] if "_" in context_property_id else context_property_id
            sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id WHERE p.id = '{raw_id}' GROUP BY p.id"
            tool_output = query_sql_database.run(sql)
            
            # If the user is specifically asking for *other* or *more* properties across the board, fall back slightly
            if "other" in user_input or "more properties" in user_input:
                 sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id GROUP BY p.id LIMIT 5"
                 tool_output += "\n" + query_sql_database.run(sql)
        else:
            sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id GROUP BY p.id LIMIT 5"
            tool_output = query_sql_database.run(sql)
    
    elif step_type == "query_vector_db":
        tool_output = query_vector_database.run(user_input)
    
    outputs = state.get("tool_outputs", []) + [{ "step": step_type, "output": tool_output }]
    
    draft = "I'm looking into that for you right now."
    translation = ""
    current_prop_id = context_property_id 
    
    if current_step >= len(plan) - 1:
        from app.agents.llm_provider import llm
        user_name = state.get("user_name", "Kisal")
        
        # 🧩 V5: Force language matching and robust translation key
        system_prompt = f"""
        You are NOOR (نور), a friendly AI Concierge for Qatar.
        Partner to {user_name}.
        
        RULES:
        1. GREETING: Address '{user_name}' by name.
        2. LANGUAGE: Detected language is '{detected_lang}'. ALWAYS respond to the user in this language as your primary 'response'.
        3. TRANSLATION: Provide the opposite language version in 'translation'.
        4. NO FINANCIALS: Never use 'ROI', 'Investment', 'Yield'.
        5. NO COORDINATES: NEVER read, speak, or output raw GPS coordinates (e.g., 25.31, 51.48) in your conversational response.
        
        OUTPUT FORMAT (Strict JSON):
        {{
          "response": "Text in {detected_lang}.",
          "translation": "Text in {'Arabic' if detected_lang == 'en' else 'English'}.",
          "ui_commands": []
        }}
        """
        
        try:
            history_str = "\n".join(state["chat_history"])
            prompt = system_prompt + f"\n\nCHAT_HISTORY:\n{history_str}\n\nDATA:\n{tool_output}\n\nUSER_QUERY: {state['user_input']}"
            llm_response_str = await llm.chat([{"role": "user", "content": prompt}])
            
            # Robust JSON parsing with regex extract
            json_match = re.search(r'\{.*\}', llm_response_str, re.DOTALL)
            if json_match:
                res_data = json.loads(json_match.group())
                draft = res_data.get("response", llm_response_str)
                translation = res_data.get("translation", "")
                
                llm_cmds = res_data.get("ui_commands", [])
                if isinstance(llm_cmds, list):
                    ui_commands.extend(llm_cmds)
                
                # Auto-inject ID if not present
                if "prop_" in tool_output and not any(c.get("action") == "show_property" for c in ui_commands):
                    p_ids = list(set([m.group() for m in re.finditer(r'prop_\d+', tool_output)]))
                    
                    if len(p_ids) > 1:
                        properties_list = []
                        for p_id in p_ids:
                            p_id_raw = p_id.split("_")[1]
                            p_details_raw = query_sql_database.run(f"SELECT 'prop_' || p.id as id, p.name, p.address as location, p.latitude as lat, p.longitude as lng, min(u.rent_price) as price FROM properties p JOIN units u ON p.id = u.property_id WHERE p.id = {p_id_raw} GROUP BY p.id")
                            if "prop_" in p_details_raw:
                                properties_list.append(json.loads(p_details_raw)[0])
                        
                        if properties_list:
                            ui_commands.append({"action": "show_properties_carousel", "properties": properties_list})
                    elif len(p_ids) == 1:
                        p_id_raw = p_ids[0].split("_")[1]
                        p_details_raw = query_sql_database.run(f"SELECT 'prop_' || p.id as id, p.name, p.address as location, p.latitude as lat, p.longitude as lng, min(u.rent_price) as price FROM properties p JOIN units u ON p.id = u.property_id WHERE p.id = {p_id_raw} GROUP BY p.id")
                        if "prop_" in p_details_raw:
                            ui_commands.append({"action": "show_property", **json.loads(p_details_raw)[0]})
                
                for cmd in ui_commands:
                    if isinstance(cmd, dict) and cmd.get("action") in ["show_property", "show_properties_carousel"]:
                        if cmd.get("id"):
                            current_prop_id = cmd["id"]
                            break
                        elif cmd.get("properties") and len(cmd["properties"]) > 0:
                            current_prop_id = cmd["properties"][0]["id"]
                            break
            else:
                draft = llm_response_str
        except Exception as e:
            print(f"[Executor] LLM Error: {e}", flush=True)

    return {
        "tool_outputs": outputs,
        "current_step": current_step + 1,
        "draft_response": draft,
        "translation": translation,
        "ui_commands": ui_commands,
        "last_property_id": current_prop_id
    }
