# NOOR (نور): Elite AI Real Estate Concierge 🎙️🏢

NOOR is a premium, "Elite Bright Tech" AI concierge designed exclusively for the high-end real estate market in Qatar. It transcends traditional property searching by providing an intelligent, voice-first interface that handles everything from property discovery to lease management.

## ✨ Ecosystem Capabilities

- **Elite Bright Tech UI**: A state-of-the-art, high-contrast light interface inspired by Apple and Tesla design aesthetics. Minimalist, professional, and razor-sharp.
- **Bilingual Intelligence (Arabic & English)**: NOOR autonomously detects spoken language and adapts her persona. Full RTL support for the Arabic market.
- **Voice-First Interaction**: Driven by a static, premium AI Orb. High-fidelity voice responses with haptic synchronization.
- **Data-Driven Portfolio**: Integrated management of properties, viewings, and documents (PDF Leases, Qatar IDs) with a secure, centralized dashboard.
- **Market Pulse Analytics**: Real-time tracking of neighborhood yields, ROI trends, and premium asset performance.

## 🧠 Tech Stack

### **Frontend**
- **Framework**: Flutter (Dart)
- **Theme**: "Elite Brightness" (Solid surfaces, high readability, accent teal)
- **Sensors**: GPS, Compass, and Haptic Resonance.

### **Backend**
- **Reasoning Engine**: Groq-accelerated Llama 3 70B (Sub-second latency).
- **Audio Intelligence**: Faster-Whisper (STT) & Edge-TTS (Cloud synthesis).
- **Core API**: FastAPI with WebSocket streaming.
- **Database**: SQLite (Core Data), Redis (Cache), and Qdrant (Vector search).

## 🛠️ Setup & Security

### 1. Environment Protected
Local credentials and API keys are stored in `backend/.env` and are strictly excluded from version control via `.gitignore`.

### 2. Backend Boot
```bash
# Requires Docker
cd backend
docker-compose up --build
```

### 3. Mobile Build
```bash
cd frontend
flutter pub get
# Connect your Android device
./build_android.bat
```

---

**Developed for Synic Intelligence Systems | NOOR Core v5.2.0**
