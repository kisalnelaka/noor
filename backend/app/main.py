import os
import sys
import json
import base64
import asyncio
import tempfile
import logging
import subprocess
import time
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from app.db.database import get_db, engine
from app.db.models import Base
from app.agents.graph import aura_app as app_graph
from app.agents.states import AgentState
import uuid

# Initialize FastAPI
app = FastAPI(title="NOOR AI Concierge Core")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    # Ensure tables exist. This is silent and does not seed data.
    from app.db.models import Base
    from app.db.database import engine
    Base.metadata.create_all(bind=engine)

# Database tables are managed externally by the seeder script for initial data population.


@app.get("/properties/featured")
async def get_featured_properties(db: Session = Depends(get_db)):
    from app.db.models import Property, Unit
    from sqlalchemy import func
    props = db.query(Property.id, Property.name, Property.address, Property.image_url, Property.latitude.label("lat"), Property.longitude.label("lng"), func.min(Unit.rent_price).label("price")).join(Unit).group_by(Property.id).limit(5).all()
    valid_images = [
        "1600596542815-ffad4c1539a9",
        "1512917774080-9991f1c4c750",
        "1600607687920-4e2a09cf159d",
        "1580587771525-78b9dba3b914",
        "1600585154340-be6161a56a0c"
    ]
    return [{"id": f"prop_{p.id}", "name": p.name, "address": p.address, "image_url": f"https://images.unsplash.com/photo-{valid_images[i % len(valid_images)]}?auto=format&fit=crop&q=80&w=1200", "price": f"QAR {int(p.price):,}/mo", "lat": p.lat, "lng": p.lng, "sqft": "2,450", "beds": 3, "baths": 2, "pois": "Shopping (2m), Metro (5m)"} for i, p in enumerate(props)]

from pydantic import BaseModel
from fastapi import Form

class RegisterRequest(BaseModel):
    email: str
    password: str
    full_name: str

@app.post("/auth/register")
async def register(req: RegisterRequest, db: Session = Depends(get_db)):
    from app.db.models import User
    existing = db.query(User).filter(User.email == req.email).first()
    if existing:
        return {"access_token": "token", "full_name": existing.full_name} # Existing user logic
    
    new_user = User(
        email=req.email,
        hashed_password=req.password, # For demo, raw storage
        full_name=req.full_name
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"access_token": f"token_{new_user.id}", "full_name": new_user.full_name}

@app.post("/auth/login")
async def login(username: str = Form(...), password: str = Form(...), db: Session = Depends(get_db)):
    from app.db.models import User
    user = db.query(User).filter(User.email == username).first()
    if user and user.hashed_password == password:
        return {"access_token": f"token_{user.id}", "full_name": user.full_name}
    return {"detail": "Invalid credentials", "statusCode": 401}

@app.get("/user/portfolio")
async def get_portfolio(db: Session = Depends(get_db)):
    # In a full app, we'd use the access token. 
    # For this demo/walkthrough, we fetch the first user or default.
    from app.db.models import User, Booking
    user = db.query(User).first()
    name = user.full_name if user else "Noor User"
    email = user.email if user else "demo@noor.qa"
    
    return {
        "full_name": name,
        "email": email,
        "bookings": [{"property_name": "Azure Manor 1", "time": "10 May 2026, 14:00", "status": "Confirmed"}],
        "documents": [{"type": "lease", "name": "Digital Lease Agreement", "status": "Signed"}]
    }

# Load Models
try:
    from faster_whisper import WhisperModel
    print("[NOOR] Loading Whisper (medium)...", flush=True)
    whisper_model = WhisperModel("medium", device="cpu", compute_type="int8")
except: whisper_model = None

