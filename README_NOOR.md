# NOOR: AI Concierge System Documentation (V5.12)

## OVERVIEW
NOOR is a hyper-intelligent, voice-first AI Concierge tailored for the Qatari luxury real estate ecosystem. Unlike standard RAG bots, NOOR utilizes a **Zero-Hallucination Architecture** to provide flawless property discovery, spatial navigation, and bilingual assistance. It is designed to feel less like a lifestyle partner than a search tool.

---

## CORE CAPABILITIES

### 1. Zero-Hallucination Intelligence Engine
*   **Planning & Execution**: Uses a three-tier agentic loop (**Planner → Executor → Critic**) to validate every response against the live SQL database and Vector store.
*   **Hard-Trigger Navigation**: Bypasses LLM text generation for directions. "Take me there" triggers a direct OS-level map injection with sub-meter accuracy.
*   **Contextual Binding**: Every message bubble is uniquely bound to its specific property ID; "View Details" always opens the correct, real-time listing for that specific turn.

### 2. Native Bilingual Protocol (EN/AR)
*   **Auto-Language Matching**: Automatically detects the user's input language. If the user speaks Arabic, NOOR responds natively in Arabic (not English with an accent).
*   **Parallel Translation Relay**: Generates an English/Arabic translation for every interaction, accessible via a real-time "Translate" toggle in the chat interface.

### 3. Lifestyle-First Experience
*   **Persona Enforcement**: Strictly prohibits financial jargon (`ROI`, `Yield`, `Investment`). Responses focus on neighborhood vibes, luxury amenities, and lifestyle scores.
*   **Personalized Greeting**: Persistent session memory ensures NOOR remembers the user's name and priorities across the entire conversation.
*   **Haptic Orchestration**: Synchronized haptic pulses (Light/Medium/Heavy) match the AI's "thinking" and "speaking" states for a physical connection.

---

## TECHNICAL ARCHITECTURE

### Input & Processing Pipeline
1.  **Audio**: Captured at 16kHz and transcribed via **Faster-Whisper (INT8 optimized)** with sub-1s latency.
2.  **Telemetry**: Real-time GPS/Compass data is injected into the prompt context for spatial awareness.
3.  **Synthesis**: **Llama 3 (70B) via Groq Cloud** handles reasoning, conditioned by a strict Concierge System Prompt.
4.  **Delivery**: Streamed WebSocket output allows parallel delivery of:
    *   **Text Streaming**: Word-by-word UI rendering.
    *   **Neural TTS**: High-fidelity streaming audio via **Edge-TTS (Azure Neural)**.
    *   **UI Payloads**: Dynamic triggers for property cards, map previews, and viewing booking.

### Data Layer
*   **Relational (SQL)**: Core property inventory and user profiles.
*   **Vector (Qdrant)**: Similarity search for lifestyle descriptions and Qatari neighborhood insights.
*   **Session (Redis)**: Cross-turn memory and transient state management.

---

## SYSTEM CONSTRAINTS & ROADMAP
*   **Current State**: Optimized for the State of Qatar; expertise in Lusail, West Bay, The Pearl, and Msheireb.
*   **Transactions**: Advanced booking flow creates secure viewing requests directly in the agent's calendar.
*   **Future Development**: Predictive neighborhood price modeling and Augmented Reality (AR) interior walkthroughs are currently in closed beta.

---

## ACCESS & DEPLOYMENT
*   **Development Portal**: `http://localhost:8000/docs`
*   **Brain WebSocket**: `ws/wss://[TUNNEL-URL]/ws/chat`
*   **Seed Data**: Auto-deploys 50+ premium Qatari listings on system boot.
