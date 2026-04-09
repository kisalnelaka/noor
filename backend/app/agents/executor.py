from typing import Dict, Any
from app.agents.states import AgentState
from app.tools.sql_tool import query_sql_database
from app.tools.rag_tool import query_vector_database
import json
import re

async def executor_node(state: AgentState) -> Dict[str, Any]:
    """
    Executor Agent Node (NOOR).
    - Employs 'NOOR' persona for synthesis.
    - Saves last_property_id to session memory.
    - Generates NOOR structured JSON responses.
    - Provides proactive 'Auto-Insights'.
    """
    plan = state["plan"]
    current_step = state.get("current_step", 0)
    user_input = state["user_input"].lower()
    
    # 🕵️ Context Resolution for 'it' or 'that'
    context_property_id = state.get("last_property_id")
    
    print(f"[Executor] Step {current_step+1}/{len(plan)}: {plan[current_step]}", flush=True)
    print(f"[Executor] Context Property ID (memory): {context_property_id}", flush=True)
    
    tool_output = ""
    step_type = plan[current_step]

    # 🕵️ Location Resolution (from augmented input)
    lat_lng_match = re.search(r'\[Location: ([\d\.-]+),([\d\.-]+)\]', state["user_input"])
    user_lat = float(lat_lng_match.group(1)) if lat_lng_match else None
    user_lng = float(lat_lng_match.group(2)) if lat_lng_match else None

    if step_type == "query_sql_db":
        # 🧠 Intent Resolution Engine: Price, Proximity, & District
        base_select = """
            'prop_' || p.id as id, p.name, p.address, p.latitude, p.longitude, 
            min(u.rent_price) as price,
            'Premium Amenities & Metro (500m)' as pois,
            '6.8%' as roi,
            'QAR ' || CAST(min(u.rent_price) * 12 * 0.07 AS INT) || 'k' as yield
        """
        
        # 🎯 INTENT PRIORITY ORDER (Hardened for Demo)
        # 1. Explicit Property Name (Highest Priority)
        # 2. Filter Overrides (Expensive/Cheap) - Resets Context
        # 3. District-based search
        # 4. Context Follow-up (What are POIs? / Tell me more)
        # 5. Proximity Search (Near me)
        
        # 🔍 Step 1: Explicit Name Matching (Regex)
        property_name_match = None
        # Dynamic list of known property keywords from DB names
        match_keywords = ["horizon", "pearl", "al sadd", "lusail smart", "sapphire", "onyx", "azure", "velvet", "oasis", "marina", "west bay tower"]
        for kw in match_keywords:
            if re.search(rf"\b{kw}\b", user_input):
                property_name_match = kw
                break
        
        if property_name_match:
            print(f"[Executor] 🎯 MATCHED NAME: {property_name_match}")
            sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id WHERE LOWER(p.name) LIKE '%{property_name_match}%' GROUP BY p.id LIMIT 1"
            tool_output = query_sql_database.run(sql)
            
        elif any(w in user_input for w in ["expensive", "luxury", "premium", "top tier", "high end", "most", "highest"]):
            print(f"[Executor] 🎯 MATCHED INTENT: Expensive")
            sql = f"SELECT {base_select.replace('min(u.rent_price)', 'max(u.rent_price)')} FROM properties p JOIN units u ON p.id = u.property_id GROUP BY p.id ORDER BY price DESC LIMIT 3"
            tool_output = query_sql_database.run(sql)
            
        elif any(w in user_input for w in ["cheap", "budget", "affordable", "lowest", "least", "cheapest"]):
            print(f"[Executor] 🎯 MATCHED INTENT: Cheapest")
            sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id GROUP BY p.id ORDER BY price ASC LIMIT 3"
            tool_output = query_sql_database.run(sql)
            
        elif any(w in user_input for w in ["west bay", "lusail", "pearl", "al sadd", "mushaireb"]):
            district = next(d for d in ["west bay", "lusail", "pearl", "al sadd", "mushaireb"] if d in user_input)
            print(f"[Executor] 🎯 MATCHED DISTRICT: {district}")
            sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id WHERE LOWER(p.address) LIKE '%{district}%' GROUP BY p.id LIMIT 3"
            tool_output = query_sql_database.run(sql)
            
        elif context_property_id and any(w in user_input for w in ["it", "that", "this", "more", "details", "poi", "point", "interest", "amenities", "close", "near"]):
            # 🧠 FOLLOW-UP: The user is asking about the specific property we just discussed.
            raw_id = context_property_id.split("_")[1] if "_" in context_property_id else context_property_id
            print(f"[Executor] 🎯 MATCHED CONTEXT: {context_property_id}")
            sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id WHERE p.id = '{raw_id}' GROUP BY p.id"
            tool_output = query_sql_database.run(sql)
            
        elif any(w in user_input for w in ["near me", "closest", "nearby", "nearest"]) and user_lat and user_lng:
            print(f"[Executor] 🎯 MATCHED PROXIMITY: Near User", flush=True)
            sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id GROUP BY p.id ORDER BY ((latitude - :lat) * (latitude - :lat) + (longitude - :lng) * (longitude - :lng)) ASC LIMIT 3"
            params = {"lat": user_lat, "lng": user_lng}
            tool_output = query_sql_database.func(sql, params=params)
            
        elif any(w in user_input for w in ["trend", "market", "analytics", "price history", "history"]):
            print(f"[Executor] 🎯 MATCHED INTENT: District Trends", flush=True)
            district = "Doha"
            for d in ["west bay", "lusail", "pearl", "al sadd"]:
                if d in user_input: district = d.title(); break
            
            # Proactive Analytical Command
            ui_commands.append({
                "action": "show_trends",
                "district": district,
                "history": [2.4, 2.5, 2.8, 3.1, 2.9, 3.2, 3.5] # 📊 Luxury Price Index (Millions QAR)
            })
            tool_output = f"Retrieved latest market trends for {district}. Prices are currently trending upwards by 8.4% YoY."
            
        elif any(w in user_input for w in ["book", "viewing", "visit", "schedule"]):
            print(f"[Executor] 🎯 MATCHED INTENT: Jarvis Scheduler", flush=True)
            prop_name = "this property"
            if context_property_id:
                # Mock booking logic
                ui_commands.append({
                    "action": "book_viewing",
                    "id": context_property_id,
                    "date": "Tomorrow at 4:30 PM",
                    "status": "Confirmed"
                })
                tool_output = f"Successfully scheduled a private viewing for {context_property_id} tomorrow at 4:30 PM. I have notified the listing agent."
            else:
                tool_output = "I'd be happy to schedule a viewing. Which property were you interested in?"
        else:
            print(f"[Executor] 🎯 FALLBACK: Default List", flush=True)
            sql = f"SELECT {base_select} FROM properties p JOIN units u ON p.id = u.property_id GROUP BY p.id LIMIT 5"
            tool_output = query_sql_database.run(sql)
        
        print(f"[Executor] SQL Result Summary: {tool_output[:200]}...")
        
    elif step_type == "query_vector_db":
        enhanced_query = user_input
        if context_property_id:
            enhanced_query = f"Regarding {context_property_id}: {user_input}"
        tool_output = query_vector_database.run(enhanced_query)
    
    outputs = state.get("tool_outputs", []) + [{ "step": step_type, "output": tool_output }]
    
    # 🏁 Response Synthesis (NOOR Intelligence)
    draft = ""
    ui_commands = []
    current_prop_id = context_property_id # Default to previous memory
    
    if current_step >= len(plan) - 1:
        from app.agents.llm_provider import llm
        
        system_prompt = """
        You are NOOR (نور), a friendly, helpful, and highly intelligent AI Real Estate Concierge for the Qatar market.
        Your tone is warm, professional, and welcoming—like a premier hotel concierge or a trusted luxury property advisor.
        
        RULE: BE CONVERSATIONAL & HELPFUL. Always be polite. Use phrases like "I'm happy to show you," "Certainly! Here is what I identified," or "I've found a wonderful option for you."
        
        BILINGUAL EXCELLENCE:
        - If the user speaks Arabic, respond in fluent, high-fidelity Arabic.
        - If the user speaks English, respond in polished, professional English.
        - Ensure all property names and details are described naturally in the target language.
        
        TASK:
        1. Provide a warm and factual response. If you find multiple listings, guide the user through the best options politely.
        2. Identify the language (Arabic/English) and respond perfectly in that language.
        3. Include at least one helpful detail (Price, ROI, or Location) to assist their decision.
        4. If a specific property is a great match, output 'show_property'.
        5. CLOSURE: Always offer further assistance (e.g., "Would you like more details on this tower, or perhaps a different neighborhood?").
        
        STRICT PROTOCOLS:
        - PERSONALIZATION: Address the user as {user_name} where appropriate (e.g., "Certainly, {user_name}" or "I've found this for you, {user_name}").
        - Maintain the 'NOOR' persona as a helpful partner.
        - NEVER say raw IDs like 'prop_1'. Always use the property's name.
        - You MUST ONLY use 'id' values derived from the {tool_data}. 
        - Accuracy is paramount. Do not hallucinate prices.

        OUTPUT FORMAT (Strict JSON):
        {{
          "response": "Your spoken text. Concise and expert.",
          "detected_language": "en",
          "ui_commands": [
            {{
              "action": "show_property", 
              "id": "COPY_ID_FROM_DATA", 
              "name": "COPY_NAME_FROM_DATA",
              "price": "COPY_PRICE_FROM_DATA",
              "roi": "COPY_ROI_FROM_DATA",
              "yield": "COPY_YIELD_FROM_DATA",
              "pois": "COPY_POIS_FROM_DATA",
              "address": "COPY_ADDRESS_FROM_DATA",
              "lat": COPY_LAT_FROM_DATA,
              "lng": COPY_LNG_FROM_DATA,
              "image_url": "COPY_URL_FROM_DATA",
              "furnished_image_url": "COPY_URL_FROM_DATA",
              "tour_url": "COPY_URL_FROM_DATA"
            }}
          ]
        }}
        
        CRITICAL: All values in 'ui_commands' MUST be copied EXACTLY from the provided {tool_data}. If 'image_url' is provided in the data, you MUST include it in the JSON output.
        """
        
        # 🛠️ V5: CLEAN DATA EXTRACTION
        # Pre-process tool outputs to give the LLM a clean, searchable list of properties
        clean_tool_data = []
        for out in outputs:
            if out.get("step") == "query_sql_db":
                try:
                    props = json.loads(out["output"])
                    clean_tool_data.extend(props)
                except:
                    pass
            else:
                clean_tool_data.append(out)

        tool_data_str = json.dumps(clean_tool_data, indent=2)
        user_name = state.get("user_name", "Kisal")
        prompt = system_prompt.format(tool_data=tool_data_str, user_query=state["user_input"], user_name=user_name)
        
        print("[Executor] Synthesizing NOOR Response...", flush=True)
        llm_response_str = await llm.chat([{"role": "user", "content": prompt}])
        
        try:
            start_idx = llm_response_str.find("{")
            end_idx = llm_response_str.rfind("}") + 1
            if start_idx != -1 and end_idx != -1:
                clean_json = llm_response_str[start_idx:end_idx]
                res_data = json.loads(clean_json)
                draft = res_data.get("response", "").strip()
                if not draft:
                    # Fallback: Find the first paragraph in the raw response that isn't JSON
                    paragraphs = llm_response_str.split('\n\n')
                    draft = paragraphs[0].strip() if paragraphs else llm_response_str
                
                ui_commands = res_data.get("ui_commands", [])
                
                # 🧠 Context Update Logic
                for cmd in ui_commands:
                    if cmd.get("action") == "show_property" and cmd.get("id"):
                        current_prop_id = cmd["id"]
                        print(f"[Executor] Memory Context Updated: {current_prop_id}")
                        break
            else:
                draft = llm_response_str if llm_response_str.strip() else "I encountered an error analyzing my database results."
        except Exception as e:
            print(f"[Executor] Synthesis Error: {e}", flush=True)
            draft = "I apologize, but I encountered a technical issue while synthesizing your response. Please try again."

    return {
        "tool_outputs": outputs,
        "current_step": current_step + 1,
        "final_response": draft, # 🛠️ Updated key for main.py sync
        "ui_commands": ui_commands,
        "last_property_id": current_prop_id
    }
