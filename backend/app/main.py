from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import time
import asyncio
from app.agents.memory import memory
from app.agents.graph import aura_app
from app.agents.states import AgentState
from app.api import auth
import os
import tempfile
import uuid
import json
import base64
import subprocess
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 🚀 Auto-Seed Database if empty
    from sqlalchemy import inspect
    from app.db.database import engine
    from scripts.seed_data import seed_db, generate_mock_pdfs
    
    inspector = inspect(engine)
    if not inspector.has_table("users"):
        print("[Startup] Creating database tables...")
        from app.db.models import Base
        Base.metadata.create_all(bind=engine)
        
    if not inspector.has_table("properties"):
        print("[Startup] Database needs seeding. Running auto-seed...")
        from scripts.seed_data import seed_db, generate_mock_pdfs
        seed_db()
        generate_mock_pdfs()
    else:
        print("[Startup] Database already initialized.")
    
    yield
import json

import base64
import os
import tempfile
import json
import redis

try:
    redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)
except Exception as e:
    print(f"[NOOR] Redis not available: {e}")
    redis_client = None

app = FastAPI(
    title="NOOR - Luxury AI Real Estate Concierge",
    description="God-Tier Multi-Agent API for Real Estate in Qatar",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)

def normalize_query(text: str) -> str:
    """Cleans up STT transcribed text: strips filler words and fixes formatting."""
    fillers = ["uh", "um", "ah", "like", "actually", "basically"]
    cleaned = text.lower().strip()
    for filler in fillers:
        cleaned = cleaned.replace(f" {filler} ", " ")
    return cleaned.strip(".?! ")

# Load AI Models
try:
    from faster_whisper import WhisperModel
    print("[NOOR] Loading WhisperModel (base) - Instant Demo Initialization...", flush=True)
    # Downgraded to base + VAD for ultra-fast English/Arabic recognition
    whisper_model = WhisperModel("base", device="cpu", compute_type="int8")
except Exception as e:
    print(f"Warning: WhisperModel not loaded: {e}")
    whisper_model = None

# 🚀 XTTS completely removed to liberate CPU. Using Edge-TTS.
tts_model = "edge-tts"

# Serve PDFs for the frontend
import os
os.makedirs("sample_docs", exist_ok=True)
app.mount("/docs", StaticFiles(directory="sample_docs"), name="docs")