@app.websocket("/ws/chat")
async def websocket_endpoint(websocket: WebSocket):
    last_interaction_time = time.time()
    
    session_id = str(uuid.uuid4())
    await websocket.accept()
    
    # Session-Scoped State
    session_state = {
        "is_speaking": False,
        "last_property_id": None,
        "user_name": "Kisal",
        "user_priorities": "Lifestyle & Premium Service",
        "current_language": "en"
    }
    
    chat_history = []
    print(f"--- [NEW_SESSION] {session_id} ---", flush=True)

    async def handle_message(payload: dict):
        try:
            if payload.get("type") == "set_profile":
                session_state["user_name"] = payload.get("full_name", session_state["user_name"])
                session_state["user_priorities"] = payload.get("priorities", session_state["user_priorities"])
                print(f"[Profile] Active: {session_state['user_name']} | {session_state['user_priorities']}", flush=True)
                return

            if payload.get("type") == "playback_complete":
                session_state["is_speaking"] = False
                return

            t_start = time.time()
            content = ""
            lat, lng = "none", "none"
            loc = payload.get("location")
            if loc and "," in loc:
                lat, lng = loc.split(",", 1)
            elif payload.get("lat") and payload.get("lng"):
                lat, lng = payload.get("lat"), payload.get("lng")

            # 🛠️ Fast-Path Greeting
            raw_text = payload.get("text", "").lower() if payload.get("type") == "chat" else ""
            if any(w in raw_text for w in ["hi", "hello", "good morning", "good evening", "hey"]):
                greeting = "Hello! I'm NOOR, your AI Concierge. How can I assist you with Qatar's premium real estate today?"
                await websocket.send_json({"type": "user_transcription", "text": payload.get("text")})
                await websocket.send_json({"type": "text_stream", "content": greeting, "is_complete": True})
                return

            if payload.get("type") == "audio_input":
                if session_state["is_speaking"]: 
                    print("[NOOR] Ignoring audio input while speaking.", flush=True)
                    return
                    
                audio_bytes = base64.b64decode(payload.get("audio_b64", ""))
                with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp_audio:
                    tmp_audio.write(audio_bytes)
                    tmp_audio_path = tmp_audio.name
                
                groq_key = os.getenv("GROQ_API_KEY")
                if groq_key:
                    from groq import Groq
                    print("[NOOR] Using Groq API for STT...", flush=True)
                    client = Groq(api_key=groq_key)
                    with open(tmp_audio_path, "rb") as file:
                        transcription = client.audio.transcriptions.create(
                            file=(tmp_audio_path, file.read()),
                            model="whisper-large-v3",
                            prompt="Qatar, Doha, Lusail, West Bay, The Pearl, NOOR, عقارات, قطر, لوسيل",
                            response_format="text",
                            language="ar" if is_arabic else None # Auto-detecting mostly
                        )
                    content = transcription
                    session_state["current_language"] = "ar" if any(c in content for c in "بضصفغعهخحجدذرزسشصضطظعغفقكلمنهوي") else "en"
                elif whisper_model:
                    t0_stt = time.time()
                    segments, info = await asyncio.to_thread(
                        whisper_model.transcribe, tmp_audio_path, beam_size=1, vad_filter=True,
                        initial_prompt="Qatar, Doha, Lusail, West Bay, The Pearl, NOOR, عقارات, قطر, لوسيل"
                    )
                    t_stt = time.time() - t0_stt
                    session_state["current_language"] = info.language if info.language in ["ar", "en"] else "en"
                    content = " ".join([s.text for s in segments])
                
                await websocket.send_json({"type": "user_transcription", "text": content})
                if os.path.exists(tmp_audio_path): os.unlink(tmp_audio_path)
            
            elif payload.get("type") == "chat":
                content = payload.get("text", "")
                await websocket.send_json({"type": "user_transcription", "text": content})

            if not content or len(content.strip()) < 2: return

            is_arabic = any(c in content for c in "بضصفغعهخحجدذرزسشصضطظعغفقكلمنهوي")
            await websocket.send_json({"type": "status", "content": "Searching..."})

            # Graph Input with 15s Watchdog
            graph_input = f"[Language: {'ar' if is_arabic else 'en'}] [Priority: {session_state['user_priorities']}] [Location: {lat},{lng}] {content}"
            initial_state = AgentState(
                user_input=graph_input, session_id=session_id, chat_history=list(chat_history[-6:]), plan=[], current_step=0, tool_outputs=[],
                draft_response="", is_valid=False, final_response="", ui_commands=[], 
                last_property_id=session_state["last_property_id"], user_name=session_state["user_name"], user_prefs={"priorities": session_state["user_priorities"]}
            )

            try:
                t0_agent = time.time()
                result = await asyncio.wait_for(app_graph.ainvoke(initial_state), timeout=15.0)
                t_agent = time.time() - t0_agent
            except asyncio.TimeoutError:
                await websocket.send_json({"type": "text_stream", "content": "I apologize, my intelligence core is taking longer than usual. Please try again in a moment.", "is_complete": True})
                return

            final_response = result.get("draft_response", "I'm ready to help.")
            translation = result.get("translation", "")
            session_state["last_property_id"] = result.get("last_property_id")
            
            chat_history.append(f"User: {content}")
            chat_history.append(f"NOOR: {final_response}")

            # Stream & Speak
            words = final_response.split(" ")
            await websocket.send_json({"type": "text_stream", "content": (words.pop(0) + " ") if words else final_response, "is_complete": False})
            
            for cmd in result.get("ui_commands", []):
                if isinstance(cmd, dict):
                    await websocket.send_json({"type": "ui_trigger", "widget": cmd.get("action", "show_property"), "data": cmd})

            async def stream_task():
                for i, word in enumerate(words):
                    await websocket.send_json({"type": "text_stream", "content": word + " ", "is_complete": (i == len(words)-1)})
                    await asyncio.sleep(0.04)
                await websocket.send_json({"type": "text_final", "translation": translation})

            async def speak_task():
                voice = "ar-QA-AmalNeural" if session_state["current_language"] == "ar" else "en-US-AvaNeural"
                with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as tmp_mp3:
                    tmp_mp3_path = tmp_mp3.name
                try:
                    await asyncio.to_thread(subprocess.run, ["edge-tts", "--voice", voice, "--text", final_response, "--write-media", tmp_mp3_path], check=True, timeout=8)
                    with open(tmp_mp3_path, "rb") as f:
                        await websocket.send_json({"type": "audio_stream", "audio_b64": base64.b64encode(f.read()).decode('utf-8'), "language": session_state["current_language"]})
                except Exception as e: print(f"[TTS] Error: {e}")
                finally:
                    if os.path.exists(tmp_mp3_path): os.unlink(tmp_mp3_path)

            await asyncio.gather(stream_task(), speak_task())
            session_state["is_speaking"] = True

        except Exception as e:
            print(f"[Handler Error] {e}", flush=True)

    try:
        while True:
            data = await websocket.receive_text()
            try:
                payload = json.loads(data)
                asyncio.create_task(handle_message(payload))
            except Exception as e:
                print(f"[Loop Error] {e}", flush=True)
    except WebSocketDisconnect:
        print(f"[Disconnected] {session_id}")
