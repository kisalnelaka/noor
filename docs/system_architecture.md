# AURA - System Architecture

## Architecture Overview
The Aura platform is designed as a high-performance, low-latency, hybrid intelligence system tailored specifically for real estate. It seamlessly marries voice interactions with structured data queries (SQL), unstructured RAG queries (Vector Search), and spatial intelligence.

### 1. The Client Layer (Flutter)
- **Voice-First Experience**: The user's primary interface is a listening orb. Speech is streamed directly via WebSockets to the backend.
- **Smart UI Reactivity**: The backend pushes JSON payloads containing structural data (Property Cards, Maps, PDF references). Flutter dynamically renders these elements in a conversation feed below the voice visualizer.
- **State Management**: Built potentially with Riverpod or Bloc for responsive UI updates from WebSockets.

### 2. The API Layer (FastAPI)
- **Streaming WebSockets**: Essential for low latency. Receive raw audio bytes, send STT (Speech-to-text) transcripts back for confirmation, execute the Agent graph, and stream TTS (Text-to-speech) audio bytes + JSON payloads to the frontend.
- **Security Middleware**: Validates JWTs, sets rate limits to prevent expensive API spam, and applies Prompt Injection Protection heuristics before queries enter the LangGraph orchestrator.

### 3. The Orchestration Layer (LangGraph + LangChain)
The core "Brain" of Aura consists of a Multi-Agent StateGraph.
- **Planner Agent**: Analyzes user intent, translates voice intent into a multi-step sequence. For example: "Find me a 3-bedroom unit near the park and summarize its pet policy from the lease."
  - Step 1: SQL Agent -> fetch 3-bedroom near park.
  - Step 2: RAG Agent -> query Pet Policy in Vector DB using Lease PDF for the found unit.
- **Executor Agent**: Calls the tools defined by the planner. Tools include:
  - `SQLDatabaseChain` (PostgreSQL)
  - `QdrantVectorStore` Retreiver (RAG)
  - `GoogleMapsAPI` (Routing / Distance)
- **Critic Agent**: Intercepts the executor's output before TTS generation. Validates against hallucination and ensures logical consistency (e.g., ensuring a fetched property is actually active).
- **Memory Agent**: Interacts with Redis to store conversation memory and frequently queried properties. Retrieves user context (e.g., "this property" resolves to the last property ID in Redis).

### 4. The Data Layer
- **PostgreSQL + PostGIS**: Relational real estate data (users, properties, units, leases, transaction records) and spatial query support (`ST_DWithin`, geometry representations).
- **Qdrant**: High-performance Vector DB storing embeddings of unstructured PDFs (Leases, Permits, Floor Plan descriptions), Chunked using LangChain's RecursiveCharacterTextSplitter.
- **Redis**: Semantic query caching (to prevent executing the graph if someone asks the exact same question recently), context memory, and system metrics.

## Deployment Strategy
All components are Dockerized and managed via `docker-compose.yml` for local development. CI/CD pipelines will be integrated sequentially.
