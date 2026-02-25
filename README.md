<div align="center">

#  TransitAI Platform
### *Aura — AI-Powered Virtual Air Hostess*

![Unreal Engine](https://img.shields.io/badge/Unreal_Engine-5.5-black?style=for-the-badge&logo=unrealengine)
![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?style=for-the-badge&logo=flutter)
![WebRTC](https://img.shields.io/badge/WebRTC-Realtime-red?style=for-the-badge&logo=webrtc)
![Convai](https://img.shields.io/badge/Convai-AI_Engine-purple?style=for-the-badge)
![Node.js](https://img.shields.io/badge/Node.js-Signaling-339933?style=for-the-badge&logo=nodedotjs)

> **Namaste! Main Aura hoon** — A lifelike MetaHuman Air Hostess powered by Unreal Engine 5.5, Convai AI, and WebRTC Pixel Streaming. Built for airports, smart kiosks, and immersive passenger assistance.

</div>

---

## 🌟 What is TransitAI?

**TransitAI** is a modular, AI-powered virtual human assistant platform that delivers real-time, interactive guidance in physical environments — starting with airports, featuring **Aura**, your AI-powered cabin crew assistant.

Aura speaks **Hinglish (Hindi + English)**, understands passenger queries, performs real-time lip-sync, and responds with the warmth and grace of a real air hostess — all powered by a MetaHuman avatar streamed live to any smartphone.

---
---

## ✨ Key Features

### Core Capabilities

| Feature | Description | Status |
|---------|-------------|--------|
| 🎭 **MetaHuman Avatar** | Photorealistic UE5 character with full facial animation | ✅ Live |
| 🔊 **Real-Time Lip Sync** | Audio-driven mouth movement synced to TTS output | ✅ Live |
| 🧠 **Conversational AI** | Convai-powered NLU with contextual memory | ✅ Live |
| 🌐 **WebRTC Streaming** | Sub-100ms latency avatar streaming to mobile | ✅ Live |
| 🗣️ **Hinglish NLP** | Bidirectional Hindi ↔ English language support | ✅ Live |
| 📱 **Flutter Mobile Client** | Cross-platform iOS & Android support | ✅ Live |
| 🔁 **Signaling Server** | WebSocket-based WebRTC session management | ✅ Live |
| 🎙️ **Voice Input** | Real-time microphone capture and STT processing | ✅ Live |
| 💬 **Text Fallback** | Text input mode for noisy environments | ✅ Live |
| 🌙 **Idle Animations** | Natural breathing and blinking when not speaking | 🔄 Beta |
| 📊 **Analytics Dashboard** | Interaction logs and session metrics | 🔄 Beta |
| 🌍 **Multilingual Expansion** | Tamil, Bengali, Marathi, Gujarati | ✅ live |
| 🔌 **Offline Edge Mode** | On-device AI inference without internet | 📅 Planned |

### Performance Characteristics


## 🎭 Meet Aura

| Attribute | Details |
|-----------|---------|
| 👩 **Name** | Aura |
| ✈️ **Role** | Lead Cabin Crew — SkyHigh Airways |
| 🗣️ **Language** | Hinglish (Hindi + English) |
| 🧠 **AI Engine** | Convai (Character AI) |
| 🎨 **Renderer** | Unreal Engine 5.5 MetaHuman |
| 📱 **Client** | Flutter (Mobile App) |
| 📡 **Streaming** | WebRTC Pixel Streaming |

### Aura's Personality
- Warm, calm, and professional — even during turbulence 🌩️
- Greets every passenger with **"Namaste"** or **"Welcome aboard"**
- Switches between Hindi and English based on the passenger's language
- Uses polite Hindi words: *Kripya, Dhanyawad, Aap*
- Remains diplomatic with difficult passengers: *"Kripya shant rahein, main abhi check karti hoon."*

---

## 🏗️ System Architecture
```
┌─────────────────────────────────────────────────────┐
│                    USER (Passenger)                  │
│                  📱 Flutter App                      │
└────────────────────────┬────────────────────────────┘
                         │ WebRTC
┌────────────────────────▼────────────────────────────┐
│              🔁 Signaling Server (Node.js)           │
│           WebSocket — ICE Candidate Exchange         │
└──────────┬─────────────────────────────┬────────────┘
           │                             │
┌──────────▼──────────┐     ┌────────────▼────────────┐
│  🎭 Unreal Engine   │     │   🤖 Convai AI Engine    │
│  MetaHuman Avatar   │◄────│  NLU + Response + TTS    │
│  Pixel Streaming    │     │  Hinglish Character       │
│  Lip-Sync + Anim    │     └─────────────────────────┘
└─────────────────────┘
```

### Interaction Flow
```
1. 📱 User opens Flutter App
2. 📡 App connects via WebRTC Signaling Server
3. 🎭 Unreal Engine streams Aura (MetaHuman) to phone
4. 🎙️ User speaks (Hindi / English)
5. 🤖 Convai AI processes query → generates Hinglish response
6. 🔊 Response converted to speech (TTS)
7. 👄 Unreal Engine syncs Aura's lip movements to audio
8. ✨ Aura responds in real-time — live on screen
```

---

## 📁 Project Structure
```
transitai-platform/
│
├── 📱 flutter_client/              # Mobile App (Flutter + Dart)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── services/
│   │   │   └── pixel_streaming_service.dart
│   │   ├── screens/
│   │   └── widgets/
│   ├── pubspec.yaml
│   └── README.md
│
├── 🎭 unreal_avatar/               # Unreal Engine 5.5 Project
│   ├── Config/
│   ├── Content/
│   │   ├── MetaHuman/             # Aura — MetaHuman character
│   │   ├── Animations/            # Facial + body animations
│   │   └── Maps/                  # Scene / environment
│   └── TransitAI.uproject
│
├── 📡 signaling_server/            # Node.js WebRTC Signaling
│   ├── server.js
│   ├── package.json
│   └── README.md
│
├── 📚 docs/                        # Documentation
│   ├── architecture.md
│   ├── workflow.md
│   └── diagrams/
│
├── 🖼️ assets/                      # Media & Visuals
│   ├── screenshots/
│   └── demo/
│
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Unreal Engine | 5.5+ | Avatar rendering |
| Flutter SDK | 3.x+ | Mobile client |
| Node.js | 18+ | Signaling server |
| Convai Account | — | AI character engine |
| Git LFS | — | Large asset handling |

---

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/yourusername/transitai-platform.git
cd transitai-platform
```

---

### 2️⃣ Start the Signaling Server
```bash
cd signaling_server
npm install
node server.js
```

> Server runs on `ws://localhost:8080` by default.

---

### 3️⃣ Run the Flutter Client
```bash
cd flutter_client
flutter pub get
flutter run
```

> Make sure your device and PC are on the same local network.

---

### 4️⃣ Launch Unreal Engine Project
```
1. Open `unreal_avatar/TransitAI.uproject` in Unreal Engine 5.5
2. Select your MetaHuman (Aura) in the scene
3. In the Convai Chatbot Component → paste your Character ID
4. Enable Pixel Streaming plugin (Edit → Plugins → Pixel Streaming ✅)
5. Click Compile & Save
6. Hit ▶ Play
```

---

### 5️⃣ Configure Convai (Aura's Soul)

Paste the following into your **Convai Dashboard → Backstory field**:
```
Name: Aura
Role: Lead Cabin Crew / Air Hostess for SkyHigh Airways.

Personality:
Aura is the definition of grace and professionalism. She is warm, welcoming,
and incredibly calm, even during turbulence. She speaks a beautiful blend of
formal Hindi and professional English (Hinglish). She always puts passenger
safety and comfort first.

Core Knowledge & Tasks:
1. Greets every passenger with "Namaste" or "Welcome aboard."
2. Knows all safety protocols (seatbelts, oxygen masks, emergency exits).
3. Provides information about in-flight meals and beverages.
4. Assists with medical concerns or flight anxiety using a soothing tone.

Speaking Style:
- Uses polite Hindi words: "Kripya" (Please), "Dhanyawad" (Thank you), "Aap" (You - respectful).
- Responds in English if asked in English. Responds in Hindi if asked in Hindi.
- Example: "Namaste! Main Aura hoon. Main aapki kya sahayata kar sakti hoon?"

Constraint:
Never be rude. If a passenger is difficult, say:
"I understand your concern, sir/ma'am. Kripya shant rahein, main abhi check karti hoon."
```

**Voice Setting:** Choose a soft Indian English female voice in Convai.
**Language Setting:** Set primary language to **Hindi** for accurate lip-sync.

---

## 🧪 Test Aura — Try These Phrases
```
✅ "Hello Aura! Namaste."
✅ "Mera seatbelt kaam nahi kar raha." (My seatbelt isn't working.)
✅ "What is for dinner today?"
✅ "Main bohot nervous hoon, yeh meri pehli flight hai."
✅ "Where is the emergency exit?"
```

---

## ⚙️ Troubleshooting

| Issue | Fix |
|-------|-----|
| Mouth moves but no sound | Set Windows Default Microphone in UE5 Audio Settings |
| Flutter can't connect | Ensure PC & phone are on same WiFi network |
| Black screen on stream | Enable Pixel Streaming plugin and restart editor |
| Convai not responding | Check Character ID in the Convai Chatbot component |
| High RAM usage | Use face-only MetaHuman mesh, disable unused plugins |

---

## ⚡ Design Principles

| Principle | Description |
|-----------|-------------|
| 🚀 **Low Latency** | WebRTC ensures near real-time interaction |
| 🧩 **Modular** | Each component scales independently |
| 📱 **Edge Compatible** | Runs on standard consumer smartphones |
| 🔌 **Extensible** | Swap AI models or UI with ease |
| 🎭 **Realistic** | MetaHuman delivers human-like presence |

---

## 🌍 Expansion Roadmap

- [x] ✈️ Airport Navigation Assistant (Aura)
- [ ] 🚇 Metro Rail Kiosks
- [ ] 🏥 Hospital Guidance Assistant
- [ ] 🛍️ Retail Environment Helper
- [ ] 🌐 Multilingual Support (Tamil, Bengali, Marathi)
- [ ] 🔌 Offline Edge Deployment

---

## 🔐 Ethics & Privacy

- No personal data stored without explicit consent
- Transparent AI responses — Aura identifies herself as AI
- Human override available in critical scenarios
- Privacy-first voice handling — audio not retained post-session

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| 🎭 Avatar Rendering | Unreal Engine 5.5 + MetaHuman Creator |
| 🤖 AI Engine | Convai (NLU + TTS + Character AI) |
| 📱 Mobile Client | Flutter (Dart) |
| 📡 Streaming | WebRTC Pixel Streaming |
| 🔁 Signaling | Node.js + WebSocket (ws) |
| 🎨 Animation | Animation Blueprints + Live Link |

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with ❤️ for the future of human-AI interaction**

*"Namaste! Main Aura hoon. Aapka safar shubh ho."* ✈️

</div>