@app.websocket("/ws/chat")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    session_id = "user_demo_session_123"
    session_id = str(uuid.uuid4())
    last_property_id = None
    user_prefs = {}
    full_name = "Kisal" # Default Demo Name
    current_language = "en" # Default
    is_speaking = False # 🛡️ Speaking lock for echo suppression
    
    try:
        while True:
            data = await websocket.receive_text()
            
            try:
                payload = json.loads(data)
                
                # 🏛️ V4: DOCUMENT INTELLIGENCE BRIDGE
                if payload.get("type") == "document_query":
                    doc_name = payload.get("document", "Lease")
                    query = payload.get("content", "Explain this")
                    print(f"[NOOR] Document Intelligence Query: {query} for {doc_name}", flush=True)
                    
                    await websocket.send_json({"type": "status", "content": f"Analyzing {doc_name}..."})
                    
                    # Call RAG tool directly for document context
                    from app.tools.rag_tool import query_vector_database
                    rag_response = query_vector_database.run(f"Regarding the document {doc_name}: {query}")
                    
                    # Stream the RAG response back as a text bubble
                    words = rag_response.split(" ")
                    for i, word in enumerate(words):
                        await websocket.send_json({
                            "type": "text_stream",
                            "content": word + " ",
                            "is_complete": (i == len(words) - 1)
                        })
                        await asyncio.sleep(0.02)
                    continue

                # ✨ Echo Shield: Drop wake-words if NOOR is currently talking
                if payload.get("type") == "audio_input" and payload.get("is_wake_word") == True and is_speaking:
                    print("[NOOR] Speaking lockout active. Dropping background burst.", flush=True)
                    continue

                # ✨ Handle Profile Identification
                if payload.get("type") == "set_profile":
                    user_prefs["full_name"] = payload.get("full_name", "Kisal")
                    user_prefs["email"] = payload.get("email", "")
                    print(f"[NOOR] Profile identified: {user_prefs['full_name']}", flush=True)
                    continue

                # ✨ Handle Profile Identification
                if payload.get("type") == "set_profile":
                    full_name = payload.get("full_name", "Kisal")
                    print(f"[NOOR] Profile identified: {full_name}", flush=True)
                    continue

                # 🧩 Handle Playback Complete Sync from Phone
                if payload.get("type") == "playback_complete":
                    is_speaking = False
                    print("[NOOR] Speech lockout released.", flush=True)
                    continue

                content = ""
                
                # Sync language with client preference
                if payload.get("language"):
                    current_language = payload.get("language")
                
                # 🤯 Feature: Audio Input via Whisper
                if payload.get("type") == "audio_input":
                    audio_b64 = payload.get("audio_b64", "")
                    audio_bytes = base64.b64decode(audio_b64)
                    
                    await websocket.send_json({"type": "status", "content": "Transcribing voice..."})
                    
                    with tempfile.NamedTemporaryFile(delete=False, suffix=".m4a") as tmp_audio:
                        tmp_audio.write(audio_bytes)
                        tmp_audio_path = tmp_audio.name
                        
                    if whisper_model:
                        # ✨ Aura V2: Improved STT with VAD & Normalization
                        import functools
                        import subprocess
                        transcribe_func = functools.partial(
                            whisper_model.transcribe,
                            tmp_audio_path,
                            beam_size=5,
                            vad_filter=True,
                            vad_parameters=dict(min_silence_duration_ms=800), # 🛡️ Tuning: More aggressive silence detection
                            initial_prompt="Qatar, Doha, Lusail, West Bay, Msheireb, The Pearl, NOOR, عقارات, قطر, الدوحة",
                            language=None # Enable Autodetection
                        )
                        segments, info = await asyncio.to_thread(transcribe_func)
                        detected_lang = info.language if info.language in ["ar", "en"] else "en"
                        current_language = detected_lang
                        print(f"[NOOR] Language Detected: {detected_lang}", flush=True)
                        original_text = " ".join([segment.text for segment in segments])
                        content = normalize_query(original_text)
                        
                        if payload.get("is_wake_word"):
                            if "noor" not in content.lower():
                                os.unlink(tmp_audio_path)
                                continue
                            else:
                                print(f"[NOOR] Wake-word detected! (Heard: {content})", flush=True)
                                await websocket.send_json({"type": "pulse", "intensity": 1})
                                await websocket.send_json({"type": "status", "content": "Listening..."})
                                await websocket.send_json({"type": "text_stream", "content": "Yes? I am here. ", "is_complete": True})
                                os.unlink(tmp_audio_path)
                                continue

                        print(f"[NOOR] Transcribed: {content} (original: {original_text})", flush=True)
                        
                        if not content or len(content) < 2:
                            repeat_msg = "I'm sorry, I didn't quite catch that. Could you repeat? (أعتذر، لم أسمعك جيداً. هل يمكنك التكرار؟)"
                            await websocket.send_json({"type": "text_stream", "content": repeat_msg, "is_complete": True})
                            os.unlink(tmp_audio_path)
                            continue
                        
                        await websocket.send_json({"type": "user_input", "content": content})
                        await asyncio.sleep(0.5)
                    
                    os.unlink(tmp_audio_path)
                else:
                    content = payload.get("content", "")
                
                # Extract NOOR Context (Geo-fencing & Profile)
                lat = payload.get("lat")
                lng = payload.get("lng")
                heading = payload.get("heading")
                # 🛡️ DEMO OVERRIDE: Prevent 401 Auth Crashing in demo
                token = payload.get("token", "demo-token")
                from app.core.security import verify_jwt_token
                try:
                    user_context = verify_jwt_token(token)
                except Exception:
                    # In demo mode, fallback to a standard profile
                    user_context = {"user_id": 1, "priorities": "Standard"}
                
                priorities = user_context.get("priorities", "Standard")
                
                if not content:
                    continue

                # Signal "Thinking Mode 2.0"
                thinking_msg = "NOOR is processing..."
                if "horizon" in content.lower() or (last_property_id == "prop_1"):
                    thinking_msg = "Consulting The Horizon Tower's intelligence feed..."
                elif "vendome" in content.lower() or "lusail" in content.lower():
                    thinking_msg = "Analyzing Place Vendôme and Lusail metrics..."
                
                await websocket.send_json({"type": "status", "content": thinking_msg})
                
                # 🤯 Zero-Latency Shutter: Disabled for 100% Demo Command Accuracy
                fast_response = None
                
                if fast_response:
                    await websocket.send_json({"type": "status", "content": "Instant NOOR Memory accessed."})
                    final_response = fast_response
                    result = {"final_response": final_response, "ui_commands": [], "last_property_id": last_property_id, "user_prefs": user_prefs}
                else:
                    # Pass to real LangGraph with Priority Prompt Injection
                    augmented_input = f"[User Priority: {priorities}] [Location: {lat},{lng}] {content}"
                    initial_state = AgentState(
                        user_input=augmented_input,
                        session_id=session_id,
                        chat_history=[],
                        plan=[],
                        current_step=0,
                        tool_outputs=[],
                        draft_response="",
                        critic_notes="",
                        is_valid=False,
                        final_response="",
                        ui_commands=[],
                        last_property_id=last_property_id,
                        user_name=full_name, # 🧑‍💼 Personalized Name
                        user_prefs=user_prefs
                    )
                    
                    # We could stream graph steps, but for now we invoke and wait
                    result = await aura_app.ainvoke(initial_state)
                    final_response = result.get("final_response", "I'm sorry, I couldn't process that.")
                    
                    # Cache the response for future zero-latency
                    if redis_client:
                        try:
                            redis_client.setex(f"noor_cache:{content.lower().strip()}", 3600, final_response)
                        except:
                            pass
                
                # Update persistent session state
                last_property_id = result.get("last_property_id")
                user_prefs = result.get("user_prefs", {})
                
                # 🚀 SHUTTER: ENGAGE!
                is_speaking = True 

                # Safety: Auto-reset speaking lock after 15s if no pulse is received
                async def auto_reset_lock():
                    await asyncio.sleep(15)
                    nonlocal is_speaking
                    if is_speaking:
                        is_speaking = False
                        print("[NOOR] Safety timeout: Speaking lockout released.", flush=True)
                
                asyncio.create_task(auto_reset_lock())

                # 🤯 Feature: Parallel Text & Audio Pipelining
                async def stream_text():
                    words = final_response.split(" ")
                    for i, word in enumerate(words):
                        is_end = (i == len(words) - 1)
                        await websocket.send_json({
                            "type": "text_stream",
                            "content": word + " ",
                            "is_complete": is_end # 🛠️ Sync with frontend expectation
                        })
                        await asyncio.sleep(0.04) 
                    
                    # Safety Shutter: Close the bubble
                    await websocket.send_json({"type": "text_final"})

                async def handle_audio():
                    # Send an initial pulse command for the Haptic sync kick-off
                    await websocket.send_json({"type": "pulse", "intensity": 1})
                    
                    try:
                        voice = "ar-QA-AmalNeural" if current_language == "ar" else "en-US-AriaNeural"
                        # 🌪️ V5 Resilience: Try Fast Cloud TTS first
                        try:
                            with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as tmp_mp3:
                                tmp_mp3_path = tmp_mp3.name
                            
                            await asyncio.to_thread(
                                subprocess.run,
                                ["edge-tts", "--voice", voice, "--text", final_response, "--write-media", tmp_mp3_path],
                                check=True, timeout=5
                            )
                        except Exception as cloud_err:
                            print(f"[NOOR] Cloud TTS Failed (503), falling back to local espeak-ng: {cloud_err}")
                            with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp_wav:
                                tmp_mp3_path = tmp_wav.name
                            
                            # Fallback: Local espeak-ng (robotic but reliable for the demo)
                            # Using '-v ar' for Arabic fallback or default for English
                            v_flag = "ar" if current_language == "ar" else "en-us"
                            await asyncio.to_thread(
                                subprocess.run,
                                ["espeak-ng", "-v", v_flag, "-w", tmp_mp3_path, final_response],
                                check=True
                            )
                        
                        with open(tmp_mp3_path, "rb") as f:
                            wav_bytes = f.read()
                        wav_b64 = base64.b64encode(wav_bytes).decode('utf-8')
                        if os.path.exists(tmp_mp3_path): os.unlink(tmp_mp3_path)
                        
                        await websocket.send_json({
                            "type": "audio_stream",
                            "audio_b64": wav_b64,
                            "language": current_language
                        })
                    except Exception as e:
                        print(f"[NOOR] Total Audio Failure: {e}", flush=True)


                # Execute Text and Audio tasks concurrently with error resilience
                try:
                    await asyncio.gather(stream_text(), handle_audio())
                except Exception as gather_err:
                    print(f"[NOOR] Gather Tasks Error: {gather_err}", flush=True)
                
                # 🛡️ Release shutter after streaming (or wait for frontend confirmation)
                is_speaking = True # Keep True for now, will be reset by 'playback_complete' or a timeout if needed

                # 🧩 V5: Pure Data Relay — No mocks, no interception
                ui_commands = result.get("ui_commands", [])
                for cmd in ui_commands:
                    action = cmd.get("action", "")
                    
                    if action == "show_property":
                        # Send as property_card with full data from LLM
                        await websocket.send_json({
                            "type": "ui_trigger",
                            "widget": "show_property",
                            "data": cmd
                        })
                    elif action == "show_directions":
                        # Extract lat/lng for Google Maps launch
                        await websocket.send_json({
                            "type": "ui_trigger",
                            "widget": "show_directions",
                            "data": {
                                "lat": cmd.get("lat"),
                                "lng": cmd.get("lng"),
                                "name": cmd.get("name", "Property")
                            }
                        })
                    elif action == "book_viewing":
                        await websocket.send_json({
                            "type": "ui_trigger",
                            "widget": "book_viewing",
                            "data": cmd
                        })
                    elif action == "show_trends":
                        await websocket.send_json({
                            "type": "ui_trigger",
                            "widget": "trend_chart",
                            "data": cmd
                        })
                    else:
                        # book_viewing, show_calculator, share_property etc
                        await websocket.send_json({
                            "type": "ui_trigger",
                            "widget": action,
                            "data": cmd
                        })
                
                # 🤯 Feature: Dynamic Follow-up Suggestions (Smart Chips)
                chips = ["Show properties", "West Bay only", "Lusail deals"] # Default
                response_lower = final_response.lower()
                
                if "horizon" in response_lower:
                    chips = ["View Location", "Lease Summary", "Gym & Pool info"]
                elif "maplewood" in response_lower:
                    chips = ["Garden details", "Termination policy", "Lusail map"]
                elif "loft" in response_lower or "industrial" in response_lower:
                    chips = ["Smoking policy", "View availability", "Similar lofts"]
                elif "amenities" in response_lower or "gym" in response_lower:
                    chips = ["Properties with Gym", "Pool access rules", "Parking price"]
                elif "lease" in response_lower or "contract" in response_lower:
                    chips = ["Penalty details", "Notice period", "Deposit info"]
                
                await websocket.send_json({
                    "type": "suggestions",
                    "chips": chips
                })

            except json.JSONDecodeError:
                print("Invalid JSON received.")
                
    except WebSocketDisconnect:
        print("Client disconnected from NOOR feed.", flush=True)
